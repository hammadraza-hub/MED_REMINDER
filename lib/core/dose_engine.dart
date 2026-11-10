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
/// Each local time converts to a UTC Timestamp for Firestore storage.
class DoseEngine {
  /// Generates doses for a medication from [from] to [to] date range.
  ///
  /// Parameters:
  ///   • medication — The medication to generate doses for
  ///   • profileId — Parent profile ID
  ///   • missedAfterMin — Minutes after scheduledAt before dose is missed
  ///   • from — Start date (inclusive)
  ///   • to — End date (inclusive)
  ///
  /// Returns a list of Dose objects with deterministic IDs.
  /// PRN medications return an empty list.
  static List<Dose> generateDoses({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required DateTime from,
    required DateTime to,
  }) {
    final schedule = medication.schedule;

    // Don't generate doses before schedule start date
    final effectiveFrom = from.isBefore(schedule.startDate)
        ? schedule.startDate
        : from;

    // Don't generate doses after schedule end date (if set)
    DateTime effectiveTo = to;
    if (schedule.endDate != null && to.isAfter(schedule.endDate!)) {
      effectiveTo = schedule.endDate!;
    }

    if (effectiveFrom.isAfter(effectiveTo)) return [];

    switch (schedule.type) {
      case ScheduleType.daily:
        return _generateDaily(
          medication: medication,
          profileId: profileId,
          missedAfterMin: missedAfterMin,
          from: effectiveFrom,
          to: effectiveTo,
        );
      case ScheduleType.weekdays:
        return _generateWeekdays(
          medication: medication,
          profileId: profileId,
          missedAfterMin: missedAfterMin,
          from: effectiveFrom,
          to: effectiveTo,
        );
      case ScheduleType.cyclical:
        return _generateCyclical(
          medication: medication,
          profileId: profileId,
          missedAfterMin: missedAfterMin,
          from: effectiveFrom,
          to: effectiveTo,
        );
      case ScheduleType.taper:
        return _generateTaper(
          medication: medication,
          profileId: profileId,
          missedAfterMin: missedAfterMin,
          from: effectiveFrom,
          to: effectiveTo,
        );
      case ScheduleType.prn:
        return []; // PRN doses are created on-demand when logged
    }
  }

  /// Generates doses for the default 14-day window (today + 14 days).
  /// Per M6 plan: "Turn schedules into concrete dose documents 14 days ahead."
  static List<Dose> generate14DayDoses({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
  }) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 14));

    return generateDoses(
      medication: medication,
      profileId: profileId,
      missedAfterMin: missedAfterMin,
      from: from,
      to: to,
    );
  }

  // ============================================================
  // DAILY — every day × times
  // ============================================================

  static List<Dose> _generateDaily({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required DateTime from,
    required DateTime to,
  }) {
    final doses = <Dose>[];
    final schedule = medication.schedule;

    DateTime currentDay = DateTime(from.year, from.month, from.day);
    final endDay = DateTime(to.year, to.month, to.day);

    while (!currentDay.isAfter(endDay)) {
      for (final time in schedule.times) {
        doses.add(
          _createDose(
            medication: medication,
            profileId: profileId,
            missedAfterMin: missedAfterMin,
            date: currentDay,
            timeStr: time,
            doseAmount: medication.doseAmount,
          ),
        );
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return doses;
  }

  // ============================================================
  // WEEKDAYS — specific days × times
  // ============================================================

  static List<Dose> _generateWeekdays({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required DateTime from,
    required DateTime to,
  }) {
    final doses = <Dose>[];
    final schedule = medication.schedule;

    DateTime currentDay = DateTime(from.year, from.month, from.day);
    final endDay = DateTime(to.year, to.month, to.day);

    while (!currentDay.isAfter(endDay)) {
      // DateTime.weekday: 1=Mon, 7=Sun (matches schedule.weekdays format)
      if (schedule.weekdays.contains(currentDay.weekday)) {
        for (final time in schedule.times) {
          doses.add(
            _createDose(
              medication: medication,
              profileId: profileId,
              missedAfterMin: missedAfterMin,
              date: currentDay,
              timeStr: time,
              doseAmount: medication.doseAmount,
            ),
          );
        }
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return doses;
  }

  // ============================================================
  // CYCLICAL — days on/off cycle × times
  // ============================================================

  static List<Dose> _generateCyclical({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required DateTime from,
    required DateTime to,
  }) {
    final doses = <Dose>[];
    final schedule = medication.schedule;

    final cycleStart = schedule.cycleStart ?? schedule.startDate;
    final cycleOn = schedule.cycleOn ?? 0;
    final cycleOff = schedule.cycleOff ?? 0;
    final cycleLength = cycleOn + cycleOff;

    if (cycleLength == 0) return [];

    final cycleStartDay = DateTime(
      cycleStart.year,
      cycleStart.month,
      cycleStart.day,
    );

    DateTime currentDay = DateTime(from.year, from.month, from.day);
    final endDay = DateTime(to.year, to.month, to.day);

    while (!currentDay.isAfter(endDay)) {
      // Calculate days since cycle start
      final daysSinceStart = currentDay.difference(cycleStartDay).inDays;

      // Check if this day is in the "on" period
      // daysSinceStart % cycleLength gives position in cycle
      // If < cycleOn, it's an "on" day
      final dayInCycle = daysSinceStart % cycleLength;
      if (dayInCycle >= 0 && dayInCycle < cycleOn) {
        for (final time in schedule.times) {
          doses.add(
            _createDose(
              medication: medication,
              profileId: profileId,
              missedAfterMin: missedAfterMin,
              date: currentDay,
              timeStr: time,
              doseAmount: medication.doseAmount,
            ),
          );
        }
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return doses;
  }

  // ============================================================
  // TAPER — taper steps (days × doseAmount × times)
  // ============================================================

  static List<Dose> _generateTaper({
    required Medication medication,
    required String profileId,
    required int missedAfterMin,
    required DateTime from,
    required DateTime to,
  }) {
    final doses = <Dose>[];
    final schedule = medication.schedule;

    final startDate = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    DateTime currentStepDay = startDate;
    final endDay = DateTime(to.year, to.month, to.day);

    for (final step in schedule.taperSteps) {
      // Each step lasts `step.days` days
      for (int dayInStep = 0; dayInStep < step.days; dayInStep++) {
        // Skip days before "from" or after "to"
        if (currentStepDay.isAfter(endDay)) break;
        if (!currentStepDay.isBefore(
          DateTime(from.year, from.month, from.day),
        )) {
          for (final time in step.times) {
            doses.add(
              _createDose(
                medication: medication,
                profileId: profileId,
                missedAfterMin: missedAfterMin,
                date: currentStepDay,
                timeStr: time,
                doseAmount: step.doseAmount, // Use step's doseAmount
              ),
            );
          }
        }
        currentStepDay = currentStepDay.add(const Duration(days: 1));
      }
      if (currentStepDay.isAfter(endDay)) break;
    }

    return doses;
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
  }) {
    // Parse time string "HH:mm"
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Create scheduledAt in local time, then convert to UTC
    final scheduledLocal = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    final scheduledUtc = scheduledLocal.toUtc();

    // missDeadline = scheduledAt + missedAfterMin
    final missDeadlineUtc = scheduledUtc.add(Duration(minutes: missedAfterMin));

    // Deterministic ID: {medId}_{yyyyMMddHHmm}
    final idDateStr = _formatDateForId(scheduledLocal);
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
      createdAt: DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Format date for deterministic ID: yyyyMMddHHmm
  static String _formatDateForId(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y$m$d$h$min';
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
