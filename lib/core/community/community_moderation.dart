import 'package:flutter/foundation.dart';

import 'community_feed.dart';
import 'community_models.dart';
import 'community_posts.dart';

/// Moderation: reading reports and acting on them. M19 step 7.
///
/// Only an account with the `moderator` claim can read reports or hide /
/// delete other people's posts and comments (the rules enforce it; the screen
/// is only shown to moderators).

class CommunityReportPage {
  const CommunityReportPage(this.reports, this.cursor, {required this.hasMore});

  final List<CommunityReport> reports;
  final Object? cursor;
  final bool hasMore;
}

abstract class CommunityModerationStore {
  /// Reports, newest first.
  Future<CommunityReportPage> reports({Object? after, required int limit});

  /// One comment, or null when it does not exist.
  Future<CommunityComment?> getComment(
    String groupId,
    String postId,
    String commentId,
  );

  Future<void> setHidden(String groupId, String postId, bool hidden);

  Future<void> deletePost(String groupId, String postId);

  Future<void> deleteComment(String groupId, String postId, String commentId);

  /// Deletes every report about one post (or one comment of it).
  Future<void> deleteReportsFor(
    String groupId,
    String postId, {
    String? commentId,
  });
}

/// All reports about one post or comment, with the reported content.
class CommunityModerationEntry {
  const CommunityModerationEntry({
    required this.key,
    required this.groupId,
    required this.postId,
    this.commentId,
    required this.reports,
    this.post,
    this.comment,
    this.author,
  });

  /// `groupId/postId` or `groupId/postId/commentId`.
  final String key;
  final String groupId;
  final String postId;
  final String? commentId;
  final List<CommunityReport> reports;

  /// The reported post (also set for a comment report: the post it is on).
  /// Null when the post no longer exists.
  final CommunityFeedPost? post;

  /// The reported comment. Null for a post report, or when it is gone.
  final CommunityComment? comment;

  /// Profile of the author of the reported thing (null = deleted account).
  final CommunityProfile? author;

  bool get isComment => commentId != null;

  /// The reported post / comment does not exist (any more).
  bool get isGone => isComment ? comment == null : post == null;

  /// How often each reason was given, most common first.
  List<MapEntry<CommunityReportReason, int>> get reasons {
    final counts = <CommunityReportReason, int>{};
    for (final r in reports) {
      counts[r.reason] = (counts[r.reason] ?? 0) + 1;
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  CommunityModerationEntry copyWith({CommunityFeedPost? post}) =>
      CommunityModerationEntry(
        key: key,
        groupId: groupId,
        postId: postId,
        commentId: commentId,
        reports: reports,
        post: post ?? this.post,
        comment: comment,
        author: author,
      );
}

enum CommunityModerationStatus { loading, ready, failed }

/// The moderator's list: reports grouped by what they are about.
class CommunityModerationController extends ChangeNotifier {
  CommunityModerationController(
    this._store,
    this._posts,
    this._feed, {
    this.pageSize = CommunityLimits.feedPageSize,
  });

  final CommunityModerationStore _store;
  final CommunityPostStore _posts;
  final CommunityFeedStore _feed;
  final int pageSize;

  CommunityModerationStatus status = CommunityModerationStatus.loading;
  List<CommunityModerationEntry> entries = const [];
  bool hasMore = false;
  bool loadingMore = false;
  bool loadMoreFailed = false;

  Object? _cursor;
  int _generation = 0;
  bool _disposed = false;

  Future<void> refresh() async {
    final gen = ++_generation;
    if (entries.isEmpty) status = CommunityModerationStatus.loading;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _store.reports(limit: pageSize);
      final built = await _build(page.reports);
      if (gen != _generation) return;
      entries = built;
      _cursor = page.cursor;
      hasMore = page.hasMore;
      status = CommunityModerationStatus.ready;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunityModerationController.refresh failed — $e');
      if (entries.isEmpty) status = CommunityModerationStatus.failed;
    }
    _notify();
  }

  Future<void> loadMore() async {
    if (loadingMore ||
        !hasMore ||
        status != CommunityModerationStatus.ready ||
        _cursor == null) {
      return;
    }
    final gen = _generation;
    loadingMore = true;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _store.reports(after: _cursor, limit: pageSize);
      // Reports of an item that is already in the list join that entry.
      final known = {for (final e in entries) e.key: e};
      final fresh = <CommunityReport>[];
      final merged = <String, List<CommunityReport>>{};
      for (final r in page.reports) {
        final k = _keyOf(r);
        if (known.containsKey(k)) {
          merged.putIfAbsent(k, () => []).add(r);
        } else {
          fresh.add(r);
        }
      }
      final built = await _build(fresh);
      if (gen != _generation) return;
      entries = [
        for (final e in entries)
          if (merged.containsKey(e.key))
            CommunityModerationEntry(
              key: e.key,
              groupId: e.groupId,
              postId: e.postId,
              commentId: e.commentId,
              reports: [...e.reports, ...merged[e.key]!],
              post: e.post,
              comment: e.comment,
              author: e.author,
            )
          else
            e,
        ...built,
      ];
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunityModerationController.loadMore failed — $e');
      loadMoreFailed = true;
    } finally {
      if (gen == _generation) loadingMore = false;
    }
    _notify();
  }

