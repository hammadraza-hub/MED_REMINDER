/// ============================================================
/// MEDICATION SCHEDULE DOMAIN MODEL
///
/// Ek record ek medication ke ek dose/reminder time ko represent
/// karta hai.
///
/// Example:
/// Metformin 8:30 AM + 8:00 PM
/// → 2 MedicationScheduleProfile records.
///
/// UI Drift generated classes directly use nahi karegi.
/// ============================================================
class MedicationScheduleProfile {
  const MedicationScheduleProfile({
    required this.id,
    required this.medicationId,
    required this.memberId,
    required this.scheduleType,
    required this.timeOfDay,
    this.daysOfWeek,
    required this.doseAmount,
    this.doseUnit,
    required this.startDate,
    this.endDate,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String medicationId;
  final String memberId;

  /// daily / specific_days / cyclical / prn / tapering
  final String scheduleType;

  /// Persistent storage format: HH:mm
  /// Example: 08:30, 20:00
  final String timeOfDay;

  /// Persistent compact representation:
  /// "1,2,3,4,5"
  ///
  /// 1=Monday ... 7=Sunday.
  final String? daysOfWeek;

  final double doseAmount;
  final String? doseUnit;

  final DateTime startDate;
  final DateTime? endDate;

  final bool isEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;
}

/// ============================================================
/// MEDICATION SCHEDULE REPOSITORY CONTRACT
///
/// CURRENT:
/// LocalMedicationScheduleRepository → Drift / SQLite
///
/// FUTURE:
/// FirebaseMedicationScheduleRepository → Firestore
/// ============================================================
abstract class MedicationScheduleRepository {
  Stream<List<MedicationScheduleProfile>> watchSchedulesForMedication(
    String medicationId,
  );

  Future<List<MedicationScheduleProfile>> getSchedulesForMedication(
    String medicationId,
  );

  Future<void> saveSchedule(MedicationScheduleProfile schedule);

  /// Medication edit flow mein purani schedules replace karne ke liye.
  Future<void> deleteSchedulesForMedication(String medicationId);
}
