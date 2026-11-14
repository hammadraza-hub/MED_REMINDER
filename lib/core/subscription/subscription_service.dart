/// ============================================================
/// SUBSCRIPTION SERVICE — M12 RevenueCat Integration
/// ============================================================
///
/// Initializes RevenueCat SDK and provides purchase/restore
/// functionality. Spark-compatible (client-side SDK).
/// ============================================================

library;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Thrown when a purchase-related call is made but RevenueCat is not
/// configured (no real API key supplied). The app keeps working on the
/// free plan; callers should show [message] instead of a raw error.
class SubscriptionUnavailableException implements Exception {
  const SubscriptionUnavailableException();

  String get message => 'Purchases are not available right now.';

  @override
  String toString() => message;
}

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  /// Placeholder shipped as the default so builds without a key still run.
  static const String _placeholderKey = 'your_revenuecat_api_key_here';

  bool _initialized = false;

  /// True only when the SDK was configured with a real API key.
  bool get isConfigured => _initialized;

  /// Initialize RevenueCat SDK.
  /// Call once at app startup, after Firebase init.
  ///
  /// Pass the key with `--dart-define=REVENUECAT_API_KEY=<key>`. If it is
  /// missing or still the placeholder, the SDK is NOT configured and the app
  /// runs on the free plan (purchase methods throw
  /// [SubscriptionUnavailableException]).
  Future<void> initialize() async {
    if (_initialized) return;

    const apiKey = String.fromEnvironment(
      'REVENUECAT_API_KEY',
      defaultValue: _placeholderKey,
    );

    if (apiKey.trim().isEmpty || apiKey == _placeholderKey) {
      debugPrint('M12: REVENUECAT_API_KEY not set — purchases disabled');
      return;
    }

    // Enable debug logs in debug mode
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));

    _initialized = true;
    debugPrint('M12: RevenueCat SDK initialized');
  }

  void _ensureConfigured() {
    if (!_initialized) throw const SubscriptionUnavailableException();
  }

  /// Get current customer info from RevenueCat.
  Future<CustomerInfo> getCustomerInfo() async {
    _ensureConfigured();
    return await Purchases.getCustomerInfo();
  }

  /// Get available offerings (plans).
  Future<Offerings> getOfferings() async {
    _ensureConfigured();
    return await Purchases.getOfferings();
  }

  /// Purchase a package (subscription).
  Future<CustomerInfo> purchasePackage(Package package) async {
    _ensureConfigured();
    return await Purchases.purchasePackage(package);
  }

  /// Restore previous purchases.
  Future<CustomerInfo> restorePurchases() async {
    _ensureConfigured();
    return await Purchases.restorePurchases();
  }

  /// Check if user has premium access.
  bool hasPremiumAccess(CustomerInfo info) {
    return info.entitlements.active.isNotEmpty;
  }

  /// Get current entitlements.
  Map<String, EntitlementInfo> getActiveEntitlements(CustomerInfo info) {
    return info.entitlements.active;
  }
}
