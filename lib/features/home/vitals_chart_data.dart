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

  /// Dummy frontend history.
  ///
  /// TODO Backend:
  /// Is method ko Firestore query/stream se replace karna:
  /// users/{uid}/members/{memberId}/vitalEntries
  /// where(type == selectedType)
  /// orderBy(measuredAt)
  static List<VitalChartReading> history(VitalType type) {
    final now = DateTime.now();

    switch (type) {
      case VitalType.bloodPressure:
        return _buildBloodPressureHistory(now);

      case VitalType.bloodGlucose:
        return _buildSingleValueHistory(
          now: now,
          base: 96,
          variation: const [-4, 2, 5, -1, 3, -2, 0, 4, -3, 2, 1, -1],
        );

      case VitalType.weight:
        return _buildSingleValueHistory(
          now: now,
          base: 72.4,
          step: 0.1,
          variation: const [6, 5, 5, 4, 3, 3, 2, 2, 1, 1, 0, 0],
        );

      case VitalType.heartRate:
        return _buildSingleValueHistory(
          now: now,
          base: 74,
          variation: const [-2, 3, -1, 2, 0, 4, -3, 1, 2, -2, 0, 1],
        );
    }
  }

  static List<VitalChartReading> _buildBloodPressureHistory(DateTime now) {
    const systolic = [
      122.0,
      124.0,
      121.0,
      127.0,
      125.0,
      123.0,
      126.0,
      129.0,
      124.0,
      128.0,
      126.0,
      128.0,
    ];

    const diastolic = [
      78.0,
      80.0,
      79.0,
      83.0,
      81.0,
      80.0,
      82.0,
      84.0,
      79.0,
      82.0,
      81.0,
      82.0,
    ];

    return List.generate(systolic.length, (index) {
      final daysAgo = (systolic.length - 1 - index) * 3;

      return VitalChartReading(
        recordedAt: DateTime(
          now.year,
          now.month,
          now.day,
          8,
        ).subtract(Duration(days: daysAgo)),
        primaryValue: systolic[index],
        secondaryValue: diastolic[index],
      );
    });
  }

  static List<VitalChartReading> _buildSingleValueHistory({
    required DateTime now,
    required double base,
    required List<int> variation,
    double step = 1,
  }) {
    return List.generate(variation.length, (index) {
      final daysAgo = (variation.length - 1 - index) * 3;

      return VitalChartReading(
        recordedAt: DateTime(
          now.year,
          now.month,
          now.day,
          8,
        ).subtract(Duration(days: daysAgo)),
        primaryValue: base + (variation[index] * step),
      );
    });
  }

  static List<VitalChartReading> filteredHistory(
    List<VitalChartReading> history,
    VitalChartRange range,
  ) {
    if (history.isEmpty) return [];

    final latestDate = history.last.recordedAt;

    final cutoff = latestDate.subtract(Duration(days: daysFor(range) - 1));

    final filtered = history.where((reading) {
      return !reading.recordedAt.isBefore(cutoff);
    }).toList();

    // Dummy dataset sparse hone ki wajah se 7D mein kam az kam
    // useful recent readings chart par visible rakho.
    if (range == VitalChartRange.days7 &&
        filtered.length < 3 &&
        history.length >= 3) {
      return history.sublist(history.length - 3);
    }

    return filtered;
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
