/// ============================================================
/// FIREBASE SUBSCRIPTION REPOSITORY — M12 RevenueCat Integration
/// ============================================================
///
/// Implements SubscriptionRepository using:
///   - Firestore reads for subscription state (customers/{uid})
///   - RevenueCat SDK for purchases/restores
///
/// Spark-compatible: client-side only, no Cloud Functions.
/// RevenueCat handles server-side sync via webhooks.
/// ============================================================

library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/subscription/subscription_repository.dart';
import '../core/subscription/subscription_service.dart';

class FirebaseSubscriptionRepository implements SubscriptionRepository {
  // Singleton
  static final FirebaseSubscriptionRepository instance =
      FirebaseSubscriptionRepository._();
  FirebaseSubscriptionRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Get current subscription info for a user.
  /// Reads from Firestore customers/{uid} collection.
  @override
  Future<SubscriptionInfo?> getSubscription(String uid) async {
    try {
      final doc = await _firestore.collection('customers').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return SubscriptionInfo(
        uid: uid,
        plan: SubscriptionPlanX.fromString(data['activePlan'] as String?),
        status: SubscriptionStatusX.fromString(data['status'] as String?),
        startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
        expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
        renewalEnabled: data['renewalEnabled'] as bool? ?? false,
        revenueCatId: data['revenueCatId'] as String?,
      );
    } catch (e) {
      debugPrint('FirebaseSubscriptionRepository: getSubscription failed: $e');
      return null;
    }
  }

  /// Watch subscription state in realtime.
  /// Streams from Firestore customers/{uid} collection.
  @override
  Stream<SubscriptionInfo?> watchSubscription(String uid) {
    return _firestore
        .collection('customers')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return SubscriptionInfo(
        uid: uid,
        plan: SubscriptionPlanX.fromString(data['activePlan'] as String?),
        status: SubscriptionStatusX.fromString(data['status'] as String?),
        startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
        expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
        renewalEnabled: data['renewalEnabled'] as bool? ?? false,
        revenueCatId: data['revenueCatId'] as String?,
      );
    });
  }

  /// Subscribe to a plan (initiates purchase flow via RevenueCat).
  @override
  Future<void> subscribe({required String uid, required SubscriptionPlan plan}) async {
    try {
      // Get offerings from RevenueCat
      final offerings = await SubscriptionService.instance.getOfferings();
      final package = _findPackageForPlan(offerings, plan);
      if (package == null) {
        throw Exception('Package not found for plan: $plan');
      }

      // Initiate purchase flow via RevenueCat
      await SubscriptionService.instance.purchasePackage(package);

      // RevenueCat webhook will sync to Firestore automatically
      debugPrint('M12: Purchase initiated for $plan');
    } catch (e) {
      debugPrint('M12: subscribe failed: $e');
      rethrow;
    }
  }

  /// Cancel active subscription.
  /// Subscription remains active until expiresAt.
  @override
  Future<void> cancelSubscription(String uid) async {
    try {
      // RevenueCat doesn't support direct cancellation from SDK
      // User must cancel via App Store/Play Store
      // We can only update local state
      await _firestore.collection('customers').doc(uid).update({
        'renewalEnabled': false,
        'status': 'canceled',
      });
    } catch (e) {
      debugPrint('M12: cancelSubscription failed: $e');
      rethrow;
    }
  }

  /// Restore previous purchases (e.g., after app reinstall).
  @override
  Future<SubscriptionInfo?> restorePurchases(String uid) async {
    try {
      await SubscriptionService.instance.restorePurchases();
      // RevenueCat webhook will sync to Firestore
      // Return updated subscription from Firestore
      return await getSubscription(uid);
    } catch (e) {
      debugPrint('M12: restorePurchases failed: $e');
      return null;
    }
  }

  /// Check if user has premium access right now.
  @override
  Future<bool> hasPremiumAccess(String uid) async {
    try {
      final sub = await getSubscription(uid);
      return sub?.hasPremiumAccess ?? false;
    } catch (e) {
      debugPrint('M12: hasPremiumAccess failed: $e');
      return false;
    }
  }

  /// Helper: find the RevenueCat package for a given plan.
  Package? _findPackageForPlan(Offerings offerings, SubscriptionPlan plan) {
    final currentOffering = offerings.current;
    if (currentOffering == null) return null;

    switch (plan) {
      case SubscriptionPlan.free:
        return null; // Free plan doesn't need purchase
      case SubscriptionPlan.monthlyPremium:
        return currentOffering.monthly;
      case SubscriptionPlan.annualPremium:
        return currentOffering.annual;
      case SubscriptionPlan.familyPlan:
        // Family plan might be a custom package
        return currentOffering.availablePackages.firstWhere(
          (p) => p.identifier.contains('family'),
          orElse: () => currentOffering.availablePackages.first,
        );
    }
  }
}