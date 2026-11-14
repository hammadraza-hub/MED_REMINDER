/// ============================================================
/// APP LOCK POLICY — M13 step 6
///
/// Pure rules for WHEN the biometric app lock asks to unlock:
///
///   - cold start             -> lock (every time the app process starts)
///   - back from background   -> lock only if the app was away for MORE
///                               than [grace] (30 s), so a quick glance at a
///                               notification or another app does not
///                               prompt again
///
/// The lock never applies when the lock is off or nobody is signed in.
/// Notifications and their actions are unaffected (they do not go through
/// the UI). No Flutter / Firebase imports — easy to unit test.
/// ============================================================
class AppLockPolicy {
  AppLockPolicy._();

  /// How long the app may stay in the background before it re-locks.
  static const Duration grace = Duration(seconds: 30);

  static bool lockOnColdStart({
    required bool enabled,
    required bool signedIn,
  }) => enabled && signedIn;

  /// [backgroundedAt] is when the app last went to the background
  /// (null = unknown, treated as "do not lock").
  /// A negative elapsed time (clock moved backwards) locks, to be safe.
  static bool lockOnResume({
    required bool enabled,
    required bool signedIn,
    required DateTime? backgroundedAt,
    required DateTime now,
    Duration gracePeriod = grace,
  }) {
    if (!enabled || !signedIn || backgroundedAt == null) return false;
    final away = now.difference(backgroundedAt);
    if (away.isNegative) return true;
    return away > gracePeriod;
  }
}
