import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_models.dart';
import '../../core/community/community_safety.dart';
import '../../core/community/community_profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_moderation_service.dart';
import '../../core/services/community_profile_service.dart';
import '../../core/services/community_safety_service.dart';
import '../../l10n/app_localizations.dart';
import 'community_avatar.dart';
import 'community_blocked_screen.dart';
import 'community_groups_list.dart';
import 'community_moderation_screen.dart';
import 'community_profile_screen.dart';
import 'community_saved_screen.dart';

/// The way into the community. M19 step 2.
///
/// Loads the user's pseudonym profile. Without one, the "create profile"
/// screen is shown first; with one, the profile is shown (groups and posts
/// arrive in the next steps).
class CommunityGateScreen extends StatefulWidget {
  const CommunityGateScreen({
    super.key,
    this.controller,
    this.feedStore,
    this.safety,
    this.moderatorCheck,
  });

  /// For tests: a controller with a fake store.
  @visibleForTesting
  final CommunityProfileController? controller;

  /// For tests: a fake groups / feed store.
  @visibleForTesting
  final CommunityFeedStore? feedStore;

  /// For tests: fake report / block.
  @visibleForTesting
  final CommunitySafety? safety;

  /// For tests: says whether the user is a moderator.
  @visibleForTesting
  final Future<bool> Function()? moderatorCheck;

  @override
  State<CommunityGateScreen> createState() => _CommunityGateScreenState();
}

enum _Phase { loading, failed, needsProfile, ready }

class _CommunityGateScreenState extends State<CommunityGateScreen> {
  _Phase _phase = _Phase.loading;
  CommunityProfile? _profile;
  bool _isModerator = false;

  CommunityProfileController get _controller =>
      widget.controller ?? CommunityProfileService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final p = await _controller.load();
      if (!mounted) return;
      // The block list belongs to this account: read it again.
      (widget.safety ?? CommunitySafetyService.instance).blocks.load();
      _checkModerator();
      setState(() {
        _profile = p;
        _phase = p == null ? _Phase.needsProfile : _Phase.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  /// Moderators get one more button. A failed check just means "no".
  Future<void> _checkModerator() async {
    try {
      final yes =
          await (widget.moderatorCheck ??
              CommunityModerationService.isModerator)();
      if (mounted && yes != _isModerator) setState(() => _isModerator = yes);
    } catch (_) {
      if (mounted && _isModerator) setState(() => _isModerator = false);
    }
  }

  Future<void> _edit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<CommunityProfile>(
      MaterialPageRoute(
        builder: (_) => CommunityProfileScreen(
          existing: _profile,
          controller: widget.controller,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() => _profile = saved);
    messenger.showSnackBar(SnackBar(content: Text(l10n.communityProfileSaved)));
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.needsProfile) {
      return CommunityProfileScreen(
        controller: widget.controller,
        onSaved: (p) => setState(() {
          _profile = p;
          _phase = _Phase.ready;
        }),
      );
    }

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.permissionsHeader,
        foregroundColor: AppColors.surface,
        title: Text(
          l10n.communityTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _body(l10n)),
    );
  }

  Widget _body(AppLocalizations l10n) {
    switch (_phase) {
      case _Phase.loading:
      case _Phase.needsProfile:
        return const Center(
          child: CircularProgressIndicator(key: Key('community-loading')),
        );
      case _Phase.failed:
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
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('community-retry'),
                  onPressed: _load,
                  child: Text(l10n.communityRetry),
                ),
              ],
            ),
          ),
        );
      case _Phase.ready:
        return _profileView(l10n, _profile!);
    }
  }

  Widget _profileView(AppLocalizations l10n, CommunityProfile p) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Row(
                children: [
                  CommunityAvatar(avatarKey: p.avatar, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.communityYourProfile,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.permissionsSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.pseudonym,
                          key: const Key('community-profile-name'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.permissionsHeader,
                          ),
                        ),
                        if (p.bio.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.bio,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.permissionsSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('community-edit'),
                    tooltip: l10n.communityEditAction,
                    onPressed: _edit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              children: [
                TextButton.icon(
                  key: const Key('community-saved'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommunitySavedScreen(
                        feedStore: widget.feedStore,
                        safety: widget.safety,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.bookmark_border_rounded),
                  label: Text(l10n.communitySavedButton),
                ),
                TextButton.icon(
                  key: const Key('community-blocked'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommunityBlockedScreen(
                        feedStore: widget.feedStore,
                        safety: widget.safety,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.block_rounded),
                  label: Text(l10n.communityBlockedButton),
                ),
                if (_isModerator)
                  TextButton.icon(
                    key: const Key('community-moderation'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommunityModerationScreen(
                          feedStore: widget.feedStore,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.gavel_rounded),
                    label: Text(l10n.communityModerationButton),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            CommunityGroupsList(store: widget.feedStore),
          ],
        ),
      ),
    );
  }
}
