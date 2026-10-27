import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_exception.dart';
import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../widgets/social_icons.dart';
import '../onboarding/splash_screen.dart';
import 'account_data.dart';

/// ============================================================
/// ACCOUNT — account-level personal info & security
///
/// PURPOSE:
/// Profile info (name, email), linked social sign-ins aur
/// account deletion ko manage karna.
///
/// NAVIGATION:
/// Settings screen ke profile card se push hoti hai (secondary
/// screen) — isliye dark header + back button, koi bottom nav nahi.
///
/// ACTIONS (M2 — Firebase Auth integrated):
/// • Change Photo     → showProfilePhotoPicker (real)
/// • Save Changes     → ProfileController.updateDisplayName + Firebase Auth + Firestore
/// • Change Password  → sends password reset email via Firebase Auth
/// • Sign Out (NEW)   → Firebase Auth signOut + navigate to splash
/// • Delete Account   → Firebase Auth deleteAccount + navigate to splash
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
/// Action button standard green (formAccent) — app convention.
/// ============================================================
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _nameController;
  late List<LinkedAccount> _accounts;

  // M2: Loading states for async operations
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: ProfileController.instance.displayName,
    );
    _accounts = List.of(AccountData.linkedAccounts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// M2: Real email from Firebase Auth (was fake before)
  String get _email {
    return AuthRepository.instance.currentEmail ?? '(no email on file)';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.formAccent,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.surface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.surface),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _changePhoto() async {
    await showProfilePhotoPicker(context);
  }

  /// M2: Save changes — updates ProfileController + Firebase Auth + Firestore
  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();

      // 1. Update local ProfileController
      await ProfileController.instance.updateDisplayName(name);

      // 2. Update Firebase Auth display name
      await AuthRepository.instance.updateDisplayName(displayName: name);

      // 3. Update Firestore users/{uid}.displayName
      final user = AuthRepository.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      _showMessage('Changes saved successfully');
    } on AppException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// M2: Send password reset email via Firebase Auth
  Future<void> _changePassword() async {
    final email = AuthRepository.instance.currentEmail;
    if (email == null) {
      _showMessage('No email on file');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Reset password',
            style: TextStyle(
              color: AppColors.permissionsHeader,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'A password reset link will be sent to $email.',
            style: const TextStyle(color: AppColors.permissionsSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Send Link',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await AuthRepository.instance.sendPasswordResetEmail(email: email);
      if (mounted) _showMessage('Password reset link sent to $email');
    } on AppException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage('Failed to send reset email: $e');
    }
  }

  void _linkApple() {
    setState(() {
      _accounts = _accounts.map((account) {
        if (account.provider == LinkedProvider.apple) {
          return account.copyWith(linked: true, subtitle: 'Connected');
        }
        return account;
      }).toList();
    });
  }

  void _exportData() {
    _showMessage('Preparing your medical archive — coming soon');
  }

  /// M2: Delete account via Firebase Auth + navigate to splash
  Future<void> _openDeleteSheet() async {
    if (_isDeleting) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.allergyScrim,
      builder: (sheetContext) {
        return _DeleteAccountSheet(
          onExport: _exportData,
          onDelete: () => Navigator.of(sheetContext).pop(true),
          onKeep: () => Navigator.of(sheetContext).pop(false),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await AuthRepository.instance.deleteAccount();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    } on AppException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage('Failed to delete account: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  /// M2: Sign out via Firebase Auth + navigate to splash
  Future<void> _signOut() async {
    if (_isSigningOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Sign Out',
            style: TextStyle(
              color: AppColors.permissionsHeader,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.permissionsSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);

    try {
      await AuthRepository.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    } on AppException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage('Failed to sign out: $e');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 16),
                        _buildProfileInfoSection(),
                        const SizedBox(height: 16),
                        _buildSecuritySection(),
                        const SizedBox(height: 12),
                        _buildSaveButton(),
                        const SizedBox(height: 12),
                        _buildSignOutButton(),
                        const SizedBox(height: 12),
                        _buildDangerZone(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.permissionsHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
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
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Account',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.reportPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.surface,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -48,
            left: 0,
            right: 0,
            height: 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.permissionsChipFill,
                    AppColors.permissionsChipFill.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ListenableBuilder(
                listenable: ProfileController.instance,
                builder: (context, child) {
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: _changePhoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const AppAvatar(size: 72),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.permissionsHeader,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.photo_camera_rounded,
                                  color: AppColors.surface,
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ProfileController.instance.displayName,
                            style: const TextStyle(
                              color: AppColors.permissionsHeader,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.permissionsGreenDark,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _email,
                        style: const TextStyle(
                          color: AppColors.permissionsSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _changePhoto,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Change Photo',
                            style: TextStyle(
                              color: AppColors.permissionsGreenDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE INFO SECTION
  // ============================================================

  Widget _buildProfileInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  'PROFILE INFO',
                  style: TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                'Caregiver sync active',
                style: TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel('Full Name'),
              const SizedBox(height: 6),
              _field(
                controller: _nameController,
                suffixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: _FieldLabelText('Email Address')),
                  Row(
                    children: [
                      SizedBox(
                        width: 6,
                        height: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.permissionsGreenDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.permissionsGreenDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _field(
                controller: null,
                staticValue: _email,
                suffixIcon: Icons.check_circle_rounded,
                suffixColor: AppColors.permissionsGreenDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) => _FieldLabelText(label);

  Widget _field({
    TextEditingController? controller,
    String? staticValue,
    required IconData suffixIcon,
    Color suffixColor = AppColors.permissionsSecondary,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: controller != null
                ? TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: AppColors.permissionsHeader,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    staticValue ?? '',
                    style: const TextStyle(
                      color: AppColors.permissionsHeader,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          Icon(suffixIcon, size: 20, color: suffixColor),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY SECTION
  // ============================================================

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'SECURITY',
            style: TextStyle(
              color: AppColors.permissionsHeader,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        _Card(
          child: Column(
            children: [
              _buildPasswordRow(),
              _divider(),
              for (var i = 0; i < _accounts.length; i++) ...[
                if (i > 0) _divider(),
                _buildAccountRow(_accounts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow() {
    return InkWell(
      onTap: _changePassword,
      child: Row(
        children: [
          _iconBox(icon: Icons.lock_rounded),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Updated 3 months ago',
                  style: TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.permissionsSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow(LinkedAccount account) {
    final logo = account.provider == LinkedProvider.google
        ? const GoogleLogo(size: 20)
        : const AppleLogo(size: 20, color: AppColors.permissionsHeader);

    return Row(
      children: [
        _iconBox(child: logo),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.title,
                style: const TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                account.subtitle,
                style: const TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (account.linked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.permissionsChipFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppColors.permissionsGreenDark,
                ),
                SizedBox(width: 4),
                Text(
                  'LINKED',
                  style: TextStyle(
                    color: AppColors.permissionsGreenDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _linkApple,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Link',
                style: TextStyle(
                  color: AppColors.permissionsGreenDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SAVE BUTTON (M2 — loading state)
  // ============================================================

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shareButtonShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.formAccent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isSaving ? null : _save,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.surface,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.save_rounded,
                    size: 20,
                    color: AppColors.surface,
                  ),
                const SizedBox(width: 8),
                Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIGN OUT BUTTON (M2 — NEW)
  // ============================================================

  Widget _buildSignOutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shareButtonShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isSigningOut ? null : _signOut,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSigningOut)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.permissionsHeader,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppColors.permissionsHeader,
                  ),
                const SizedBox(width: 8),
                Text(
                  _isSigningOut ? 'Signing Out...' : 'Sign Out',
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DANGER ZONE (M2 — loading state on Delete Account)
  // ============================================================

  Widget _buildDangerZone() {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.permissionsErrorIcon,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Account Deletion',
                  style: TextStyle(
                    color: AppColors.permissionsErrorIcon,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: _exportData,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 14,
                        color: AppColors.permissionsSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Export Data',
                        style: TextStyle(
                          color: AppColors.permissionsSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.permissionsErrorContainer),
            ),
            child: Material(
              color: AppColors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _isDeleting ? null : _openDeleteSheet,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isDeleting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.permissionsErrorIcon,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(
                          Icons.delete_forever_rounded,
                          size: 20,
                          color: AppColors.permissionsErrorIcon,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isDeleting ? 'Deleting...' : 'Delete Account',
                        style: const TextStyle(
                          color: AppColors.permissionsErrorIcon,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You will be prompted to export medication history and '
            'prescriber notes first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL PIECES
  // ============================================================

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, thickness: 1, color: AppColors.reportChipHigh),
    );
  }

  Widget _iconBox({IconData? icon, Widget? child}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child:
            child ??
            Icon(icon, size: 20, color: AppColors.permissionsSecondary),
      ),
    );
  }
}

/// ============================================================
/// FIELD LABEL TEXT
/// ============================================================

class _FieldLabelText extends StatelessWidget {
  const _FieldLabelText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.permissionsHeader,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// ============================================================
/// CARD — white card with shared shadow
/// ============================================================

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          ),
        ],
      ),
      child: child,
    );
  }
}

/// ============================================================
/// DELETE ACCOUNT SHEET
/// ============================================================

class _DeleteAccountSheet extends StatelessWidget {
  const _DeleteAccountSheet({
    required this.onExport,
    required this.onDelete,
    required this.onKeep,
  });

  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.permissionsHeaderShadow,
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.permissionsErrorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_rounded,
                  color: AppColors.permissionsErrorIcon,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Account?',
                style: TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'All schedule logs, caregiver links, and pill inventory '
                'tracking will be permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.permissionsChipFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_edu_rounded,
                      color: AppColors.permissionsSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Medical Logs',
                            style: TextStyle(
                              color: AppColors.permissionsHeader,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Download PDF report before deleting.',
                            style: TextStyle(
                              color: AppColors.permissionsSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onExport,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'Export',
                            style: TextStyle(
                              color: AppColors.permissionsSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: AppColors.permissionsErrorIcon,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onDelete,
                    child: const Center(
                      child: Text(
                        'Permanently Delete',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: AppColors.permissionsChipFill,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onKeep,
                    child: const Center(
                      child: Text(
                        'Keep Account',
                        style: TextStyle(
                          color: AppColors.permissionsHeader,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
