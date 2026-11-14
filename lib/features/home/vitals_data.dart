import 'package:flutter/material.dart';

import '../../core/vitals/vital_input.dart';
import '../../core/vitals/vital_models.dart';
import '../../core/vitals/vital_summary.dart';
import '../../core/vitals/vital_types.dart';

/// ============================================================
/// VITALS DATA
///
/// PURPOSE:
/// Vitals List screen ke dummy/frontend data ko UI se separate rakhna.
///
/// FUTURE DATA FLOW:
/// Current User / Family Member
///   → Vital Type
///   → Vital Entries
///   → Latest Value
///   → History
///   → Trend
///
/// TODO Backend:
/// - Firebase/Firestore se current user/family member ke vitals load karna.
/// - Latest value latest timestamp se calculate karna.
/// - Trend historical entries se calculate karna.
/// - Profile/caregiver sync state Firebase se load karna.
/// ============================================================

enum VitalType { bloodPressure, bloodGlucose, weight, heartRate }

enum VitalTrend { up, down, stable }

class VitalMetric {
  const VitalMetric({
    required this.id,
    required this.type,
    required this.title,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.trend,
    required this.history,
    required this.detailText,
  });

  final String id;
  final VitalType type;
  final String title;

  /// Examples:
  /// 128/82
  /// 95
  /// 72.4
  /// 74
  final String value;

  final String unit;
  final DateTime recordedAt;
  final VitalTrend trend;

  /// Small sparkline ke liye recent numeric values.
  ///
  /// Blood Pressure ke liye systolic values use ho rahi hain.
  final List<double> history;

  /// Examples:
  /// Target: <120/80
  /// Post-prandial (Normal)
  /// -0.6 kg this month
  /// Resting: 68 - 78 bpm
  final String detailText;

  IconData get icon {
    switch (type) {
      case VitalType.bloodPressure:
        return Icons.monitor_heart_rounded;
      case VitalType.bloodGlucose:
        return Icons.water_drop_rounded;
      case VitalType.weight:
        return Icons.monitor_weight_outlined;
      case VitalType.heartRate:
        return Icons.favorite_rounded;
    }
  }

  /// The trend is calculated when the metric is built (see
  /// [VitalsData.fromReadings]), so the card and the chart agree.
  VitalTrend get calculatedTrend => trend;

  IconData get trendIcon {
    switch (calculatedTrend) {
      case VitalTrend.up:
        return Icons.north_east_rounded;
      case VitalTrend.down:
        return Icons.south_east_rounded;
      case VitalTrend.stable:
        return Icons.east_rounded;
    }
  }
}

class VitalsData {
  VitalsData._();

  static bool get caregiverSyncLive => true;

  static List<VitalMetric> metrics() {
    final now = DateTime.now();

    return [
      VitalMetric(
        id: 'vital_bp',
        type: VitalType.bloodPressure,
        title: 'Blood Pressure',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: DateTime(now.year, now.month, now.day, 8),
        trend: VitalTrend.up,
        history: const [121, 123, 119, 124, 128],
        detailText: 'Target: <120/80',
      ),
      VitalMetric(
        id: 'vital_glucose',
        type: VitalType.bloodGlucose,
        title: 'Blood Glucose',
        value: '95',
        unit: 'mg/dL',
        recordedAt: DateTime(now.year, now.month, now.day - 1, 21, 30),
        trend: VitalTrend.stable,
        history: const [101, 97, 94, 98, 95],
        detailText: 'Post-prandial (Normal)',
      ),
      VitalMetric(
        id: 'vital_weight',
        type: VitalType.weight,
        title: 'Weight',
        value: '72.4',
        unit: 'kg',
        recordedAt: DateTime(now.year, now.month, now.day - 4, 7, 45),
        trend: VitalTrend.down,
        history: const [73.0, 72.9, 72.7, 72.5, 72.4],
        detailText: '-0.6 kg this month',
      ),
      VitalMetric(
        id: 'vital_hr',
        type: VitalType.heartRate,
        title: 'Heart Rate',
        value: '74',
        unit: 'bpm',
        recordedAt: DateTime(now.year, now.month, now.day, 7, 45),
        trend: VitalTrend.stable,
        history: const [72, 72, 76, 71, 74, 74, 72, 76, 73, 74],
        detailText: 'Resting: 68 - 78 bpm',
      ),
    ];
  }

  // ------------------------------------------------------------
  // M15 step 5: real data
  // ------------------------------------------------------------

