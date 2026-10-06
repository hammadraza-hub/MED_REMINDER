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
/// 🆕 MODULE 1:
/// Seed ab schedules bhi SQLite mein insert karta hai.
///
/// 🆕 MODULE 2:
/// - discontinueMedication() ab reason bhi SQLite mein save karta hai
/// - saveMedication() course fields (courseDay/courseTotalDays) persist karta hai
/// - Amoxicillin seed ab course data (Day 4 of 10) ke saath hota hai
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

            // 🆕 MODULE 2
            discontinuedReason: Value(medication.discontinuedReason),
            courseDay: Value(medication.courseDay),
            courseTotalDays: Value(medication.courseTotalDays),

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
    String? reason,
  }) async {
    await (_database.update(
      _database.medications,
    )..where((table) => table.id.equals(medicationId))).write(
      MedicationsCompanion(
        isActive: const Value(false),
        discontinuedAt: Value(discontinuedAt),

        // 🆕 MODULE 2:
        // Discontinue modal ka reason ab SQLite mein persist hota hai.
        discontinuedReason: Value(reason),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Historical schedules/dose events intentionally delete nahi hote.
    //
    // TODO Backend:
    // Firestore mein medication document:
    // isActive = false
    // discontinuedAt = server timestamp
    // discontinuedReason = modal reason
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

    // ---------- 1) Medications seed ----------
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

    // 🆕 MODULE 2:
    // Amoxicillin course medicine hai — legacy MedsData mein
    // "Day 4 of 10" fixed demo progress tha. Ab SQLite se aata hai.
    // Module 5 (DoseEvents) se ye dynamic banega.
    await _seedIfMissing(
      id: 'local_sarah_amoxicillin',
      memberId: memberId,
      name: 'Amoxicillin',
      strength: '250',
      strengthUnit: 'mg',
      medicineForm: 'capsule',
      imagePath: 'assets/images/capsule.jpg',
      courseDay: 4,
      courseTotalDays: 10,
    );

    // ---------- 2) Schedules seed ----------
    await _seedSchedulesIfMissing(memberId);
  }

  /// Seeded medicines ke schedules MedicationSchedules table mein
  /// insert karta hai (agar pehle se na hon).
  ///
  /// Deterministic schedule IDs (sched_sarah_...) use hote hain
  /// isliye ye idempotent hai — jitni baar chale, duplicate nahi
  /// banega.
  Future<void> _seedSchedulesIfMissing(String memberId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Times MedsData legacy nextDose labels se align hain:
    // - Metformin   2x daily → 8:30 AM + 8:30 PM
    // - Amlodipine  1x daily → 7:00 AM
    // - Vitamin D3  1x daily → 8:00 PM
    // - Amoxicillin 3x daily → 8:00 AM + 2:00 PM + 8:00 PM
    const seedSchedules = <_SeedSchedule>[
      _SeedSchedule(
        id: 'sched_sarah_metformin_morning',
        medicationId: 'local_sarah_metformin',
        timeOfDay: '08:30',
        doseUnit: 'tablet',
      ),
      _SeedSchedule(
        id: 'sched_sarah_metformin_evening',
        medicationId: 'local_sarah_metformin',
        timeOfDay: '20:30',
        doseUnit: 'tablet',
      ),
      _SeedSchedule(
        id: 'sched_sarah_amlodipine_morning',
        medicationId: 'local_sarah_amlodipine',
        timeOfDay: '07:00',
        doseUnit: 'tablet',
      ),
      _SeedSchedule(
        id: 'sched_sarah_vitamind3_evening',
        medicationId: 'local_sarah_vitamin_d3_drops',
        timeOfDay: '20:00',
        doseUnit: 'drop',
      ),
      _SeedSchedule(
        id: 'sched_sarah_amoxicillin_morning',
        medicationId: 'local_sarah_amoxicillin',
        timeOfDay: '08:00',
        doseUnit: 'capsule',
      ),
      _SeedSchedule(
        id: 'sched_sarah_amoxicillin_noon',
        medicationId: 'local_sarah_amoxicillin',
        timeOfDay: '14:00',
        doseUnit: 'capsule',
      ),
      _SeedSchedule(
        id: 'sched_sarah_amoxicillin_evening',
        medicationId: 'local_sarah_amoxicillin',
        timeOfDay: '20:00',
        doseUnit: 'capsule',
      ),
    ];

    for (final seed in seedSchedules) {
      await _seedScheduleIfMissing(
        id: seed.id,
        medicationId: seed.medicationId,
        memberId: memberId,
        timeOfDay: seed.timeOfDay,
        doseUnit: seed.doseUnit,
        startDate: today,
      );
    }
  }

  /// Ek schedule insert karta hai agar wo ID pehle se na ho.
  Future<void> _seedScheduleIfMissing({
    required String id,
    required String medicationId,
    required String memberId,
    required String timeOfDay,
    required String? doseUnit,
    required DateTime startDate,
  }) async {
    final existing = await (_database.select(
      _database.medicationSchedules,
    )..where((table) => table.id.equals(id))).getSingleOrNull();

    if (existing != null) {
      return;
    }

    final now = DateTime.now();

    await _database
        .into(_database.medicationSchedules)
        .insert(
          MedicationSchedulesCompanion.insert(
            id: id,
            medicationId: medicationId,
            memberId: memberId,
            scheduleType: 'daily',
            timeOfDay: timeOfDay,
            startDate: startDate,
            createdAt: now,
            updatedAt: now,
            doseUnit: Value(doseUnit),
          ),
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
    int? courseDay,
    int? courseTotalDays,
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

        // 🆕 MODULE 2
        courseDay: courseDay,
        courseTotalDays: courseTotalDays,

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

      // 🆕 MODULE 2
      discontinuedReason: row.discontinuedReason,
      courseDay: row.courseDay,
      courseTotalDays: row.courseTotalDays,

      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

/// Seed schedule ka chhota data holder.
class _SeedSchedule {
  const _SeedSchedule({
    required this.id,
    required this.medicationId,
    required this.timeOfDay,
    required this.doseUnit,
  });

  final String id;
  final String medicationId;
  final String timeOfDay;
  final String? doseUnit;
}
