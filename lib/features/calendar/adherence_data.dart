import '../meds/meds_data.dart';

/// ============================================================
/// ADHERENCE DATA
///
/// Adherence Detail ki data/model layer.
///
/// Current phase:
/// Dummy adherence records.
///
/// Future:
/// Firestore dose-history records se ye calculations hongi.
/// UI ko percentage/count manually calculate nahi karna padega.
/// ============================================================

enum AdherenceDoseStatus { taken, missed, skipped }

/// ============================================================
/// DATE RANGE FILTER
/// ============================================================

enum AdherenceRange { sevenDays, thirtyDays, ninetyDays, custom }

/// ============================================================
/// SINGLE ADHERENCE RECORD
///
/// Backend mein ideally ek scheduled dose / dose-history
/// document ko represent karega.
/// ============================================================

class AdherenceRecord {
  const AdherenceRecord({
    required this.id,
    required this.medicineName,
    required this.strength,
    required this.medicineType,
    required this.date,
    required this.status,
    required this.frequencyLabel,
  });

  final String id;
  final String medicineName;
  final String strength;
  final MedicineType medicineType;

  final DateTime date;

  final AdherenceDoseStatus status;

  /// Example:
  /// 2x daily
  /// 1x daily
  /// Evening
  /// Course ending
  final String frequencyLabel;

  String get displayName {
    if (strength.trim().isEmpty) {
      return medicineName;
    }

    return '$medicineName $strength';
  }

  String? get medicineImageAsset {
    switch (medicineType) {
      case MedicineType.tablet:
        return 'assets/images/tablet.jpg';

      case MedicineType.capsule:
        return 'assets/images/capsule.jpg';

      case MedicineType.liquid:
        return 'assets/images/liquid.jpg';

      case MedicineType.injection:
        return 'assets/images/injection.jpg';

      case MedicineType.drops:
        return null;
    }
  }
}

/// ============================================================
/// PER MEDICATION SUMMARY
/// ============================================================

class MedicationAdherenceSummary {
  const MedicationAdherenceSummary({
    required this.name,
    required this.strength,
    required this.type,
    required this.frequencyLabel,
    required this.taken,
    required this.missed,
    required this.skipped,
  });

  final String name;
  final String strength;
  final MedicineType type;
  final String frequencyLabel;

  final int taken;
  final int missed;
  final int skipped;

  String get displayName {
    if (strength.trim().isEmpty) {
      return name;
    }

    return '$name $strength';
  }

  int get total => taken + missed + skipped;

  /// Adherence:
  /// Taken / total scheduled outcomes.
  int get adherencePercent {
    if (total == 0) return 0;

    return ((taken / total) * 100).round();
  }

  double get progress {
    if (total == 0) return 0;

    return (taken / total).clamp(0.0, 1.0);
  }

  String get breakdownLabel {
    final parts = <String>['$taken taken'];

    if (missed > 0) {
      parts.add('$missed missed');
    }

    if (skipped > 0) {
      parts.add('$skipped skipped');
    }

    return parts.join(' · ');
  }

  String? get medicineImageAsset {
    switch (type) {
      case MedicineType.tablet:
        return 'assets/images/tablet.jpg';

      case MedicineType.capsule:
        return 'assets/images/capsule.jpg';

      case MedicineType.liquid:
        return 'assets/images/liquid.jpg';

      case MedicineType.injection:
        return 'assets/images/injection.jpg';

      case MedicineType.drops:
        return null;
    }
  }
}

/// ============================================================
/// OVERALL SUMMARY
/// ============================================================

class AdherenceSummary {
  const AdherenceSummary({
    required this.taken,
    required this.missed,
    required this.skipped,
    required this.previousPeriodPercent,
  });

  final int taken;
  final int missed;
  final int skipped;

  final int previousPeriodPercent;

  int get total => taken + missed + skipped;

  int get adherencePercent {
    if (total == 0) return 0;

    return ((taken / total) * 100).round();
  }

  double get adherenceProgress {
    if (total == 0) return 0;

    return (taken / total).clamp(0.0, 1.0);
  }

  int get differenceFromPrevious {
    return adherencePercent - previousPeriodPercent;
  }
}

/// ============================================================
/// DATA PROVIDER
/// ============================================================

class AdherenceData {
  AdherenceData._();

  /// Goal shown in progress ring.
  ///
  /// TODO Backend:
  /// Future mein user preference / health goal se aa sakta hai.
  static int adherenceGoalPercent() => 80;

  /// ==========================================================
  /// DATE RANGE
  /// ==========================================================

  static DateTime rangeStart({
    required AdherenceRange range,
    required DateTime endDate,
    DateTimeRangeValue? customRange,
  }) {
    switch (range) {
      case AdherenceRange.sevenDays:
        return endDate.subtract(const Duration(days: 6));

      case AdherenceRange.thirtyDays:
        return endDate.subtract(const Duration(days: 29));

      case AdherenceRange.ninetyDays:
        return endDate.subtract(const Duration(days: 89));

      case AdherenceRange.custom:
        return customRange?.start ?? endDate;
    }
  }

  /// ==========================================================
  /// RECORDS
  ///
  /// Current phase:
  /// Date range ke mutabiq deterministic dummy history.
  ///
  /// TODO Backend:
  /// Firestore query:
  ///
  /// current user
  /// + date >= startDate
  /// + date <= endDate
  ///
  /// Ek hi range query use karna hai.
  /// Har day ke liye separate Firebase query nahi.
  /// ==========================================================

