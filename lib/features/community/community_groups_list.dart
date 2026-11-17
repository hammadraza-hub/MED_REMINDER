import 'package:flutter/material.dart';

import '../../core/community/community_feed.dart';
import '../../core/community/community_models.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_feed_service.dart';
import '../../l10n/app_localizations.dart';
import 'community_group_screen.dart';

/// The list of groups under the profile card. M19 step 3.
class CommunityGroupsList extends StatefulWidget {
  const CommunityGroupsList({super.key, this.store});

  /// For tests: a fake store.
  @visibleForTesting
  final CommunityFeedStore? store;

  @override
  State<CommunityGroupsList> createState() => _CommunityGroupsListState();
}

class _CommunityGroupsListState extends State<CommunityGroupsList> {
  List<CommunityGroup>? _groups;
  bool _failed = false;

  CommunityFeedStore get _store =>
      widget.store ?? CommunityFeedService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _groups = null;
    });
    try {
      final g = await _store.groups();
      if (mounted) setState(() => _groups = g);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_failed) {
      return Column(
        children: [
          Text(
            l10n.communityLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.permissionsSecondary),
          ),
          TextButton(
            key: const Key('groups-retry'),
            onPressed: _load,
            child: Text(l10n.communityRetry),
          ),
        ],
      );
    }

    final groups = _groups;
    if (groups == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(key: Key('groups-loading')),
        ),
      );
    }
    if (groups.isEmpty) {
      return Text(
        l10n.communityGroupsEmpty,
        key: const Key('groups-empty'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.permissionsSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.communityGroupsTitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.permissionsHeader,
          ),
        ),
        const SizedBox(height: 8),
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: ListTile(
                key: Key('group-${g.id}'),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                leading: const Icon(
                  Icons.forum_outlined,
                  color: AppColors.permissionsGreen,
                ),
                title: Text(
                  g.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.permissionsHeader,
                  ),
                ),
                subtitle: g.description.isEmpty ? null : Text(g.description),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CommunityGroupScreen(group: g, store: widget.store),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
