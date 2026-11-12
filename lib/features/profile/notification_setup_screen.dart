import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/reminder_scheduler.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/onboarding_header.dart';
import 'family_setup_screen.dart';

/// Notifications permission — Step 2 of 3 (design flow)
/// Real permission via ReminderScheduler.instance.requestPermissions().
class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() => _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  bool _isRequesting = false;
  bool? _permissionGranted; // null = not asked yet

  // ================= BENEFITS DATA =================
  static const List<(IconData, String)> _benefits = [
    (Icons.alarm_rounded, 'Dose reminders at your scheduled times'),
    (Icons.medical_services_rounded, 'Refill alerts before you run out'),
    (
      Icons.family_restroom_rounded,
      'Caregiver alerts when a family dose is missed',
    ),
    (
      Icons.notifications_active_rounded,
      'Smart escalation after 10 min of no response',
    ),
  ];

  /// Calls ReminderScheduler.instance.requestPermissions() and proceeds
  /// to family setup regardless of grant/deny (user can enable later in Settings).
  Future<void> _allow() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final granted = await ReminderScheduler.instance.requestPermissions();
      if (!mounted) return;
      setState(() {
        _permissionGranted = granted;
        _isRequesting = false;
      });

      // Always proceed to Step 3 (Family); permission can be enabled later.
      if (mounted) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const FamilySetupScreen()));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission setup failed: $e')),
      );
    }
  }

  void _notNow() {
    // Not Now → still proceed to family setup
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FamilySetupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // ================= RESPONSIVE =================
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 700;
    final titleSize = isCompact ? 22.0 : 26.0;
    final subtitleSize = isCompact ? 13.5 : 14.5;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= SHARED HEADER =================
                  OnboardingHeader(
                    step: 2,
                    totalSteps: 3,
                    onBack: () => Navigator.of(context).maybePop(),
                    onSkip: () => _notNow(),
                  ),

                  // ================= SCROLLABLE CONTENT =================
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        children: [
                          // ================= ILLUSTRATION =================
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/notification.png',
                                width: screenHeight * 0.26,
                                height: screenHeight * 0.26,
                                fit: BoxFit.cover,
                                cacheWidth: 600,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: screenHeight * 0.26,
                                  height: screenHeight * 0.26,
                                  color: AppColors.primaryLight,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    size: 64,
                                    color: AppColors.formAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ================= TITLE =================
                          Text(
                            'Stay On Schedule',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Allow notifications so MedRemind alerts you for every dose, refill, and missed medication.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              height: 1.5,
                              color: AppColors.formSubtitle,
                            ),
                          ),
                          SizedBox(height: isCompact ? 14 : 20),

                          // ================= BENEFITS =================
                          for (final (icon, text) in _benefits)
                            _BenefitRow(icon: icon, text: text),
                          SizedBox(height: isCompact ? 10 : 16),

                          // ================= SETTINGS HINT =================
                          const _SettingsHintCard(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ================= ALLOW BUTTON =================
                  CustomButton.classic(
                    label: _permissionGranted == true
                        ? 'Notifications On'
                        : 'Allow Notifications',
                    radius: 16,
                    elevation: 0,
                    onPressed: _isRequesting ? null : _allow,
                  ),

                  // ================= NOT NOW =================
                  TextButton(
                    onPressed: _isRequesting ? null : _notNow,
                    child: const Text(
                      'Not Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.formAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BENEFIT ROW — icon badge + text (compact-aware)
// ============================================================
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).height < 700;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: AppColors.formAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isCompact ? 13.5 : 15,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS HINT CARD — yellow warning
// ============================================================
class _SettingsHintCard extends StatelessWidget {
  const _SettingsHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.hintBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: AppColors.hintAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.warning_amber_rounded,
              size: 22,
              color: AppColors.hintAccent,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Tapping Not Now? Enable anytime in Settings → MedRemind.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.hintText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
