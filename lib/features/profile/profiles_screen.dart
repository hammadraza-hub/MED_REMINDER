import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../main_shell.dart';
import '../../models/profile.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'profiles_data.dart';
import 'invite_member_screen.dart';
import 'member_permissions_screen.dart';

/// ============================================================
/// PROFILES — switch between managed family members
///
/// M3: Replaced mock data (ProfilesData.managedProfiles()) with
/// Firestore stream query — profiles where memberUids array-contains
/// current user UID. Real-time updates via StreamBuilder.
/// ============================================================
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  // M3: Firestore stream for real-time profile list
  Stream<List<ManagedProfile>>? _profilesStream;

  @override
  void initState() {
    super.initState();
    _profilesStream = _createProfilesStream();
  }

  /// M3: Query profiles where memberUids array-contains current user UID
  Stream<List<ManagedProfile>> _createProfilesStream() {
    final uid = AuthRepository.instance.currentUid;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('profiles')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final profile = Profile.fromFirestore(doc);
            return ManagedProfile(
              memberId: profile.id,
              displayName: profile.name,
              relationship:
                  profile.relationship ??
                  (profile.kind == ProfileKind.self ? 'Self' : 'Member'),
              medicationCount: 0,
              adherencePercent: 0,
              adherenceLabel: '30d Score',
              imagePath: profile.avatarPath,
            );
          }).toList();
        });
  }

  String? get _activeMemberId => ProfileController.instance.memberId;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  void _switchProfile(ManagedProfile profile) {
    final isActive = _activeMemberId == profile.memberId;

    if (isActive) {
      Navigator.of(context).maybePop();
      return;
    }

    ProfileController.instance.selectProfile(
      memberId: profile.memberId,
      displayName: profile.displayName,
      profileImagePath: profile.imagePath,
    );

    if (!mounted) return;

    _showMessage('Switched to ${profile.displayName}');

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: 0,
          onTap: _onBottomNavigationTap,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              const Expanded(
                child: Text(
                  'Profiles',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppAvatar(
                size: 35,
                ringColor: AppColors.surface,
                ringWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _managedTitle()),
            _buildCaregiverSyncChip(),
          ],
        ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tap a profile to view doses and manage their routine.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        const SizedBox(height: 14),

        // M3: Firestore StreamBuilder for profile cards
        StreamBuilder<List<ManagedProfile>>(
          stream: _profilesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.formAccent),
                ),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading profiles: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            final profiles = snapshot.data ?? [];
            if (profiles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_off_rounded,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No profiles yet',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your profiles will appear here',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final profile in profiles) ...[
                  _buildProfileCard(profile),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),

        _buildAddInviteCard(),
        const SizedBox(height: 14),
        _buildCaregiverBanner(),
      ],
    );
  }

  Widget _managedTitle() {
    return StreamBuilder<List<ManagedProfile>>(
      stream: _profilesStream,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Text(
          'MANAGED PROFILES ($count)',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        );
      },
    );
  }

  Widget _buildCaregiverSyncChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.upcomingBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_rounded, size: 11, color: AppColors.textTeal),
          SizedBox(width: 4),
          Text(
            'Caregiver Sync',
            style: TextStyle(
              color: AppColors.textTeal,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ManagedProfile profile) {
    final isActive = _activeMemberId == profile.memberId;

    return GestureDetector(
      onTap: () => _switchProfile(profile),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.formAccent : AppColors.divider,
            width: isActive ? 1.3 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileAvatar(profile, isActive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 7),
                        _buildActiveBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${profile.relationship} · ${profile.medicationCount} ${profile.medicationCount == 1 ? 'medication' : 'medications'}',
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (profile.todayLabel != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          profile.todayIsPositive
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          size: 13,
                          color: profile.todayIsPositive
                              ? AppColors.success
                              : AppColors.missedReasonWarning,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            profile.todayLabel!,
                            style: TextStyle(
                              color: profile.todayIsPositive
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (profile.overdueLabel != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 13,
                          color: AppColors.missedReasonWarning,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            profile.overdueLabel!,
                            style: const TextStyle(
                              color: AppColors.missedReasonWarning,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${profile.adherencePercent}%',
                      style: TextStyle(
                        color: profile.adherencePercent >= 80
                            ? AppColors.formAccent
                            : AppColors.missedReasonWarning,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!isActive) ...[
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: AppColors.fieldHint,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  profile.adherenceLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
                if (profile.statusChip != null) ...[
                  const SizedBox(height: 6),
                  _buildStatusChip(profile),
                ],
              ],
            ),
            const SizedBox(width: 6),
            _buildPermissionsButton(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsButton(ManagedProfile profile) {
    return Tooltip(
      message: 'Permissions — ${profile.displayName}',
      child: GestureDetector(
        onTap: () => _openMemberPermissions(profile),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.manageIconFill,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.manage_accounts_outlined,
            size: 18,
            color: AppColors.formAccent,
          ),
        ),
      ),
    );
  }

  void _openMemberPermissions(ManagedProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => MemberPermissionsScreen(
          memberId: profile.memberId,
          memberDisplayName: profile.displayName,
          memberRelationship: profile.relationship,
          memberProfileImagePath: profile.imagePath,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ManagedProfile profile, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(
          size: 46,
          imagePath: profile.imagePath,
          useSelectedProfileImage: false,
          ringColor: isActive ? AppColors.formAccent : null,
          ringWidth: isActive ? 2 : 0,
        ),
        if (isActive)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 10,
                color: AppColors.surface,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.avatarSelected.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 5, color: AppColors.avatarSelected),
          SizedBox(width: 4),
          Text(
            'ACTIVE',
            style: TextStyle(
              color: AppColors.avatarSelected,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ManagedProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: profile.isStatusChipWarning
            ? AppColors.lowBadgeBackground
            : AppColors.upcomingBackground,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: profile.isStatusChipWarning
              ? AppColors.lowBadgeBorder
              : AppColors.upcomingBackground,
          width: 0.8,
        ),
      ),
      child: Text(
        profile.statusChip!,
        style: TextStyle(
          color: profile.isStatusChipWarning
              ? AppColors.lowBadgeText
              : AppColors.textTeal,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAddInviteCard() {
    return GestureDetector(
      onTap: _openAddInvite,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.upcomingBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 19,
                color: AppColors.textTeal,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Add / Invite Family Member',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.fieldHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.upcomingBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textTeal.withValues(alpha: 0.15)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 16,
            color: AppColors.textTeal,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Caregiver controls allow you to log doses, receive refill '
              'alerts, and track adherence for dependents securely with '
              'HIPAA-compliant encryption.',
              style: TextStyle(
                color: AppColors.textTeal,
                fontSize: 10.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddInvite() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const InviteMemberScreen()));
    if (result == true && mounted) {
      _showMessage('Invite sent / profile created');
    }
  }
}
