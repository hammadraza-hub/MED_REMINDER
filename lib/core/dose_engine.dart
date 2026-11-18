import 'package:timezone/timezone.dart' as tz;

import '../models/dose.dart';
import '../models/medication.dart';
import '../models/schedule.dart';

/// DoseEngine — client-side dose generation (M6 logic).
///
/// Generates dose documents from a medication's schedule.
/// This is the client-side implementation of M6's generateDoses() function.
/// When Blaze plan is enabled, this logic moves to a Cloud Function
/// (functions/src/doses/generate.ts using Luxon).
///
/// Supports all 5 schedule types per PRD:
///   • daily      — Every day × times
///   • weekdays   — Specific weekdays × times
///   • cyclical   — Days on/off cycle × times
///   • taper      — Taper steps (days × doseAmount × times)
///   • PRN        — No scheduled doses (created on-demand when logged)
///
/// Deterministic ID: {medId}_{yyyyMMddHHmm} — prevents duplicates on regenerate.
/// The id is the INTENDED wall-clock slot of the profile's zone (a 02:30 dose
/// is `..._0230` even on the day 02:30 does not exist), so two slots can never
/// get the same id. Each local time converts to a UTC Timestamp for Firestore.
///
/// M22 step 2 (PDF M6): doses are generated in the PROFILE's time zone
/// (`zone`), the day loop walks CALENDAR dates (never "+24 hours", which is
/// wrong on a 23 h or 25 h daylight-saving day), a non-existent local time
/// moves forward (02:30 -> 03:30) and an ambiguous one resolves to its FIRST
/// occurrence.
///
/// Dates: `from`, `to`, `schedule.startDate`, `endDate` and `cycleStart` are
/// CALENDAR dates; only their year / month / day count (they are what the
/// person picked in the date picker). Both ends are inclusive.
class DoseEngine {
  /// How many days after today the default window reaches.
  static const int windowDays = 14;

  /// Generates doses for a medication from [from] to [to] (calendar dates,
  /// inclusive) in [zone].
  ///
  /// Parameters:
  ///   • medication — The medication to generate doses for
  ///   • profileId — Parent profile ID
  ///   • missedAfterMin — Minutes after scheduledAt before dose is missed
  ///   • from / to — First and last calendar day
  ///   • zone — The profile's time zone (`DoseZone.forProfile`)
  ///   • now — Only for `createdAt` (tests pass a fixed value)
  ///
  /// Returns a list of Dose objects with deterministic IDs, oldest first.
  /// PRN medications return an empty list.
  static List<Dose> generateDoses({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required DateTime from,
    required DateTime to,
    required tz.Location zone,
    DateTime? now,
  }) {
    final schedule = medication.schedule;
    if (schedule.type == ScheduleType.prn) {
      return []; // PRN doses are created on-demand when logged
    }

    var first = _date(from);
    var last = _date(to);

    // Not before the schedule starts, not after it ends (both inclusive).
    final start = _date(schedule.startDate);
    if (first.isBefore(start)) first = start;
    final end = schedule.endDate == null ? null : _date(schedule.endDate!);
    if (end != null && last.isAfter(end)) last = end;
    if (first.isAfter(last)) return [];

    final createdAt = (now ?? DateTime.now()).toUtc();
    final doses = <Dose>[];

    void addDay(DateTime day, List<String> times, double? amount) {
      for (final time in times) {
        doses.add(
          _createDose(
            medication: medication,
            profileId: profileId,
            missedAfterMin: missedAfterMin,
            date: day,
            timeStr: time,
            doseAmount: amount,
            zone: zone,
            createdAt: createdAt,
          ),
        );
      }
    }

    switch (schedule.type) {
      case ScheduleType.daily:
        for (var d = first; !d.isAfter(last); d = _nextDay(d)) {
          addDay(d, schedule.times, medication.doseAmount);
        }
      case ScheduleType.weekdays:
        for (var d = first; !d.isAfter(last); d = _nextDay(d)) {
          // DateTime.weekday: 1=Mon, 7=Sun (matches schedule.weekdays format)
          if (schedule.weekdays.contains(d.weekday)) {
            addDay(d, schedule.times, medication.doseAmount);
          }
        }
      case ScheduleType.cyclical:
        // PDF M6: a day is kept when daysSince(cycleStart) mod (on + off) < on.
        // Days BEFORE the cycle starts get no dose.
        final cycleOn = schedule.cycleOn ?? 0;
        final cycleLength = cycleOn + (schedule.cycleOff ?? 0);
        if (cycleLength <= 0) return [];
        final cycleStart = _date(schedule.cycleStart ?? schedule.startDate);
        for (var d = first; !d.isAfter(last); d = _nextDay(d)) {
          // Both are UTC midnights, so this is an exact number of days.
          final daysSince = d.difference(cycleStart).inDays;
          if (daysSince >= 0 && daysSince % cycleLength < cycleOn) {
            addDay(d, schedule.times, medication.doseAmount);
          }
        }
      case ScheduleType.taper:
        // Steps follow each other from the start date, `days` days each.
        var day = start;
        for (final step in schedule.taperSteps) {
          for (var i = 0; i < step.days; i++) {
            if (day.isAfter(last)) break;
            if (!day.isBefore(first)) addDay(day, step.times, step.doseAmount);
            day = _nextDay(day);
          }
          if (day.isAfter(last)) break;
        }
      case ScheduleType.prn:
        return [];
    }
    return doses;
  }

