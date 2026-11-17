import 'package:flutter/foundation.dart';

import 'community_models.dart';

/// Reading groups and the post feed. M19 step 3.

/// One page of posts. [cursor] is opaque (Firestore: the last document); pass
/// it back to get the next page.
class CommunityFeedPage {
  const CommunityFeedPage(this.posts, this.cursor, {required this.hasMore});

  final List<CommunityFeedPost> posts;
  final Object? cursor;
  final bool hasMore;
}

/// Where the data comes from (Firestore in the app).
abstract class CommunityFeedStore {
  /// Groups, ordered by `order`.
  Future<List<CommunityGroup>> groups();

  /// Visible (not hidden) posts of a group, newest first.
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  });

  /// Profiles by id. An id with no profile (deleted account) is simply not in
  /// the result.
  Future<Map<String, CommunityProfile>> profiles(Set<String> ids);
}

/// A post with its author's public profile (null = account deleted).
class CommunityFeedItem {
  const CommunityFeedItem(this.post, this.author);

  final CommunityFeedPost post;
  final CommunityProfile? author;
}

enum CommunityFeedStatus { loading, ready, failed }

/// The feed of one group: first page, next pages, refresh.
class CommunityFeedController extends ChangeNotifier {
  CommunityFeedController(
    this._store,
    this.groupId, {
    this.pageSize = CommunityLimits.feedPageSize,
    this.blocked,
  });

  final CommunityFeedStore _store;
  final String groupId;
  final int pageSize;

  /// Community ids whose posts are hidden (the user's block list).
  final Set<String> Function()? blocked;

  CommunityFeedStatus status = CommunityFeedStatus.loading;

  List<CommunityFeedItem> _all = const [];

  /// The posts to show: everything loaded, except posts of blocked people.
  List<CommunityFeedItem> get items {
    final b = blocked?.call();
    if (b == null || b.isEmpty) return _all;
    return [
      for (final i in _all)
        if (!b.contains(i.post.authorId)) i,
    ];
  }

  bool hasMore = false;
  bool loadingMore = false;

  /// The last "load more" failed (the first page is still shown).
  bool loadMoreFailed = false;

  Object? _cursor;
  int _generation = 0;
  final Map<String, CommunityProfile?> _authors = {};
  bool _disposed = false;

  /// Loads the first page again (also used for the first load). Older
  /// answers that arrive late are ignored.
  Future<void> refresh() async {
    final gen = ++_generation;
    status = _all.isEmpty ? CommunityFeedStatus.loading : status;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _store.posts(groupId, limit: pageSize);
      final built = await _withAuthors(page.posts);
      if (gen != _generation) return;
      _all = built;
      _cursor = page.cursor;
      hasMore = page.hasMore;
      status = CommunityFeedStatus.ready;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunityFeedController.refresh failed — $e');
      if (_all.isEmpty) status = CommunityFeedStatus.failed;
    }
    _notify();
    await _fillIfBlocked();
  }

  /// Loads the next page. Does nothing while loading or at the end.
  Future<void> loadMore() async {
    if (loadingMore ||
        !hasMore ||
        status != CommunityFeedStatus.ready ||
        _cursor == null) {
      return;
    }
    final gen = _generation;
    loadingMore = true;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _store.posts(groupId, after: _cursor, limit: pageSize);
      final built = await _withAuthors(page.posts);
      if (gen != _generation) return;
      final seen = {for (final i in _all) i.post.id};
      _all = [..._all, ...built.where((i) => !seen.contains(i.post.id))];
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunityFeedController.loadMore failed — $e');
      loadMoreFailed = true;
    } finally {
      if (gen == _generation) loadingMore = false;
    }
    _notify();
    await _fillIfBlocked();
  }

  bool _filling = false;

  /// When every loaded post belongs to a blocked person the screen would show
  /// nothing and never scroll, so keep loading (a few pages at most).
  Future<void> _fillIfBlocked() async {
    if (_filling) return;
    _filling = true;
    try {
      var n = 0;
      while (_all.isNotEmpty &&
          items.isEmpty &&
          hasMore &&
          !loadMoreFailed &&
          n++ < 5) {
        await loadMore();
      }
    } finally {
      _filling = false;
    }
  }

  Future<List<CommunityFeedItem>> _withAuthors(
    List<CommunityFeedPost> posts,
  ) async {
    // A hidden post must never show, even if the store returned one.
    final visible = posts.where((p) => !p.hidden).toList();
    final missing = {
      for (final p in visible)
        if (!_authors.containsKey(p.authorId)) p.authorId,
    };
    if (missing.isNotEmpty) {
      final found = await _store.profiles(missing);
      for (final id in missing) {
        _authors[id] = found[id];
      }
    }
    return [
      for (final p in visible) CommunityFeedItem(p, _authors[p.authorId]),
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
