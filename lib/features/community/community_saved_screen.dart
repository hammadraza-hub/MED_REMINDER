import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_posts.dart';
import '../../core/community/community_reactions.dart';
import '../../core/community/community_safety.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_feed_service.dart';
import '../../core/services/community_post_service.dart';
import '../../core/services/community_reaction_service.dart';
import '../../core/services/community_safety_service.dart';
import '../../l10n/app_localizations.dart';
import 'community_post_card.dart';
import 'community_post_screen.dart';

/// The posts the user saved. M19 step 5.
class CommunitySavedScreen extends StatefulWidget {
  const CommunitySavedScreen({
    super.key,
    this.bookmarkStore,
    this.postStore,
    this.feedStore,
    this.reactions,
    this.safety,
    this.actions,
    this.myId,
    this.now,
  });

  /// For tests: fake stores.
  @visibleForTesting
  final CommunityBookmarkStore? bookmarkStore;
  @visibleForTesting
  final CommunityPostStore? postStore;
  @visibleForTesting
  final CommunityFeedStore? feedStore;
  @visibleForTesting
  final CommunityReactionsController? reactions;
  @visibleForTesting
  final CommunitySafety? safety;
  @visibleForTesting
  final CommunityPostActions? actions;
  @visibleForTesting
  final String? myId;
  @visibleForTesting
  final DateTime Function()? now;

  @override
  State<CommunitySavedScreen> createState() => _CommunitySavedScreenState();
}

class _CommunitySavedScreenState extends State<CommunitySavedScreen> {
  late final CommunitySavedController _saved;
  late final CommunityReactionsController _reactions;
  late final CommunitySafety _safety;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _reactions = widget.reactions ?? CommunityReactionService.create();
    _safety = widget.safety ?? CommunitySafetyService.instance;
    _safety.blocks.addListener(_changed);
    _safety.blocks.ensureLoaded();
    _saved =
        CommunitySavedController(
            widget.bookmarkStore ?? CommunityReactionService.bookmarks,
            widget.postStore ?? CommunityPostService.store,
            widget.feedStore ?? CommunityFeedService.instance,
            blocked: () => _safety.blocks.ids,
          )
          ..addListener(_changed)
          ..refresh();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) {
        _saved.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _safety.blocks.removeListener(_changed);
    if (widget.reactions == null) _reactions.dispose();
    _saved
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _remove(CommunitySavedEntry e) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _saved.remove(e);
      _reactions.forgetSaved(e.bookmark.postId);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.communitySaveFailed)));
    }
  }

  Future<void> _open(CommunitySavedEntry e) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CommunityPostScreen(
          item: e.item!,
          feedStore: widget.feedStore,
          postStore: widget.postStore,
          actions: widget.actions,
          myId: widget.myId,
          reactions: _reactions,
          safety: _safety,
          now: widget.now,
        ),
      ),
    );
    if (changed == true) _saved.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.permissionsHeader,
        foregroundColor: AppColors.surface,
        title: Text(
          l10n.communitySavedTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _body(l10n)),
    );
  }

  Widget _body(AppLocalizations l10n) {
    switch (_saved.status) {
      case CommunitySavedStatus.loading:
        return const Center(
          child: CircularProgressIndicator(key: Key('saved-loading')),
        );
      case CommunitySavedStatus.failed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: AppColors.permissionsSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.communityLoadFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.permissionsSecondary),
                ),
                TextButton(
                  key: const Key('saved-retry'),
                  onPressed: _saved.refresh,
                  child: Text(l10n.communityRetry),
                ),
              ],
            ),
          ),
        );
      case CommunitySavedStatus.ready:
        if (_saved.entries.isEmpty) {
          return RefreshIndicator(
            onRefresh: _saved.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      l10n.communitySavedEmpty,
                      key: const Key('saved-empty'),
                      style: const TextStyle(
                        color: AppColors.permissionsSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _saved.refresh,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView.builder(
                key: const Key('saved-list'),
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _saved.entries.length + 1,
                itemBuilder: (context, i) {
                  if (i == _saved.entries.length) return _footer(l10n);
                  return _tile(l10n, _saved.entries[i]);
                },
              ),
            ),
          ),
        );
    }
  }

  Widget _tile(AppLocalizations l10n, CommunitySavedEntry e) {
    final remove = IconButton(
      key: Key('saved-remove-${e.bookmark.postId}'),
      tooltip: l10n.communityRemoveFromSaved,
      onPressed: () => _remove(e),
      icon: const Icon(Icons.bookmark_remove_outlined),
    );

    if (e.item == null) {
      return Container(
        key: Key('saved-gone-${e.bookmark.postId}'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.communityPostGone,
                style: const TextStyle(color: AppColors.permissionsSecondary),
              ),
            ),
            remove,
          ],
        ),
      );
    }

    return CommunityPostCard(
      item: e.item!,
      now: widget.now,
      menu: remove,
      onTap: () => _open(e),
    );
  }

  Widget _footer(AppLocalizations l10n) {
    if (_saved.loadMoreFailed) {
      return TextButton(
        key: const Key('saved-load-more-retry'),
        onPressed: _saved.loadMore,
        child: Text(l10n.communityLoadMoreFailed),
      );
    }
    if (_saved.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}
