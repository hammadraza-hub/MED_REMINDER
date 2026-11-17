import 'package:flutter/foundation.dart';

import 'community_content_filter.dart';
import 'community_feed.dart';
import 'community_models.dart';
import 'community_profile_controller.dart';
import 'community_validator.dart';

/// Writing posts and comments, and reading comments. M19 step 4.

class CommunityCommentPage {
  const CommunityCommentPage(
    this.comments,
    this.cursor, {
    required this.hasMore,
  });

  final List<CommunityComment> comments;
  final Object? cursor;
  final bool hasMore;
}

/// Where posts and comments live (Firestore in the app).
abstract class CommunityPostStore {
  /// Creates a post and returns its id.
  Future<String> createPost(
    String groupId, {
    required String authorId,
    required String body,
  });

  /// Changes only the text (and the edited time).
  Future<void> editPost(String groupId, String postId, String body);

  Future<void> deletePost(String groupId, String postId);

  /// One post, or null when it does not exist (or is not readable).
  Future<CommunityFeedPost?> getPost(String groupId, String postId);

  /// Comments, oldest first.
  Future<CommunityCommentPage> comments(
    String groupId,
    String postId, {
    Object? after,
    required int limit,
  });

  /// Number of comments (a count query; no stored counter).
  Future<int> commentCount(String groupId, String postId);

  Future<String> createComment(
    String groupId,
    String postId, {
    required String authorId,
    required String body,
  });

  Future<void> editComment(
    String groupId,
    String postId,
    String commentId,
    String body,
  );

  Future<void> deleteComment(String groupId, String postId, String commentId);
}

/// The user has no community profile, so they cannot write.
class CommunityNoProfileException implements Exception {
  const CommunityNoProfileException();

  @override
  String toString() => 'CommunityNoProfileException';
}

/// The server refused the write (for example the post was hidden or deleted
/// meanwhile). Thrown by the Firestore store.
class CommunityDeniedException implements Exception {
  const CommunityDeniedException();

  @override
  String toString() => 'CommunityDeniedException';
}

/// The text is not allowed (abuse, or an e-mail / link). Not posted.
class CommunityContentException implements Exception {
  const CommunityContentException(this.verdict);

  final CommunityVerdict verdict;

  @override
  String toString() => 'CommunityContentException($verdict)';
}

/// The text needs the user's OK first (self-harm wording, or risky medicine
/// advice). Ask, then call again with `confirmed: true`.
class CommunityNeedsConfirmException implements Exception {
  const CommunityNeedsConfirmException(this.verdict);

  final CommunityVerdict verdict;

  @override
  String toString() => 'CommunityNeedsConfirmException($verdict)';
}

/// The signed-in user is not the author.
class CommunityNotAuthorException implements Exception {
  const CommunityNotAuthorException();

  @override
  String toString() => 'CommunityNotAuthorException';
}

/// The write side: checks the text, adds the user's community id, and calls
/// the store. Throws [CommunityInputException], [CommunityNoProfileException],
/// [CommunityNotAuthorException], or whatever the store throws.
class CommunityPostActions {
  CommunityPostActions(this._store, this._myId);

  final CommunityPostStore _store;

  /// The user's community id, or null when they have no profile.
  final Future<String?> Function() _myId;

  /// Throws when the text is refused, or needs a yes first.
  void _filter(String body, bool confirmed) {
    final v = CommunityContentFilter.check(body);
    switch (v) {
      case CommunityVerdict.ok:
        return;
      case CommunityVerdict.abusive:
      case CommunityVerdict.contact:
        throw CommunityContentException(v);
      case CommunityVerdict.selfHarm:
      case CommunityVerdict.medicalWarning:
        if (!confirmed) throw CommunityNeedsConfirmException(v);
    }
  }

  Future<String> _needId() async {
    final id = await _myId();
    if (id == null) throw const CommunityNoProfileException();
    return id;
  }

  void _checkPost(String body) {
    final e = CommunityValidator.postBody(body);
    if (e != null) throw CommunityInputException(CommunityField.body, e);
  }

  void _checkComment(String body) {
    final e = CommunityValidator.commentBody(body);
    if (e != null) throw CommunityInputException(CommunityField.body, e);
  }

  Future<String> createPost(
    String groupId,
    String body, {
    bool confirmed = false,
  }) async {
    _checkPost(body);
    _filter(body, confirmed);
    final id = await _needId();
    return _store.createPost(groupId, authorId: id, body: body.trim());
  }

  Future<void> editPost(
    CommunityFeedPost post,
    String body, {
    bool confirmed = false,
  }) async {
    _checkPost(body);
    _filter(body, confirmed);
    final id = await _needId();
    if (post.authorId != id) throw const CommunityNotAuthorException();
    await _store.editPost(post.groupId, post.id, body.trim());
  }

  Future<void> deletePost(CommunityFeedPost post) async {
    final id = await _needId();
    if (post.authorId != id) throw const CommunityNotAuthorException();
    await _store.deletePost(post.groupId, post.id);
  }

