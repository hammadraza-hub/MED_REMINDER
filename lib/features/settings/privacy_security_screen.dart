import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_toggle_switch.dart';
import 'privacy_security_data.dart';

/// ============================================================
/// PRIVACY & SECURITY SCREEN
///
/// PURPOSE:
/// Data protection settings — biometric app lock, active sessions
/// (remote sign out) aur privacy policy / trust info.
///
/// NAVIGATION:
/// Settings → Privacy & Security row se khulti hai. Detail screen hone
/// ki wajah se shared AppBottomNavigation reuse hoti hai (Settings tab).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// local_auth se asli biometric lock, aur remote session revoke
/// backend phase mein wire honge.
/// ============================================================
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  // ============================================================
  // STATE
  // ============================================================

  late bool _biometricLock;

  /// Sign out kiye gaye remote sessions ke indices.
  final Set<int> _signedOut = {};

  @override
  void initState() {
    super.initState();

    _biometricLock = PrivacySecurityData.defaultBiometricLock;
  }

  // ============================================================
  // ACTIONS
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAppLockCard(),
                        const SizedBox(height: 16),
                        _buildSessionsCard(),
                        const SizedBox(height: 16),
                        _buildPoliciesCard(),
                        const SizedBox(height: 12),
                        _buildTrustCallout(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 4,
        onTap: _onBottomNavigationTap,
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
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 10),
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
                  'Privacy & Security',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppAvatar(
                size: 32,
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
  // APP LOCK CARD
  // ============================================================

  Widget _buildAppLockCard() {
    return _card(
      child: Row(
        children: [
          _iconBox(
            icon: Icons.fingerprint_rounded,
            size: 40,
            color: AppColors.formAccent,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face ID / Biometric Lock',
                  style: TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Require unlock to open app',
                  style: TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppToggleSwitch(
            value: _biometricLock,
            onChanged: (value) {
              setState(() {
                _biometricLock = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE SESSIONS CARD
  // ============================================================

  Widget _buildSessionsCard() {
    final sessions = PrivacySecurityData.sessions;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ACTIVE SESSIONS',
            style: TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < sessions.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.reportSurfaceContainer,
                ),
              ),
            _buildSessionRow(i, sessions[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionRow(int index, ActiveSession session) {
    final isSignedOut = _signedOut.contains(index);

    return Row(
      children: [
        _iconBox(
          icon: session.icon,
          size: 32,
          color: AppColors.permissionsSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isSignedOut
              ? const Text(
                  'Device signed out securely.',
                  style: TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.deviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.permissionsHeader,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.lastActive,
                      style: const TextStyle(
                        color: AppColors.permissionsSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 8),
        if (isSignedOut)
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.formAccent,
          )
        else if (session.isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.permissionsChipFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'CURRENT',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          )
        else
          TextButton(
            onPressed: () {
              setState(() {
                _signedOut.add(index);
              });
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.permissionsErrorIcon,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // POLICIES CARD
  // ============================================================

  Widget _buildPoliciesCard() {
    return _card(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showMessage('Privacy Policy — coming soon'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _iconBox(
                icon: Icons.verified_user_rounded,
                size: 32,
                color: AppColors.permissionsSecondary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  PrivacySecurityData.policyTitle,
                  style: TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.permissionsSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TRUST CALLOUT
  // ============================================================

  Widget _buildTrustCallout() {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.permissionsChipFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 14,
              color: AppColors.formAccent,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              PrivacySecurityData.trustNote,
              style: TextStyle(
                color: AppColors.permissionsSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED HELPERS
  // ============================================================

  Widget _iconBox({
    required IconData icon,
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
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
