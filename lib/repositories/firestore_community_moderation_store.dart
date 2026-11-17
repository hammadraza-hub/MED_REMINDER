import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/community/community_models.dart';
import '../core/community/community_moderation.dart';

const Duration _timeout = Duration(seconds: 10);

/// Moderation in Firestore (reports, hide, delete). M19 step 7.
class FirestoreCommunityModerationStore implements CommunityModerationStore {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _post(String g, String p) =>
      _db.collection('groups').doc(g).collection('posts').doc(p);

  @override
  Future<CommunityReportPage> reports({
    Object? after,
    required int limit,
  }) async {
    var q = _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    final snap = await q.get().timeout(_timeout);
    return CommunityReportPage(
      [for (final d in snap.docs) CommunityReport.fromMap(d.id, d.data())],
      snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  @override
  Future<CommunityComment?> getComment(
    String groupId,
    String postId,
    String commentId,
  ) async {
    final snap = await _post(
      groupId,
      postId,
    ).collection('comments').doc(commentId).get().timeout(_timeout);
    final data = snap.data();
    return data == null ? null : CommunityComment.fromMap(snap.id, data);
  }

  @override
  Future<void> setHidden(String groupId, String postId, bool hidden) =>
      _post(groupId, postId).update({'hidden': hidden}).timeout(_timeout);

  @override
  Future<void> deletePost(String groupId, String postId) =>
      _post(groupId, postId).delete().timeout(_timeout);

  @override
  Future<void> deleteComment(String groupId, String postId, String commentId) =>
      _post(
        groupId,
        postId,
      ).collection('comments').doc(commentId).delete().timeout(_timeout);

  @override
  Future<void> deleteReportsFor(
    String groupId,
    String postId, {
    String? commentId,
  }) async {
    final snap = await _db
        .collection('reports')
        .where('postId', isEqualTo: postId)
        .get()
        .timeout(_timeout);
    final batch = _db.batch();
    var any = false;
    for (final d in snap.docs) {
      final data = d.data();
      if (data['groupId'] != groupId) continue;
      if ((data['commentId'] as String?) != commentId) continue;
      batch.delete(d.reference);
      any = true;
    }
    if (any) await batch.commit().timeout(_timeout);
  }
}

/// Whether the signed-in account is a moderator (custom claim `moderator`).
/// The token is refreshed so a claim set a moment ago is seen.
Future<bool> readModeratorClaim() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  try {
    final result = await user.getIdTokenResult(true);
    return result.claims?['moderator'] == true;
  } catch (_) {
    return false;
  }
}
