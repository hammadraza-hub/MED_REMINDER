import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/app_avatar.dart';
import 'member_permissions_data.dart';

/// ============================================================
/// MEMBER PERMISSIONS SCREEN
///
/// PURPOSE:
/// Caregiver (e.g. Mom) ke liye access level (Viewer / Co-Manager)
/// aur granular visibility toggles select karke save karna.
///
/// FLOW:
/// Profile list se push → role select + 4 visibility toggles →
/// Save Permissions (dummy delay, TODO Backend) /
/// Revoke Access (confirmation dialog).
///
/// NOTE:
/// Detail screen hai — design mein bottom bar nahi hai,
/// isliye wapas sirf back arrow se jaata hai.
/// ============================================================
class MemberPermissionsScreen extends StatefulWidget {
  const MemberPermissionsScreen({
    super.key,
    this.memberId = MemberPermissionsData.defaultMemberId,
    this.memberDisplayName,
    this.memberRelationship,
    this.memberProfileImagePath,
    this.initialAccessLevel,
  });

  /// Kis member ke permissions edit karne hain.
  final String memberId;

  /// Linked-Profile Dashboard se asli member details (override).
  final String? memberDisplayName;
  final String? memberRelationship;
  final String? memberProfileImagePath;

  /// Invite screen se selected role (Viewer/Co-manager) carry forward.
  /// Na diya jaye to profile ka saved level use hoga.
  final AccessLevel? initialAccessLevel;

  @override
  State<MemberPermissionsScreen> createState() =>
      _MemberPermissionsScreenState();
}

/// Save button ki visual state (HTML: idle → saving → saved → idle).
enum _SaveState { idle, saving, saved }

class _MemberPermissionsScreenState extends State<MemberPermissionsScreen> {
  late final MemberPermissionProfile _profile;
  late AccessLevel _accessLevel;
  late final List<PermissionCategory> _categories;
  _SaveState _saveState = _SaveState.idle;

