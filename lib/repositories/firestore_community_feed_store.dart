import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/community/community_feed.dart';
import '../core/community/community_models.dart';

/// Firestore side of reading groups and feeds. M19 step 3.
class FirestoreCommunityFeedStore implements CommunityFeedStore {
  static const Duration _timeout = Duration(seconds: 10);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<List<CommunityGroup>> groups() async {
    final snap = await _db
        .collection('groups')
        .orderBy('order')
        .get()
        .timeout(_timeout);
    return [for (final d in snap.docs) CommunityGroup.fromMap(d.id, d.data())];
  }

  @override
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  }) async {
    // `hidden == false` is required by the rules (hidden posts are only for
    // their author and moderators). Needs the composite index hidden +
    // createdAt (firestore.indexes.json).
    var q = _db
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .where('hidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);

    final snap = await q.get().timeout(_timeout);
    return CommunityFeedPage(
      [
        for (final d in snap.docs)
          CommunityFeedPost.fromMap(groupId, d.id, d.data()),
      ],
      snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  @override
  Future<Map<String, CommunityProfile>> profiles(Set<String> ids) async {
    final out = <String, CommunityProfile>{};
    final list = ids.toList();
    // whereIn takes at most 30 values.
    for (var i = 0; i < list.length; i += 30) {
      final chunk = list.sublist(
        i,
        i + 30 > list.length ? list.length : i + 30,
      );
      final snap = await _db
          .collection('communityProfiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get()
          .timeout(_timeout);
      for (final d in snap.docs) {
        out[d.id] = CommunityProfile.fromMap(d.id, d.data());
      }
    }
    return out;
  }
}
