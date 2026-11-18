import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/app_exception.dart';
import '../core/services/reminder_scheduler.dart';
import '../models/medication.dart';
import '../core/dose_engine.dart';
import '../core/dose_zone.dart';
import '../models/schedule.dart';

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
      // 1. Create the medication document
      final docRef = await _medicationsRef(profileId)
          .add(medication.toJsonForCreate());

      // 2. Generate 14-day doses (M6 client-side dose generation)
      final medicationWithId = medication.copyWith(id: docRef.id);
      await _generateAndWriteDoses(profileId, medicationWithId);

      unawaited(ReminderScheduler.instance.rescheduleAll());
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
      // 1. Get old medication to check if schedule changed
      final oldDoc = await _medicationsRef(profileId).doc(medication.id).get();
      if (!oldDoc.exists) {
        throw AppException.notFound('Medication not found');
      }
      final oldMedication = Medication.fromJson(oldDoc.data()!, id: oldDoc.id);

      // 2. Update the medication document
      await _medicationsRef(profileId)
          .doc(medication.id)
          .update(medication.toJsonForUpdate());

      // 3. If schedule changed, regenerate future doses
      if (_scheduleChanged(oldMedication.schedule, medication.schedule)) {
        await _deleteFuturePendingDoses(profileId, medication.id);
        // Only the future, and never over a dose that already exists.
        await _generateAndWriteDoses(
          profileId,
          medication,
          notBefore: DateTime.now(),
        );
      }

      unawaited(ReminderScheduler.instance.rescheduleAll());
    } on AppException {
      rethrow;
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
      // 1. Archive the medication
      await _medicationsRef(profileId).doc(medicationId).update({
        'status': 'archived',
        'archivedReason': reason,
        'updatedAt': DateTime.now(),
        'updatedBy': archivedBy,
      });

      // 2. Delete future pending doses (logged history stays)
      await _deleteFuturePendingDoses(profileId, medicationId);

      unawaited(ReminderScheduler.instance.rescheduleAll());
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

  // ──────────────────────────────────────────────────────────────
  // M6: CLIENT-SIDE DOSE GENERATION HELPERS
  // ──────────────────────────────────────────────────────────────

  /// Fetches the profile's missedAfterMin (default 30 if not set).
  Future<int> _getProfileMissedAfterMin(String profileId) async {
    try {
      final doc = await _db.collection('profiles').doc(profileId).get();
      if (!doc.exists) return 30;
      final data = doc.data()!;
      return (data['missedAfterMin'] as num?)?.toInt() ?? 30;
    } catch (_) {
      return 30; // Default on error
    }
  }

  /// The profile's time zone (IANA name; the phone's zone for an old profile
  /// that stored an abbreviation like "PKT", UTC as the last resort).
  Future<tz.Location> _getProfileZone(String profileId) async {
    String? name;
    try {
      final doc = await _db.collection('profiles').doc(profileId).get();
      name = doc.data()?['timezone'] as String?;
    } catch (_) {
      name = null;
    }
    return DoseZone.forProfile(name);
  }

  /// Generates the 14-day window for a medication and writes ONLY the doses
  /// that are not there yet (deterministic ids). A dose that already exists,
  /// for example one taken today, is never overwritten (M22 finding 2).
  /// [notBefore] limits it to the future (used after a schedule change).
  /// Returns how many doses were written.
  Future<int> _generateAndWriteDoses(
    String profileId,
    Medication medication, {
    DateTime? notBefore,
    int? missedAfterMin,
    tz.Location? zone,
  }) async {
    missedAfterMin ??= await _getProfileMissedAfterMin(profileId);
    // PDF M6: doses are generated in the PROFILE's time zone.
    zone ??= await _getProfileZone(profileId);

    final generated = DoseEngine.generate14DayDoses(
      medication: medication,
      profileId: profileId,
      missedAfterMin: missedAfterMin,
      zone: zone,
    );
    if (generated.isEmpty) return 0;

    final dosesRef = _db
        .collection('profiles')
        .doc(profileId)
        .collection('doses');

    // Which of these ids exist already (one query per medicine).
    final first = generated
        .map((d) => d.scheduledAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final last = generated
        .map((d) => d.scheduledAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final existing = await dosesRef
        .where('medicationId', isEqualTo: medication.id)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(first))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(last))
        .get();

    final toWrite = DoseEngine.onlyMissing(
      generated,
      existing.docs.map((d) => d.id).toSet(),
      notBefore: notBefore,
    );
    if (toWrite.isEmpty) return 0;

    // Batches stay far below the 500-write limit.
    for (var i = 0; i < toWrite.length; i += 400) {
      final batch = _db.batch();
      for (final dose in toWrite.skip(i).take(400)) {
        batch.set(dosesRef.doc(dose.id), dose.toJson());
      }
      await batch.commit();
    }
    return toWrite.length;
  }

  /// Keeps every active medicine topped up to today + 14 days (the old code
  /// wrote the window once, so doses ran out after 14 days; PDF M6 extends it
  /// every night with a Blaze function, this is the Spark replacement). Called
  /// on app start / resume; at most once an hour per profile. Writes only
  /// missing doses. Returns how many were written. Never throws.
  Future<int> topUpDoses(String profileId, {bool force = false}) async {
    final last = _lastTopUp[profileId];
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < const Duration(hours: 1)) {
      return 0;
    }
    try {
      final snapshot = await _medicationsRef(profileId)
          .where('status', isEqualTo: 'active')
          .get();
      final missedAfterMin = await _getProfileMissedAfterMin(profileId);
      final zone = await _getProfileZone(profileId);
      var written = 0;
      for (final doc in snapshot.docs) {
        final medication = Medication.fromJson(doc.data(), id: doc.id);
        written += await _generateAndWriteDoses(
          profileId,
          medication,
          missedAfterMin: missedAfterMin,
          zone: zone,
        );
      }
      _lastTopUp[profileId] = DateTime.now();
      return written;
    } catch (e) {
      debugPrint('MedicationRepository: top-up failed: $e');
      return 0;
    }
  }

  final Map<String, DateTime> _lastTopUp = {};

  /// Deletes future pending doses for a medication.
  /// Used when schedule changes (regenerate) or medication is archived.
  /// Logged history (taken/skipped/missed) is preserved.
  Future<void> _deleteFuturePendingDoses(
    String profileId,
    String medicationId,
  ) async {
    final now = Timestamp.now();

    final snapshot = await _db
        .collection('profiles')
        .doc(profileId)
        .collection('doses')
        .where('medicationId', isEqualTo: medicationId)
        .where('status', isEqualTo: 'pending')
        .where('scheduledAt', isGreaterThanOrEqualTo: now)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Checks if the schedule has changed between old and new versions.
  /// Returns true if any schedule field that affects dose generation changed.
  bool _scheduleChanged(Schedule old, Schedule current) {
    if (old.type != current.type) return true;
    if (!_listEquals(old.times, current.times)) return true;
    if (!_listEquals(old.weekdays, current.weekdays)) return true;
    if (old.cycleOn != current.cycleOn) return true;
    if (old.cycleOff != current.cycleOff) return true;
    if (old.taperSteps.length != current.taperSteps.length) return true;
    if (old.startDate != current.startDate) return true;
    if (old.endDate != current.endDate) return true;
    return false;
  }

  /// Helper: compare two lists for equality.
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
