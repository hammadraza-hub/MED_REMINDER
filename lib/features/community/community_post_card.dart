import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_models.dart';
import '../../core/community/community_posts.dart';
import '../../core/community/community_reactions.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'community_avatar.dart';
import 'community_texts.dart';

/// One post as a card (feed and post screen). M19 step 3/4.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.item,
    this.now,
    this.onTap,
    this.menu,
    this.reactions,
  });

  final CommunityFeedItem item;
  final DateTime Function()? now;
  final VoidCallback? onTap;

  /// A menu (edit / delete) shown at the top right, for the author only.
  final Widget? menu;

  /// Vote / save buttons. Without it the vote count is just shown.
  final CommunityReactionsController? reactions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final post = item.post;
    final author = item.author;
    final ago = communityAgoText(context, post.createdAt, now: now);

    return Container(
      key: Key('post-${post.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CommunityAvatar(avatarKey: author?.avatar, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.pseudonym ?? l10n.communityDeletedAuthor,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: author == null
                                ? AppColors.permissionsSecondary
                                : AppColors.permissionsHeader,
                          ),
                        ),
                        Text(
                          post.isEdited
                              ? '$ago · ${l10n.communityEdited}'
                              : ago,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.permissionsSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?menu,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.permissionsHeader,
                ),
              ),
              const SizedBox(height: 10),
              if (reactions == null)
                _staticVotes(l10n, post.voteCount)
              else
                CommunityReactionBar(post: post, reactions: reactions!),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _staticVotes(AppLocalizations l10n, int count) {
  return Semantics(
    label: l10n.communityVotesLabel(count),
    child: ExcludeSemantics(
      child: Row(
        children: [
          const Icon(
            Icons.thumb_up_alt_outlined,
            size: 16,
            color: AppColors.permissionsSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.permissionsSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Vote count, upvote button and save button of one post. M19 step 5.
class CommunityReactionBar extends StatelessWidget {
  const CommunityReactionBar({
    super.key,
    required this.post,
    required this.reactions,
  });

  final CommunityFeedPost post;
  final CommunityReactionsController reactions;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String failMessage,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is CommunityNoProfileException
                ? l10n.communityNoProfile
                : failMessage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: reactions,
      builder: (context, _) {
        final voted = reactions.isVoted(post);
        final saved = reactions.isSaved(post);
        final mine = reactions.isMine(post);
        final count = reactions.votesOf(post);
        final busy = reactions.isBusy(post);

        return Row(
          children: [
            if (mine)
              _staticVotes(l10n, count)
            else ...[
              IconButton(
                key: Key('vote-${post.id}'),
                tooltip: voted
                    ? l10n.communityRemoveUpvote
                    : l10n.communityUpvote,
                visualDensity: VisualDensity.compact,
                onPressed: busy
                    ? null
                    : () => _run(
                        context,
                        () => reactions.toggleVote(post),
                        l10n.communityVoteFailed,
                      ),
                icon: Icon(
                  voted
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined,
                  size: 20,
                  color: voted
                      ? AppColors.permissionsGreen
                      : AppColors.permissionsSecondary,
                ),
              ),
              Semantics(
                label: l10n.communityVotesLabel(count),
                child: ExcludeSemantics(
                  child: Text(
                    '$count',
                    key: Key('votes-${post.id}'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: voted ? FontWeight.w700 : FontWeight.w400,
                      color: voted
                          ? AppColors.permissionsGreen
                          : AppColors.permissionsSecondary,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              key: Key('save-${post.id}'),
              tooltip: saved
                  ? l10n.communityUnsavePost
                  : l10n.communitySavePost,
              visualDensity: VisualDensity.compact,
              onPressed: () => _run(
                context,
                () => reactions.toggleSave(post),
                l10n.communitySaveFailed,
              ),
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 22,
                color: saved
                    ? AppColors.permissionsGreen
                    : AppColors.permissionsSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
