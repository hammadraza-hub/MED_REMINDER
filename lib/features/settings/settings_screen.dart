import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_avatar.dart';
import 'about_screen.dart';
import 'accessibility_screen.dart';
import 'account_screen.dart';
import 'data_export_screen.dart';
import 'help_support_screen.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'settings_data.dart';
import 'subscription_screen.dart';

// ============================================================
// LOCALIZATION HELPERS
//
// settings_data mein sirf stable IDs rehte hain; actual display
// text yahan AppLocalizations se resolve hota hai.
// ============================================================

String _groupLabel(AppLocalizations l10n, String id) {
  return switch (id) {
    'preferences' => l10n.settingsGroupPreferences,
    'accountPlan' => l10n.settingsGroupAccountPlan,
    _ => l10n.settingsGroupSupportLegal,
  };
}

String _itemTitle(AppLocalizations l10n, String id) {
  return switch (id) {
    'notifications' => l10n.settingsNotifications,
    'language' => l10n.settingsLanguage,
    'accessibility' => l10n.settingsAccessibility,
    'privacySecurity' => l10n.settingsPrivacySecurity,
    'subscription' => l10n.settingsSubscription,
    'dataExport' => l10n.settingsDataExport,
    'helpSupport' => l10n.settingsHelpSupport,
    _ => l10n.settingsAbout,
  };
}

String _trailingText(AppLocalizations l10n, String? trailingId) {
  return switch (trailingId) {
    'settingsNotificationsTrailing' => l10n.settingsNotificationsTrailing,
    'settingsLanguageTrailing' => l10n.settingsLanguageTrailing,
    'settingsDataExportTrailing' => l10n.settingsDataExportTrailing,
    'settingsAboutTrailing' => l10n.settingsAboutTrailing,
    _ => '',
  };
}

/// ============================================================
/// SETTINGS — main account/settings tab
///
/// PURPOSE:
/// Account-level info aur app preferences ko manage karna
/// (profile summary, preferences, plan, support, log out).
///
/// NAVIGATION:
/// Yeh med_remind_shell ka Settings tab (index 4) hai — isliye
/// apni bottom navigation ya back button NAHI.
///
/// ACTIONS (abhi placeholder — sub-screens pending):
/// • Profile card          → profile screen (pending)
/// • Har settings row      → uski detail screen (pending)
/// • Log Out               → confirmation (auth backend pending)
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
/// Action buttons standard green (formAccent) — app convention.
/// ============================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            l10n.settingsLogoutTitle,
            style: const TextStyle(
              color: AppColors.permissionsHeader,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            l10n.settingsLogoutMessage,
            style: const TextStyle(color: AppColors.permissionsSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.permissionsSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                l10n.settingsLogOut,
                style: const TextStyle(
                  color: AppColors.permissionsErrorText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      // TODO Auth backend: session clear karke LoginScreen par bhejo.
      _showMessage(context, l10n.settingsLogoutComingSoon);
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
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileSummaryCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AccountScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._buildGroups(context),
                        const SizedBox(height: 8),
                        _LogOutButton(
                          onTap: () => _confirmLogout(context),
                        ),
                        const SizedBox(height: 16),
                        const _AppFooter(),
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

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MedRemind',
                      style: TextStyle(
                        color: AppColors.assistantOnlineText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.settingsTitle,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
  // MENU GROUPS
  // ============================================================

  List<Widget> _buildGroups(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final widgets = <Widget>[];

    for (var i = 0; i < SettingsData.groups.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: 24));
      }

      widgets.add(_SettingsGroupCard(
        group: SettingsData.groups[i],
        onItemTap: (item) {
          final Widget? screen = switch (item.id) {
            'notifications' => const NotificationsScreen(),
            'language' => const LanguageScreen(),
            'subscription' => const SubscriptionScreen(),
            'privacySecurity' => const PrivacySecurityScreen(),
            'accessibility' => const AccessibilityScreen(),
            'dataExport' => const DataExportScreen(),
            'helpSupport' => const HelpSupportScreen(),
            'about' => const AboutScreen(),
            _ => null,
          };

          if (screen != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => screen),
            );
            return;
          }

          _showMessage(context, l10n.comingSoon(_itemTitle(l10n, item.id)));
        },
      ));
    }

    return widgets;
  }
}

/// ============================================================
/// PROFILE SUMMARY CARD
/// ============================================================

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: onTap,
      child: ListenableBuilder(
        listenable: ProfileController.instance,
        builder: (context, child) {
          final name = ProfileController.instance.displayName;
          final email =
              '${name.toLowerCase().replaceAll(RegExp(r'\s+'), '.')}@email.com';

          return Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const AppAvatar(size: 56),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.formAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.permissionsHeader,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.permissionsSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: AppColors.permissionsSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context).settingsCaregiverSync,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.permissionsSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.reportSurfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ============================================================
/// SETTINGS GROUP CARD — label + rows
/// ============================================================

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.group, required this.onItemTap});

  final SettingsGroup group;
  final ValueChanged<SettingsMenuItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            _groupLabel(l10n, group.id).toUpperCase(),
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.permissionsCardShadow,
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.reportChipHigh,
                    ),
                  _SettingsRow(
                    item: group.items[i],
                    onTap: () => onItemTap(group.items[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item, required this.onTap});

  final SettingsMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.highlightIcon
                    ? AppColors.reportVitalsTile
                    : AppColors.permissionsChipFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: AppColors.permissionsHeader,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _itemTitle(l10n, item.id),
                style: const TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (item.trailingId != null) ...[
              Text(
                _trailingText(l10n, item.trailingId),
                style: const TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (item.showProBadge) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.formAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.settingsPro,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.permissionsSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// LOG OUT BUTTON
/// ============================================================

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.permissionsErrorContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.permissionsErrorText,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.settingsLogOut,
                  style: const TextStyle(
                    color: AppColors.permissionsErrorText,
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
}

/// ============================================================
/// FOOTER — build + compliance line
/// ============================================================

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Text(
          l10n.settingsFooterVersion,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.permissionsSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: AppColors.formAccent,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.settingsHipaa,
              style: const TextStyle(
                color: AppColors.permissionsSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ============================================================
/// CARD — tappable white card with shared shadow
/// ============================================================

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
