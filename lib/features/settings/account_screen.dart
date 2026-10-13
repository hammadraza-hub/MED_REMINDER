import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../widgets/social_icons.dart';
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
/// ACTIONS:
/// • Change Photo     → showProfilePhotoPicker (real)
/// • Save Changes     → ProfileController.updateDisplayName (real)
/// • Change Password  → reset link dialog
/// • Apple "Link"     → in-memory LINKED
/// • Delete Account   → confirm sheet (backend pending)
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

  String get _email {
    final name = ProfileController.instance.displayName;
    return '${name.toLowerCase().replaceAll(RegExp(r'\s+'), '.')}@email.com';
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

  Future<void> _save() async {
    await ProfileController.instance.updateDisplayName(_nameController.text);

    if (!mounted) return;

    FocusScope.of(context).unfocus();
    _showMessage('Changes saved successfully');
  }

  void _changePassword() {
    showDialog<void>(
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
            'A password reset link will be sent to $_email.',
            style: const TextStyle(color: AppColors.permissionsSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
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

  Future<void> _openDeleteSheet() async {
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

    if (confirmed == true && mounted) {
      _showMessage('Account deletion scheduled — coming soon');
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  // SAVE BUTTON
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
          onTap: _save,
          child: const SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, size: 20, color: AppColors.surface),
                SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: TextStyle(
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
  // DANGER ZONE
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
                onTap: _openDeleteSheet,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_forever_rounded,
                        size: 20,
                        color: AppColors.permissionsErrorIcon,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delete Account',
                        style: TextStyle(
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
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.reportChipHigh,
      ),
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
        child: child ??
            Icon(
              icon,
              size: 20,
              color: AppColors.permissionsSecondary,
            ),
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
