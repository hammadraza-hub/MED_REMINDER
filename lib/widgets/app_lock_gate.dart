import 'package:flutter/material.dart';

import '../core/app_navigator.dart';
import '../core/constants/app_colors.dart';
import '../core/services/app_lock_service.dart';
import '../features/onboarding/splash_screen.dart';
import '../l10n/app_localizations.dart';
import '../repositories/auth_repository.dart';

/// ============================================================
/// APP LOCK GATE — M13 step 6
///
/// Wrap the app with this (MaterialApp.builder). While
/// [AppLockService.locked] is true a full-screen lock screen covers
/// everything, including dialogs and sheets, until the user unlocks with
/// biometrics / device PIN. Otherwise it just shows [child].
/// ============================================================
class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.child, this.service});

  final Widget child;

  /// Defaults to [AppLockService.instance]; injectable for tests.
  final AppLockService? service;

  @override
  Widget build(BuildContext context) {
    final s = service ?? AppLockService.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (s.locked) Positioned.fill(child: AppLockScreen(service: s)),
          ],
        );
      },
    );
  }
}

/// The lock screen itself. Prompts automatically when it appears; the
/// "Unlock" button asks again if the user cancelled.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.service});

  final AppLockService service;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Ask right away, once the first frame is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final reason = AppLocalizations.of(context).appLockReasonUnlock;
    final ok = await widget.service.unlock(reason);
    if (!mounted) return;
    // On success the gate removes this screen; nothing more to do.
    if (!ok) setState(() => _failed = true);
    setState(() => _busy = false);
  }

  Future<void> _signOut() async {
    if (_busy) return;
    try {
      await AuthRepository.instance.signOut();
    } catch (_) {
      // Still leave: the user asked to sign out.
    }
    widget.service.handleAuthChanged(false);
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 72,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.appLockTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.permissionsHeader,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _failed ? l10n.appLockNotVerified : l10n.appLockSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _failed
                            ? AppColors.interactionWarningRed
                            : AppColors.shareSecondaryText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _unlock,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          l10n.appLockUnlock,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandTeal,
                          foregroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _signOut,
                      child: Text(
                        l10n.appLockSignOut,
                        style: const TextStyle(
                          color: AppColors.shareSecondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
