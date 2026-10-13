/// ============================================================
/// NOTIFICATIONS PREFERENCES DATA — backend-ready
///
/// PURPOSE:
/// Settings → Notifications screen ki alert types, escalation
/// options aur quiet-hours defaults ka static config.
///
/// Backend: Future mein yahan se real preferences (per member)
/// load/save hongi — UI structure waisa hi rahega.
/// ============================================================
library;

import 'package:flutter/material.dart';

/// Ek alert type row ka presentation + default config.
class AlertTypeOption {
  const AlertTypeOption({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.defaultEnabled,
  });

  final String id;

  final IconData icon;

  final String title;

  final String subtitle;

  final bool defaultEnabled;
}

class NotificationsData {
  NotificationsData._();

  /// Alert Types section — screen order.
  static const List<AlertTypeOption> alertTypes = [
    AlertTypeOption(
      id: 'dose',
      icon: Icons.notifications_active_rounded,
      title: 'Dose Reminders',
      subtitle: 'Remind me at each dose time',
      defaultEnabled: true,
    ),
    AlertTypeOption(
      id: 'refill',
      icon: Icons.medication_rounded,
      title: 'Refill Alerts',
      subtitle: 'When supply runs low',
      defaultEnabled: true,
    ),
    AlertTypeOption(
      id: 'caregiver',
      icon: Icons.supervised_user_circle_rounded,
      title: 'Caregiver Alerts',
      subtitle: 'Alert family if a dose is missed',
      defaultEnabled: true,
    ),
  ];

  /// Escalation Timing — "Re-remind after" options (minutes).
  static const List<int> escalationMinutes = [5, 10, 15, 30];

  /// Escalation default (matches design: 10 minutes).
  static const int defaultEscalationMinutes = 10;

  /// Quiet hours default state + range label.
  static const bool defaultQuietHoursEnabled = false;

  static const String quietHoursRange = '10:00 PM — 7:00 AM';
}