  @override
  void initState() {
    super.initState();
    _profile = MemberPermissionsData.profileForMember(
      widget.memberId,
      displayName: widget.memberDisplayName,
      relationship: widget.memberRelationship,
      profileImagePath: widget.memberProfileImagePath,
    );
    _accessLevel = widget.initialAccessLevel ?? _profile.accessLevel;
    _categories =
        _profile.categories.map((category) => category.copyWith()).toList();
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
        statusBarColor: AppColors.permissionsHeader,
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ],
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
      decoration: const BoxDecoration(
        color: AppColors.permissionsHeader,
        boxShadow: [
          BoxShadow(
            color: AppColors.permissionsHeaderShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
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
                  'Permissions',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppAvatar(
                size: 34,
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
        // 1. MEMBER PROFILE CARD
        // ======================================================

        _buildProfileCard(),

        const SizedBox(height: 16),

        // ======================================================
        // 2. ACCESS LEVEL
        // ======================================================

        _buildSectionHeader(
          title: 'ACCESS LEVEL',
          trailing: _buildRoleDetailsHint(),
        ),

        const SizedBox(height: 8),

        _buildAccessLevelCard(),

        const SizedBox(height: 16),

        // ======================================================
        // 3. VISIBILITY TOGGLES
        // ======================================================

        _buildSectionHeader(
          title:
              'WHAT ${_profile.displayName.toUpperCase()} CAN SEE & MANAGE',
          trailing: Text(
            '${_categories.length} Categories',
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),

        const SizedBox(height: 8),

        _buildVisibilityCard(),

        const SizedBox(height: 14),

        // ======================================================
        // 4. REVOKE ACCESS (danger zone)
        // ======================================================

        _buildRevokeSection(),

        const SizedBox(height: 16),

        // ======================================================
        // 5. SAVE PERMISSIONS
        // ======================================================

        _buildSaveSection(),
      ],
    );
  }

  // ============================================================
  // SECTION HEADER (uppercase label + trailing meta)
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.permissionsHeader,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),

          trailing,
        ],
      ),
    );
  }

  Widget _buildRoleDetailsHint() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Viewer: read-only access · Co-manager: can edit schedules '
              'and log doses',
            ),
          ),
        );
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.permissionsSecondary,
          ),
          SizedBox(width: 4),
          Text(
            'Role details',
            style: TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 1. PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar + online dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                size: 48,
                imagePath: _profile.profileImagePath,
                useSelectedProfileImage: false,
              ),

              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.permissionsBadgeBackground,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.permissionsGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Name + role chip + linked info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _profile.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.permissionsHeader,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.permissionsBadgeBackground
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _accessLevel.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.permissionsGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  _profile.linkedSinceLabel != null
                      ? 'Linked as: ${_profile.relationship} '
                          '· since ${_profile.linkedSinceLabel}'
                      : 'Linked as: ${_profile.relationship}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. ACCESS LEVEL — radio card
  // ============================================================

  Widget _buildAccessLevelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRoleRow(AccessLevel.viewer),

          _buildCardDivider(),

          _buildRoleRow(AccessLevel.coManager),
        ],
      ),
    );
  }

  Widget _buildRoleRow(AccessLevel level) {
    final bool selected = _accessLevel == level;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _accessLevel = level;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        level.label,
                        style: const TextStyle(
                          color: AppColors.permissionsHeader,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (level == AccessLevel.coManager) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_user,
                          size: 16,
                          color: AppColors.permissionsGreen,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 2),

                  Text(
                    level.description,
                    style: const TextStyle(
                      color: AppColors.permissionsSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Radio circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.permissionsGreen
                    : AppColors.permissionsInactiveFill,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x33006F56),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.surface
                      : AppColors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 3. VISIBILITY TOGGLES
  // ============================================================

  Widget _buildVisibilityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < _categories.length; index++) ...[
            if (index > 0) _buildCardDivider(),
            _buildToggleRow(index),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow(int index) {
    final PermissionCategory category = _categories[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.permissionsChipFill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              category.icon,
              size: 18,
              color: AppColors.permissionsSecondary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  category.subtitle,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Switch(
            value: category.isEnabled,
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppColors.permissionsGreen,
            inactiveTrackColor: AppColors.permissionsInactiveFill,
            inactiveThumbColor: AppColors.surface,
            onChanged: (value) {
              setState(() {
                _categories[index] = category.copyWith(isEnabled: value);
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. REVOKE ACCESS
  // ============================================================

  Widget _buildRevokeSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showRevokeDialog,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.permissionsErrorContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1AF3B7B1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gpp_bad,
                  size: 20,
                  color: AppColors.permissionsErrorIcon,
                ),
                SizedBox(width: 8),
                Text(
                  'Revoke Access',
                  style: TextStyle(
                    color: AppColors.permissionsErrorText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${_profile.displayName} will lose access immediately. '
            'Dose histories remain securely preserved.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRevokeDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            "Revoke ${_profile.displayName}'s access?",
          ),
          content: const Text(
            'They will lose access to MedRemind immediately. '
            'Dose histories remain securely preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Revoke',
                style: TextStyle(
                  color: AppColors.permissionsErrorIcon,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // TODO Backend: Firestore par caregiver link revoke karo
    // (member.isActive = false / permissions doc delete).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Access revoked. ${_profile.displayName} has been removed '
          'from active co-managers.',
        ),
      ),
    );
  }

  // ============================================================
  // 5. SAVE PERMISSIONS
  // ============================================================

  Widget _buildSaveSection() {
    final bool isSaving = _saveState == _SaveState.saving;
    final bool isSaved = _saveState == _SaveState.saved;

    return Column(
      children: [
        GestureDetector(
          onTap: isSaving ? null : _savePermissions,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: isSaved
                  ? AppColors.permissionsGreenDark
                  : AppColors.permissionsGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59002C1D),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                else
                  Icon(
                    isSaved ? Icons.task_alt : Icons.check_circle_outline,
                    size: 20,
                    color: AppColors.surface,
                  ),

                const SizedBox(width: 8),

                Text(
                  isSaving
                      ? 'Updating Caregiver...'
                      : isSaved
                          ? 'Saved Successfully'
                          : 'Save Permissions',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Caregiver audit stamp
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: AppColors.permissionsSecondary,
            ),
            SizedBox(width: 6),
            Text(
              'End-to-end encrypted caregiver link',
              style: TextStyle(
                color: AppColors.permissionsSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _savePermissions() async {
    setState(() {
      _saveState = _SaveState.saving;
    });

    // TODO Backend: accessLevel + categories (id → isEnabled map)
    // Firestore mein member document par save karo.
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _saveState = _SaveState.saved;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _saveState = _SaveState.idle;
    });
  }

  // ============================================================
  // CARD DIVIDER
  // ============================================================

  Widget _buildCardDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.permissionsChipFill,
      ),
    );
  }
}
