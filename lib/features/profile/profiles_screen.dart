import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'profiles_data.dart';
import 'invite_member_screen.dart';

/// ============================================================
/// PROFILES — switch between managed family members
///
/// PURPOSE:
/// Switch between the profiles a user manages
/// (self + linked family members).
///
/// KEY ELEMENTS:
/// • List of profiles with avatar/name
/// • Quick adherence-status indicator per profile
/// • Active profile highlight (green check ring)
///
/// USER ACTIONS:
/// • Tap to switch active profile → ProfileController.selectProfile
///   (saari member-isolated screens auto-reload — listener pattern)
/// • Tap + to add/invite another (family setup / invite phase)
///
/// DATA:
/// UI → ProfilesData.managedProfiles() (demo stats)
///
/// AVATAR ISOLATION:
/// AppAvatar useSelectedProfileImage: false — Sarah ki selected
/// image Mom/Jake ke avatar par leak nahi hogi.
///
/// BOTTOM BAR:
/// Shared AppBottomNavigation (baaki detail screens jaisi).
///
/// TODO Backend:
/// Adherence stats DoseEvents se derive hongi.
/// Invite flow — family_setup_screen / invite member.
/// ============================================================
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  // ============================================================
  // DATA
  // ============================================================

  List<ManagedProfile> _profiles = [];

  @override
  void initState() {
    super.initState();

    _profiles = ProfilesData.managedProfiles();
  }

  String? get _activeMemberId => ProfileController.instance.memberId;

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // SWITCH PROFILE
  //
  // ProfileController.selectProfile persist + notify karta hai —
  // Meds/Home jaisi screens ke listeners auto-reload karte hain.
  // ============================================================

  void _switchProfile(ManagedProfile profile) {
    final isActive = _activeMemberId == profile.memberId;

    if (isActive) {
      // Already active — wapas dashboard.
      Navigator.of(context).maybePop();
      return;
    }

    ProfileController.instance.selectProfile(
      memberId: profile.memberId,
      displayName: profile.displayName,
      profileImagePath: profile.imagePath,
    );

    if (!mounted) {
      return;
    }

    _showMessage('Switched to ${profile.displayName}');

    Navigator.of(context).maybePop();
  }

  // ============================================================
  // BUILD
  //
  // AnnotatedRegion:
  // Status bar style sirf ISI screen par scoped hai.
  // ============================================================

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

  // ============================================================
  // HEADER
  // ============================================================

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
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
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

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // SECTION HEADER
        // ======================================================

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

        // ======================================================
        // PROFILE CARDS
        // ======================================================
        for (final profile in _profiles) ...[
          _buildProfileCard(profile),
          const SizedBox(height: 12),
        ],

        // ======================================================
        // ADD / INVITE
        // ======================================================
        _buildAddInviteCard(),

        const SizedBox(height: 14),

        // ======================================================
        // CAREGIVER INFO BANNER
        // ======================================================
        _buildCaregiverBanner(),
      ],
    );
  }

  // ============================================================
  // MANAGED TITLE — count ke saath
  // ============================================================

  Widget _managedTitle() {
    return Text(
      'MANAGED PROFILES (${_profiles.length})',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  // ============================================================
  // CAREGIVER SYNC CHIP
  // ============================================================

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
            '3 Caregiver Sync',
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

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard(ManagedProfile profile) {
    final isActive = _activeMemberId == profile.memberId;

    return GestureDetector(
      onTap: () {
        _switchProfile(profile);
      },
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
            // Avatar — active par green check ring
            _buildProfileAvatar(profile, isActive),

            const SizedBox(width: 12),

            // Name + relationship + today status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + ACTIVE badge
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

                  // Relationship + meds count
                  Text(
                    '${profile.relationship} · '
                    '${profile.medicationCount} '
                    '${profile.medicationCount == 1 ? 'medication' : 'medications'}',
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Today status / overdue warning
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

            // Adherence % + label + status chip
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
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE AVATAR — active par green check
  //
  // useSelectedProfileImage: false — member isolation!
  // ============================================================

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

  // ============================================================
  // ACTIVE BADGE
  // ============================================================

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

  // ============================================================
  // STATUS CHIP — "Needs Check-in"
  // ============================================================

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

  // ============================================================
  // ADD / INVITE CARD
  // ============================================================

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

  // ============================================================
  // CAREGIVER INFO BANNER
  // ============================================================

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

  // ============================================================
  // ADD / INVITE
  // ============================================================

  Future<void> _openAddInvite() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const InviteMemberScreen()));

    if (result == true && mounted) {
      _showMessage('Invite sent / profile created');
    }
  }
}
