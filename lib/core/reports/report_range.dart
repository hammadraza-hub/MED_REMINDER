/// ============================================================
/// REPORT RANGE — M17 step 1
///
/// The date range of a report, in whole local calendar days (from the start of
/// the first day to the end of the last day). Pure Dart.
///
/// Days are counted as calendar days, never as 24-hour blocks, so a daylight
/// saving change or a time zone never adds or drops a day.
/// ============================================================
enum ReportRangeError {
  /// `from` is after `to`.
  fromAfterTo,

  /// More than [ReportRange.maxDays] days.
  tooLong,

  /// `to` is after today.
  inFuture,
}

class ReportRange {
  const ReportRange._(this.from, this.to);

  /// Longest allowed report: one year (spec M17 step 3).
  static const int maxDays = 365;

  /// First day, at 00:00 local time.
  final DateTime from;

  /// Last day, at 00:00 local time (the whole day is included).
  final DateTime to;

  /// Strips the time of day (local calendar day).
  static DateTime dayOf(DateTime t) {
    final l = t.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  /// The last [days] days ending today (today included): 7, 30 or 90.
  static ReportRange lastDays(int days, {DateTime? now}) {
    assert(days >= 1);
    final today = dayOf(now ?? DateTime.now());
    return ReportRange._(
      DateTime(today.year, today.month, today.day - (days - 1)),
      today,
    );
  }

  /// A custom range. Check it with [validate] before using it.
  factory ReportRange.custom(DateTime from, DateTime to) =>
      ReportRange._(dayOf(from), dayOf(to));

  /// Empty set means the range is fine.
  static Set<ReportRangeError> validate(
    DateTime from,
    DateTime to, {
    DateTime? now,
  }) {
    final f = dayOf(from);
    final t = dayOf(to);
    final today = dayOf(now ?? DateTime.now());
    final errors = <ReportRangeError>{};

    if (f.isAfter(t)) {
      errors.add(ReportRangeError.fromAfterTo);
    } else if (_daysBetween(f, t) + 1 > maxDays) {
      errors.add(ReportRangeError.tooLong);
    }
    if (t.isAfter(today)) errors.add(ReportRangeError.inFuture);
    return errors;
  }

  /// Number of calendar days, both ends included (7 for a week).
  int get dayCount => _daysBetween(from, to) + 1;

  /// Start of the range (inclusive).
  DateTime get start => from;

  /// First instant AFTER the range (exclusive end): midnight after `to`.
  DateTime get endExclusive => DateTime(to.year, to.month, to.day + 1);

  /// Is [t] inside the range (by its local calendar day)?
  bool contains(DateTime t) {
    final d = dayOf(t);
    return !d.isBefore(from) && !d.isAfter(to);
  }

  /// Every day of the range, oldest first.
  List<DateTime> get days => [
    for (var i = 0; i < dayCount; i++)
      DateTime(from.year, from.month, from.day + i),
  ];

  /// `yyyy-MM-dd` key of a day (same format as M15 `vitalsDaily`).
  static String dayKey(DateTime d) {
    final l = d.toLocal();
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    return '${l.year.toString().padLeft(4, '0')}-$m-$day';
  }

  static int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  @override
  bool operator ==(Object other) =>
      other is ReportRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'ReportRange(${dayKey(from)}..${dayKey(to)})';
}
