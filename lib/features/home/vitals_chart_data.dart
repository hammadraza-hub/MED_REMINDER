import '../../core/vitals/vital_models.dart';
import '../../core/vitals/vital_summary.dart';
import 'vitals_data.dart';

/// ============================================================
/// VITALS CHART DATA
///
/// PURPOSE:
/// Single vital ki historical readings, filtering, averages,
/// latest reading aur trend calculation ko UI se separate rakhna.
///
/// FUTURE BACKEND:
/// Current User / Family Member
///   → Vital Type
///   → Firestore Vital Entries
///   → Selected Date Range
///   → Chart / Latest / Average / Trend
///
/// TODO Backend:
/// - memberId ke basis par Firestore history query karna.
/// - selected range ke according measuredAt filter/query karna.
/// - realtime updates ke liye Firestore stream use karna.
/// ============================================================

enum VitalChartRange { days7, days30, days90, days365 }

class VitalChartReading {
  const VitalChartReading({
    required this.recordedAt,
    required this.primaryValue,
    this.secondaryValue,
  });

  final DateTime recordedAt;

  /// BP → systolic
  /// Glucose → mg/dL
  /// Weight → kg
  /// Heart Rate → bpm
  final double primaryValue;

  /// Sirf Blood Pressure ke liye diastolic.
  final double? secondaryValue;
}

class VitalReferenceRange {
  const VitalReferenceRange({
    required this.minimum,
    required this.maximum,
    required this.label,
  });

  final double minimum;
  final double maximum;
  final String label;
}

class VitalsChartData {
  VitalsChartData._();

  static int daysFor(VitalChartRange range) {
    switch (range) {
      case VitalChartRange.days7:
        return 7;
      case VitalChartRange.days30:
        return 30;
      case VitalChartRange.days90:
        return 90;
      case VitalChartRange.days365:
        return 365;
    }
  }

  static String rangeLabel(VitalChartRange range) {
    switch (range) {
      case VitalChartRange.days7:
        return '7D';
      case VitalChartRange.days30:
        return '30D';
      case VitalChartRange.days90:
        return '90D';
      case VitalChartRange.days365:
        return '365D';
    }
  }

