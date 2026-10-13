/// ============================================================
/// UPGRADE (PAYWALL) DATA — backend-ready
///
/// PURPOSE:
/// Free user ko Pro mein convert karne wala paywall screen ka
/// static config — plan ids, unlock feature ids, comparison matrix
/// aur pricing.
///
/// IMPORTANT:
/// Display text yahan nahi rakhte — woh AppLocalizations (ARB) se
/// stable id ke through aata hai, taake language change effect ho.
/// Sirf demo user ka naam (proper noun) constant rakha gaya hai.
///
/// TODO Backend:
/// Pricing aur plan catalog RevenueCat / App Store / Play Billing
/// se aayega. Abhi hardcoded USD demo values hain.
/// ============================================================
library;

class UpgradeData {
  UpgradeData._();

  /// Demo user name (proper noun — localized nahi hota).
  static const String demoUserName = 'Sarah Jenkins';

  /// "What you'll unlock" feature ids (display order).
  static const List<String> unlockIds = [
    'interactions',
    'refills',
    'reports',
    'family',
  ];

  /// Full comparison matrix feature ids (display order).
  static const List<String> comparisonIds = [
    'reminders',
    'interactions',
    'refills',
    'reports',
    'family',
  ];

  /// Plan ids (display order).
  static const List<String> planIds = ['solo', 'family'];

  /// Jis plan par "POPULAR" chip dikhta hai.
  static const String popularPlanId = 'family';

  /// Default selected plan.
  static const String defaultPlanId = 'solo';

  /// Annual pricing (USD). TODO: StoreKit / Play Billing.
  static const Map<String, String> annualPrice = {
    'solo': r'$39.99',
    'family': r'$79.99',
  };

  /// Annual "was" price (strikethrough). TODO: StoreKit / Play Billing.
  static const Map<String, String> annualWasPrice = {
    'solo': r'$83.88',
    'family': r'$155.88',
  };

  /// Monthly pricing (USD). TODO: StoreKit / Play Billing.
  static const Map<String, String> monthlyPrice = {
    'solo': r'$6.99',
    'family': r'$12.99',
  };
}
