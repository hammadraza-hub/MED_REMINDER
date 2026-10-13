/// ============================================================
/// SETTINGS DATA — backend-ready
///
/// PURPOSE:
/// Settings screen ke menu groups (Preferences / Account & Plan /
/// Support & Legal) + unke rows ka static config.
///
/// IMPORTANT:
/// Display text (titles/subtitles) yahan nahi rakhte — woh
/// AppLocalizations (ARB) se aata hai localization-key (id/trailingId)
/// ke through. Yeh is liye taake language change poori app par
/// effect ho.
///
/// Backend: Future mein rows ki actual sub-screens aur persisted
/// preferences wire hongi — UI structure waisa hi rahega.
/// ============================================================
library;

import 'package:flutter/material.dart';

/// Ek settings row ka presentation config.
class SettingsMenuItem {
  const SettingsMenuItem({
    required this.id,
    required this.icon,
    this.trailingId,
    this.showProBadge = false,
    this.highlightIcon = false,
  });

  /// Stable localization key — navigation + translation lookup.
  final String id;

  final IconData icon;

  /// Row ke right side ka muted value (e.g. "Chime & Vibrate").
  final String? trailingId;

  /// Subscription row par "PRO" pill.
  final bool showProBadge;

  /// Icon box ka background highlight (e.g. Subscription star).
  final bool highlightIcon;
}

/// Ek labelled settings section.
class SettingsGroup {
  const SettingsGroup({required this.id, required this.items});

  /// Stable localization key — section label lookup.
  final String id;

  final List<SettingsMenuItem> items;
}

class SettingsData {
  SettingsData._();

  /// Settings ke teen menu groups — order = screen order.
  static const List<SettingsGroup> groups = [
    SettingsGroup(
      id: 'preferences',
      items: [
        SettingsMenuItem(
          id: 'notifications',
          icon: Icons.notifications_none_rounded,
          trailingId: 'settingsNotificationsTrailing',
        ),
        SettingsMenuItem(
          id: 'language',
          icon: Icons.language_rounded,
          trailingId: 'settingsLanguageTrailing',
        ),
        SettingsMenuItem(
          id: 'accessibility',
          icon: Icons.accessibility_new_rounded,
        ),
      ],
    ),
    SettingsGroup(
      id: 'accountPlan',
      items: [
        SettingsMenuItem(
          id: 'privacySecurity',
          icon: Icons.shield_outlined,
        ),
        SettingsMenuItem(
          id: 'subscription',
          icon: Icons.star_rounded,
          showProBadge: true,
          highlightIcon: true,
        ),
        SettingsMenuItem(
          id: 'dataExport',
          icon: Icons.download_rounded,
          trailingId: 'settingsDataExportTrailing',
        ),
      ],
    ),
    SettingsGroup(
      id: 'supportLegal',
      items: [
        SettingsMenuItem(
          id: 'helpSupport',
          icon: Icons.help_outline_rounded,
        ),
        SettingsMenuItem(
          id: 'about',
          icon: Icons.info_outline_rounded,
          trailingId: 'settingsAboutTrailing',
        ),
      ],
    ),
  ];
}