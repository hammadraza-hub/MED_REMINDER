import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../models/medication.dart';

/// Medication Repository — Firestore CRUD operations for medications.
///
/// M5 — Medications & Schedules
///
/// Data path: profiles/{profileId}/medications/{medicationId}
///
/// Operations:
///   • createMedication  — adds new medication (uses toJsonForCreate)
///   • getMedication      — single doc read
///   • watchMedication    — real-time stream for single doc
///   • watchActiveMedications — stream of active meds (for Medication List screen)
///   • watchAllMedications    — stream of all meds (active + archived)
///   • updateMedication  — updates modifiable fields only (uses toJsonForUpdate)
///   • archiveMedication  — sets status = archived + archivedReason
///   • getMedicationDetail — bundled read (medication + next 3 doses + 30-day history)
///
/// Per M5 plan: "Archive, never delete."
/// Deletion is not exposed — only archive.
///
/// Phase A (Spark):
///   • All CRUD operations work
///   • getMedicationDetail's dose queries will return empty lists
///     (no M6 trigger to populate doses — comes in Phase B with Blaze)
class MedicationRepository {
  final FirebaseFirestore _db;

  static MedicationRepository? _instance;
  static MedicationRepository get instance =>
      _instance ??= MedicationRepository._(FirebaseFirestore.instance);

  MedicationRepository._(this._db);

  // For testing — inject custom FirebaseFirestore
  MedicationRepository.withDb(this._db);

