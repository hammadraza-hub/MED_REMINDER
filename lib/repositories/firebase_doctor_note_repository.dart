import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../core/doctors/doctor_note_models.dart';
import '../core/doctors/doctor_note_validator.dart';
import 'doctor_firestore.dart';

/// ============================================================
/// FIREBASE DOCTOR NOTE REPOSITORY — M16 step 3
///
/// Path: profiles/{memberId}/doctorNotes/{id}   (memberId == profile id)
/// Fields: body, createdAt, doneAt (null while open), appointmentId?
///
/// The "open list" is every note with `doneAt == null`. The notes are read in
/// one query and split in the app, so no extra Firestore index is needed.
/// All methods throw [AppException].
/// ============================================================
class FirebaseDoctorNoteRepository {
  FirebaseDoctorNoteRepository({FirebaseFirestore? firestore})
    // ignore: prefer_initializing_formals
    : _firestore = firestore;

  static final FirebaseDoctorNoteRepository instance =
      FirebaseDoctorNoteRepository();

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String memberId) =>
      DoctorFirestore.profile(_db, memberId).collection('doctorNotes');

  void _validate(String body) {
    final errors = DoctorNoteValidator.validate(body);
    if (errors.isNotEmpty) {
      throw AppException.validation(
        'Invalid note: ${errors.map((e) => e.name).join(', ')}',
      );
    }
  }

  DoctorNote _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      DoctorNote.fromMap(
        d.id,
        DoctorFirestore.toModelMap(d.data() ?? {}, fallback: DateTime.now()),
      );

  /// Adds an open note and returns it with its id.
  Future<DoctorNote> add(
    String memberId,
    String body, {
    String? appointmentId,
  }) async {
    DoctorFirestore.requireUid();
    _validate(body);
    try {
      final ref = _col(memberId).doc();
      await ref.set({
        'body': body.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'doneAt': null,
        if (appointmentId != null && appointmentId.isNotEmpty)
          'appointmentId': appointmentId,
      });
      return DoctorNote(
        id: ref.id,
        body: body.trim(),
        createdAt: DateTime.now(),
        appointmentId: (appointmentId?.isEmpty ?? true) ? null : appointmentId,
      );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Every note: open ones first (newest first), then done ones.
  Future<List<DoctorNote>> list(String memberId) async {
    try {
      final snap = await _col(memberId)
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();
      return DoctorNote.sorted(snap.docs.map(_fromDoc));
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Notes still to ask the doctor (`doneAt == null`).
  Future<List<DoctorNote>> listOpen(String memberId) async =>
      (await list(memberId)).where((n) => n.isOpen).toList();

  /// How many notes are still open (`doneAt == null`): one server-side
  /// count() query, no documents downloaded.
  Future<int> openCount(String memberId) async {
    try {
      final agg = await _col(memberId)
          .where('doneAt', isNull: true)
          .count()
          .get();
      return agg.count ?? 0;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> editBody(String memberId, String id, String body) async {
    DoctorFirestore.requireUid();
    _validate(body);
    try {
      await _col(memberId).doc(id).update({'body': body.trim()});
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> markDone(String memberId, String id) async {
    DoctorFirestore.requireUid();
    try {
      await _col(memberId)
          .doc(id)
          .update({'doneAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> reopen(String memberId, String id) async {
    DoctorFirestore.requireUid();
    try {
      await _col(memberId).doc(id).update({'doneAt': null});
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<void> delete(String memberId, String id) async {
    DoctorFirestore.requireUid();
    try {
      await _col(memberId).doc(id).delete();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Removes every note that is already done. Returns how many were removed.
  Future<int> clearDone(String memberId) async {
    DoctorFirestore.requireUid();
    try {
      final done = (await list(memberId)).where((n) => !n.isOpen).toList();
      await DoctorFirestore.commitInChunks(_db, [
        for (final n in done) (b) => b.delete(_col(memberId).doc(n.id)),
      ]);
      return done.length;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
