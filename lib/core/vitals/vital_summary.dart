import 'vital_types.dart';

/// ============================================================
/// VITAL SUMMARY — M15 step 1
///
/// Pure calculations on a list of readings:
///   - [VitalAnalysis.latest]  newest reading (for the "latest value" cards)
///   - [VitalAnalysis.trend]   up / down / stable
///   - [VitalAnalysis.dailySummaries]  per-day avg / min / max, the content of
///     `vitalsDaily/{type}_{yyyy-MM-dd}` used by long-range charts
///
/// Spark plan: there is no Cloud Function to keep the daily documents, so the
/// app writes them itself from these functions (repository, step 3).
/// ============================================================
enum VitalTrendDirection { up, down, stable }

/// One reading in canonical units. For blood pressure [value] is systolic and
/// [value2] diastolic.
class VitalPoint {
  const VitalPoint({required this.at, required this.value, this.value2});

  final DateTime at;
  final double value;
  final double? value2;
}

/// Per-day summary (document `vitalsDaily/{type}_{yyyy-MM-dd}`).
class VitalDaily {
  const VitalDaily({
    required this.dayKey,
    required this.count,
    required this.avg,
    required this.min,
    required this.max,
    this.avg2,
    this.min2,
    this.max2,
  });

  /// `yyyy-MM-dd` in the user's local time.
  final String dayKey;
  final int count;
  final double avg;
  final double min;
  final double max;

  /// Diastolic summary (blood pressure only).
  final double? avg2;
  final double? min2;
  final double? max2;

  /// Firestore document id: `{type}_{yyyy-MM-dd}`.
  String docId(VitalKind kind) => '${kind.wireName}_$dayKey';

  Map<String, Object?> toMap(VitalKind kind) => {
    'type': kind.wireName,
    'day': dayKey,
    'count': count,
    'avg': avg,
    'min': min,
    'max': max,
    if (avg2 != null) 'avg2': avg2,
    if (min2 != null) 'min2': min2,
    if (max2 != null) 'max2': max2,
  };
}

class VitalAnalysis {
  VitalAnalysis._();

  /// A change smaller than this (in percent) counts as "stable".
  static const double stableThresholdPercent = 2.0;

  /// How many earlier readings the latest one is compared with.
  static const int trendWindow = 3;

  /// Newest reading by time, or null when empty.
  static VitalPoint? latest(Iterable<VitalPoint> points) {
    VitalPoint? best;
    for (final p in points) {
      if (best == null || p.at.isAfter(best.at)) best = p;
    }
    return best;
  }

  /// Compares the newest value with the average of up to [trendWindow]
  /// readings before it. Fewer than two readings, or a change under
  /// [stableThresholdPercent], is stable. Blood pressure uses systolic.
  static VitalTrendDirection trend(Iterable<VitalPoint> points) {
    final sorted = points.toList()..sort((a, b) => a.at.compareTo(b.at));
    if (sorted.length < 2) return VitalTrendDirection.stable;

    final newest = sorted.last.value;
    final before = sorted.sublist(0, sorted.length - 1);
    final window = before.length > trendWindow
        ? before.sublist(before.length - trendWindow)
        : before;
    final baseline =
        window.fold<double>(0, (sum, p) => sum + p.value) / window.length;
    if (baseline == 0) return VitalTrendDirection.stable;

    final changePercent = (newest - baseline) / baseline * 100;
    if (changePercent.abs() < stableThresholdPercent) {
      return VitalTrendDirection.stable;
    }
    return changePercent > 0
        ? VitalTrendDirection.up
        : VitalTrendDirection.down;
  }

  /// Groups readings by local calendar day. Result is ordered by day.
  static List<VitalDaily> dailySummaries(Iterable<VitalPoint> points) {
    final byDay = <String, List<VitalPoint>>{};
    for (final p in points) {
      byDay.putIfAbsent(dayKey(p.at.toLocal()), () => []).add(p);
    }

    final days = byDay.keys.toList()..sort();
    return [for (final d in days) _summarise(d, byDay[d]!)];
  }

  static VitalDaily _summarise(String day, List<VitalPoint> pts) {
    final values = pts.map((p) => p.value).toList();
    final second = [
      for (final p in pts)
        if (p.value2 != null) p.value2!,
    ];

    return VitalDaily(
      dayKey: day,
      count: pts.length,
      avg: _round1(_avg(values)),
      min: _min(values),
      max: _max(values),
      avg2: second.isEmpty ? null : _round1(_avg(second)),
      min2: second.isEmpty ? null : _min(second),
      max2: second.isEmpty ? null : _max(second),
    );
  }

  /// `yyyy-MM-dd` for a local date.
  static String dayKey(DateTime local) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-'
        '${two(local.month)}-${two(local.day)}';
  }

  /// Start (inclusive) and end (exclusive) of the local calendar day
  /// `yyyy-MM-dd`, used to query that day's raw readings. Null if malformed.
  static ({DateTime start, DateTime end})? dayBounds(String dayKey) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dayKey);
    if (m == null) return null;
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    return (start: DateTime(y, mo, d), end: DateTime(y, mo, d + 1));
  }

  static double _avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
  static double _min(List<double> v) => v.reduce((a, b) => a < b ? a : b);
  static double _max(List<double> v) => v.reduce((a, b) => a > b ? a : b);
  static double _round1(double v) => (v * 10).roundToDouble() / 10;
}