  /// Hides a post from the feed (or shows it again). Throws on failure.
  Future<void> setHidden(CommunityModerationEntry e, bool hidden) async {
    if (e.isComment || e.post == null) return;
    await _store.setHidden(e.groupId, e.postId, hidden);
    final p = e.post!;
    _replace(
      e,
      e.copyWith(
        post: CommunityFeedPost(
          id: p.id,
          groupId: p.groupId,
          authorId: p.authorId,
          body: p.body,
          createdAt: p.createdAt,
          editedAt: p.editedAt,
          voteCount: p.voteCount,
          hidden: hidden,
        ),
      ),
    );
  }

  /// Deletes the reported post or comment and every report about it.
  Future<void> deleteTarget(CommunityModerationEntry e) async {
    if (!e.isGone) {
      if (e.isComment) {
        await _store.deleteComment(e.groupId, e.postId, e.commentId!);
      } else {
        await _store.deletePost(e.groupId, e.postId);
      }
    }
    await _store.deleteReportsFor(e.groupId, e.postId, commentId: e.commentId);
    _remove(e);
  }

  /// Nothing wrong: removes every report about this item, keeps the item.
  Future<void> dismiss(CommunityModerationEntry e) async {
    await _store.deleteReportsFor(e.groupId, e.postId, commentId: e.commentId);
    _remove(e);
  }

  void _replace(CommunityModerationEntry old, CommunityModerationEntry fresh) {
    entries = [
      for (final e in entries)
        if (e.key == old.key) fresh else e,
    ];
    _notify();
  }

  void _remove(CommunityModerationEntry old) {
    entries = [
      for (final e in entries)
        if (e.key != old.key) e,
    ];
    _notify();
  }

  static String _keyOf(CommunityReport r) => r.commentId == null
      ? '${r.groupId}/${r.postId}'
      : '${r.groupId}/${r.postId}/${r.commentId}';

  Future<List<CommunityModerationEntry>> _build(
    List<CommunityReport> reports,
  ) async {
    final groups = <String, List<CommunityReport>>{};
    for (final r in reports) {
      groups.putIfAbsent(_keyOf(r), () => []).add(r);
    }
    final keys = groups.keys.toList();

    final posts = await Future.wait([
      for (final k in keys)
        _posts.getPost(groups[k]!.first.groupId, groups[k]!.first.postId),
    ]);
    final comments = await Future.wait([
      for (final k in keys)
        groups[k]!.first.commentId == null
            ? Future<CommunityComment?>.value(null)
            : _store.getComment(
                groups[k]!.first.groupId,
                groups[k]!.first.postId,
                groups[k]!.first.commentId!,
              ),
    ]);

    final authorIds = <String>{
      for (var i = 0; i < keys.length; i++)
        if (groups[keys[i]]!.first.commentId != null)
          ?comments[i]?.authorId
        else
          ?posts[i]?.authorId,
    };
    final profiles = authorIds.isEmpty
        ? <String, CommunityProfile>{}
        : await _feed.profiles(authorIds);

    return [
      for (var i = 0; i < keys.length; i++)
        CommunityModerationEntry(
          key: keys[i],
          groupId: groups[keys[i]]!.first.groupId,
          postId: groups[keys[i]]!.first.postId,
          commentId: groups[keys[i]]!.first.commentId,
          reports: groups[keys[i]]!,
          post: posts[i],
          comment: comments[i],
          author:
              profiles[groups[keys[i]]!.first.commentId != null
                  ? comments[i]?.authorId
                  : posts[i]?.authorId],
        ),
    ];
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
