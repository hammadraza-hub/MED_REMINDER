import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../core/doctors/prescriber_models.dart';
import '../core/doctors/prescriber_validator.dart';
import 'doctor_firestore.dart';

/// ============================================================
/// FIREBASE PRESCRIBER REPOSITORY — M16 step 3
///
/// Path: profiles/{memberId}/prescribers/{id}   (memberId == profile id)
/// Fields: name, specialty?, phone?, clinic?, address?, createdAt, updatedAt
///
/// Deleting a doctor also clears the link on its appointments and
/// medications, so nothing points at a doctor that is gone. All methods throw
/// [AppException].
/// ============================================================
class FirebasePrescriberRepository {
  FirebasePrescriberRepository({FirebaseFirestore? firestore})
    // ignore: prefer_initializing_formals
    : _firestore = firestore;

  static final FirebasePrescriberRepository instance =
      FirebasePrescriberRepository();

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String memberId) =>
      DoctorFirestore.profile(_db, memberId).collection('prescribers');

  void _validate(Prescriber p) {
    final errors = PrescriberValidator.validate(
      name: p.name,
      specialty: p.specialty,
      phone: p.phone,
      clinic: p.clinic,
      address: p.address,
    );
    if (errors.isNotEmpty) {
      throw AppException.validation(
        'Invalid doctor: ${errors.map((e) => e.name).join(', ')}',
      );
    }
  }

  Prescriber _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      Prescriber.fromMap(
        d.id,
        DoctorFirestore.toModelMap(d.data() ?? {}, fallback: DateTime.now()),
      );

  /// Saves a doctor and returns it with its id.
  Future<Prescriber> add(String memberId, Prescriber p) async {
    DoctorFirestore.requireUid();
    _validate(p);
    try {
      final ref = _col(memberId).doc();
      await ref.set({
        ...p.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Prescriber.fromMap(ref.id, p.toMap());
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// All doctors of the profile, A to Z.
  Future<List<Prescriber>> list(String memberId) async {
    try {
      final snap = await _col(memberId).limit(500).get();
      final out = snap.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return out;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Future<Prescriber?> get(String memberId, String id) async {
    try {
      final d = await _col(memberId).doc(id).get();
      return d.exists ? _fromDoc(d) : null;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Replaces the editable fields; blank optional fields are removed.
  Future<void> update(String memberId, Prescriber p) async {
    DoctorFirestore.requireUid();
    _validate(p);
    try {
      await _col(memberId).doc(p.id).update({
        'name': p.name.trim(),
        'specialty': DoctorFirestore.optional(p.specialty),
        'phone': DoctorFirestore.optional(p.phone),
        'clinic': DoctorFirestore.optional(p.clinic),
        'address': DoctorFirestore.optional(p.address),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Makes the given medications name this doctor ([toLink]) and removes the
  /// doctor from the others ([toUnlink]). A medication has one doctor, so
  /// linking replaces any other doctor it had.
  Future<void> setMedicationLinks(
    String memberId,
    String doctorId, {
    required Iterable<String> toLink,
    required Iterable<String> toUnlink,
  }) async {
    final uid = DoctorFirestore.requireUid();
    try {
      final meds = DoctorFirestore.profile(
        _db,
        memberId,
      ).collection('medications');
      final ops = <void Function(WriteBatch)>[
        for (final id in toLink)
          (b) => b.update(meds.doc(id), {
            'prescriberId': doctorId,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': uid,
          }),
        for (final id in toUnlink)
          (b) => b.update(meds.doc(id), {
            'prescriberId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': uid,
          }),
      ];
      await DoctorFirestore.commitInChunks(_db, ops);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Number of ACTIVE medications that name this doctor (server-side
  /// count() query: one read, no documents downloaded).
  Future<int> linkedMedicationCount(String memberId, String id) async {
    try {
      final agg = await DoctorFirestore.profile(_db, memberId)
          .collection('medications')
          .where('prescriberId', isEqualTo: id)
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      return agg.count ?? 0;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Deletes the doctor and clears the link from its appointments and
  /// medications first (the doctor is removed last, so a failure half-way
  /// leaves a doctor that can simply be deleted again).
  Future<void> delete(String memberId, String id) async {
    final uid = DoctorFirestore.requireUid();
    try {
      final profile = DoctorFirestore.profile(_db, memberId);
      final appointments = await profile
          .collection('appointments')
          .where('prescriberId', isEqualTo: id)
          .get();
      final medications = await profile
          .collection('medications')
          .where('prescriberId', isEqualTo: id)
          .get();

      final ops = <void Function(WriteBatch)>[
        for (final a in appointments.docs)
          (b) => b.update(a.reference, {
            'prescriberId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          }),
        for (final m in medications.docs)
          (b) => b.update(m.reference, {
            'prescriberId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': uid,
          }),
      ];
      await DoctorFirestore.commitInChunks(_db, ops);
      await _col(memberId).doc(id).delete();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
