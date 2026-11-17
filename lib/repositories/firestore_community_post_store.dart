import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/community/community_models.dart';
import '../core/community/community_posts.dart';

/// Firestore side of posts and comments. M19 step 4.
class FirestoreCommunityPostStore implements CommunityPostStore {
  static const Duration _timeout = Duration(seconds: 10);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _posts(String groupId) =>
      _db.collection('groups').doc(groupId).collection('posts');

  CollectionReference<Map<String, dynamic>> _comments(
    String groupId,
    String postId,
  ) => _posts(groupId).doc(postId).collection('comments');

  /// A refused write becomes [CommunityDeniedException]; other errors pass.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run().timeout(_timeout);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw const CommunityDeniedException();
      rethrow;
    }
  }

  @override
  Future<String> createPost(
    String groupId, {
    required String authorId,
    required String body,
  }) => _guard(() async {
    final ref = await _posts(groupId)
        .add(CommunityFeedPost.createMap(authorId: authorId, body: body));
    return ref.id;
  });

  @override
  Future<void> editPost(String groupId, String postId, String body) => _guard(
    () =>
        _posts(groupId)
            .doc(postId)
            .update({'body': body, 'editedAt': FieldValue.serverTimestamp()}),
  );

  @override
  Future<void> deletePost(String groupId, String postId) =>
      _guard(() => _posts(groupId).doc(postId).delete());

  @override
  Future<CommunityFeedPost?> getPost(String groupId, String postId) async {
    try {
      final snap = await _posts(groupId).doc(postId).get().timeout(_timeout);
      final data = snap.data();
      return data == null
          ? null
          : CommunityFeedPost.fromMap(groupId, snap.id, data);
    } on FirebaseException catch (e) {
      // A hidden post of someone else is "not readable" = not there.
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  @override
  Future<CommunityCommentPage> comments(
    String groupId,
    String postId, {
    Object? after,
    required int limit,
  }) async {
    var q = _comments(groupId, postId).orderBy('createdAt').limit(limit);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    final snap = await q.get().timeout(_timeout);
    return CommunityCommentPage(
      [for (final d in snap.docs) CommunityComment.fromMap(d.id, d.data())],
      snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  @override
  Future<int> commentCount(String groupId, String postId) async {
    final agg = await _comments(
      groupId,
      postId,
    ).count().get().timeout(_timeout);
    return agg.count ?? 0;
  }

  @override
  Future<String> createComment(
    String groupId,
    String postId, {
    required String authorId,
    required String body,
  }) => _guard(() async {
    final ref = await _comments(
      groupId,
      postId,
    ).add(CommunityComment.createMap(authorId: authorId, body: body));
    return ref.id;
  });

  @override
  Future<void> editComment(
    String groupId,
    String postId,
    String commentId,
    String body,
  ) => _guard(
    () => _comments(groupId, postId).doc(commentId).update({
      'body': body,
      'editedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteComment(String groupId, String postId, String commentId) =>
      _guard(() => _comments(groupId, postId).doc(commentId).delete());
}
