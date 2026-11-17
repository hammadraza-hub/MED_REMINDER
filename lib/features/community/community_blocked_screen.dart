import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_safety.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_feed_service.dart';
import '../../core/services/community_safety_service.dart';
import '../../l10n/app_localizations.dart';
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
  List<CommunityBlockedPerson>? _people;
  bool _failed = false;

  CommunitySafety get _safety =>
      widget.safety ?? CommunitySafetyService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _people = null;
    });
    try {
      await _safety.blocks.load();
      final people = await _safety.blocks.people(
        widget.feedStore ?? CommunityFeedService.instance,
      );
      if (mounted) setState(() => _people = people);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _unblock(CommunityBlockedPerson p) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _safety.blocks.unblock(p.id);
      if (mounted) {
        setState(
          () => _people = [
            for (final x in _people!)
              if (x.id != p.id) x,
          ],
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
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.communityLoadFailed,
              style: const TextStyle(color: AppColors.permissionsSecondary),
            ),
            TextButton(
              key: const Key('blocked-retry'),
              onPressed: _load,
              child: Text(l10n.communityRetry),
            ),
          ],
        ),
      );
    }
    final people = _people;
    if (people == null) {
      return const Center(
        child: CircularProgressIndicator(key: Key('blocked-loading')),
      );
    }
    if (people.isEmpty) {
      return Center(
        child: Text(
          l10n.communityBlockedEmpty,
          key: const Key('blocked-empty'),
          style: const TextStyle(color: AppColors.permissionsSecondary),
        ),
      );
    }
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