  Future<String> createComment(
    String groupId,
    String postId,
    String body, {
    bool confirmed = false,
  }) async {
    _checkComment(body);
    _filter(body, confirmed);
    final id = await _needId();
    return _store.createComment(
      groupId,
      postId,
      authorId: id,
      body: body.trim(),
    );
  }

  Future<void> editComment(
    String groupId,
    String postId,
    CommunityComment comment,
    String body, {
    bool confirmed = false,
  }) async {
    _checkComment(body);
    _filter(body, confirmed);
    final id = await _needId();
    if (comment.authorId != id) throw const CommunityNotAuthorException();
    await _store.editComment(groupId, postId, comment.id, body.trim());
  }

  Future<void> deleteComment(
    String groupId,
    String postId,
    CommunityComment comment,
  ) async {
    final id = await _needId();
    if (comment.authorId != id) throw const CommunityNotAuthorException();
    await _store.deleteComment(groupId, postId, comment.id);
  }
}

/// A comment with its author's public profile (null = account deleted).
class CommunityCommentItem {
  const CommunityCommentItem(this.comment, this.author);

  final CommunityComment comment;
  final CommunityProfile? author;
}

enum CommunityCommentsStatus { loading, ready, failed }

/// The comments of one post: first page, next pages, count.
class CommunityCommentsController extends ChangeNotifier {
  CommunityCommentsController(
    this._posts,
    this._feed,
    this.groupId,
    this.postId, {
    this.pageSize = CommunityLimits.feedPageSize,
    this.blocked,
  });

  final CommunityPostStore _posts;

  /// Community ids whose comments are hidden (the user's block list).
  final Set<String> Function()? blocked;

  /// Only used to look up authors.
  final CommunityFeedStore _feed;
  final String groupId;
  final String postId;
  final int pageSize;

  CommunityCommentsStatus status = CommunityCommentsStatus.loading;

  List<CommunityCommentItem> _all = const [];

  /// Everything loaded, except comments of blocked people.
  List<CommunityCommentItem> get items {
    final b = blocked?.call();
    if (b == null || b.isEmpty) return _all;
    return [
      for (final i in _all)
        if (!b.contains(i.comment.authorId)) i,
    ];
  }

  bool hasMore = false;
  bool loadingMore = false;
  bool loadMoreFailed = false;

  /// null until known, or when the count could not be read.
  int? count;

  Object? _cursor;
  int _generation = 0;
  final Map<String, CommunityProfile?> _authors = {};
  bool _disposed = false;

  Future<void> refresh() async {
    final gen = ++_generation;
    if (_all.isEmpty) status = CommunityCommentsStatus.loading;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _posts.comments(groupId, postId, limit: pageSize);
      final built = await _withAuthors(page.comments);
      if (gen != _generation) return;
      _all = built;
      _cursor = page.cursor;
      hasMore = page.hasMore;
      status = CommunityCommentsStatus.ready;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunityCommentsController.refresh failed — $e');
      if (_all.isEmpty) status = CommunityCommentsStatus.failed;
      _notify();
      return;
    }
    _notify();
    try {
      final c = await _posts.commentCount(groupId, postId);
      if (gen == _generation) count = c;
    } catch (e) {
      debugPrint('CommunityCommentsController.count failed — $e');
    }
    _notify();
    await _fillIfBlocked();
  }

  bool _filling = false;

  /// When every loaded comment belongs to a blocked person, keep loading (a
  /// few pages at most) so the list is not empty for no reason.
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

  /// After the user adds a comment: load every page, so the new one (the
  /// newest, at the end) is visible. Bounded.
  Future<void> reloadThroughEnd() async {
    await refresh();
    var guard = 0;
    while (hasMore &&
        !loadMoreFailed &&
        status == CommunityCommentsStatus.ready &&
        guard++ < 50) {
      await loadMore();
    }
  }

  Future<void> loadMore() async {
    if (loadingMore ||
        !hasMore ||
        status != CommunityCommentsStatus.ready ||
        _cursor == null) {
      return;
    }
    final gen = _generation;
    loadingMore = true;
    loadMoreFailed = false;
    _notify();
    try {
      final page = await _posts.comments(
        groupId,
        postId,
        after: _cursor,
        limit: pageSize,
      );
      final built = await _withAuthors(page.comments);
      if (gen != _generation) return;
      final seen = {for (final i in _all) i.comment.id};
      _all = [..._all, ...built.where((i) => !seen.contains(i.comment.id))];
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('CommunityCommentsController.loadMore failed — $e');
      loadMoreFailed = true;
    } finally {
      if (gen == _generation) loadingMore = false;
    }
    _notify();
    await _fillIfBlocked();
  }

  Future<List<CommunityCommentItem>> _withAuthors(
    List<CommunityComment> comments,
  ) async {
    final missing = {
      for (final c in comments)
        if (!_authors.containsKey(c.authorId)) c.authorId,
    };
    if (missing.isNotEmpty) {
      final found = await _feed.profiles(missing);
      for (final id in missing) {
        _authors[id] = found[id];
      }
    }
    return [
      for (final c in comments) CommunityCommentItem(c, _authors[c.authorId]),
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
