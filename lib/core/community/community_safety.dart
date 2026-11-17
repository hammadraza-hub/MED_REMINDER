import 'package:flutter/foundation.dart';

import 'community_feed.dart';
import 'community_models.dart';
import 'community_posts.dart';

/// Reports and blocks. M19 step 6.

/// Where reports go (Firestore in the app). A report is created once; only
/// moderators can read it.
abstract class CommunityReportStore {
  /// Creates `reports/{id}`. Throws [CommunityDeniedException] when it exists
  /// already (or is refused).
  Future<void> create(String id, Map<String, dynamic> data);
}

/// Files reports. The report id is fixed (`{my id}_{post}[_{comment}]`), so
/// the same person can report the same thing only once.
class CommunityReportActions {
  CommunityReportActions(this._store, this._myId);

  final CommunityReportStore _store;
  final Future<String?> Function() _myId;

  static String reportId(
    String reporterId,
    String postId, [
    String? commentId,
  ]) => commentId == null
      ? '${reporterId}_$postId'
      : '${reporterId}_${postId}_$commentId';

  /// Reports a post (or, with [commentId], one of its comments).
  Future<void> report({
    required String groupId,
    required String postId,
    String? commentId,
    required CommunityReportReason reason,
  }) async {
    final me = await _myId();
    if (me == null) throw const CommunityNoProfileException();
    final data = CommunityReport.createMap(
      reporterId: me,
      target: commentId == null
          ? CommunityReportTarget.post
          : CommunityReportTarget.comment,
      groupId: groupId,
      postId: postId,
      commentId: commentId,
      reason: reason,
    );
    await _store.create(reportId(me, postId, commentId), data);
  }
}

/// The user's block list (`users/{uid}/blocks/{community id}`).
abstract class CommunityBlockStore {
  /// All blocked community ids.
  Future<Set<String>> all();

  Future<void> block(String cpid);

  Future<void> unblock(String cpid);
}

/// A blocked person with their public profile (null = account deleted).
class CommunityBlockedPerson {
  const CommunityBlockedPerson(this.id, this.profile);

  final String id;
  final CommunityProfile? profile;
}

/// The blocked list. Feeds and comment lists hide what these people wrote.
class CommunityBlocksController extends ChangeNotifier {
  CommunityBlocksController(this._store, this._myId);

  final CommunityBlockStore _store;
  final Future<String?> Function() _myId;

  final Set<String> _ids = {};
  bool _loaded = false;
  bool _disposed = false;

  /// The blocked community ids (read only).
  Set<String> get ids => Set.unmodifiable(_ids);

  bool get isLoaded => _loaded;

  bool isBlocked(String cpid) => _ids.contains(cpid);

  /// Reads the list from the server (every time the community is opened, so
  /// a different account on this phone never sees another's list). A failure
  /// leaves the list as it was.
  Future<void> load() async {
    try {
      final fresh = await _store.all();
      _ids
        ..clear()
        ..addAll(fresh);
      _loaded = true;
      _notify();
    } catch (e) {
      debugPrint('CommunityBlocksController.load failed — $e');
    }
  }

  /// Loads once (when nothing was read yet).
  Future<void> ensureLoaded() => _loaded ? Future.value() : load();

  /// Blocks a person. Throws when it cannot be saved (nothing changes). You
  /// cannot block yourself.
  Future<void> block(String cpid) async {
    final me = await _myId();
    if (me == null) throw const CommunityNoProfileException();
    if (cpid == me) return;
    await _store.block(cpid);
    _ids.add(cpid);
    _notify();
  }

  Future<void> unblock(String cpid) async {
    await _store.unblock(cpid);
    _ids.remove(cpid);
    _notify();
  }

  /// Forget everything (sign-out).
  void reset() {
    _ids.clear();
    _loaded = false;
    _notify();
  }

  /// The blocked people with their profiles, for the blocked list screen.
  Future<List<CommunityBlockedPerson>> people(CommunityFeedStore feed) async {
    final ids = _ids.toList();
    final profiles = ids.isEmpty
        ? <String, CommunityProfile>{}
        : await feed.profiles(ids.toSet());
    return [for (final id in ids) CommunityBlockedPerson(id, profiles[id])];
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

/// Everything the screens need for safety, in one object.
class CommunitySafety {
  const CommunitySafety({required this.reports, required this.blocks});

  final CommunityReportActions reports;
  final CommunityBlocksController blocks;
}
