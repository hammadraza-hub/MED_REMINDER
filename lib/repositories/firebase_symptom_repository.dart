import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_exception.dart';
import '../core/vitals/symptom_entry.dart';
import '../core/vitals/symptom_validator.dart';

/// ============================================================
/// FIREBASE SYMPTOM REPOSITORY — M15 step 3
///
/// Path: profiles/{memberId}/symptoms/{id}   (memberId == profile id)
/// Fields: symptom, severity (1-5), medicationId?, occurredAt, notes?,
///         createdBy, createdAt
///
/// Only `notes` can be edited later (security rules). All methods throw
/// [AppException].
/// ============================================================
class FirebaseSymptomRepository {
  static final FirebaseSymptomRepository instance =
      FirebaseSymptomRepository._();
  FirebaseSymptomRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _symptoms(String memberId) =>
      _db.collection('profiles').doc(memberId).collection('symptoms');

  String _uid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw AppException.permission('Not signed in');
    return uid;
  }

  /// Saves a symptom and returns it with its id.
  Future<SymptomEntry> add(String memberId, SymptomEntry entry) async {
    final uid = _uid();

    final check = SymptomValidator.validate(
      name: entry.symptom,
      severity: entry.severity,
      notes: entry.notes,
      occurredAt: entry.occurredAt,
    );
    if (!check.isValid) {
      throw AppException.validation('Invalid symptom: ${check.error}');
    }

    try {
      final ref = _symptoms(memberId).doc();
      await ref.set({
        ...entry.toCreateMap(),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return SymptomEntry(
        id: ref.id,
        symptom: entry.symptom.trim(),
        severity: entry.severity,
        medicationId: entry.medicationId,
        occurredAt: entry.occurredAt,
        notes: entry.notes,
        createdBy: uid,
      );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Newest first. [since] limits how far back.
  Future<List<SymptomEntry>> list(
    String memberId, {
    DateTime? since,
    int limit = 200,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _symptoms(memberId);
      if (since != null) {
        q = q.where('occurredAt', isGreaterThanOrEqualTo: since);
      }
      final snap = await q
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      final out = <SymptomEntry>[];
      for (final d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        final at = data['occurredAt'];
        if (at is Timestamp) data['occurredAt'] = at.toDate();
        final e = SymptomEntry.fromMap(d.id, data);
        if (e != null) out.add(e);
      }
      return out;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Only the notes of a saved symptom can change.
  Future<void> updateNotes(String memberId, String id, String? notes) async {
    _uid();
    final n = notes?.trim() ?? '';
    if (n.length > SymptomValidator.maxNotesLength) {
      throw AppException.validation('Notes are too long');
    }
    try {
      await _symptoms(memberId)
          .doc(id)
          .update({'notes': n.isEmpty ? FieldValue.delete() : n});
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> delete(String memberId, String id) async {
    _uid();
    try {
      await _symptoms(memberId).doc(id).delete();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
