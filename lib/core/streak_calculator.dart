import 'package:timezone/timezone.dart' as tz;

import '../models/dose.dart';

/// What happened on one calendar day.
class DayTally {
  int taken = 0;
  int skipped = 0;
  int missed = 0;
  int pending = 0;

  /// Good day: at least one taken and nothing missed.
  bool get isGood => taken > 0 && missed == 0;

  /// Bad day: something was missed.
  bool get isBad => missed > 0;
}

class StreakResult {
  const StreakResult({
    required this.current,
    required this.longest,
    required this.totalTaken,
    required this.days,
    this.reachedStart = false,
    this.oldestDay,
  });

  final int current;
  final int longest;
  final int totalTaken;
  final Map<DateTime, DayTally> days;

  /// The current streak ran back to the oldest day that was given: it may be
  /// longer than what the history shows (the caller can load more).
  final bool reachedStart;

  /// The oldest day that has any dose in the data given (null = none).
  final DateTime? oldestDay;
}

/// Streaks from dose history (M7, M22 step 3). Pure.
///
///  * the day of a dose is its calendar date in [zone] (the PROFILE's zone; the
///    phone's own zone when none is given); all date arithmetic is on
///    calendar dates (never "minus 24 hours", which breaks on a daylight-saving
///    day);
///  * good day = at least one taken and none missed; skipped is neutral;
///  * a pending dose past its miss deadline counts as missed;
///  * days with nothing decided (no doses, only pending, only skipped) neither
///    break nor extend a streak: a Mon/Wed/Fri medicine keeps its streak over
///    Tuesday, and today stays open until its first dose is taken or missed;
///  * as-needed (PRN) doses are ignored.
class StreakCalculator {
  StreakCalculator._();

  static DateTime dateKey(DateTime local) =>
      DateTime.utc(local.year, local.month, local.day);

  /// The calendar date of [at] in [zone] (or the phone's zone), as a UTC
  /// midnight value.
  static DateTime dayIn(DateTime at, tz.Location? zone) {
    if (zone == null) return dateKey(at.toLocal());
    final z = tz.TZDateTime.from(at.toUtc(), zone);
    return DateTime.utc(z.year, z.month, z.day);
  }

  static StreakResult compute(
    Iterable<Dose> doses, {
    required DateTime now,
    tz.Location? zone,
  }) {
    final today = dayIn(now, zone);
    final days = <DateTime, DayTally>{};

    for (final dose in doses) {
      if (dose.isPrn) continue;
      final key = dayIn(dose.scheduledAt, zone);
      if (key.isAfter(today)) continue; // the future has not happened
      final tally = days.putIfAbsent(key, DayTally.new);
      switch (dose.status) {
        case DoseStatus.taken:
          tally.taken++;
        case DoseStatus.skipped:
          tally.skipped++;
        case DoseStatus.missed:
          tally.missed++;
        case DoseStatus.pending:
        case DoseStatus.snoozed:
          if (dose.missDeadline.isBefore(now)) {
            tally.missed++;
          } else {
            tally.pending++;
          }
      }
    }

    final keys = days.keys.toList()..sort();

    var current = 0;
    var broke = false;
    for (final key in keys.reversed) {
      final tally = days[key]!;
      if (tally.isBad) {
        broke = true;
        break;
      }
      if (tally.isGood) current++;
    }

    var longest = 0;
    var run = 0;
    for (final key in keys) {
      final tally = days[key]!;
      if (tally.isBad) {
        run = 0;
      } else if (tally.isGood) {
        run++;
        if (run > longest) longest = run;
      }
    }

    final totalTaken = days.values.fold<int>(0, (a, d) => a + d.taken);
    return StreakResult(
      current: current,
      longest: longest,
      totalTaken: totalTaken,
      days: days,
      reachedStart: !broke && current > 0,
      oldestDay: keys.isEmpty ? null : keys.first,
    );
  }

  /// Taken / (taken + missed + skipped) for the calendar month of [now], as a
  /// rounded percent; 0 when nothing was decided.
  static int monthAdherencePercent(
    StreakResult r, {
    required DateTime now,
    tz.Location? zone,
  }) {
    final today = dayIn(now, zone);
    var taken = 0, other = 0;
    r.days.forEach((key, t) {
      if (key.year == today.year && key.month == today.month) {
        taken += t.taken;
        other += t.missed + t.skipped;
      }
    });
    final total = taken + other;
    return total == 0 ? 0 : ((taken / total) * 100).round();
  }
}
