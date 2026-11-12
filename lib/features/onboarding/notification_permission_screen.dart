import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/reminder_scheduler.dart';
import '../../l10n/app_localizations.dart';
import '../auth/signup_screen.dart';

/// Notification permission screen — part of M8 step 5c (onboarding).
///
/// Asks the user to grant:
///   • POST_NOTIFICATIONS — so dose reminders can appear even when the app is closed
///   • SCHEDULE_EXACT_ALARM — so reminders fire at the exact dose time (Android 12+)
///
/// Also includes a battery-optimisation hint for Xiaomi, Oppo and Samsung phones
/// (per M8 spec), since aggressive battery killing can block exact alarms.
///
/// On grant/deny/skip, navigates to SignupScreen so the flow stays within onboarding.
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _isRequesting = false;
  String? _status; // 'granted', 'denied', 'error'

  late final AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    l10n = AppLocalizations.of(context);
  }

  /// Calls ReminderScheduler.instance.requestPermissions() and records the result.
  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
      _status = null;
    });

    try {
      final allowed = await ReminderScheduler.instance.requestPermissions();
      if (!mounted) return;
      setState(() {
        _status = allowed ? 'granted' : 'denied';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
      });
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _continueToSignup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final granted = _status == 'granted';
    final denied = _status == 'denied';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // HEADER
            // =========================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primary,
                      size: 64,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      l10n.permTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      l10n.permSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // =========================================================
                    // PERMISSION CARDS
                    // =========================================================
                    _PermissionCard(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.permCardNotificationsTitle,
                      subtitle: l10n.permCardNotificationsSubtitle,
                    ),
                    const SizedBox(height: 12),
                    _PermissionCard(
                      icon: Icons.schedule_rounded,
                      title: l10n.permCardExactAlarmsTitle,
                      subtitle: l10n.permCardExactAlarmsSubtitle,
                    ),
                    const SizedBox(height: 24),

                    // =========================================================
                    // BATTERY HINT (per M8 spec)
                    // =========================================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.battery_saver_rounded,
                            color: AppColors.brandTeal,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.permBatteryTitle,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.permBatterySubtitle,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // =========================================================
                    // STATUS / RESULT
                    // =========================================================
                    if (_status != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: granted
                              ? AppColors.successBackground
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              granted
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: granted
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                granted
                                    ? l10n.permStatusGranted
                                    : denied
                                    ? l10n.permStatusDenied
                                    : l10n.permStatusError,
                                style: TextStyle(
                                  color: granted
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // =========================================================
                    // PRIMARY BUTTON
                    // =========================================================
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isRequesting
                            ? null
                            : (granted || denied
                                ? _continueToSignup
                                : _requestPermissions),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.primaryDark.withValues(alpha: 0.22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isRequesting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                granted || denied
                                    ? l10n.permBtnContinue
                                    : l10n.permTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // =========================================================
                    // SKIP
                    // =========================================================
                    TextButton(
                      onPressed: _isRequesting ? null : _continueToSignup,
                      child: Text(
                        l10n.permBtnSkip,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single permission explanation card.
class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
