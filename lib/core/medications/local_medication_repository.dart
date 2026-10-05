import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'medication_repository.dart';

/// ============================================================
/// LOCAL MEDICATION REPOSITORY
///
/// Structured medication persistence:
/// Drift + SQLite.
///
/// IMPORTANT:
/// Schedule data aur inventory data Medications table mein duplicate
/// nahi ki jati.
///
/// MedicationSchedules:
/// frequency / time / dose schedule
///
/// InventoryRecords:
/// remaining stock / days remaining / LOW state
///
/// TODO Backend:
/// FirebaseMedicationRepository future mein same
/// MedicationRepository contract implement karegi.
/// ============================================================
class LocalMedicationRepository implements MedicationRepository {
  LocalMedicationRepository({AppDatabase? database})
    : _database = database ?? DatabaseProvider.instance;

  final AppDatabase _database;

  // ============================================================
  // WATCH ACTIVE
  // ============================================================

  @override
  Stream<List<MedicationProfile>> watchActiveMedications(String memberId) {
    final query = _database.select(_database.medications)
      ..where(
        (table) =>
            table.memberId.equals(memberId) & table.isActive.equals(true),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);

    return query.watch().map((rows) => rows.map(_mapMedication).toList());
  }

  // ============================================================
  // WATCH ARCHIVED
  // ============================================================

  @override
  Stream<List<MedicationProfile>> watchArchivedMedications(String memberId) {
    final query = _database.select(_database.medications)
      ..where(
        (table) =>
            table.memberId.equals(memberId) & table.isActive.equals(false),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]);

    return query.watch().map((rows) => rows.map(_mapMedication).toList());
  }

  // ============================================================
  // GET ACTIVE
  // ============================================================

  @override
  Future<List<MedicationProfile>> getActiveMedications(String memberId) async {
    final query = _database.select(_database.medications)
      ..where(
        (table) =>
            table.memberId.equals(memberId) & table.isActive.equals(true),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);

    final rows = await query.get();

    return rows.map(_mapMedication).toList();
  }

  // ============================================================
  // GET ARCHIVED
  // ============================================================

  @override
  Future<List<MedicationProfile>> getArchivedMedications(
    String memberId,
  ) async {
    final query = _database.select(_database.medications)
      ..where(
        (table) =>
            table.memberId.equals(memberId) & table.isActive.equals(false),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]);

    final rows = await query.get();

    return rows.map(_mapMedication).toList();
  }

  // ============================================================
  // GET ONE
  // ============================================================

  @override
  Future<MedicationProfile?> getMedicationById(String medicationId) async {
    final query = _database.select(_database.medications)
      ..where((table) => table.id.equals(medicationId));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _mapMedication(row);
  }

  // ============================================================
  // SAVE
  // ============================================================

  @override
  Future<void> saveMedication(MedicationProfile medication) async {
    await _database
        .into(_database.medications)
        .insertOnConflictUpdate(
          MedicationsCompanion(
            id: Value(medication.id),
            memberId: Value(medication.memberId),
            name: Value(medication.name),
            strength: Value(medication.strength),
            strengthUnit: Value(medication.strengthUnit),
            medicineForm: Value(medication.medicineForm),
            colorName: Value(medication.colorName),
            instructions: Value(medication.instructions),
            imagePath: Value(medication.imagePath),
            linkedPharmacyId: Value(medication.linkedPharmacyId),
            isActive: Value(medication.isActive),
            discontinuedAt: Value(medication.discontinuedAt),
            createdAt: Value(medication.createdAt),
            updatedAt: Value(medication.updatedAt),
          ),
        );
  }

  // ============================================================
  // DISCONTINUE
  // ============================================================

  @override
  Future<void> discontinueMedication({
    required String medicationId,
    required DateTime discontinuedAt,
  }) async {
    await (_database.update(
      _database.medications,
    )..where((table) => table.id.equals(medicationId))).write(
      MedicationsCompanion(
        isActive: const Value(false),
        discontinuedAt: Value(discontinuedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Historical schedules/dose events intentionally delete nahi hote.
    //
    // TODO Backend:
    // Firestore mein medication document:
    // isActive = false
    // discontinuedAt = server timestamp
    //
    // Dose history preserve karni hai.
  }

  // ============================================================
  // INITIAL LOCAL SEED
  // ============================================================

  @override
  Future<void> seedInitialMedicationsIfNeeded(String memberId) async {
    // Current dummy medicines Sarah ke existing frontend records hain.
    //
    // Isliye initial local migration seed sirf Sarah ke stable member
    // record ke liye create hota hai.
    //
    // Mom/Jake ko Sarah ki medicines automatically nahi milni chahiye.
    if (memberId != 'local_sarah') {
      return;
    }

    await _seedIfMissing(
      id: 'local_sarah_metformin',
      memberId: memberId,
      name: 'Metformin',
      strength: '500',
      strengthUnit: 'mg',
      medicineForm: 'tablet',
      imagePath: 'assets/images/tablet.jpg',
    );

    await _seedIfMissing(
      id: 'local_sarah_amlodipine',
      memberId: memberId,
      name: 'Amlodipine',
      strength: '5',
      strengthUnit: 'mg',
      medicineForm: 'tablet',
      imagePath: 'assets/images/tablet.jpg',
    );

    await _seedIfMissing(
      id: 'local_sarah_vitamin_d3_drops',
      memberId: memberId,
      name: 'Vitamin D3 Drops',
      strength: '1000',
      strengthUnit: 'IU',
      medicineForm: 'drops',
    );

    await _seedIfMissing(
      id: 'local_sarah_amoxicillin',
      memberId: memberId,
      name: 'Amoxicillin',
      strength: '250',
      strengthUnit: 'mg',
      medicineForm: 'capsule',
      imagePath: 'assets/images/capsule.jpg',
    );
  }

  Future<void> _seedIfMissing({
    required String id,
    required String memberId,
    required String name,
    required String strength,
    required String strengthUnit,
    required String medicineForm,
    String? imagePath,
  }) async {
    final existing = await getMedicationById(id);

    if (existing != null) {
      return;
    }

    final now = DateTime.now();

    await saveMedication(
      MedicationProfile(
        id: id,
        memberId: memberId,
        name: name,
        strength: strength,
        strengthUnit: strengthUnit,
        medicineForm: medicineForm,
        imagePath: imagePath,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // ============================================================
  // DB → DOMAIN
  // ============================================================

  MedicationProfile _mapMedication(Medication row) {
    return MedicationProfile(
      id: row.id,
      memberId: row.memberId,
      name: row.name,
      strength: row.strength,
      strengthUnit: row.strengthUnit,
      medicineForm: row.medicineForm,
      colorName: row.colorName,
      instructions: row.instructions,
      imagePath: row.imagePath,
      linkedPharmacyId: row.linkedPharmacyId,
      isActive: row.isActive,
      discontinuedAt: row.discontinuedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