  static String titleFor(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return 'Blood Pressure Trend';
      case VitalType.bloodGlucose:
        return 'Blood Glucose Trend';
      case VitalType.weight:
        return 'Weight Trend';
      case VitalType.heartRate:
        return 'Heart Rate Trend';
    }
  }

  static String chartTitleFor(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return 'Systolic / Diastolic';
      case VitalType.bloodGlucose:
        return 'Blood Glucose';
      case VitalType.weight:
        return 'Weight';
      case VitalType.heartRate:
        return 'Heart Rate';
    }
  }

  static String unitFor(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return 'mmHg';
      case VitalType.bloodGlucose:
        return 'mg/dL';
      case VitalType.weight:
        return 'kg';
      case VitalType.heartRate:
        return 'bpm';
    }
  }

  static VitalReferenceRange? referenceRange(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        // Chart par systolic target/reference band.
        return const VitalReferenceRange(
          minimum: 90,
          maximum: 120,
          label: 'Target <120/80',
        );

      case VitalType.bloodGlucose:
        return const VitalReferenceRange(
          minimum: 70,
          maximum: 140,
          label: 'Reference 70–140',
        );

      case VitalType.heartRate:
        return const VitalReferenceRange(
          minimum: 60,
          maximum: 100,
          label: 'Resting 60–100',
        );

      case VitalType.weight:
        // Weight ka universal healthy target user-specific hota hai.
        return null;
    }
  }

  // ------------------------------------------------------------
  // M15 step 5: real data -> chart points
  // ------------------------------------------------------------

  /// Raw readings (any order) -> chart points, oldest first.
  static List<VitalChartReading> fromReadings(Iterable<VitalReading> readings) {
    final list = readings.toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return [
      for (final r in list)
        VitalChartReading(
          recordedAt: r.measuredAt,
          primaryValue: r.value,
          secondaryValue: r.value2,
        ),
    ];
  }

  /// Daily summaries -> one chart point per day (the day's average, drawn at
  /// local noon), oldest first. Used for the long (365 day) range so the chart
  /// reads at most one small document per day.
  static List<VitalChartReading> fromDaily(Iterable<VitalDaily> days) {
    final out = <VitalChartReading>[];
    for (final d in days) {
      final bounds = VitalAnalysis.dayBounds(d.dayKey);
      if (bounds == null) continue;
      out.add(
        VitalChartReading(
          recordedAt: bounds.start.add(const Duration(hours: 12)),
          primaryValue: d.avg,
          secondaryValue: d.avg2,
        ),
      );
    }
    out.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return out;
  }

  /// First moment (local midnight) of the window shown for [range], counting
  /// today as day 1: 7D = today and the 6 days before.
  static DateTime windowStart(VitalChartRange range, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(today.year, today.month, today.day - (daysFor(range) - 1));
  }

  /// Readings inside the window of [range] (anchored on [now], default today).
  static List<VitalChartReading> filteredHistory(
    List<VitalChartReading> history,
    VitalChartRange range, {
    DateTime? now,
  }) {
    final start = windowStart(range, now ?? DateTime.now());
    return [
      for (final r in history)
        if (!r.recordedAt.isBefore(start)) r,
    ];
  }

  static double averagePrimary(List<VitalChartReading> readings) {
    if (readings.isEmpty) return 0;

    final total = readings.fold<double>(
      0,
      (sum, reading) => sum + reading.primaryValue,
    );

    return total / readings.length;
  }

  static double? averageSecondary(List<VitalChartReading> readings) {
    final values = readings
        .map((reading) => reading.secondaryValue)
        .whereType<double>()
        .toList();

    if (values.isEmpty) return null;

    final total = values.fold<double>(0, (sum, value) => sum + value);

    return total / values.length;
  }

  static VitalChartReading? latest(List<VitalChartReading> readings) {
    if (readings.isEmpty) return null;
    return readings.last;
  }

  static String averageLabel(VitalType type, List<VitalChartReading> readings) {
    if (readings.isEmpty) return '—';

    final primary = averagePrimary(readings);

    if (type == VitalType.bloodPressure) {
      final secondary = averageSecondary(readings) ?? 0;

      return '${primary.round()}/${secondary.round()}';
    }

    if (type == VitalType.weight) {
      return primary.toStringAsFixed(1);
    }

    return primary.round().toString();
  }

  static String readingValue(VitalType type, VitalChartReading reading) {
    if (type == VitalType.bloodPressure) {
      final secondary = reading.secondaryValue?.round() ?? 0;

      return '${reading.primaryValue.round()}/$secondary';
    }

    if (type == VitalType.weight) {
      return reading.primaryValue.toStringAsFixed(1);
    }

    return reading.primaryValue.round().toString();
  }

  static String statusFor(VitalType type, VitalChartReading reading) {
    switch (type) {
      case VitalType.bloodPressure:
        final diastolic = reading.secondaryValue ?? 0;

        if (reading.primaryValue < 120 && diastolic < 80) {
          return 'Normal';
        }

        if (reading.primaryValue < 130 && diastolic < 80) {
          return 'Elevated Normal';
        }

        return 'Review';

      case VitalType.bloodGlucose:
        if (reading.primaryValue >= 70 && reading.primaryValue <= 140) {
          return 'Normal';
        }
        return 'Review';

      case VitalType.weight:
        return 'Recorded';

      case VitalType.heartRate:
        if (reading.primaryValue >= 60 && reading.primaryValue <= 100) {
          return 'Normal';
        }
        return 'Review';
    }
  }

  static String trendSummary(
    VitalType type,
    List<VitalChartReading> readings,
    VitalChartRange range,
  ) {
    if (readings.length < 2) {
      return 'Add more readings to build a meaningful trend.';
    }

    final first = readings.first.primaryValue;
    final last = readings.last.primaryValue;
    final change = last - first;

    final rangeText = '${daysFor(range)} days';

    if (change.abs() < 3) {
      return 'Trend is stable over $rangeText';
    }

    if (change > 0) {
      return '${titleFor(type).replaceAll(' Trend', '')} has increased slightly over $rangeText';
    }

    return '${titleFor(type).replaceAll(' Trend', '')} has decreased slightly over $rangeText';
  }

  static String trendDetail(VitalType type, List<VitalChartReading> readings) {
    if (readings.length < 2) {
      return 'Continue logging readings to see personalized insights.';
    }

    final reference = referenceRange(type);
    final latestReading = readings.last;

    if (reference == null) {
      return 'Your recent readings remain consistent. Continue tracking regularly to monitor long-term changes.';
    }

    final value = latestReading.primaryValue;

    if (value >= reference.minimum && value <= reference.maximum) {
      return 'Recent readings remain comfortably within your current reference range.';
    }

    return 'Your latest reading is outside the reference range. Continue monitoring and follow your care plan.';
  }
}
