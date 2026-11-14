import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_exception.dart';

/// Small helpers shared by the M16 repositories (prescribers, appointments,
/// doctor notes).
class DoctorFirestore {
  DoctorFirestore._();

  static DocumentReference<Map<String, dynamic>> profile(
    FirebaseFirestore db,
    String memberId,
  ) => db.collection('profiles').doc(memberId);

  static String requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw AppException.permission('Not signed in');
    return uid;
  }

  /// Firestore [Timestamp] values become [DateTime] so the pure models
  /// (lib/core/doctors) never see Firebase types. A timestamp that is still
  /// pending (null) becomes [fallback].
  static Map<String, Object?> toModelMap(
    Map<String, dynamic> data, {
    required DateTime fallback,
  }) {
    final out = <String, Object?>{};
    data.forEach((k, v) {
      out[k] = v is Timestamp ? v.toDate() : v;
    });
    for (final key in const ['startsAt', 'createdAt']) {
      if (out.containsKey(key) && out[key] == null) out[key] = fallback;
    }
    return out;
  }

  /// A field value for an optional string: the text, or "remove the field".
  static Object optional(String? value) {
    final t = value?.trim() ?? '';
    return t.isEmpty ? FieldValue.delete() : t;
  }

  /// Commits many writes in batches below Firestore's 500 limit.
  static Future<void> commitInChunks(
    FirebaseFirestore db,
    List<void Function(WriteBatch)> ops, {
    int chunk = 400,
  }) async {
    for (var i = 0; i < ops.length; i += chunk) {
      final batch = db.batch();
      for (final op in ops.skip(i).take(chunk)) {
        op(batch);
      }
      await batch.commit();
    }
  }
}
