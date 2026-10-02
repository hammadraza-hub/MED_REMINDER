/// ============================================================
/// ADD VITALS ENTRY DATA
///
/// PURPOSE:
/// Log Vitals screen ki models, validation helpers aur dummy latest values.
///
/// FUTURE DATA FLOW:
/// Current User / Family Member
///   → selected Vital Type
///   → new Vital Entry
///   → Firestore
///   → Vitals List / Chart automatically refresh
///
/// TODO Backend:
/// - Latest reading selected memberId ke according query karna.
/// - New vital entry Firestore mein save karna.
/// - serverTimestamp use karna.
/// - Caregiver/provider sync backend se karna.
/// ============================================================

enum AddVitalType { bloodPressure, glucose, weight, heartRate }

class PreviousVitalReading {
  const PreviousVitalReading({
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  final String value;
  final String unit;
  final DateTime recordedAt;
}

class AddVitalsEntryResult {
  const AddVitalsEntryResult({
    required this.type,
    required this.recordedAt,
    required this.primaryValue,
    this.secondaryValue,
    this.pulse,
  });

  final AddVitalType type;
  final DateTime recordedAt;
  final double primaryValue;

  /// Blood Pressure ke liye diastolic value.
  final double? secondaryValue;

  /// Blood Pressure ke sath concurrent pulse.
  final int? pulse;
}

class AddVitalsEntryData {
  AddVitalsEntryData._();

  static String titleFor(AddVitalType type) {
    switch (type) {
      case AddVitalType.bloodPressure:
        return 'Blood Pressure';
      case AddVitalType.glucose:
        return 'Glucose';
      case AddVitalType.weight:
        return 'Weight';
      case AddVitalType.heartRate:
        return 'Heart Rate';
    }
  }

  static String unitFor(AddVitalType type) {
    switch (type) {
      case AddVitalType.bloodPressure:
        return 'mmHg';
      case AddVitalType.glucose:
        return 'mg/dL';
      case AddVitalType.weight:
        return 'kg';
      case AddVitalType.heartRate:
        return 'bpm';
    }
  }

  static String targetFor(AddVitalType type) {
    switch (type) {
      case AddVitalType.bloodPressure:
        return '<120/80';
      case AddVitalType.glucose:
        return '70–140 mg/dL';
      case AddVitalType.weight:
        return 'Personal goal';
      case AddVitalType.heartRate:
        return '60–100 bpm';
    }
  }

  static String primaryLabel(AddVitalType type) {
    switch (type) {
      case AddVitalType.bloodPressure:
        return 'SYSTOLIC (TOP)';
      case AddVitalType.glucose:
        return 'BLOOD GLUCOSE';
      case AddVitalType.weight:
        return 'WEIGHT';
      case AddVitalType.heartRate:
        return 'HEART RATE';
    }
  }

  static String primaryDefault(AddVitalType type) {
    switch (type) {
      case AddVitalType.bloodPressure:
        return '128';
      case AddVitalType.glucose:
        return '95';
      case AddVitalType.weight:
        return '72.4';
      case AddVitalType.heartRate:
        return '74';
    }
  }

  static String? secondaryDefault(AddVitalType type) {
    if (type == AddVitalType.bloodPressure) {
      return '82';
    }

    return null;
  }

  static PreviousVitalReading previousReading(AddVitalType type) {
    final now = DateTime.now();

    switch (type) {
      case AddVitalType.bloodPressure:
        return PreviousVitalReading(
          value: '124/80',
          unit: 'mmHg',
          recordedAt: DateTime(now.year, now.month, now.day - 1, 8, 15),
        );

      case AddVitalType.glucose:
        return PreviousVitalReading(
          value: '98',
          unit: 'mg/dL',
          recordedAt: DateTime(now.year, now.month, now.day - 1, 21, 30),
        );

      case AddVitalType.weight:
        return PreviousVitalReading(
          value: '72.6',
          unit: 'kg',
          recordedAt: DateTime(now.year, now.month, now.day - 3, 7, 30),
        );

      case AddVitalType.heartRate:
        return PreviousVitalReading(
          value: '72',
          unit: 'bpm',
          recordedAt: DateTime(now.year, now.month, now.day - 1, 7, 45),
        );
    }
  }

  static String valueStatus(
    AddVitalType type,
    double primary, {
    double? secondary,
  }) {
    switch (type) {
      case AddVitalType.bloodPressure:
        if (primary < 120 && secondary != null && secondary < 80) {
          return 'Normal';
        }

        if (primary < 130 && secondary != null && secondary < 80) {
          return 'Elevated';
        }

        return 'Review';

      case AddVitalType.glucose:
        if (primary >= 70 && primary <= 140) {
          return 'Normal';
        }

        return 'Review';

      case AddVitalType.weight:
        return 'Recorded';

      case AddVitalType.heartRate:
        if (primary >= 60 && primary <= 100) {
          return 'Normal';
        }

        return 'Review';
    }
  }
}