  // ──────────────────────────────────────────────────────────────
  // COLLECTION REFERENCE
  // ──────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _medicationsRef(String profileId) {
    return _db.collection('profiles').doc(profileId).collection('medications');
  }

  // ──────────────────────────────────────────────────────────────
  // CREATE
  // ──────────────────────────────────────────────────────────────

  /// Creates a new medication under profiles/{profileId}/medications.
  /// Returns the generated medication ID.
  ///
  /// Uses toJsonForCreate() which excludes server-maintained fields:
  ///   • quantityOnHand (set by M9 in Phase B)
  ///   • daysOfSupply   (set by M6 in Phase B)
  ///   • flags          (set by M9/M10 in Phase B)
  Future<String> createMedication({
    required String profileId,
    required Medication medication,
  }) async {
    try {
      final docRef = await _medicationsRef(profileId)
          .add(medication.toJsonForCreate());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to create medication: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // READ (single)
  // ──────────────────────────────────────────────────────────────

  /// Fetches a single medication by ID.
  /// Returns null if not found.
  Future<Medication?> getMedication({
    required String profileId,
    required String medicationId,
  }) async {
    try {
      final doc = await _medicationsRef(profileId).doc(medicationId).get();
      if (!doc.exists) return null;
      return Medication.fromJson(doc.data()!, id: doc.id);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to fetch medication: $e');
    }
  }

  /// Real-time stream of a single medication.
  /// Useful for Medication Detail screen — auto-updates when doc changes.
  Stream<Medication?> watchMedication({
    required String profileId,
    required String medicationId,
  }) {
    return _medicationsRef(profileId).doc(medicationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Medication.fromJson(doc.data()!, id: doc.id);
    });
  }

  // ──────────────────────────────────────────────────────────────
  // READ (lists)
  // ──────────────────────────────────────────────────────────────

  /// Stream of active medications, ordered by updatedAt (most recent first).
  /// Used by the Medication List screen.
  Stream<List<Medication>> watchActiveMedications(String profileId) {
    return _medicationsRef(profileId)
        .where('status', isEqualTo: 'active')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Medication.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Stream of ALL medications (active + archived).
  /// Useful for showing medication history / archive list.
  Stream<List<Medication>> watchAllMedications(String profileId) {
    return _medicationsRef(profileId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Medication.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Stream of archived medications only.
  /// Useful for showing archived / discontinued medications separately.
  Stream<List<Medication>> watchArchivedMedications(String profileId) {
    return _medicationsRef(profileId)
        .where('status', isEqualTo: 'archived')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Medication.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  // ──────────────────────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────────────────────

  /// Updates an existing medication.
  /// Uses toJsonForUpdate() which blocks server-maintained + immutable fields.
  ///
  /// Per M5 plan: "Schedule edits change only future doses."
  /// (Phase B: M6 trigger will delete old future doses + regenerate new ones)
  Future<void> updateMedication({
    required String profileId,
    required Medication medication,
  }) async {
    try {
      await _medicationsRef(profileId)
          .doc(medication.id)
          .update(medication.toJsonForUpdate());
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to update medication: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // ARCHIVE (per M5 plan: "Archive, never delete.")
  // ──────────────────────────────────────────────────────────────

  /// Archives a medication — sets status = 'archived' + archivedReason.
  ///
  /// Per M5 plan:
  ///   • "Archive sets status = archived and archivedReason."
  ///   • "The M6 trigger then deletes future pending doses,
  ///      and logged history stays."
  ///
  /// In Phase A (no M6 trigger), future doses will remain.
  /// In Phase B (Blaze), M6 trigger will auto-clean future doses on archive.
  Future<void> archiveMedication({
    required String profileId,
    required String medicationId,
    required String reason,
    required String archivedBy,
  }) async {
    try {
      await _medicationsRef(profileId).doc(medicationId).update({
        'status': 'archived',
        'archivedReason': reason,
        'updatedAt': DateTime.now(),
        'updatedBy': archivedBy,
      });
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to archive medication: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // MEDICATION DETAIL (bundled read)
  // ──────────────────────────────────────────────────────────────

  /// Fetches the medication + next 3 doses + last 30 days' doses.
  ///
  /// Per M5 plan:
  ///   "read the medication document, the next 3 doses
  ///    (doses where medicationId == id and scheduledAt >= now
  ///     orderBy scheduledAt limit 3),
  ///    and that medication's doses for the last 30 days
  ///    for the mini calendar."
  ///
  /// In Phase A (no M6 trigger):
  ///   • nextDoses will be empty list
  ///   • recentDoses will be empty list
  ///   • medication document will be returned
  ///
  /// In Phase B (Blaze):
  ///   • M6 trigger populates doses — both lists will have data
  Future<MedicationDetail> getMedicationDetail({
    required String profileId,
    required String medicationId,
  }) async {
    try {
      // 1. Get medication document
      final medDoc = await _medicationsRef(profileId).doc(medicationId).get();
      if (!medDoc.exists) {
        throw AppException.notFound('Medication not found');
      }
      final medication = Medication.fromJson(medDoc.data()!, id: medDoc.id);

      // 2. Get next 3 doses (will be empty in Phase A)
      final now = Timestamp.now();
      final nextDosesQuery = await _db
          .collection('profiles')
          .doc(profileId)
          .collection('doses')
          .where('medicationId', isEqualTo: medicationId)
          .where('scheduledAt', isGreaterThanOrEqualTo: now)
          .orderBy('scheduledAt')
          .limit(3)
          .get();

      final nextDoses = nextDosesQuery.docs.map((doc) => doc.data()).toList();

      // 3. Get last 30 days' doses (will be empty in Phase A)
      final thirtyDaysAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)),
      );
      final recentDosesQuery = await _db
          .collection('profiles')
          .doc(profileId)
          .collection('doses')
          .where('medicationId', isEqualTo: medicationId)
          .where('scheduledAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('scheduledAt', descending: true)
          .get();

      final recentDoses = recentDosesQuery.docs
          .map((doc) => doc.data())
          .toList();

      return MedicationDetail(
        medication: medication,
        nextDoses: nextDoses,
        recentDoses: recentDoses,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to fetch medication detail: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // COUNT (for future profile limits)
  // ──────────────────────────────────────────────────────────────

  /// Returns count of active medications for a profile.
  /// Useful for profile limits enforcement (Phase B with Cloud Functions).
  Future<int> getActiveMedicationsCount(String profileId) async {
    try {
      final snapshot = await _medicationsRef(profileId)
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Non-fatal — return 0 on error
      return 0;
    }
  }
}

/// Bundled result of getMedicationDetail —
/// medication document + next 3 doses + last 30 days' doses.
///
/// In Phase A (Spark), dose lists will be empty (no M6 trigger).
class MedicationDetail {
  final Medication medication;

  /// Next 3 upcoming doses (scheduledAt >= now).
  /// Empty in Phase A.
  final List<Map<String, dynamic>> nextDoses;

  /// Doses from the last 30 days (for mini calendar).
  /// Empty in Phase A.
  final List<Map<String, dynamic>> recentDoses;

  const MedicationDetail({
    required this.medication,
    required this.nextDoses,
    required this.recentDoses,
  });
}
