import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// ============================================================
/// MEDREMIND LOCAL DATABASE
///
/// CURRENT:
/// Drift + SQLite = app ka persistent offline data source.
///
/// FUTURE:
/// Screens directly database use NAHI karengi.
/// Repository interfaces ke through data access hoga.
///
/// Local repository       → AppDatabase
/// Firebase repository    → Firestore / real backend
///
/// Is boundary ki wajah se backend migration ke waqt UI ko
/// rewrite nahi karna padega.
///
/// 🆕 MODULE 2:
/// schemaVersion 1 → 2
/// Medications table mein 3 naye columns:
/// - discontinuedReason (discontinue modal ka reason)
/// - courseDay / courseTotalDays (course wali dawai)
/// ============================================================

// ============================================================
// FAMILY MEMBERS
// ============================================================

class Members extends Table {
  TextColumn get id => text()();

  TextColumn get accountId => text().nullable()();

  TextColumn get displayName => text()();

  TextColumn get relationship => text().nullable()();

  TextColumn get profileImagePath => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ============================================================
// MEDICATIONS
// ============================================================

class Medications extends Table {
  TextColumn get id => text()();

  TextColumn get memberId => text().references(Members, #id)();

  TextColumn get name => text()();

  TextColumn get strength => text()();

  TextColumn get strengthUnit => text().nullable()();

  TextColumn get medicineForm => text().nullable()();

  TextColumn get colorName => text().nullable()();

  TextColumn get instructions => text().nullable()();

  TextColumn get imagePath => text().nullable()();

  TextColumn get linkedPharmacyId => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get discontinuedAt => dateTime().nullable()();

  // 🆕 MODULE 2: Discontinue modal ka reason persist karta hai.
  TextColumn get discontinuedReason => text().nullable()();

  // 🆕 MODULE 2: Course wali dawai (Amoxicillin type).
  // Example: Day 4 of 10 → courseDay = 4, courseTotalDays = 10.
  // Course progression Module 5 (DoseEvents) se dynamic banegi.
  IntColumn get courseDay => integer().nullable()();

  IntColumn get courseTotalDays => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ============================================================
// MEDICATION SCHEDULES
// ============================================================

class MedicationSchedules extends Table {
  TextColumn get id => text()();

  TextColumn get medicationId => text().references(Medications, #id)();

  TextColumn get memberId => text().references(Members, #id)();

  /// daily / specificDays / interval etc.
  TextColumn get scheduleType => text()();

  /// HH:mm local wall-clock time.
  TextColumn get timeOfDay => text()();

  /// JSON/string representation initially.
  /// Example: Mon,Tue,Wed
  TextColumn get daysOfWeek => text().nullable()();

  RealColumn get doseAmount => real().withDefault(const Constant(1))();

  TextColumn get doseUnit => text().nullable()();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime().nullable()();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ============================================================
// DOSE EVENTS / HISTORY
//
// Calendar, adherence and streaks eventually derive from this.
// ============================================================

class DoseEvents extends Table {
  TextColumn get id => text()();

  TextColumn get memberId => text().references(Members, #id)();

  TextColumn get medicationId => text().references(Medications, #id)();

  TextColumn get scheduleId =>
      text().nullable().references(MedicationSchedules, #id)();

  DateTimeColumn get scheduledAt => dateTime()();

  /// pending / taken / missed / skipped
  TextColumn get status => text()();

  DateTimeColumn get completedAt => dateTime().nullable()();

  TextColumn get missedReasonType => text().nullable()();

  TextColumn get missedReasonText => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get snoozedUntil => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ============================================================
// PHARMACIES
// ============================================================

class Pharmacies extends Table {
  TextColumn get id => text()();

  TextColumn get memberId => text().references(Members, #id)();

  TextColumn get name => text()();

  TextColumn get address => text().nullable()();

  TextColumn get phone => text().nullable()();

  TextColumn get email => text().nullable()();

  TextColumn get website => text().nullable()();

  TextColumn get hoursText => text().nullable()();

  RealColumn get latitude => real().nullable()();

  RealColumn get longitude => real().nullable()();

  BoolColumn get isPreferred => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ============================================================
// INVENTORY
// ============================================================

class InventoryRecords extends Table {
  TextColumn get id => text()();

  TextColumn get memberId => text().references(Members, #id)();

  TextColumn get medicationId => text().references(Medications, #id)();

  RealColumn get remainingQuantity => real()();

  RealColumn get packageQuantity => real()();

  RealColumn get unitsPerDay => real()();

  TextColumn get unitLabel => text()();

  IntColumn get lowStockThresholdDays =>
      integer().withDefault(const Constant(7))();

  DateTimeColumn get lastRefilledAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {memberId, medicationId},
  ];
}

// ============================================================
// REFILL EVENTS
// ============================================================

class RefillEvents extends Table {
  TextColumn get id => text()();

  TextColumn get memberId => text().references(Members, #id)();

  TextColumn get medicationId => text().references(Medications, #id)();

  TextColumn get pharmacyId => text().nullable().references(Pharmacies, #id)();

  RealColumn get quantityAdded => real()();

  DateTimeColumn get refilledAt => dateTime()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ============================================================
// VITAL ENTRIES
//
// Vitals List + chart dono isi raw history se derive honge.
// ============================================================

class VitalEntries extends Table {
  TextColumn get id => text()();

  TextColumn get memberId => text().references(Members, #id)();

  /// bloodPressure / bloodGlucose / weight / heartRate
  TextColumn get vitalType => text()();

  RealColumn get primaryValue => real()();

  /// BP diastolic etc.
  RealColumn get secondaryValue => real().nullable()();

  /// BP ke saath optional pulse.
  RealColumn get pulse => real().nullable()();

  TextColumn get unit => text()();

  DateTimeColumn get recordedAt => dateTime()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ============================================================
// APP DATABASE
// ============================================================

@DriftDatabase(
  tables: [
    Members,
    Medications,
    MedicationSchedules,
    DoseEvents,
    Pharmacies,
    InventoryRecords,
    RefillEvents,
    VitalEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Tests ke liye in-memory/custom executor inject kiya ja sakta hai.
  AppDatabase.forTesting(super.executor);

  // 🆕 MODULE 2: schemaVersion 1 → 2
  @override
  int get schemaVersion => 2;

  // 🆕 MODULE 2: Migration
  //
  // Purane installs (version 1) naye columns ke saath upgrade hote hain.
  // Existing data SAFE rehta hai — kuch delete nahi hota.
  //
  // Fresh install pe onUpgrade nahi chalti (direct v2 banti hai),
  // sirf pehle se installed apps pe chalega.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(medications, medications.discontinuedReason);

        await m.addColumn(medications, medications.courseDay);
        await m.addColumn(medications, medications.courseTotalDays);
      }
    },
  );

  // TODO Backend:
  // Screens ko AppDatabase directly inject/use nahi karna.
  // Har feature Repository contract use karega.
  //
  // Firebase phase mein:
  // Local repositories ko Firebase repositories se replace/sync
  // kiya ja sakega without UI rewrite.
}

// ============================================================
// DATABASE CONNECTION
// ============================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final databaseFile = File(
      p.join(documentsDirectory.path, 'med_remind.sqlite'),
    );

    return NativeDatabase.createInBackground(databaseFile);
  });
}
