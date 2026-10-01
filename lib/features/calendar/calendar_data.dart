import '../meds/meds_data.dart';

/// ============================================================
/// CALENDAR DATA — dose history
///
/// Abhi local/dummy data.
/// Future mein Firestore dose-history collection se replace hogi.
/// ============================================================

enum DoseHistoryStatus { taken, missed, pending, upcoming }

enum DayAdherenceStatus { taken, partial, missed, none }

/// ============================================================
/// SINGLE DOSE HISTORY
/// ============================================================
class DoseHistoryItem {
  const DoseHistoryItem({
    required this.id,
    required this.medicineName,
    required this.strength,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.medicineType,
    this.missedReason,
  });

  final String id;
  final String medicineName;
  final String strength;
  final String subtitle;
  final String time;
  final DoseHistoryStatus status;
  final MedicineType medicineType;

  /// Missed dose ka saved reason.
  final String? missedReason;

  String get displayName {
    if (strength.trim().isEmpty) {
      return medicineName;
    }

    return '$medicineName $strength';
  }

  String get statusLabel {
    switch (status) {
      case DoseHistoryStatus.taken:
        return 'TAKEN';

      case DoseHistoryStatus.missed:
        return 'MISSED';

      case DoseHistoryStatus.pending:
        return 'PENDING';

      case DoseHistoryStatus.upcoming:
        return 'UPCOMING';
    }
  }

  /// Same medication images jo Meds suite use karti hai.
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

  /// Fallback icon ke liye temporary Medicine object banane ki
  /// zarurat nahi — CalendarScreen medicineType se icon resolve karegi.
}

