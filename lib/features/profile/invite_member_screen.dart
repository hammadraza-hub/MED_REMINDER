import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'invites_data.dart';

/// ============================================================
/// INVITE MEMBER
///
/// PURPOSE:
/// Add a new linked profile — invite an independent adult or
/// create a dependent profile.
///
/// KEY ELEMENTS:
/// • Invite type selector (Adult / Dependent)
/// • Contact input (email/phone) — adult only
/// • Relationship label chips
/// • Permission-level selector (Viewer / Co-manager)
/// • "Managed by me" toggle for dependents
///
/// USER ACTIONS:
/// • Send invite → InvitesData.addInvite (TODO backend)
/// • Skip for now → pop
///
/// DATA:
/// UI → InvitesData.addInvite (member-isolated)
///
/// BOTTOM BAR:
/// Shared AppBottomNavigation (baaki detail screens jaisi).
///
/// TODO Backend:
/// Firestore invites/{id} create + secure invite link email/SMS.
/// Dependent profile → Members collection mein real member create.
/// ============================================================
class InviteMemberScreen extends StatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  InviteType _inviteType = InviteType.adult;

  final _contactController = TextEditingController();

  String _selectedRelationship = 'Mother';

  PermissionLevel _permissionLevel = PermissionLevel.viewer;

  bool _managedByMe = true;

  bool _isSending = false;

  static const List<String> _relationships = [
    'Mother',
    'Father',
    'Son',
    'Daughter',
    'Other',
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
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
  // SEND INVITE
  // ============================================================

  Future<void> _sendInvite() async {
    if (_isSending) {
      return;
    }

    final memberId = ProfileController.instance.memberId;

    if (memberId == null || memberId.isEmpty) {
      _showMessage('No family member selected.');
      return;
    }

    // Adult invite ke liye contact zaroori hai.
    final contact = _contactController.text.trim();

    if (_inviteType == InviteType.adult && contact.isEmpty) {
      _showMessage('Please enter email or phone number.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    InvitesData.addInvite(
      inviterMemberId: memberId,
      type: _inviteType,
      relationship: _selectedRelationship,
      contact: _inviteType == InviteType.adult ? contact : null,
      permissionLevel: _permissionLevel,
      managedByMe: _inviteType == InviteType.dependent ? _managedByMe : false,
    );

    // TODO Backend:
    // 1. Firestore invites/{id} create
    // 2. Adult → secure invite link email/SMS
    // 3. Dependent → Members collection mein real member create
    //    (MemberRepository.saveMember)

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) {
      return;
    }

    _showMessage(
      _inviteType == InviteType.adult
          ? 'Invite sent to $contact'
          : '${_selectedRelationship} profile created',
    );

    Navigator.of(context).pop(true);
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
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
                  'Invite Member',
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
        // INVITE TYPE
        // ======================================================

        const Text(
          'INVITE TYPE',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),

        const SizedBox(height: 10),

        _buildInviteTypeCard(
          title: 'Invite an Adult',
          subtitle: 'They manage their own login & data',
          icon: Icons.person_outline_rounded,
          selected: _inviteType == InviteType.adult,
          onTap: () {
            setState(() {
              _inviteType = InviteType.adult;
            });
          },
        ),

        const SizedBox(height: 10),

        _buildInviteTypeCard(
          title: 'Create Dependent Profile',
          subtitle: 'I manage everything for them (e.g. a child)',
          icon: Icons.family_restroom_rounded,
          selected: _inviteType == InviteType.dependent,
          onTap: () {
            setState(() {
              _inviteType = InviteType.dependent;
            });
          },
        ),

        const SizedBox(height: 18),

        // ======================================================
        // EMAIL / PHONE — adult mode only
        // ======================================================
        if (_inviteType == InviteType.adult) ...[
          _buildLabel('Email or Phone'),

          const SizedBox(height: 6),

          _buildContactField(),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: AppColors.textTeal,
              ),

              const SizedBox(width: 5),

              const Expanded(
                child: Text(
                  "They'll receive a secure invite link",
                  style: TextStyle(color: AppColors.textTeal, fontSize: 10.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
        ],

        // ======================================================
        // RELATIONSHIP
        // ======================================================
        _buildLabel('Relationship'),

        const SizedBox(height: 8),

        _buildRelationshipChips(),

        const SizedBox(height: 18),

        // ======================================================
        // PERMISSION LEVEL
        // ======================================================
        _buildLabel('Permission Level'),

        const SizedBox(height: 8),

        _buildPermissionCard(
          title: 'Viewer',
          subtitle: 'can see adherence only',
          selected: _permissionLevel == PermissionLevel.viewer,
          onTap: () {
            setState(() {
              _permissionLevel = PermissionLevel.viewer;
            });
          },
        ),

        const SizedBox(height: 10),

        _buildPermissionCard(
          title: 'Co-manager',
          subtitle: 'can edit schedule & log doses',
          selected: _permissionLevel == PermissionLevel.coManager,
          onTap: () {
            setState(() {
              _permissionLevel = PermissionLevel.coManager;
            });
          },
        ),

        const SizedBox(height: 14),

        // ======================================================
        // MANAGED BY ME — dependents ke liye
        // ======================================================
        _buildManagedByMeCard(),

        const SizedBox(height: 22),

        // ======================================================
        // SEND INVITE
        // ======================================================
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.primaryDark.withValues(
                alpha: 0.65,
              ),
              elevation: 4,
              shadowColor: AppColors.primaryDark.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, size: 17),
                      SizedBox(width: 8),
                      Text(
                        'Send Invite',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // ======================================================
        // SKIP FOR NOW
        // ======================================================
        Center(
          child: TextButton(
            onPressed: _isSending
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: AppColors.textTeal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // INVITE TYPE CARD — radio style
  // ============================================================

  Widget _buildInviteTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.formAccent : AppColors.divider,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.fieldHint,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTACT FIELD
  // ============================================================

  Widget _buildContactField() {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: _contactController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'name@email.com or +1 555...',
          hintStyle: const TextStyle(
            color: AppColors.fieldHint,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          suffixIcon: const Icon(
            Icons.alternate_email_rounded,
            color: AppColors.textTeal,
            size: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RELATIONSHIP CHIPS
  // ============================================================

  Widget _buildRelationshipChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _relationships.map((relationship) {
        final selected = _selectedRelationship == relationship;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRelationship = relationship;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.formAccent : AppColors.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? AppColors.formAccent : AppColors.divider,
              ),
            ),
            child: Text(
              relationship,
              style: TextStyle(
                color: selected ? AppColors.surface : AppColors.textTeal,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // PERMISSION CARD — radio style
  // ============================================================

  Widget _buildPermissionCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.formAccent : AppColors.divider,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Radio circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MANAGED BY ME — toggle
  // ============================================================

  Widget _buildManagedByMeCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _managedByMe
              ? AppColors.formAccent.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Managed by me',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'For dependents — no separate login',
                  style: TextStyle(color: AppColors.textTeal, fontSize: 10.5),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _managedByMe,
              onChanged: (value) {
                setState(() {
                  _managedByMe = value;
                });
              },
              activeColor: AppColors.surface,
              activeTrackColor: AppColors.formAccent,
              inactiveThumbColor: AppColors.surface,
              inactiveTrackColor: AppColors.divider,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
