import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/account_deletion_service.dart';
import '../../core/services/account_purge_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../onboarding/splash_screen.dart';

/// ============================================================
/// ACCOUNT PURGE SCREEN — M14 step 5
///
/// Shown right after sign-in when the 7-day grace period of a deletion request
/// is over. Runs [AccountPurgeService], then returns to the start screen.
/// Spark plan has no server, so the delete can only run while the app is open.
///
/// States: running -> done (signed out, splash) | needs fresh login | failed
/// (retry). The user can always cancel the deletion instead.
/// ============================================================
class AccountPurgeScreen extends StatefulWidget {
  const AccountPurgeScreen({super.key});

  @override
  State<AccountPurgeScreen> createState() => _AccountPurgeScreenState();
}

enum _View { running, needsLogin, failed }

class _AccountPurgeScreenState extends State<AccountPurgeScreen> {
  _View _view = _View.running;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _view = _View.running);
    final outcome = await AccountPurgeService.instance.run(
      onProgress: (s) => debugPrint('Purge: $s'),
    );
    if (!mounted) return;

    switch (outcome) {
      case PurgeOutcome.done:
        _goToStart();
      case PurgeOutcome.notDue:
        // Cancelled elsewhere or clock changed: just open the app.
        _goToApp();
      case PurgeOutcome.needsRecentLogin:
        setState(() => _view = _View.needsLogin);
      case PurgeOutcome.failed:
        setState(() => _view = _View.failed);
    }
  }

  void _goToStart() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _goToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MedRemindShell()),
      (route) => false,
    );
  }

  Future<void> _loginAgain() async {
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) _goToStart();
  }

  Future<void> _cancelDeletion() async {
    setState(() => _busy = true);
    try {
      await AccountDeletionService.instance.cancel();
      if (mounted) _goToApp();
    } catch (e) {
      debugPrint('Cancel deletion failed: $e');
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).accountDeleteFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_view == _View.running) ...[
                      const CircularProgressIndicator(
                        color: AppColors.formAccent,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.accountPurgeRunning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.permissionsHeader,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.accountPurgeRunningHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.permissionsSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.shield_outlined,
                        size: 48,
                        color: AppColors.permissionsErrorIcon,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _view == _View.needsLogin
                            ? l10n.accountPurgeNeedsLogin
                            : l10n.accountPurgeFailed,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.permissionsHeader,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _button(
                        label: _view == _View.needsLogin
                            ? l10n.accountPurgeLoginButton
                            : l10n.accountPurgeRetry,
                        color: AppColors.permissionsErrorIcon,
                        textColor: AppColors.surface,
                        onTap: _view == _View.needsLogin ? _loginAgain : _run,
                      ),
                      const SizedBox(height: 10),
                      _button(
                        label: l10n.accountDeleteCancel,
                        color: AppColors.permissionsChipFill,
                        textColor: AppColors.permissionsHeader,
                        onTap: _cancelDeletion,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _busy ? null : onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
