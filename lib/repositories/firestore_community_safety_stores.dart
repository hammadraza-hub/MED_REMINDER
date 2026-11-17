import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/community/community_posts.dart';
import '../core/daily_limits.dart';
import '../core/community/community_safety.dart';

const Duration _timeout = Duration(seconds: 10);

Future<T> _guard<T>(Future<T> Function() run) async {
  try {
    return await run().timeout(_timeout);
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') throw const CommunityDeniedException();
    rethrow;
  }
}

/// Reports in Firestore (`reports/{id}`). M19 step 6.
class FirestoreCommunityReportStore implements CommunityReportStore {
  @override
  Future<void> create(String id, Map<String, dynamic> data) => _guard(() async {
    // M21 step 6: the report and the day's counter go in one batch.
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    await DailyLimits.assertRoom(db, uid, DailyLimitKind.reports);
    final batch = db.batch()..set(db.collection('reports').doc(id), data);
    DailyLimits.bump(batch, db, uid, DailyLimitKind.reports);
    await batch.commit();
  });
}

/// The block list in Firestore (`users/{uid}/blocks/{community id}`).
class FirestoreCommunityBlockStore implements CommunityBlockStore {
  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blocks');
  }

  @override
  Future<Set<String>> all() async {
    final snap = await _col().get().timeout(_timeout);
    return {for (final d in snap.docs) d.id};
  }

  @override
  Future<void> block(String cpid) => _guard(() async {
    final ref = _col().doc(cpid);
    // A second block of the same person is not an error.
    if ((await ref.get()).exists) return;
    await ref.set({'createdAt': FieldValue.serverTimestamp()});
  });

  @override
  Future<void> unblock(String cpid) => _guard(() => _col().doc(cpid).delete());
}
