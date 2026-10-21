import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../core/medications/medication_repository.dart';

/// ============================================================
/// FIREBASE MEDICATION REPOSITORY
/// ============================================================
///
/// Implements [MedicationRepository] using Firestore.
///
/// Firestore Path:
///   profiles/{memberId}/medications/{medicationId}
///
/// Note: `memberId` in the local model = `profileId` in Firestore path
/// (same concept — the patient profile under which the med lives).
///
/// Design Decisions:
///   - **`id` field stored in document**: For collectionGroup queries
///     (getMedicationById, discontinueMedication) since interface
///     doesn't pass memberId.
///   - **`active` field**: Boolean for filtering active vs archived.
///   - **`updatedAt`**: Auto-updated via FieldValue.serverTimestamp().
///   - **`createdAt`**: Set on create, preserved on update.
///   - **Image path**: Stored as String — local path OR Firebase Storage URL.
///
/// All methods throw [AppException] on failure — never raw Firebase exceptions.
/// ============================================================
class FirebaseMedicationRepository implements MedicationRepository {
  // Singleton
  static final FirebaseMedicationRepository instance =
      FirebaseMedicationRepository._();
  FirebaseMedicationRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────
  // Path helper
  // ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _medicationsRef(String memberId) {
    return _firestore
        .collection('profiles')
        .doc(memberId)
        .collection('medications');
  }

  // ───────────────────────────────────────────────────────────
  // Serialization helpers
  // ───────────────────────────────────────────────────────────

  /// Extract memberId from a document reference path.
  /// Path format: profiles/{memberId}/medications/{medId}
  String _extractMemberId(DocumentReference ref) {
    final segments = ref.path.split('/');
    return segments.length >= 4 ? segments[1] : '';
  }

  /// Convert Firestore document → MedicationProfile.
  MedicationProfile _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? memberId,
  }) {
    final data = doc.data() ?? {};
    return MedicationProfile(
      id: doc.id,
      memberId: memberId ?? (data['memberId'] as String? ?? ''),
      name: data['name'] as String? ?? '',
      strength: data['strength'] as String? ?? '',
      strengthUnit: data['strengthUnit'] as String?,
      medicineForm: data['form'] as String?,
      colorName: data['colorName'] as String?,
      instructions: data['instructions'] as String?,
      imagePath: data['imagePath'] as String?,
      linkedPharmacyId: data['linkedPharmacyId'] as String?,
      isActive: data['active'] as bool? ?? true,
      discontinuedAt: (data['discontinuedAt'] as Timestamp?)?.toDate(),
      discontinuedReason: data['discontinuedReason'] as String?,
      courseDay: data['courseDay'] as int?,
      courseTotalDays: data['courseTotalDays'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert MedicationProfile → Firestore map.
  Map<String, dynamic> _toMap(MedicationProfile med, {bool isNew = false}) {
    return {
      // Store id field for collectionGroup queries
      'id': med.id,
      'memberId': med.memberId,
      'name': med.name,
      'strength': med.strength,
      'strengthUnit': med.strengthUnit,
      'form': med.medicineForm,
      'colorName': med.colorName,
      'instructions': med.instructions,
      'imagePath': med.imagePath,
      'linkedPharmacyId': med.linkedPharmacyId,
      'active': med.isActive,
      'discontinuedAt': med.discontinuedAt != null
          ? Timestamp.fromDate(med.discontinuedAt!)
          : null,
      'discontinuedReason': med.discontinuedReason,
      'courseDay': med.courseDay,
      'courseTotalDays': med.courseTotalDays,
      'createdAt': isNew
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(med.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================
  // WATCH (realtime streams)
  // ============================================================

  @override
  Stream<List<MedicationProfile>> watchActiveMedications(String memberId) {
    try {
      return _medicationsRef(memberId)
          .where('active', isEqualTo: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((d) => _fromDoc(d, memberId: memberId))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Stream<List<MedicationProfile>> watchArchivedMedications(String memberId) {
    try {
      return _medicationsRef(memberId)
          .where('active', isEqualTo: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((d) => _fromDoc(d, memberId: memberId))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ============================================================
  // GET (one-time fetches)
  // ============================================================

  @override
  Future<List<MedicationProfile>> getActiveMedications(String memberId) async {
    try {
      final snapshot = await _medicationsRef(memberId)
          .where('active', isEqualTo: true)
          .get();
      return snapshot.docs.map((d) => _fromDoc(d, memberId: memberId)).toList();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<List<MedicationProfile>> getArchivedMedications(
    String memberId,
  ) async {
    try {
      final snapshot = await _medicationsRef(memberId)
          .where('active', isEqualTo: false)
          .get();
      return snapshot.docs.map((d) => _fromDoc(d, memberId: memberId)).toList();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ============================================================
  // GET BY ID (collectionGroup query)
  // ============================================================
  // Note: Interface only passes medicationId (no memberId).
  // Firestore needs memberId to construct path:
  //   profiles/{memberId}/medications/{medicationId}
  //
  // Solution: Query all medication subcollections via collectionGroup,
  // filtering by 'id' field stored in each doc.

  @override
  Future<MedicationProfile?> getMedicationById(String medicationId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('medications')
          .where('id', isEqualTo: medicationId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return _fromDoc(doc, memberId: _extractMemberId(doc.reference));
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ============================================================
  // SAVE (create or update)
  // ============================================================

  @override
  Future<void> saveMedication(MedicationProfile medication) async {
    try {
      final ref = _medicationsRef(medication.memberId);

      if (medication.id.isEmpty) {
        // CREATE — auto-generate ID
        final tempMed = medication.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Add the document (Firestore auto-generates ID)
        final docRef = await ref.add(_toMap(tempMed, isNew: true));

        // Update the 'id' field to match the generated doc ID
        // (Required for collectionGroup queries to find this med)
        await docRef.update({'id': docRef.id});
      } else {
        // UPDATE — existing medication
        await ref
            .doc(medication.id)
            .set(_toMap(medication, isNew: false), SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(
        'Failed to save medication: $e',
        originalError: e,
      );
    }
  }

  // ============================================================
  // DISCONTINUE (archive)
  // ============================================================

  @override
  Future<void> discontinueMedication({
    required String medicationId,
    required DateTime discontinuedAt,
    String? reason,
  }) async {
    try {
      // Find the medication across all profiles (collection group query)
      final snapshot = await _firestore
          .collectionGroup('medications')
          .where('id', isEqualTo: medicationId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw AppException.notFound(
          'Medication with ID "$medicationId" not found.',
        );
      }

      final docRef = snapshot.docs.first.reference;
      await docRef.update({
        'active': false,
        'discontinuedAt': Timestamp.fromDate(discontinuedAt),
        'discontinuedReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(
        'Failed to discontinue medication: $e',
        originalError: e,
      );
    }
  }

  // ============================================================
  // SEED INITIAL — No-op for Firebase
  // ============================================================
  //
  // Note: In local mode, this method seeds demo medications.
  // In Firebase mode, we don't seed mock data — Firebase is the
  // source of truth, and users add medications through UI.

  @override
  Future<void> seedInitialMedicationsIfNeeded(String memberId) async {
    try {
      // Check if any medications exist for this member
      final existing = await _medicationsRef(memberId).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return; // Already has medications — no seeding needed
      }
      // Firebase: no seeding — return silently
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