  /// Generates doses for the default window: today .. today + 14 days in the
  /// profile's zone (15 calendar days, both ends inclusive).
  /// Per M6 plan: "Turn schedules into concrete dose documents 14 days ahead."
  static List<Dose> generate14DayDoses({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required tz.Location zone,
    DateTime? now,
  }) {
    final today = todayIn(zone, now: now);
    return generateDoses(
      medication: medication,
      profileId: profileId,
      missedAfterMin: missedAfterMin,
      from: today,
      to: _addDays(today, windowDays),
      zone: zone,
      now: now,
    );
  }

  /// The doses of [generated] that must be WRITTEN: those whose id is not in
  /// [existingIds] (never overwrite a dose that is already there, it may be
  /// taken or skipped), and, when [notBefore] is given, only those at or after
  /// it (a schedule change touches the FUTURE only). M22 step 4.
  static List<Dose> onlyMissing(
    Iterable<Dose> generated,
    Set<String> existingIds, {
    DateTime? notBefore,
  }) => [
    for (final d in generated)
      if (!existingIds.contains(d.id) &&
          (notBefore == null || !d.scheduledAt.isBefore(notBefore)))
        d,
  ];

  /// Today's calendar date in [zone] (as a UTC midnight date value).
  static DateTime todayIn(tz.Location zone, {DateTime? now}) {
    final t = tz.TZDateTime.from((now ?? DateTime.now()).toUtc(), zone);
    return DateTime.utc(t.year, t.month, t.day);
  }

  // ============================================================
  // CALENDAR DATES
  // ============================================================

  /// Only year / month / day of [d], as a UTC midnight: date arithmetic on
  /// these never meets a daylight-saving shift.
  static DateTime _date(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime _nextDay(DateTime d) => _addDays(d, 1);

  static DateTime _addDays(DateTime d, int n) =>
      DateTime.utc(d.year, d.month, d.day + n);

  // ============================================================
  // ONE SLOT -> ONE INSTANT
  // ============================================================

  /// The instant of the wall-clock time [y]-[m]-[d] [hour]:[minute] in [zone].
  ///
  ///  * normal time: that instant;
  ///  * does not exist (spring forward, 02:30): moves forward by the gap
  ///    (03:30), like Luxon;
  ///  * happens twice (fall back, 01:30): the FIRST occurrence.
  static DateTime resolveSlot(
    tz.Location zone,
    int y,
    int m,
    int d,
    int hour,
    int minute,
  ) {
    final wall = DateTime.utc(y, m, d, hour, minute).millisecondsSinceEpoch;
    const dayMs = Duration.millisecondsPerDay;

    // The two offsets around the slot (they differ only near a transition).
    final before = zone.timeZone(wall - dayMs).offset.inMilliseconds;
    final after = zone.timeZone(wall + dayMs).offset.inMilliseconds;

    final valid = <int>[];
    for (final offset in {before, after}) {
      final instant = wall - offset;
      if (zone.timeZone(instant).offset.inMilliseconds == offset) {
        valid.add(instant);
      }
    }
    final int instant;
    if (valid.isEmpty) {
      // Gap: the wall time never showed on a clock. Read it with the offset
      // from BEFORE the jump; that lands after the jump (02:30 EST = 03:30 EDT).
      instant = wall - before;
    } else {
      valid.sort();
      instant = valid.first; // ambiguous: the first occurrence
    }
    return DateTime.fromMillisecondsSinceEpoch(instant, isUtc: true);
  }

  // ============================================================
  // CREATE SINGLE DOSE
  // ============================================================

  static Dose _createDose({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required DateTime date,
    required String timeStr,
    required double? doseAmount,
    required tz.Location zone,
    required DateTime createdAt,
  }) {
    // Parse time string "HH:mm"
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduledUtc = resolveSlot(
      zone,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    // missDeadline = scheduledAt + missedAfterMin
    final missDeadlineUtc = scheduledUtc.add(Duration(minutes: missedAfterMin));

    // Deterministic ID from the INTENDED slot: {medId}_{yyyyMMddHHmm}
    final idDateStr = _formatSlotForId(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    final doseId = '${medication.id}_$idDateStr';

    // Dose label (e.g., "1 tablet at 08:00")
    String doseLabel;
    if (doseAmount != null && medication.doseUnit != null) {
      doseLabel =
          '${_formatDoseAmount(doseAmount)} ${medication.doseUnit} at $timeStr';
    } else {
      doseLabel = 'Dose at $timeStr';
    }

    return Dose(
      id: doseId,
      profileId: profileId,
      medicationId: medication.id,
      medName: medication.name,
      doseLabel: doseLabel,
      scheduledAt: scheduledUtc,
      missDeadline: missDeadlineUtc,
      status: DoseStatus.pending,
      createdAt: createdAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Format a slot for the deterministic ID: yyyyMMddHHmm
  static String _formatSlotForId(int y, int m, int d, int h, int min) {
    return '${y.toString().padLeft(4, '0')}'
        '${m.toString().padLeft(2, '0')}'
        '${d.toString().padLeft(2, '0')}'
        '${h.toString().padLeft(2, '0')}'
        '${min.toString().padLeft(2, '0')}';
  }

  /// Format dose amount (remove trailing .0 for integers)
  static String _formatDoseAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return amount.toString();
  }

  /// Generates a PRN dose ID: {medId}_prn_{timestamp}
  /// Used when logging a PRN dose on-demand.
  static String generatePrnDoseId(String medicationId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${medicationId}_prn_$timestamp';
  }
}
