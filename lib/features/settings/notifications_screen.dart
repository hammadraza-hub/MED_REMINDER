import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../models/notification_settings.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_toggle_switch.dart';
import 'notifications_data.dart';

/// ============================================================
/// NOTIFICATIONS PREFERENCES SCREEN
///
/// PURPOSE:
/// Reminder / alert behaviour configure karna — dose reminders,
/// refill alerts, caregiver alerts, escalation timing aur
/// quiet hours.
///
/// NAVIGATION:
/// Settings → Notifications row se khulti hai. Detail screen hone
/// ki wajah se shared AppBottomNavigation reuse hoti hai
/// (Settings tab active).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend / Notification:
/// flutter_local_notifications phase mein yahan se actual
/// scheduling preferences persist hongi (per member).
/// ============================================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ============================================================
  // STATE
  // ============================================================

  Map<String, bool> _enabled = {
    for (final option in NotificationsData.alertTypes)
      option.id: option.defaultEnabled,
  };

  int _escalationMinutes = NotificationsData.defaultEscalationMinutes;

  bool _quietHoursEnabled = NotificationsData.defaultQuietHoursEnabled;

  bool _justSaved = false;

  bool _isLoading = true;

  String? _error;

  String? _uid;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _uid = AuthRepository.instance.currentUid;
    _loadSettings();
  }

  /// Loads persisted preferences from `users/{uid}.settings`; falls back to
  /// defaults on first launch or Firestore hiccup.
  Future<void> _loadSettings() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final settings = await SettingsRepository.instance.getSettings(uid);
      if (!mounted) return;
      setState(() {
        _enabled = {
          'dose': settings.doseEnabled,
          'refill': settings.refillEnabled,
          'caregiver': settings.caregiverEnabled,
        };
        _escalationMinutes = settings.escalationMinutes;
        _quietHoursEnabled = settings.quietHoursEnabled;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _savePreferences() async {
    if (_justSaved || _isLoading) return;
    if (_uid == null || _uid!.isEmpty) return;

    setState(() {
      _justSaved = true;
    });

    final settings = NotificationSettings(
      doseEnabled: _enabled['dose'] ?? false,
      refillEnabled: _enabled['refill'] ?? false,
      caregiverEnabled: _enabled['caregiver'] ?? false,
      escalationMinutes: _escalationMinutes,
      quietHoursEnabled: _quietHoursEnabled,
      quietStartHour: 22,
      quietStartMinute: 0,
      quietEndHour: 7,
      quietEndMinute: 0,
      hideMedicineNamesOnLockScreen: false,
    );

    try {
      await SettingsRepository.instance.saveSettings(_uid!, settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Preferences saved')));
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _justSaved = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _justSaved = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.formAccent.withValues(alpha: 0.9),
          ),
        );
    }
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.reportPrimary, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Could not load settings',
                  style: TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                        _buildContextCard(),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Alert Types'),
                        const SizedBox(height: 8),
                        _buildAlertTypesCard(),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Escalation Timing'),
                        const SizedBox(height: 8),
                        _buildEscalationCard(),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Quiet Hours'),
                        const SizedBox(height: 8),
                        _buildQuietHoursCard(),
                        const SizedBox(height: 12),
                        _buildSaveButton(),
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
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 2),
              const Expanded(
                child: Text(
                  'Notifications',
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
  // CONTEXT CARD
  // ============================================================

  Widget _buildContextCard() {
    return Container(
      decoration: _cardDecoration(color: AppColors.permissionsChipFill),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _iconBox(
            icon: Icons.tune_rounded,
            background: AppColors.reportSurfaceContainer,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Controls',
                  style: TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sync reminder habits with your daily rhythm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
  // ALERT TYPES CARD
  // ============================================================

  Widget _buildAlertTypesCard() {
    final options = NotificationsData.alertTypes;

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.reportSurfaceContainer,
                ),
              ),
            _buildAlertRow(options[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertRow(AlertTypeOption option) {
    final isOn = _enabled[option.id] ?? false;

    return Row(
      children: [
        _iconBox(icon: option.icon, background: AppColors.permissionsChipFill),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                style: const TextStyle(
                  color: AppColors.reportPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                option.subtitle,
                style: const TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AppToggleSwitch(
          value: isOn,
          onChanged: (value) {
            setState(() {
              _enabled[option.id] = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // ESCALATION CARD
  // ============================================================

  Widget _buildEscalationCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Re-remind after',
                  style: TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildEscalationDropdown(),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'If a dose is unconfirmed, remind again',
            style: TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationDropdown() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _escalationMinutes,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.reportPrimary,
            size: 18,
          ),
          style: const TextStyle(
            color: AppColors.reportPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: [
            for (final minutes in NotificationsData.escalationMinutes)
              DropdownMenuItem<int>(
                value: minutes,
                child: Text('$minutes minutes'),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _escalationMinutes = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // QUIET HOURS CARD
  // ============================================================

  Widget _buildQuietHoursCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiet Hours',
                  style: TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  NotificationsData.quietHoursRange,
                  style: TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppToggleSwitch(
            value: _quietHoursEnabled,
            onChanged: (value) {
              setState(() {
                _quietHoursEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: _justSaved
              ? AppColors.notificationsSaved
              : AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 4,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _justSaved ? Icons.done_all_rounded : Icons.check_circle_rounded,
              size: 20,
              color: AppColors.surface,
            ),
            const SizedBox(width: 8),
            Text(
              _justSaved ? 'Preferences Saved!' : 'Save Preferences',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHARED HELPERS
  // ============================================================

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.permissionsSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _iconBox({required IconData icon, required Color background}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: AppColors.reportPrimary),
    );
  }

  BoxDecoration _cardDecoration({Color color = AppColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: AppColors.permissionsCardShadow,
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}
