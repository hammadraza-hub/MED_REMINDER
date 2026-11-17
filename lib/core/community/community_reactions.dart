import 'package:flutter/foundation.dart';

import 'community_feed.dart';
import 'community_models.dart';
import 'community_posts.dart';

/// Votes and saved posts. M19 step 5.

/// Votes. A vote is the document `votes/{my community id}` of the post, and
/// the post's `voteCount` moves by one in the SAME batch (the rules check
/// both sides).
abstract class CommunityVoteStore {
  /// Keys (`groupId/postId`) of the posts, among [posts], that [voterId] has
  /// voted for.
  Future<Set<String>> votedAmong(String voterId, List<CommunityFeedPost> posts);

  Future<void> vote(CommunityFeedPost post, String voterId);

  Future<void> unvote(CommunityFeedPost post, String voterId);
}

/// A saved post: `users/{uid}/bookmarks/{postId}`.
class CommunityBookmark {
  const CommunityBookmark({
    required this.postId,
    required this.groupId,
    required this.createdAt,
  });

  final String postId;
  final String groupId;
  final DateTime createdAt;
}

class CommunityBookmarkPage {
  const CommunityBookmarkPage(
    this.bookmarks,
    this.cursor, {
    required this.hasMore,
  });

  final List<CommunityBookmark> bookmarks;
  final Object? cursor;
  final bool hasMore;
}

abstract class CommunityBookmarkStore {
  /// Ids, among [postIds], that the user has saved.
  Future<Set<String>> savedAmong(List<String> postIds);

  Future<void> add(String postId, String groupId);

  Future<void> remove(String postId);

  /// Newest first.
  Future<CommunityBookmarkPage> page({Object? after, required int limit});
}

class _Override {
  const _Override(this.base, this.shown);

  /// The post's `voteCount` when the override was made.
  final int base;
  final int shown;
}

/// What the user has voted for / saved, with instant (optimistic) changes.
/// One controller can serve a whole screen (feed, post, saved list).
class CommunityReactionsController extends ChangeNotifier {
  CommunityReactionsController(this._votes, this._saves, this._myId);

  final CommunityVoteStore _votes;
  final CommunityBookmarkStore _saves;

  /// The user's community id, or null when they have no profile.
  final Future<String?> Function() _myId;

  final Set<String> _voted = {};
  final Set<String> _saved = {};
  final Set<String> _loaded = {};
  final Set<String> _busyVotes = {};
  final Set<String> _busySaves = {};
  final Map<String, _Override> _override = {};
  String? _me;
  bool _disposed = false;

  static String keyOf(CommunityFeedPost p) => '${p.groupId}/${p.id}';

  bool isVoted(CommunityFeedPost p) => _voted.contains(keyOf(p));

  bool isSaved(CommunityFeedPost p) => _saved.contains(p.id);

  /// True once the user's community id is known (after the first lookup).
  bool get knowsMe => _me != null;

  /// True when this is the user's own post (it cannot be upvoted).
  bool isMine(CommunityFeedPost p) => _me != null && p.authorId == _me;

  bool isBusy(CommunityFeedPost p) =>
      _busyVotes.contains(keyOf(p)) || _busySaves.contains(p.id);

  /// The vote count to show: the post's own count, or the instant value while
  /// it is still the same server count the user's change was based on.
  int votesOf(CommunityFeedPost p) {
    final o = _override[keyOf(p)];
    if (o != null && o.base == p.voteCount) return o.shown;
    return p.voteCount;
  }

  /// Looks up the user's votes / saves for posts not seen before. A failure
  /// is not fatal: the buttons just start "off" and a later call tries again.
  Future<void> ensureLoaded(List<CommunityFeedPost> posts) async {
    final fresh = [
      for (final p in posts)
        if (!_loaded.contains(keyOf(p))) p,
    ];
    if (fresh.isEmpty) return;
    final keys = fresh.map(keyOf).toList();
    _loaded.addAll(keys);
    try {
      final me = await _myId();
      _me = me;
      if (me != null) {
        _voted.addAll(await _votes.votedAmong(me, fresh));
      }
      _saved.addAll(await _saves.savedAmong([for (final p in fresh) p.id]));
    } catch (e) {
      debugPrint('CommunityReactionsController.ensureLoaded failed — $e');
      _loaded.removeAll(keys);
    }
    _notify();
  }

  /// Forget what was looked up, so the next [ensureLoaded] asks again (after
  /// a pull-to-refresh).
  void forgetAll() {
    _loaded.clear();
    _override.clear();
  }

  /// Vote or take the vote back. Throws on failure (after undoing the change)
  /// so the screen can say so. Does nothing for the user's own post or while
  /// the same post is busy.
  Future<void> toggleVote(CommunityFeedPost p) async {
    final k = keyOf(p);
    if (_busyVotes.contains(k)) return;
    final me = _me ?? await _myId();
    if (me == null) throw const CommunityNoProfileException();
    _me = me;
    if (p.authorId == me) return;

    final was = _voted.contains(k);
    final shownBefore = votesOf(p);
    _busyVotes.add(k);
    _apply(k, p, voted: !was, shown: shownBefore + (was ? -1 : 1));
    try {
      if (was) {
        await _votes.unvote(p, me);
      } else {
        await _votes.vote(p, me);
      }
    } on CommunityDeniedException {
      // Refused: maybe the vote was already (not) there (another phone), or
      // the post is gone. Ask the server what is true.
      var serverVoted = was;
      try {
        serverVoted = (await _votes.votedAmong(me, [p])).contains(k);
      } catch (_) {}
      if (serverVoted == !was) {
        // Already in the state the user wanted: keep it, count unknown.
        _override.remove(k);
        _busyVotes.remove(k);
        _notify();
        return;
      }
      _apply(k, p, voted: was, shown: shownBefore);
      _busyVotes.remove(k);
      _notify();
      rethrow;
    } catch (_) {
      _apply(k, p, voted: was, shown: shownBefore);
      _busyVotes.remove(k);
      _notify();
      rethrow;
    }
    _busyVotes.remove(k);
    _notify();
  }