  static VitalType typeOf(VitalKind kind) {
    switch (kind) {
      case VitalKind.bloodPressure:
        return VitalType.bloodPressure;
      case VitalKind.glucose:
        return VitalType.bloodGlucose;
      case VitalKind.weight:
        return VitalType.weight;
      case VitalKind.heartRate:
        return VitalType.heartRate;
    }
  }

  static VitalKind kindOf(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return VitalKind.bloodPressure;
      case VitalType.bloodGlucose:
        return VitalKind.glucose;
      case VitalType.weight:
        return VitalKind.weight;
      case VitalType.heartRate:
        return VitalKind.heartRate;
    }
  }

  static String titleFor(VitalKind kind) {
    switch (kind) {
      case VitalKind.bloodPressure:
        return 'Blood Pressure';
      case VitalKind.glucose:
        return 'Blood Glucose';
      case VitalKind.weight:
        return 'Weight';
      case VitalKind.heartRate:
        return 'Heart Rate';
    }
  }

  static VitalTrend _trendOf(VitalTrendDirection d) {
    switch (d) {
      case VitalTrendDirection.up:
        return VitalTrend.up;
      case VitalTrendDirection.down:
        return VitalTrend.down;
      case VitalTrendDirection.stable:
        return VitalTrend.stable;
    }
  }

  /// How many recent readings feed a card's sparkline and trend.
  static const int sparklineReadings = 10;

  /// One card per kind that has readings, in a fixed order. [newestFirst]
  /// holds each kind's latest readings, newest first (as the repository
  /// returns them). Kinds without readings get no card.
  static List<VitalMetric> fromReadings(
    Map<VitalKind, List<VitalReading>> newestFirst,
  ) {
    final out = <VitalMetric>[];

    for (final kind in VitalKind.values) {
      final recent = newestFirst[kind];
      if (recent == null || recent.isEmpty) continue;

      final window = recent.take(sparklineReadings).toList();
      final chronological = window.reversed.toList();
      final latest = window.first;

      final value = kind == VitalKind.bloodPressure && latest.value2 != null
          ? '${VitalInput.formatNumber(latest.value)}/'
                '${VitalInput.formatNumber(latest.value2!)}'
          : VitalInput.formatNumber(latest.value);

      out.add(
        VitalMetric(
          id: 'vital_${kind.wireName}',
          type: typeOf(kind),
          title: titleFor(kind),
          value: value,
          unit: latest.unit,
          recordedAt: latest.measuredAt,
          trend: _trendOf(
            VitalAnalysis.trend([for (final r in chronological) r.toPoint()]),
          ),
          history: [for (final r in chronological) r.value],
          detailText: _detailFor(kind, window),
        ),
      );
    }
    return out;
  }

  /// Short, honest sub-line for a card.
  static String _detailFor(VitalKind kind, List<VitalReading> newestFirst) {
    switch (kind) {
      case VitalKind.bloodPressure:
        return 'Target: <120/80';
      case VitalKind.glucose:
        return 'Reference: 70–140 mg/dL';
      case VitalKind.heartRate:
        return 'Resting: 60–100 bpm';
      case VitalKind.weight:
        if (newestFirst.length < 2) return 'First reading';
        final change = newestFirst[0].value - newestFirst[1].value;
        if (change.abs() < 0.05) return 'No change since last reading';
        final sign = change > 0 ? '+' : '-';
        return '$sign${VitalInput.formatNumber(double.parse(change.abs().toStringAsFixed(1)))} kg since last reading';
    }
  }

  /// How many cards were last recorded today (local time).
  static int loggedToday(List<VitalMetric> metrics, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return metrics.where((m) {
      final d = m.recordedAt.toLocal();
      return d.year == n.year && d.month == n.month && d.day == n.day;
    }).length;
  }

  static DateTime? latestUpdate(List<VitalMetric> metrics) {
    if (metrics.isEmpty) return null;

    var latest = metrics.first.recordedAt;

    for (final metric in metrics.skip(1)) {
      if (metric.recordedAt.isAfter(latest)) {
        latest = metric.recordedAt;
      }
    }

    return latest;
  }

  static int completedMorningLogs(List<VitalMetric> metrics) {
    final now = DateTime.now();

    return metrics.where((metric) {
      final date = metric.recordedAt;

      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      return isToday && date.hour < 12;
    }).length;
  }

  static int morningLogPercentage(List<VitalMetric> metrics) {
    if (metrics.isEmpty) return 0;

    final completed = completedMorningLogs(metrics);

    return ((completed / metrics.length) * 100).round().clamp(0, 100);
  }
}
