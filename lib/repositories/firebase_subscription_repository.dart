import '../core/subscription/subscription_repository.dart';

/// ============================================================
/// FIREBASE SUBSCRIPTION REPOSITORY — STUB (M1)
/// ============================================================
///
/// ⚠️ NOT IMPLEMENTED IN M1.
///
/// Subscription management requires RevenueCat SDK because:
///   - In-app purchases handled by RevenueCat (iOS + Android)
///   - RevenueCat syncs subscription state to Firestore
///     customers/{uid} collection
///   - Direct Firestore writes blocked by security rules
///     (only RevenueCat Cloud Function can write)
///
/// To fully implement:
///   1. Add `purchases_flutter` (RevenueCat SDK) to pubspec.yaml
///   2. Configure RevenueCat API keys (staging + prod)
///   3. Set up RevenueCat Cloud Function for Firestore sync
///   4. Use RevenueCat SDK for purchase flows
///   5. Use Firestore for read-only subscription state
///
/// All methods throw [UnimplementedError] with clear messaging.
/// ============================================================
class FirebaseSubscriptionRepository implements SubscriptionRepository {
  // Singleton
  static final FirebaseSubscriptionRepository instance =
      FirebaseSubscriptionRepository._();
  FirebaseSubscriptionRepository._();

  static const String _notImplementedMessage =
      'Subscription operations require RevenueCat SDK + Cloud Functions. '
      'Install `purchases_flutter` package, configure API keys, '
      'deploy RevenueCat Cloud Function, then implement these methods. '
      'Subscription integration is scheduled for a later phase.';

  @override
  Future<SubscriptionInfo?> getSubscription(String uid) {
    throw UnimplementedError(
      'getSubscription not implemented. $_notImplementedMessage',
    );
  }

  @override
  Stream<SubscriptionInfo?> watchSubscription(String uid) {
    throw UnimplementedError(
      'watchSubscription not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<void> subscribe({
    required String uid,
    required SubscriptionPlan plan,
  }) {
    throw UnimplementedError(
      'subscribe not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<void> cancelSubscription(String uid) {
    throw UnimplementedError(
      'cancelSubscription not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<SubscriptionInfo?> restorePurchases(String uid) {
    throw UnimplementedError(
      'restorePurchases not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<bool> hasPremiumAccess(String uid) {
    throw UnimplementedError(
      'hasPremiumAccess not implemented. $_notImplementedMessage',
    );
  }
}