  /// Save or un-save a post.
  Future<void> toggleSave(CommunityFeedPost p) async {
    if (_busySaves.contains(p.id)) return;
    final was = _saved.contains(p.id);
    _busySaves.add(p.id);
    if (was) {
      _saved.remove(p.id);
    } else {
      _saved.add(p.id);
    }
    _notify();
    try {
      if (was) {
        await _saves.remove(p.id);
      } else {
        await _saves.add(p.id, p.groupId);
      }
    } catch (_) {
      if (was) {
        _saved.add(p.id);
      } else {
        _saved.remove(p.id);
      }
      rethrow;
    } finally {
      _busySaves.remove(p.id);
      _notify();
    }
  }

  void _apply(
    String k,
    CommunityFeedPost p, {
    required bool voted,
    required int shown,
  }) {
    if (voted) {
      _voted.add(k);
    } else {
      _voted.remove(k);
    }
    _override[k] = _Override(p.voteCount, shown);
    _notify();
  }

  /// Marks a post as un-saved without calling the store (after the saved
  /// list removed it).
  void forgetSaved(String postId) {
    _saved.remove(postId);
    _notify();
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

/// One line of the "Saved posts" list. [item] is null when the post is gone
/// (deleted or hidden).
class CommunitySavedEntry {
  const CommunitySavedEntry(this.bookmark, this.item);

  final CommunityBookmark bookmark;
  final CommunityFeedItem? item;
}

enum CommunitySavedStatus { loading, ready, failed }

/// The user's saved posts, newest saved first.
class CommunitySavedController extends ChangeNotifier {
  CommunitySavedController(
    this._saves,
    this._posts,
    this._feed, {
    this.pageSize = CommunityLimits.feedPageSize,
    this.blocked,
  });

  /// Community ids whose posts are hidden (the user's block list).
  final Set<String> Function()? blocked;

  final CommunityBookmarkStore _saves;
  final CommunityPostStore _posts;
  final CommunityFeedStore _feed;
  final int pageSize;

  CommunitySavedStatus status = CommunitySavedStatus.loading;

  List<CommunitySavedEntry> _all = const [];

  /// Saved posts, except those of blocked people.
  List<CommunitySavedEntry> get entries {
    final b = blocked?.call();
    if (b == null || b.isEmpty) return _all;
    return [
      for (final e in _all)
        if (e.item == null || !b.contains(e.item!.post.authorId)) e,
    ];
  }

  bool hasMore = false;
  bool loadingMore = false;
  bool loadMoreFailed = false;

  Object? _cursor;
  int _generation = 0;
  bool _disposed = false;

  Future<void> refresh() async {
    final gen = ++_generation;
    if (_all.isEmpty) status = CommunitySavedStatus.loading;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _saves.page(limit: pageSize);
      final built = await _build(page.bookmarks);
      if (gen != _generation) return;
      _all = built;
      _cursor = page.cursor;
      hasMore = page.hasMore;
      status = CommunitySavedStatus.ready;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunitySavedController.refresh failed — $e');
      if (_all.isEmpty) status = CommunitySavedStatus.failed;
    }
    _notify();
  }

  Future<void> loadMore() async {
    if (loadingMore ||
        !hasMore ||
        status != CommunitySavedStatus.ready ||
        _cursor == null) {
      return;
    }
    final gen = _generation;
    loadingMore = true;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _saves.page(after: _cursor, limit: pageSize);
      final built = await _build(page.bookmarks);
      if (gen != _generation) return;
      final seen = {for (final e in _all) e.bookmark.postId};
      _all = [
        ..._all,
        ...built.where((e) => !seen.contains(e.bookmark.postId)),
      ];
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunitySavedController.loadMore failed — $e');
      loadMoreFailed = true;
    } finally {
      if (gen == _generation) loadingMore = false;
    }
    _notify();
  }

  /// Takes a post out of the saved list (and from the store).
  Future<void> remove(CommunitySavedEntry entry) async {
    await _saves.remove(entry.bookmark.postId);
    _all = [
      for (final e in _all)
        if (e.bookmark.postId != entry.bookmark.postId) e,
    ];
    _notify();
  }

  Future<List<CommunitySavedEntry>> _build(
    List<CommunityBookmark> bookmarks,
  ) async {
    final posts = await Future.wait([
      for (final b in bookmarks) _posts.getPost(b.groupId, b.postId),
    ]);
    final visible = [
      for (final p in posts)
        if (p != null && !p.hidden) p,
    ];
    final authors = visible.isEmpty
        ? <String, CommunityProfile>{}
        : await _feed.profiles({for (final p in visible) p.authorId});
    return [
      for (var i = 0; i < bookmarks.length; i++)
        CommunitySavedEntry(
          bookmarks[i],
          (posts[i] == null || posts[i]!.hidden)
              ? null
              : CommunityFeedItem(posts[i]!, authors[posts[i]!.authorId]),
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
