import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_models.dart';
import '../../core/community/community_posts.dart';
import '../../core/community/community_reactions.dart';
import '../../core/community/community_safety.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_feed_service.dart';
import '../../core/services/community_post_service.dart';
import '../../core/services/community_profile_service.dart';
import '../../core/services/community_reaction_service.dart';
import '../../core/services/community_safety_service.dart';
import '../../widgets/error_retry_view.dart';
import '../../l10n/app_localizations.dart';
import 'community_avatar.dart';
import 'community_compose_screen.dart';
import 'community_post_card.dart';
import 'community_safety_ui.dart';
import 'community_texts.dart';

/// One post with its comments. M19 step 4.
///
/// Pops `true` when the post was edited or deleted here, so the feed can
/// refresh.
class CommunityPostScreen extends StatefulWidget {
  const CommunityPostScreen({
    super.key,
    required this.item,
    this.feedStore,
    this.postStore,
    this.actions,
    this.myId,
    this.reactions,
    this.safety,
    this.now,
  });

  final CommunityFeedItem item;

  /// For tests.
  @visibleForTesting
  final CommunityFeedStore? feedStore;
  @visibleForTesting
  final CommunityPostStore? postStore;
  @visibleForTesting
  final CommunityPostActions? actions;

  /// For tests: the user's community id (default: the loaded profile).
  @visibleForTesting
  final String? myId;

  /// Shared with the feed, so votes and saves look the same on both screens.
  /// For tests: a controller with fake stores.
  final CommunityReactionsController? reactions;

  /// Report / block (default: the app's).
  final CommunitySafety? safety;
  @visibleForTesting
  final DateTime Function()? now;

  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  late CommunityFeedItem _item;
  late final CommunityCommentsController _comments;
  late final CommunityReactionsController _reactions;
  late final CommunitySafety _safety;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _gone = false;
  bool _changed = false;
  bool _sending = false;
  String? _inputError;

  CommunityFeedStore get _feedStore =>
      widget.feedStore ?? CommunityFeedService.instance;
  CommunityPostStore get _postStore =>
      widget.postStore ?? CommunityPostService.store;
  CommunityPostActions get _actions =>
      widget.actions ?? CommunityPostService.actions;

  String? get _myId =>
      widget.myId ?? CommunityProfileService.instance.profile.value?.id;

