import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'medication_schedule_repository.dart';

/// ============================================================
/// LOCAL MEDICATION SCHEDULE REPOSITORY
///
/// Drift + SQLite schedule persistence.
///
/// TODO Backend:
/// FirebaseMedicationScheduleRepository same interface implement
/// karegi. Notification scheduling repository/service se separate
/// rahegi.
/// ============================================================
class LocalMedicationScheduleRepository
    implements MedicationScheduleRepository {
  LocalMedicationScheduleRepository({AppDatabase? database})
    : _database = database ?? DatabaseProvider.instance;

  final AppDatabase _database;

  @override
  Stream<List<MedicationScheduleProfile>> watchSchedulesForMedication(
    String medicationId,
  ) {
    final query = _database.select(_database.medicationSchedules)
      ..where(
        (table) =>
            table.medicationId.equals(medicationId) &
            table.isEnabled.equals(true),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.timeOfDay)]);

    return query.watch().map((rows) => rows.map(_mapSchedule).toList());
  }

  @override
  Future<List<MedicationScheduleProfile>> getSchedulesForMedication(
    String medicationId,
  ) async {
    final query = _database.select(_database.medicationSchedules)
      ..where((table) => table.medicationId.equals(medicationId))
      ..orderBy([(table) => OrderingTerm.asc(table.timeOfDay)]);

    final rows = await query.get();

    return rows.map(_mapSchedule).toList();
  }

  @override
  Future<void> saveSchedule(MedicationScheduleProfile schedule) async {
    await _database
        .into(_database.medicationSchedules)
        .insertOnConflictUpdate(
          MedicationSchedulesCompanion(
            id: Value(schedule.id),
            medicationId: Value(schedule.medicationId),
            memberId: Value(schedule.memberId),
            scheduleType: Value(schedule.scheduleType),
            timeOfDay: Value(schedule.timeOfDay),
            daysOfWeek: Value(schedule.daysOfWeek),
            doseAmount: Value(schedule.doseAmount),
            doseUnit: Value(schedule.doseUnit),
            startDate: Value(schedule.startDate),
            endDate: Value(schedule.endDate),
            isEnabled: Value(schedule.isEnabled),
            createdAt: Value(schedule.createdAt),
            updatedAt: Value(schedule.updatedAt),
          ),
        );
  }

  @override
  Future<void> deleteSchedulesForMedication(String medicationId) async {
    await (_database.delete(
      _database.medicationSchedules,
    )..where((table) => table.medicationId.equals(medicationId))).go();

    // TODO Backend:
    // Firestore implementation batch mein medication ki old active
    // schedules replace/delete karegi.
  }

  MedicationScheduleProfile _mapSchedule(MedicationSchedule row) {
    return MedicationScheduleProfile(
      id: row.id,
      medicationId: row.medicationId,
      memberId: row.memberId,
      scheduleType: row.scheduleType,
      timeOfDay: row.timeOfDay,
      daysOfWeek: row.daysOfWeek,
      doseAmount: row.doseAmount,
      doseUnit: row.doseUnit,
      startDate: row.startDate,
      endDate: row.endDate,
      isEnabled: row.isEnabled,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