/// ============================================================
/// CALENDAR DATA PROVIDER
/// ============================================================
class CalendarData {
  CalendarData._();

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  /// ==========================================================
  /// DOSES FOR DATE
  ///
  /// Current phase:
  /// Demo history selected date ke according generate hoti hai.
  ///
  /// TODO Backend:
  /// Firestore se current user ki selected date ki dose history
  /// fetch / stream hogi.
  ///
  /// Future source example:
  /// users/{uid}/doseHistory
  /// ==========================================================
  static List<DoseHistoryItem> dosesForDate(DateTime date) {
    final normalized = dateOnly(date);
    final today = dateOnly(DateTime.now());

    // ================= FUTURE =================
    if (normalized.isAfter(today)) {
      return const [
        DoseHistoryItem(
          id: 'metformin-future',
          medicineName: 'Metformin',
          strength: '500mg',
          subtitle: 'Tablet · Oral',
          time: '8:30 AM',
          status: DoseHistoryStatus.upcoming,
          medicineType: MedicineType.tablet,
        ),
        DoseHistoryItem(
          id: 'amlodipine-future',
          medicineName: 'Amlodipine',
          strength: '5mg',
          subtitle: 'Tablet · Blood Pressure',
          time: '7:00 AM',
          status: DoseHistoryStatus.upcoming,
          medicineType: MedicineType.tablet,
        ),
        DoseHistoryItem(
          id: 'vitamin-future',
          medicineName: 'Vitamin D3',
          strength: 'Drops',
          subtitle: 'Drops · Dietary Supplement',
          time: '8:00 PM',
          status: DoseHistoryStatus.upcoming,
          medicineType: MedicineType.drops,
        ),
      ];
    }

    // ================= TODAY =================
    if (isSameDate(normalized, today)) {
      return const [
        DoseHistoryItem(
          id: 'metformin-today',
          medicineName: 'Metformin',
          strength: '500mg',
          subtitle: 'Tablet · Oral',
          time: '8:30 AM',
          status: DoseHistoryStatus.pending,
          medicineType: MedicineType.tablet,
        ),
        DoseHistoryItem(
          id: 'amlodipine-today',
          medicineName: 'Amlodipine',
          strength: '5mg',
          subtitle: 'Tablet · Blood Pressure',
          time: '7:00 AM',
          status: DoseHistoryStatus.taken,
          medicineType: MedicineType.tablet,
        ),
        DoseHistoryItem(
          id: 'vitamin-today',
          medicineName: 'Vitamin D3',
          strength: 'Drops',
          subtitle: 'Drops · Dietary Supplement',
          time: '8:00 PM',
          status: DoseHistoryStatus.upcoming,
          medicineType: MedicineType.drops,
        ),
      ];
    }

    // ================= MISSED DEMO DAY =================
    //
    // Temporary deterministic dummy pattern.
    // Backend aane par ye condition remove hogi.
    if (normalized.day % 7 == 0) {
      return const [
        DoseHistoryItem(
          id: 'metformin-missed',
          medicineName: 'Metformin',
          strength: '500mg',
          subtitle: 'Tablet · Oral',
          time: '8:30 AM',
          status: DoseHistoryStatus.missed,
          medicineType: MedicineType.tablet,
        ),
        DoseHistoryItem(
          id: 'amlodipine-missed',
          medicineName: 'Amlodipine',
          strength: '5mg',
          subtitle: 'Tablet · Blood Pressure',
          time: '7:00 AM',
          status: DoseHistoryStatus.missed,
          medicineType: MedicineType.tablet,
          missedReason: 'Forgot',
        ),
      ];
    }

    // ================= PARTIAL DEMO DAY =================
    if (normalized.day % 5 == 0) {
      return const [
        DoseHistoryItem(
          id: 'metformin-partial',
          medicineName: 'Metformin',
          strength: '500mg',
          subtitle: 'Tablet · Oral',
          time: '8:30 AM',
          status: DoseHistoryStatus.taken,
          medicineType: MedicineType.tablet,
        ),
        DoseHistoryItem(
          id: 'amlodipine-partial',
          medicineName: 'Amlodipine',
          strength: '5mg',
          subtitle: 'Tablet · Blood Pressure',
          time: '7:00 AM',
          status: DoseHistoryStatus.missed,
          medicineType: MedicineType.tablet,
        ),
        DoseHistoryItem(
          id: 'vitamin-partial',
          medicineName: 'Vitamin D3',
          strength: 'Drops',
          subtitle: 'Drops · Dietary Supplement',
          time: '8:00 PM',
          status: DoseHistoryStatus.taken,
          medicineType: MedicineType.drops,
        ),
      ];
    }

    // ================= NORMAL PAST DAY =================
    return const [
      DoseHistoryItem(
        id: 'metformin-taken',
        medicineName: 'Metformin',
        strength: '500mg',
        subtitle: 'Tablet · Oral',
        time: '8:30 AM',
        status: DoseHistoryStatus.taken,
        medicineType: MedicineType.tablet,
      ),
      DoseHistoryItem(
        id: 'amlodipine-taken',
        medicineName: 'Amlodipine',
        strength: '5mg',
        subtitle: 'Tablet · Blood Pressure',
        time: '7:00 AM',
        status: DoseHistoryStatus.taken,
        medicineType: MedicineType.tablet,
      ),
    ];
  }

  /// ==========================================================
  /// DAY ADHERENCE
  ///
  /// Day ka color individual dose results se calculate hota hai.
  /// ==========================================================
  static DayAdherenceStatus adherenceForDate(DateTime date) {
    final doses = dosesForDate(date);

    if (doses.isEmpty) {
      return DayAdherenceStatus.none;
    }

    final completed = doses.where((dose) {
      return dose.status == DoseHistoryStatus.taken ||
          dose.status == DoseHistoryStatus.missed;
    }).toList();

    if (completed.isEmpty) {
      return DayAdherenceStatus.none;
    }

    final takenCount = completed
        .where((dose) => dose.status == DoseHistoryStatus.taken)
        .length;

    final missedCount = completed
        .where((dose) => dose.status == DoseHistoryStatus.missed)
        .length;

    if (takenCount > 0 && missedCount == 0) {
      return DayAdherenceStatus.taken;
    }

    if (takenCount == 0 && missedCount > 0) {
      return DayAdherenceStatus.missed;
    }

    return DayAdherenceStatus.partial;
  }
}