  CommunityFeedPost get _post => _item.post;
  bool get _isMine => _myId != null && _post.authorId == _myId;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _reactions = widget.reactions ?? CommunityReactionService.create();
    _reactions.ensureLoaded([widget.item.post]);
    _safety = widget.safety ?? CommunitySafetyService.instance;
    _safety.blocks.addListener(_blocksChanged);
    _safety.blocks.ensureLoaded();
    _comments = CommunityCommentsController(
      _postStore,
      _feedStore,
      _post.groupId,
      _post.id,
      blocked: () => _safety.blocks.ids,
    )..addListener(_changedListener);
    _scroll.addListener(_onScroll);
    _comments.refresh();
    _refreshPost();
  }

  @override
  void dispose() {
    _safety.blocks.removeListener(_blocksChanged);
    _input.dispose();
    if (widget.reactions == null) _reactions.dispose();
    _scroll.dispose();
    _comments
      ..removeListener(_changedListener)
      ..dispose();
    super.dispose();
  }

  void _changedListener() {
    if (mounted) setState(() {});
  }

  /// The author of this post was blocked (here or elsewhere): leave.
  void _blocksChanged() {
    if (!mounted) return;
    if (!_isMine && _safety.blocks.isBlocked(_post.authorId)) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {});
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 400) {
      _comments.loadMore();
    }
  }

  /// Fresh copy of the post (votes, edits); gone when it was deleted/hidden.
  Future<void> _refreshPost() async {
    try {
      final fresh = await _postStore.getPost(_post.groupId, _post.id);
      if (!mounted) return;
      setState(() {
        if (fresh == null || fresh.hidden) {
          _gone = true;
        } else {
          _item = CommunityFeedItem(fresh, _item.author);
        }
      });
    } catch (_) {
      // Keep showing what we have; the user can still read the comments.
    }
  }

  Future<void> _editPost() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CommunityComposeScreen(
          groupId: _post.groupId,
          existing: _post,
          actions: widget.actions,
        ),
      ),
    );
    if (saved == true) {
      _changed = true;
      await _refreshPost();
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(l10n.communityDeleteBody),
        actions: [
          TextButton(
            key: const Key('confirm-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.communityDelete,
              style: const TextStyle(color: AppColors.permissionsErrorText),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deletePost() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!await _confirmDelete(l10n.communityDeletePostTitle)) return;
    try {
      await _actions.deletePost(_post);
      if (mounted) navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(communityActionError(l10n, e))),
      );
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _inputError = null;
    });
    try {
      final done = await submitWithWarnings(
        context,
        (confirmed) => _actions
            .createComment(
              _post.groupId,
              _post.id,
              _input.text,
              confirmed: confirmed,
            )
            .timeout(const Duration(seconds: 10)),
      );
      if (!mounted) return;
      if (!done) {
        setState(() => _sending = false);
        return;
      }
      _input.clear();
      setState(() => _sending = false);
      await _comments.reloadThroughEnd();
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _inputError = communityActionError(
          l10n,
          e,
          max: CommunityLimits.commentBodyMax,
        );
      });
    }
  }

  Future<void> _editComment(CommunityComment c) async {
    final l10n = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditCommentDialog(initial: c.body),
    );
    if (text == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final done = await submitWithWarnings(
        context,
        (confirmed) => _actions.editComment(
          _post.groupId,
          _post.id,
          c,
          text,
          confirmed: confirmed,
        ),
      );
      if (!done) return;
      await _comments.reloadThroughEnd();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            communityActionError(l10n, e, max: CommunityLimits.commentBodyMax),
          ),
        ),
      );
    }
  }

  Future<void> _deleteComment(CommunityComment c) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirmDelete(l10n.communityDeleteCommentTitle)) return;
    try {
      await _actions.deleteComment(_post.groupId, _post.id, c);
      await _comments.reloadThroughEnd();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(communityActionError(l10n, e))),
      );
    }
  }

  Widget _menu({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required Key key,
  }) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      key: key,
      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(l10n.communityEdit)),
        PopupMenuItem(value: 'delete', child: Text(l10n.communityDelete)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.permissionsHeader,
          foregroundColor: AppColors.surface,
          title: Text(
            l10n.communityCommentsTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: _gone
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.communityPostGone,
                      key: const Key('post-gone'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.permissionsSecondary,
                      ),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        Expanded(child: _list(l10n)),
                        _inputBar(l10n),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _list(AppLocalizations l10n) {
    final c = _comments;
    final children = <Widget>[
      CommunityPostCard(
        item: _item,
        now: widget.now,
        reactions: _reactions,
        menu: _isMine
            ? _menu(
                key: const Key('post-menu'),
                onEdit: _editPost,
                onDelete: _deletePost,
              )
            : _myId == null
            ? null
            : CommunitySafetyMenu(
                key: const Key('post-safety-menu'),
                safety: _safety,
                groupId: _post.groupId,
                postId: _post.id,
                authorId: _post.authorId,
                authorName: _item.author?.pseudonym,
              ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          c.count == null
              ? l10n.communityCommentsTitle
              : l10n.communityCommentsCount(c.count!),
          key: const Key('comments-header'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.permissionsHeader,
          ),
        ),
      ),
    ];

    switch (c.status) {
      case CommunityCommentsStatus.loading:
        children.add(
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(key: Key('comments-loading')),
            ),
          ),
        );
      case CommunityCommentsStatus.failed:
        children.add(
          SizedBox(
            height: 200,
            child: ErrorRetryView(
              message: l10n.communityLoadFailed,
              retryLabel: l10n.communityRetry,
              retryKey: const Key('comments-retry'),
              onRetry: c.refresh,
            ),
          ),
        );
      case CommunityCommentsStatus.ready:
        if (c.items.isEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.communityNoComments,
                key: const Key('comments-empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.permissionsSecondary),
              ),
            ),
          );
        }
        for (final i in c.items) {
          children.add(_commentTile(l10n, i));
        }
        if (c.loadMoreFailed) {
          children.add(
            TextButton(
              key: const Key('comments-load-more-retry'),
              onPressed: c.loadMore,
              child: Text(l10n.communityLoadMoreFailed),
            ),
          );
        } else if (c.loadingMore) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
    }

    return ListView(
      key: const Key('post-list'),
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  Widget _commentTile(AppLocalizations l10n, CommunityCommentItem i) {
    final c = i.comment;
    final author = i.author;
    final ago = communityAgoText(context, c.createdAt, now: widget.now);
    final mine = _myId != null && c.authorId == _myId;

    return Container(
      key: Key('comment-${c.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommunityAvatar(avatarKey: author?.avatar, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  author?.pseudonym ?? l10n.communityDeletedAuthor,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: author == null
                        ? AppColors.permissionsSecondary
                        : AppColors.permissionsHeader,
                  ),
                ),
              ),
              Text(
                c.editedAt != null ? '$ago · ${l10n.communityEdited}' : ago,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.permissionsSecondary,
                ),
              ),
              if (mine)
                _menu(
                  key: Key('comment-menu-${c.id}'),
                  onEdit: () => _editComment(c),
                  onDelete: () => _deleteComment(c),
                )
              else if (_myId != null)
                CommunitySafetyMenu(
                  key: Key('comment-safety-${c.id}'),
                  safety: _safety,
                  groupId: _post.groupId,
                  postId: _post.id,
                  commentId: c.id,
                  authorId: c.authorId,
                  authorName: author?.pseudonym,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.permissionsHeader,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(AppLocalizations l10n) {
    return Material(
      color: AppColors.surface,
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          8,
          8,
          8 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('comment-input'),
                controller: _input,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                maxLength: CommunityLimits.commentBodyMax,
                decoration: InputDecoration(
                  hintText: l10n.communityCommentHint,
                  errorText: _inputError,
                  errorMaxLines: 2,
                  counterText: '',
                  isDense: true,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                onChanged: (_) {
                  if (_inputError != null) setState(() => _inputError = null);
                },
              ),
            ),
            IconButton(
              key: const Key('comment-send'),
              tooltip: l10n.communitySend,
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: AppColors.permissionsGreen,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCommentDialog extends StatefulWidget {
  const _EditCommentDialog({required this.initial});

  final String initial;

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.communityEditComment),
      content: TextField(
        key: const Key('edit-comment-text'),
        controller: _c,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        maxLength: CommunityLimits.commentBodyMax,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('edit-comment-save'),
          onPressed: () => Navigator.of(context).pop(_c.text),
          child: Text(l10n.communitySave),
        ),
      ],
    );
  }
}
