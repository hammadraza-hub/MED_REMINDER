/// ============================================================
/// SUBSCRIPTION DATA — backend-ready
///
/// PURPOSE:
/// Settings → Subscription screen ka current plan info aur
/// manage-plan options.
///
/// Backend: Future mein real store/billing (RevenueCat /
/// App Store / Play Billing) se ye data load hoga — UI same rahega.
/// ============================================================
library;

import 'package:flutter/material.dart';

/// Current subscription plan ka summary.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.status,
    required this.renewalDate,
    required this.billing,
    required this.isPro,
  });

  final String name;

  final String status;

  final String renewalDate;

  final String billing;

  final bool isPro;
}

/// Ek manage-plan row (upgrade / downgrade).
class ManagePlanOption {
  const ManagePlanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlightIcon,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  /// true → green action icon (upgrade), false → teal (neutral/downgrade).
  final bool highlightIcon;
}

class SubscriptionData {
  SubscriptionData._();

  /// Current plan summary.
  static const SubscriptionPlan currentPlan = SubscriptionPlan(
    name: 'Solo Pro',
    status: 'Active subscription',
    renewalDate: '01 Oct 2026',
    billing: r'$6.99 / month',
    isPro: true,
  );

  /// Manage Plan section — screen order.
  static const List<ManagePlanOption> manageOptions = [
    ManagePlanOption(
      icon: Icons.arrow_upward_rounded,
      title: 'Upgrade to Family Pro',
      subtitle: 'Up to 5 profiles',
      highlightIcon: true,
    ),
    ManagePlanOption(
      icon: Icons.arrow_downward_rounded,
      title: 'Downgrade to Free',
      subtitle: 'Basic reminders only',
      highlightIcon: false,
    ),
  ];

  static const String comparePlansLabel = 'Compare Plans';

  static const String footerNote =
      'Subscriptions auto-renew until cancelled in App Store Settings.';
}
