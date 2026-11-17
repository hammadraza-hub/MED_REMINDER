import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/ai/chat_controller.dart';
import '../../core/async_state.dart';
import '../../core/ai/chat_models.dart';
import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/chat_repository.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_retry_view.dart';
import '../../widgets/skeleton.dart';

/// What the user chose on the history screen: open a saved thread
/// ([threadId] set) or start a new chat ([threadId] null).
class AssistantHistoryChoice {
  const AssistantHistoryChoice.open(String this.threadId);
  const AssistantHistoryChoice.newChat() : threadId = null;

  final String? threadId;
}

/// ============================================================
/// CHAT HISTORY — M18 step 6
///
/// The user's saved conversations for the profile being viewed, newest first.
/// Tap one to continue it, start a new chat, or delete a conversation
/// (confirmed, with all its messages). The screen pops with an
/// [AssistantHistoryChoice]; the chat screen acts on it.
/// ============================================================
class AssistantHistoryScreen extends StatefulWidget {
  const AssistantHistoryScreen({super.key, this.store, this.profileId});

  /// For tests.
  @visibleForTesting
  final ChatStore? store;

  @visibleForTesting
  final String? profileId;

  @override
  State<AssistantHistoryScreen> createState() => _AssistantHistoryScreenState();
}

class _AssistantHistoryScreenState extends State<AssistantHistoryScreen> {
  AsyncState<List<ChatThread>> _state = const AsyncState.loading();

  ChatStore get _store => widget.store ?? ChatRepository.instance;

  String? get _profileId =>
      widget.profileId ?? ProfileController.instance.memberId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AsyncState.loading());
    final id = _profileId;
    if (id == null || id.isEmpty) {
      setState(() => _state = const AsyncState.empty());
      return;
    }
    final next = await AsyncState.guard<List<ChatThread>>(
      () => _store.listThreads(id),
    );
    if (mounted) setState(() => _state = next);
  }

  Future<void> _delete(ChatThread t) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.aiHistoryDeleteTitle),
        content: Text(l10n.aiHistoryDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('history-confirm-delete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.aiHistoryDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _store.deleteThread(t.id);
      if (!mounted) return;
      final left = [
        ...(_state.valueOrNull ?? const <ChatThread>[]).where(
          (x) => x.id != t.id,
        ),
      ];
      setState(
        () => _state = left.isEmpty
            ? const AsyncState.empty()
            : AsyncState.data(left),
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.aiHistoryDeleted)));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.aiHistoryDeleteFailed)));
    }
  }

  String _dateLabel(DateTime d, AppLocalizations l10n) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.aiHistoryToday;
    if (diff == 1) return l10n.aiHistoryYesterday;
    return DateFormat.MMMd(l10n.localeName).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.permissionsHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildBody(l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      color: AppColors.permissionsHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.aiHistoryTitle,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final children = <Widget>[_newChatButton(l10n), const SizedBox(height: 18)];

    _state.when(
      loading: () => children.add(const SkeletonList(count: 3)),
      failure: (e) => children.add(
        SizedBox(
          height: 220,
          child: ErrorRetryView(
            error: e,
            onRetry: _load,
            retryKey: const Key('history-retry'),
          ),
        ),
      ),
      empty: () => children.add(
        SizedBox(
          height: 220,
          child: EmptyStateView(
            icon: Icons.chat_bubble_outline,
            title: l10n.aiHistoryEmpty,
            message: l10n.aiHistoryEmptyBody,
          ),
        ),
      ),
      data: (threads) {
        children.add(_label(l10n.aiHistoryPast));
        children.add(const SizedBox(height: 8));
        for (final t in threads) {
          children.add(_threadTile(t, l10n));
          children.add(const SizedBox(height: 10));
        }
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.aiHistoryHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ),
        );
      },
    );

    children.add(const SizedBox(height: 16));
    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 14,
            color: AppColors.permissionsSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.aiHistorySaved,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: children,
    );
  }

  Widget _newChatButton(AppLocalizations l10n) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        key: const Key('history-new'),
        onPressed: () =>
            Navigator.of(context).pop(const AssistantHistoryChoice.newChat()),
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l10n.aiHistoryNew),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.permissionsGreen,
          foregroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.66,
      color: AppColors.permissionsSecondary,
    ),
  );

  Widget _threadTile(ChatThread t, AppLocalizations l10n) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: InkWell(
        key: Key('history-thread-${t.id}'),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: () =>
            Navigator.of(context).pop(AssistantHistoryChoice.open(t.id)),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dateLabel(t.updatedAt, l10n),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.permissionsSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('history-delete-${t.id}'),
                tooltip: l10n.aiHistoryDelete,
                onPressed: () => _delete(t),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
