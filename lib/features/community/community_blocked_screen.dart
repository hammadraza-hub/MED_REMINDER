import 'package:flutter/material.dart';

import '../../core/async_state.dart';
import '../../core/community/community_feed.dart';
import '../../core/community/community_safety.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_feed_service.dart';
import '../../core/services/community_safety_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state_view.dart';
import 'community_avatar.dart';

/// The people the user blocked, with "Unblock". M19 step 6.
class CommunityBlockedScreen extends StatefulWidget {
  const CommunityBlockedScreen({super.key, this.safety, this.feedStore});

  /// For tests.
  @visibleForTesting
  final CommunitySafety? safety;
  @visibleForTesting
  final CommunityFeedStore? feedStore;

  @override
  State<CommunityBlockedScreen> createState() => _CommunityBlockedScreenState();
}

class _CommunityBlockedScreenState extends State<CommunityBlockedScreen> {
  AsyncState<List<CommunityBlockedPerson>> _state = const AsyncState.loading();

  CommunitySafety get _safety =>
      widget.safety ?? CommunitySafetyService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AsyncState.loading());
    final next = await AsyncState.guard<List<CommunityBlockedPerson>>(() async {
      await _safety.blocks.load();
      return _safety.blocks.people(
        widget.feedStore ?? CommunityFeedService.instance,
      );
    });
    if (mounted) setState(() => _state = next);
  }

  Future<void> _unblock(CommunityBlockedPerson p) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _safety.blocks.unblock(p.id);
      if (mounted) {
        final left = [
          for (final x in _state.valueOrNull ?? const <CommunityBlockedPerson>[])
            if (x.id != p.id) x,
        ];
        setState(
          () => _state = left.isEmpty
              ? const AsyncState.empty()
              : AsyncState.data(left),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.communityBlockFailed)),
      );
    }
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
          l10n.communityBlockedTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _body(l10n)),
    );
  }

  Widget _body(AppLocalizations l10n) {
    return AsyncStateView<List<CommunityBlockedPerson>>(
      state: _state,
      onRetry: _load,
      retryKey: const Key('blocked-retry'),
      loading: (_) => const Center(
        child: CircularProgressIndicator(key: Key('blocked-loading')),
      ),
      empty: (_) => EmptyStateView(
        key: const Key('blocked-empty'),
        icon: Icons.block_outlined,
        title: l10n.communityBlockedEmpty,
      ),
      data: (context, people) => _list(l10n, people),
    );
  }

  Widget _list(AppLocalizations l10n, List<CommunityBlockedPerson> people) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final p in people)
              Container(
                key: Key('blocked-${p.id}'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    CommunityAvatar(avatarKey: p.profile?.avatar, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.profile?.pseudonym ?? l10n.communityDeletedAuthor,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.permissionsHeader,
                        ),
                      ),
                    ),
                    TextButton(
                      key: Key('unblock-${p.id}'),
                      onPressed: () => _unblock(p),
                      child: Text(l10n.communityUnblock),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
