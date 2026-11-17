import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/community/community_models.dart';
import '../core/community/community_posts.dart';
import '../core/community/community_reactions.dart';

const Duration _timeout = Duration(seconds: 10);

Future<T> _guard<T>(Future<T> Function() run) async {
  try {
    return await run().timeout(_timeout);
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') throw const CommunityDeniedException();
    rethrow;
  }
}

/// Votes in Firestore. M19 step 5.
class FirestoreCommunityVoteStore implements CommunityVoteStore {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _post(CommunityFeedPost p) =>
      _db.collection('groups').doc(p.groupId).collection('posts').doc(p.id);

  @override
  Future<Set<String>> votedAmong(
    String voterId,
    List<CommunityFeedPost> posts,
  ) async {
    // The vote document id is the voter, so each post needs its own read.
    final snaps = await Future.wait([
      for (final p in posts)
        _post(p).collection('votes').doc(voterId).get().timeout(_timeout),
    ]);
    return {
      for (var i = 0; i < posts.length; i++)
        if (snaps[i].exists) '${posts[i].groupId}/${posts[i].id}',
    };
  }

  @override
  Future<void> vote(CommunityFeedPost post, String voterId) => _guard(() {
    final ref = _post(post);
    final batch = _db.batch()
      ..set(ref.collection('votes').doc(voterId), {
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(ref, {'voteCount': FieldValue.increment(1)});
    return batch.commit();
  });

  @override
  Future<void> unvote(CommunityFeedPost post, String voterId) => _guard(() {
    final ref = _post(post);
    final batch = _db.batch()
      ..delete(ref.collection('votes').doc(voterId))
      ..update(ref, {'voteCount': FieldValue.increment(-1)});
    return batch.commit();
  });
}

/// Saved posts in Firestore (`users/{uid}/bookmarks/{postId}`).
class FirestoreCommunityBookmarkStore implements CommunityBookmarkStore {
  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks');
  }

  @override
  Future<Set<String>> savedAmong(List<String> postIds) async {
    final out = <String>{};
    for (var i = 0; i < postIds.length; i += 30) {
      final chunk = postIds.sublist(
        i,
        i + 30 > postIds.length ? postIds.length : i + 30,
      );
      final snap = await _col()
          .where(FieldPath.documentId, whereIn: chunk)
          .get()
          .timeout(_timeout);
      out.addAll(snap.docs.map((d) => d.id));
    }
    return out;
  }

  @override
  Future<void> add(String postId, String groupId) => _guard(
    () => _col().doc(postId).set({
      'groupId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> remove(String postId) =>
      _guard(() => _col().doc(postId).delete());

  @override
  Future<CommunityBookmarkPage> page({
    Object? after,
    required int limit,
  }) async {
    var q = _col().orderBy('createdAt', descending: true).limit(limit);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    final snap = await q.get().timeout(_timeout);
    return CommunityBookmarkPage(
      [
        for (final d in snap.docs)
          CommunityBookmark(
            postId: d.id,
            groupId: (d.data()['groupId'] as String?) ?? '',
            createdAt: d.data()['createdAt'] is Timestamp
                ? (d.data()['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          ),
      ],
      snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }
}