  static List<AdherenceRecord> recordsForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final records = <AdherenceRecord>[];

    DateTime cursor = DateTime(startDate.year, startDate.month, startDate.day);

    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    var dayIndex = 0;

    while (!cursor.isAfter(normalizedEnd)) {
      // Metformin — mostly taken
      records.add(
        AdherenceRecord(
          id: 'metformin-${cursor.toIso8601String()}',
          medicineName: 'Metformin',
          strength: '500mg',
          medicineType: MedicineType.tablet,
          date: cursor,
          status: dayIndex % 7 == 3
              ? AdherenceDoseStatus.missed
              : AdherenceDoseStatus.taken,
          frequencyLabel: '2x daily',
        ),
      );

      records.add(
        AdherenceRecord(
          id: 'metformin-evening-${cursor.toIso8601String()}',
          medicineName: 'Metformin',
          strength: '500mg',
          medicineType: MedicineType.tablet,
          date: cursor,
          status: dayIndex % 9 == 4
              ? AdherenceDoseStatus.missed
              : AdherenceDoseStatus.taken,
          frequencyLabel: '2x daily',
        ),
      );

      // Amlodipine — high adherence
      records.add(
        AdherenceRecord(
          id: 'amlodipine-${cursor.toIso8601String()}',
          medicineName: 'Amlodipine',
          strength: '5mg',
          medicineType: MedicineType.tablet,
          date: cursor,
          status: dayIndex % 14 == 5
              ? AdherenceDoseStatus.missed
              : AdherenceDoseStatus.taken,
          frequencyLabel: '1x daily',
        ),
      );

      // Vitamin D3 — occasional skip
      records.add(
        AdherenceRecord(
          id: 'vitamin-${cursor.toIso8601String()}',
          medicineName: 'Vitamin D3',
          strength: 'Drops',
          medicineType: MedicineType.drops,
          date: cursor,
          status: dayIndex % 7 == 6
              ? AdherenceDoseStatus.skipped
              : AdherenceDoseStatus.taken,
          frequencyLabel: 'Evening',
        ),
      );

      // Amoxicillin — course example
      if (dayIndex < 10) {
        records.add(
          AdherenceRecord(
            id: 'amoxicillin-${cursor.toIso8601String()}',
            medicineName: 'Amoxicillin',
            strength: '250mg',
            medicineType: MedicineType.capsule,
            date: cursor,
            status: dayIndex % 4 == 2
                ? AdherenceDoseStatus.missed
                : AdherenceDoseStatus.taken,
            frequencyLabel: 'Course ending',
          ),
        );
      }

      cursor = cursor.add(const Duration(days: 1));

      dayIndex++;
    }

    return records;
  }

  /// ==========================================================
  /// OVERALL SUMMARY
  /// ==========================================================

  static AdherenceSummary overallSummary(List<AdherenceRecord> records) {
    final taken = records
        .where((record) => record.status == AdherenceDoseStatus.taken)
        .length;

    final missed = records
        .where((record) => record.status == AdherenceDoseStatus.missed)
        .length;

    final skipped = records
        .where((record) => record.status == AdherenceDoseStatus.skipped)
        .length;

    // TODO Backend:
    // Previous equivalent date range ki records query karke
    // actual comparison calculate karna hai.
    //
    // Current dummy comparison baseline.
    const previousPeriodPercent = 82;

    return AdherenceSummary(
      taken: taken,
      missed: missed,
      skipped: skipped,
      previousPeriodPercent: previousPeriodPercent,
    );
  }

  /// ==========================================================
  /// PER MEDICATION SUMMARY
  /// ==========================================================

  static List<MedicationAdherenceSummary> medicationSummaries(
    List<AdherenceRecord> records,
  ) {
    final grouped = <String, List<AdherenceRecord>>{};

    for (final record in records) {
      final key =
          '${record.medicineName}|'
          '${record.strength}';

      grouped.putIfAbsent(key, () => []);

      grouped[key]!.add(record);
    }

    final summaries = <MedicationAdherenceSummary>[];

    for (final group in grouped.values) {
      if (group.isEmpty) continue;

      final first = group.first;

      final taken = group
          .where((record) => record.status == AdherenceDoseStatus.taken)
          .length;

      final missed = group
          .where((record) => record.status == AdherenceDoseStatus.missed)
          .length;

      final skipped = group
          .where((record) => record.status == AdherenceDoseStatus.skipped)
          .length;

      summaries.add(
        MedicationAdherenceSummary(
          name: first.medicineName,
          strength: first.strength,
          type: first.medicineType,
          frequencyLabel: first.frequencyLabel,
          taken: taken,
          missed: missed,
          skipped: skipped,
        ),
      );
    }

    summaries.sort((a, b) => b.adherencePercent.compareTo(a.adherencePercent));

    return summaries;
  }

  /// Medication dropdown options.
  static List<String> medicationNames(List<MedicationAdherenceSummary> meds) {
    return meds.map((med) => med.displayName).toList();
  }
}

/// Simple DateTimeRange equivalent.
///
/// Data layer Flutter Material ke DateTimeRange par directly
/// dependent na ho, isliye lightweight model.
class DateTimeRangeValue {
  const DateTimeRangeValue({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
