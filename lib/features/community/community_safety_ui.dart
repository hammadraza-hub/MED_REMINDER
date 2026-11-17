import 'package:flutter/material.dart';

import '../../core/community/community_content_filter.dart';
import '../../core/community/community_models.dart';
import '../../core/community/community_posts.dart';
import '../../core/community/community_safety.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Report / block menu and the warnings before posting. M19 step 6.

/// The "..." menu on somebody else's post or comment: Report, Block.
class CommunitySafetyMenu extends StatelessWidget {
  const CommunitySafetyMenu({
    super.key,
    required this.safety,
    required this.groupId,
    required this.postId,
    this.commentId,
    required this.authorId,
    required this.authorName,
    this.onBlocked,
  });

  final CommunitySafety safety;
  final String groupId;
  final String postId;

  /// Set when the menu is on a comment.
  final String? commentId;
  final String authorId;

  /// The pseudonym, or null when the account was deleted.
  final String? authorName;

  /// Called after the author was blocked.
  final VoidCallback? onBlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: '',
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.permissionsSecondary,
        size: 22,
      ),
      onSelected: (v) async {
        if (v == 'report') {
          await showCommunityReportDialog(
            context,
            safety: safety,
            groupId: groupId,
            postId: postId,
            commentId: commentId,
          );
        } else {
          final blocked = await confirmCommunityBlock(
            context,
            safety: safety,
            authorId: authorId,
            authorName: authorName,
          );
          if (blocked) onBlocked?.call();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          key: const Key('menu-report'),
          value: 'report',
          child: Text(l10n.communityReport),
        ),
        PopupMenuItem(
          key: const Key('menu-block'),
          value: 'block',
          child: Text(l10n.communityBlock),
        ),
      ],
    );
  }
}

String _reasonLabel(AppLocalizations l10n, CommunityReportReason r) =>
    switch (r) {
      CommunityReportReason.spam => l10n.communityReasonSpam,
      CommunityReportReason.abuse => l10n.communityReasonAbuse,
      CommunityReportReason.medical => l10n.communityReasonMedical,
      CommunityReportReason.other => l10n.communityReasonOther,
    };

/// Asks for a reason, then files the report. Returns true when it was sent.
Future<bool> showCommunityReportDialog(
  BuildContext context, {
  required CommunitySafety safety,
  required String groupId,
  required String postId,
  String? commentId,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final reason = await showDialog<CommunityReportReason>(
    context: context,
    builder: (ctx) => const _ReportDialog(),
  );
  if (reason == null) return false;

  try {
    await safety.reports.report(
      groupId: groupId,
      postId: postId,
      commentId: commentId,
      reason: reason,
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.communityReportThanks)));
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          e is CommunityNoProfileException
              ? l10n.communityNoProfile
              : e is CommunityDeniedException
              ? l10n.communityReportDenied
              : l10n.communitySaveFailed,
        ),
      ),
    );
    return false;
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  CommunityReportReason _reason = CommunityReportReason.spam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.communityReportTitle),
      content: RadioGroup<CommunityReportReason>(
        groupValue: _reason,
        onChanged: (v) => setState(() => _reason = v ?? _reason),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in CommunityReportReason.values)
              RadioListTile<CommunityReportReason>(
                key: Key('reason-${r.name}'),
                value: r,
                title: Text(_reasonLabel(l10n, r)),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('report-send'),
          onPressed: () => Navigator.of(context).pop(_reason),
          child: Text(l10n.communityReportSend),
        ),
      ],
    );
  }
}

/// Asks "Block X?" and blocks. Returns true when the person is now blocked.
Future<bool> confirmCommunityBlock(
  BuildContext context, {
  required CommunitySafety safety,
  required String authorId,
  required String? authorName,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final name = authorName ?? l10n.communityDeletedAuthor;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.communityBlockTitle(name)),
      content: Text(l10n.communityBlockBody),
      actions: [
        TextButton(
          key: const Key('block-cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('block-confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            l10n.communityBlock,
            style: const TextStyle(color: AppColors.permissionsErrorText),
          ),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  try {
    await safety.blocks.block(authorId);
    messenger.showSnackBar(SnackBar(content: Text(l10n.communityBlockedDone)));
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          e is CommunityNoProfileException
              ? l10n.communityNoProfile
              : l10n.communityBlockFailed,
        ),
      ),
    );
    return false;
  }
}

/// Runs [action] (first without, then possibly with the user's OK). When the
/// text needs a warning the user sees it first. Returns false when the user
/// went back; other errors are thrown for the caller to show.
Future<bool> submitWithWarnings(
  BuildContext context,
  Future<void> Function(bool confirmed) action,
) async {
  try {
    await action(false);
    return true;
  } on CommunityNeedsConfirmException catch (e) {
    if (!context.mounted) return false;
    final ok = await _showWarning(context, e.verdict);
    if (ok != true) return false;
    await action(true);
    return true;
  }
}

Future<bool?> _showWarning(BuildContext context, CommunityVerdict verdict) {
  final l10n = AppLocalizations.of(context);
  final selfHarm = verdict == CommunityVerdict.selfHarm;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: Key(selfHarm ? 'warning-self-harm' : 'warning-medical'),
      title: Text(
        selfHarm
            ? l10n.communityWarnSelfHarmTitle
            : l10n.communityWarnMedicalTitle,
      ),
      content: Text(
        selfHarm
            ? l10n.communityWarnSelfHarmBody
            : l10n.communityWarnMedicalBody,
      ),
      actions: [
        TextButton(
          key: const Key('warning-back'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.communityGoBack),
        ),
        TextButton(
          key: const Key('warning-post'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.communityPostAnyway),
        ),
      ],
    ),
  );
}
