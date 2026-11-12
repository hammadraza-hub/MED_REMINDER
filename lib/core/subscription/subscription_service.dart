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

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  bool _initialized = false;

  /// Initialize RevenueCat SDK.
  /// Call once at app startup, after Firebase init.
  Future<void> initialize() async {
    if (_initialized) return;

    // Enable debug logs in debug mode
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    // Configure with API key from environment
    // For now, use a placeholder key. Replace with actual
    // RevenueCat API key from dashboard.
    const apiKey = String.fromEnvironment(
      'REVENUECAT_API_KEY',
      defaultValue: 'your_revenuecat_api_key_here',
    );

    await Purchases.configure(
      PurchasesConfiguration(apiKey),
    );

    _initialized = true;
    debugPrint('M12: RevenueCat SDK initialized');
  }

  /// Get current customer info from RevenueCat.
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// Get available offerings (plans).
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  /// Purchase a package (subscription).
  Future<CustomerInfo> purchasePackage(Package package) async {
    return await Purchases.purchasePackage(package);
  }

  /// Restore previous purchases.
  Future<CustomerInfo> restorePurchases() async {
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