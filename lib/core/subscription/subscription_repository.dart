/// ============================================================
/// SUBSCRIPTION DOMAIN MODELS
/// ============================================================
///
/// Subscription management uses RevenueCat (third-party SDK).
/// RevenueCat syncs data to Firestore customers/{uid} collection.
///
/// M0 Schema:
///   customers/{uid}
///     - activePlan: string
///     - status: string (active | canceled | expired | trial)
///     - startedAt: timestamp
///     - expiresAt: timestamp | null
///     - renewalEnabled: boolean
/// ============================================================

/// Subscription plan types.
enum SubscriptionPlan {
  /// Free tier — limited features.
  free,

  /// Monthly premium subscription.
  monthlyPremium,

  /// Annual premium subscription (best value).
  annualPremium,

  /// Family plan — covers multiple members.
  familyPlan,
}

extension SubscriptionPlanX on SubscriptionPlan {
  String get name {
    switch (this) {
      case SubscriptionPlan.free:
        return 'free';
      case SubscriptionPlan.monthlyPremium:
        return 'monthly_premium';
      case SubscriptionPlan.annualPremium:
        return 'annual_premium';
      case SubscriptionPlan.familyPlan:
        return 'family_plan';
    }
  }

  static SubscriptionPlan fromString(String? value) {
    switch (value) {
      case 'monthly_premium':
        return SubscriptionPlan.monthlyPremium;
      case 'annual_premium':
        return SubscriptionPlan.annualPremium;
      case 'family_plan':
        return SubscriptionPlan.familyPlan;
      case 'free':
      default:
        return SubscriptionPlan.free;
    }
  }
}

/// Status of a subscription.
enum SubscriptionStatus {
  /// Active and paid up.
  active,

  /// In free trial period.
  trial,

  /// Canceled by user, but still active until expiry.
  canceled,

  /// Expired — no longer has access to premium features.
  expired,

  /// In grace period (payment issue being resolved).
  gracePeriod,
}

extension SubscriptionStatusX on SubscriptionStatus {
  String get name {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.trial:
        return 'trial';
      case SubscriptionStatus.canceled:
        return 'canceled';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.gracePeriod:
        return 'grace_period';
    }
  }

  static SubscriptionStatus fromString(String? value) {
    switch (value) {
      case 'trial':
        return SubscriptionStatus.trial;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'grace_period':
        return SubscriptionStatus.gracePeriod;
      case 'active':
      default:
        return SubscriptionStatus.active;
    }
  }
}

/// Current subscription state of a user.
class SubscriptionInfo {
  const SubscriptionInfo({
    required this.uid,
    required this.plan,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.renewalEnabled = false,
    this.revenueCatId,
  });

  final String uid;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool renewalEnabled;
  final String? revenueCatId;

  /// Whether user has premium access right now.
  bool get hasPremiumAccess {
    return status == SubscriptionStatus.active ||
        status == SubscriptionStatus.trial ||
        status == SubscriptionStatus.gracePeriod;
  }

  /// Whether subscription will renew automatically.
  bool get willRenew => renewalEnabled && status == SubscriptionStatus.active;
}

/// ============================================================
/// SUBSCRIPTION REPOSITORY CONTRACT
/// ============================================================
///
/// Uses RevenueCat SDK for purchases + Firestore for state sync.
/// All methods require RevenueCat SDK to be installed and configured.
/// ============================================================
abstract class SubscriptionRepository {
  /// Get current subscription info for a user.
  Future<SubscriptionInfo?> getSubscription(String uid);

  /// Watch subscription state in realtime.
  Stream<SubscriptionInfo?> watchSubscription(String uid);

  /// Subscribe to a plan (initiates purchase flow via RevenueCat).
  Future<void> subscribe({required String uid, required SubscriptionPlan plan});

  /// Cancel active subscription.
  /// Subscription remains active until expiresAt.
  Future<void> cancelSubscription(String uid);

  /// Restore previous purchases (e.g., after app reinstall).
  Future<SubscriptionInfo?> restorePurchases(String uid);

  /// Check if user has premium access right now.
  Future<bool> hasPremiumAccess(String uid);
}
