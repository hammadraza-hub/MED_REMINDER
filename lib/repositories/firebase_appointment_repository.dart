import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../core/doctors/appointment_models.dart';
import '../core/doctors/appointment_validator.dart';
import 'doctor_firestore.dart';

/// ============================================================
/// FIREBASE APPOINTMENT REPOSITORY — M16 step 3
///
/// Path: profiles/{memberId}/appointments/{id}   (memberId == profile id)
/// Fields: startsAt, type, prescriberId?, location?, notes?,
///         reminderOffsets, createdAt, updatedAt
///
/// Data only: scheduling the phone reminders is step 5. All methods throw
/// [AppException].
/// ============================================================
class FirebaseAppointmentRepository {
  FirebaseAppointmentRepository({FirebaseFirestore? firestore})
    // ignore: prefer_initializing_formals
    : _firestore = firestore;

  static final FirebaseAppointmentRepository instance =
      FirebaseAppointmentRepository();

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String memberId) =>
      DoctorFirestore.profile(_db, memberId).collection('appointments');

  void _validate(Appointment a, {required bool requireFuture}) {
    final errors = AppointmentValidator.validate(
      startsAt: a.startsAt,
      location: a.location,
      notes: a.notes,
      reminderOffsets: a.reminderOffsets,
      requireFuture: requireFuture,
    );
    if (errors.isNotEmpty) {
      throw AppException.validation(
        'Invalid appointment: ${errors.map((e) => e.name).join(', ')}',
      );
    }
  }

  Appointment _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      Appointment.fromMap(
        d.id,
        DoctorFirestore.toModelMap(d.data() ?? {}, fallback: DateTime.now()),
      );

  /// Saves a new appointment (it must be in the future) and returns it with
  /// its id. The id is needed to schedule reminders.
  Future<Appointment> add(String memberId, Appointment a) async {
    DoctorFirestore.requireUid();
    _validate(a, requireFuture: true);
    try {
      final ref = _col(memberId).doc();
      await ref.set({
        ...a.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Appointment(
        id: ref.id,
        startsAt: a.startsAt,
        prescriberId: a.prescriberId,
        type: a.type,
        location: a.location,
        notes: a.notes,
        reminderOffsets: Appointment.normalizeOffsets(a.reminderOffsets),
      );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Soonest first. [from] hides anything earlier (for the "upcoming" list).
  Future<List<Appointment>> list(
    String memberId, {
    DateTime? from,
    int limit = 300,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _col(memberId);
      if (from != null) {
        q = q.where('startsAt', isGreaterThanOrEqualTo: from);
      }
      final snap = await q.orderBy('startsAt').limit(limit).get();
      return snap.docs.map(_fromDoc).toList();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<Appointment?> get(String memberId, String id) async {
    try {
      final d = await _col(memberId).doc(id).get();
      return d.exists ? _fromDoc(d) : null;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Editing an appointment that is already in the past is allowed (e.g. to
  /// add notes); only new ones must be in the future.
  Future<void> update(String memberId, Appointment a) async {
    DoctorFirestore.requireUid();
    _validate(a, requireFuture: false);
    try {
      await _col(memberId).doc(a.id).update({
        'startsAt': a.startsAt,
        'type': a.type.code,
        'prescriberId': DoctorFirestore.optional(a.prescriberId),
        'location': DoctorFirestore.optional(a.location),
        'notes': DoctorFirestore.optional(a.notes),
        'reminderOffsets': Appointment.normalizeOffsets(a.reminderOffsets),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
}
