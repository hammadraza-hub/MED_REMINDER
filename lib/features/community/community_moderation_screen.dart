import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_models.dart';
import '../../core/community/community_moderation.dart';

import '../../core/community/community_posts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_feed_service.dart';
import '../../core/services/community_moderation_service.dart';
import '../../core/services/community_post_service.dart';
import '../../l10n/app_localizations.dart';
import 'community_texts.dart';

/// Reports and what to do about them. Only moderators get here. M19 step 7.
class CommunityModerationScreen extends StatefulWidget {
  const CommunityModerationScreen({
    super.key,
    this.store,
    this.postStore,
    this.feedStore,
    this.now,
  });

  /// For tests: fake stores.
  @visibleForTesting
  final CommunityModerationStore? store;
  @visibleForTesting
  final CommunityPostStore? postStore;
  @visibleForTesting
  final CommunityFeedStore? feedStore;
  @visibleForTesting
  final DateTime Function()? now;

  @override
  State<CommunityModerationScreen> createState() =>
      _CommunityModerationScreenState();
}

class _CommunityModerationScreenState extends State<CommunityModerationScreen> {
  late final CommunityModerationController _c;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _c =
        CommunityModerationController(
            widget.store ?? CommunityModerationService.store,
            widget.postStore ?? CommunityPostService.store,
            widget.feedStore ?? CommunityFeedService.instance,
          )
          ..addListener(_changed)
          ..refresh();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) {
        _c.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _c
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.communityModerationFailed)),
      );
    }
  }

  Future<void> _delete(CommunityModerationEntry e) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          e.isComment
              ? l10n.communityDeleteCommentTitle
              : l10n.communityDeletePostTitle,
        ),
        content: Text(l10n.communityDeleteBody),
        actions: [
          TextButton(
            key: const Key('mod-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('mod-confirm-delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.communityDelete,
              style: const TextStyle(color: AppColors.permissionsErrorText),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => _c.deleteTarget(e));
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
          l10n.communityModerationTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _body(l10n)),
    );
  }

  Widget _body(AppLocalizations l10n) {
    switch (_c.status) {
      case CommunityModerationStatus.loading:
        return const Center(
          child: CircularProgressIndicator(key: Key('mod-loading')),
        );
      case CommunityModerationStatus.failed:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.communityLoadFailed,
                style: const TextStyle(color: AppColors.permissionsSecondary),
              ),
              TextButton(
                key: const Key('mod-retry'),
                onPressed: _c.refresh,
                child: Text(l10n.communityRetry),
              ),
            ],
          ),
        );
      case CommunityModerationStatus.ready:
        if (_c.entries.isEmpty) {
          return RefreshIndicator(
            onRefresh: _c.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      l10n.communityModerationEmpty,
                      key: const Key('mod-empty'),
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
          onRefresh: _c.refresh,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView.builder(
                key: const Key('mod-list'),
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _c.entries.length + 1,
                itemBuilder: (context, i) {
                  if (i == _c.entries.length) return _footer(l10n);
                  return _card(l10n, _c.entries[i]);
                },
              ),
            ),
          ),
        );
    }
  }

  Widget _footer(AppLocalizations l10n) {
    if (_c.loadMoreFailed) {
      return TextButton(
        key: const Key('mod-load-more-retry'),
        onPressed: _c.loadMore,
        child: Text(l10n.communityLoadMoreFailed),
      );
    }
    if (_c.loadingMore) {
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

  String _reasonLabel(AppLocalizations l10n, CommunityReportReason r) =>
      switch (r) {
        CommunityReportReason.spam => l10n.communityReasonSpam,
        CommunityReportReason.abuse => l10n.communityReasonAbuse,
        CommunityReportReason.medical => l10n.communityReasonMedical,
        CommunityReportReason.other => l10n.communityReasonOther,
      };

  Widget _card(AppLocalizations l10n, CommunityModerationEntry e) {
    final text = e.isComment ? e.comment?.body : e.post?.body;
    final created = e.isComment ? e.comment?.createdAt : e.post?.createdAt;
    final hidden = e.post?.hidden ?? false;

    return Container(
      key: Key('mod-${e.key}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.isComment
                      ? l10n.communityReportedComment
                      : l10n.communityReportedPost,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.permissionsSecondary,
                  ),
                ),
              ),
              Text(
                l10n.communityReportsCount(e.reports.length),
                key: Key('mod-count-${e.key}'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsErrorText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in e.reasons)
                Chip(
                  label: Text(
                    r.value > 1
                        ? '${_reasonLabel(l10n, r.key)} × ${r.value}'
                        : _reasonLabel(l10n, r.key),
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              if (hidden)
                Chip(
                  key: Key('mod-hidden-${e.key}'),
                  label: Text(
                    l10n.communityHiddenChip,
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (e.isGone)
            Text(
              l10n.communityAlreadyRemoved,
              key: Key('mod-gone-${e.key}'),
              style: const TextStyle(color: AppColors.permissionsSecondary),
            )
          else ...[
            Text(
              '${e.author?.pseudonym ?? l10n.communityDeletedAuthor}'
              '${created == null ? '' : ' · ${communityAgoText(context, created, now: widget.now)}'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.permissionsSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text ?? '',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.permissionsHeader,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              if (!e.isComment && !e.isGone)
                TextButton(
                  key: Key('mod-hide-${e.key}'),
                  onPressed: () => _run(() => _c.setHidden(e, !hidden)),
                  child: Text(
                    hidden ? l10n.communityUnhidePost : l10n.communityHidePost,
                  ),
                ),
              if (!e.isGone)
                TextButton(
                  key: Key('mod-delete-${e.key}'),
                  onPressed: () => _delete(e),
                  child: Text(
                    l10n.communityDelete,
                    style: const TextStyle(
                      color: AppColors.permissionsErrorText,
                    ),
                  ),
                ),
              TextButton(
                key: Key('mod-dismiss-${e.key}'),
                onPressed: () => _run(() => _c.dismiss(e)),
                child: Text(l10n.communityDismissReports),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
