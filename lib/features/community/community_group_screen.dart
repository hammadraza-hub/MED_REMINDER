import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_models.dart';
import '../../core/community/community_posts.dart';
import '../../core/community/community_reactions.dart';
import '../../core/community/community_safety.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_feed_service.dart';
import '../../core/services/community_reaction_service.dart';
import '../../core/services/community_safety_service.dart';
import '../../l10n/app_localizations.dart';
import 'community_compose_screen.dart';
import 'community_post_card.dart';
import 'community_post_screen.dart';
import 'community_safety_ui.dart';

/// The post feed of one group (read only). M19 step 3.
class CommunityGroupScreen extends StatefulWidget {
  const CommunityGroupScreen({
    super.key,
    required this.group,
    this.store,
    this.postStore,
    this.actions,
    this.myId,
    this.reactions,
    this.safety,
    this.now,
  });

  final CommunityGroup group;

  /// For tests: a fake store.
  @visibleForTesting
  final CommunityFeedStore? store;

  /// For tests: fake post store / write actions / the user's community id.
  @visibleForTesting
  final CommunityPostStore? postStore;
  @visibleForTesting
  final CommunityPostActions? actions;
  @visibleForTesting
  final String? myId;

  /// For tests: a controller with fake vote / save stores.
  @visibleForTesting
  final CommunityReactionsController? reactions;

  /// For tests: fake report / block.
  @visibleForTesting
  final CommunitySafety? safety;

  /// For tests: a fixed "now" for the "2 h ago" text.
  @visibleForTesting
  final DateTime Function()? now;

  @override
  State<CommunityGroupScreen> createState() => _CommunityGroupScreenState();
}

class _CommunityGroupScreenState extends State<CommunityGroupScreen> {
  late final CommunityFeedController _feed;
  late final CommunityReactionsController _reactions;
  late final CommunitySafety _safety;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _feed = CommunityFeedController(
      widget.store ?? CommunityFeedService.instance,
      widget.group.id,
      blocked: () => _safety.blocks.ids,
    )..addListener(_changed);
    _reactions = widget.reactions ?? CommunityReactionService.create();
    _safety = widget.safety ?? CommunitySafetyService.instance;
    _safety.blocks.addListener(_rebuild);
    _reactions.addListener(_rebuild);
    _safety.blocks.ensureLoaded();
    _scroll.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _safety.blocks.removeListener(_rebuild);
    _reactions.removeListener(_rebuild);
    if (widget.reactions == null) _reactions.dispose();
    _feed
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _reactions.ensureLoaded([for (final i in _feed.items) i.post]);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Reload the first page and look up the user's votes / saves again.
  Future<void> _refresh() {
    _reactions.forgetAll();
    return _feed.refresh();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 400) _feed.loadMore();
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
          widget.group.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _body(l10n)),
      floatingActionButton: FloatingActionButton(
        key: const Key('new-post'),
        tooltip: l10n.communityNewPost,
        backgroundColor: AppColors.permissionsGreen,
        foregroundColor: AppColors.surface,
        onPressed: _compose,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Future<void> _compose() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CommunityComposeScreen(
          groupId: widget.group.id,
          actions: widget.actions,
        ),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _open(CommunityFeedItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CommunityPostScreen(
          item: item,
          feedStore: widget.store,
          postStore: widget.postStore,
          actions: widget.actions,
          myId: widget.myId,
          reactions: _reactions,
          safety: _safety,
          now: widget.now,
        ),
      ),
    );
    if (changed == true) _refresh();
  }

  Widget _body(AppLocalizations l10n) {
    switch (_feed.status) {
      case CommunityFeedStatus.loading:
        return const Center(
          child: CircularProgressIndicator(key: Key('feed-loading')),
        );
      case CommunityFeedStatus.failed:
        return _message(
          icon: Icons.cloud_off_rounded,
          text: l10n.communityLoadFailed,
          retry: l10n.communityRetry,
        );
      case CommunityFeedStatus.ready:
        if (_feed.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      l10n.communityFeedEmpty,
                      key: const Key('feed-empty'),
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
          onRefresh: _refresh,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView.builder(
                key: const Key('feed-list'),
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: _feed.items.length + 1,
                itemBuilder: (context, i) {
                  if (i < _feed.items.length) {
                    final item = _feed.items[i];
                    return CommunityPostCard(
                      item: item,
                      now: widget.now,
                      reactions: _reactions,
                      menu: _reactions.knowsMe && !_reactions.isMine(item.post)
                          ? CommunitySafetyMenu(
                              key: Key('safety-${item.post.id}'),
                              safety: _safety,
                              groupId: item.post.groupId,
                              postId: item.post.id,
                              authorId: item.post.authorId,
                              authorName: item.author?.pseudonym,
                            )
                          : null,
                      onTap: () => _open(item),
                    );
                  }
                  return _footer(l10n);
                },
              ),
            ),
          ),
        );
    }
  }

  Widget _footer(AppLocalizations l10n) {
    if (_feed.loadMoreFailed) {
      return TextButton(
        key: const Key('feed-load-more-retry'),
        onPressed: _feed.loadMore,
        child: Text(l10n.communityLoadMoreFailed),
      );
    }
    if (_feed.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              key: Key('feed-loading-more'),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _message({
    required IconData icon,
    required String text,
    required String retry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.permissionsSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.permissionsSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('feed-retry'),
              onPressed: _refresh,
              child: Text(retry),
            ),
          ],
        ),
      ),
    );
  }
}
