/// ============================================================
/// ACCOUNT DELETION POLICY — M14 step 4
///
/// Pure logic (no Firebase / Flutter imports): given the time the user asked
/// to delete their account, decide whether it is still in the grace period,
/// how many days are left, and when the delete may run.
///
/// Spark plan has no server job, so "due" only means "the app may now run the
/// delete (step 5) the next time the user opens it".
/// ============================================================
enum DeletionPhase {
  /// No deletion requested.
  none,

  /// Requested; user can still cancel.
  scheduled,

  /// Grace period over; the delete can run.
  due,
}

class DeletionStatus {
  const DeletionStatus({
    required this.phase,
    this.requestedAt,
    this.executeAfter,
    this.daysLeft = 0,
  });

  static const DeletionStatus none = DeletionStatus(phase: DeletionPhase.none);

  final DeletionPhase phase;
  final DateTime? requestedAt;

  /// Earliest time the delete may run.
  final DateTime? executeAfter;

  /// Whole days remaining, rounded up (6 days 1 hour left -> 7). 0 when due.
  final int daysLeft;

  bool get isPending => phase != DeletionPhase.none;
}

class AccountDeletionPolicy {
  AccountDeletionPolicy._();

  /// Days between the request and the earliest delete.
  static const int graceDays = 7;

  /// Firebase Auth only lets an account be deleted shortly after a fresh
  /// sign-in (about 5 minutes). Use a shorter window so there is margin.
  static const Duration recentLoginWindow = Duration(minutes: 3);

  /// True when [lastSignIn] is recent enough to delete the Auth account.
  static bool isRecentLogin(DateTime? lastSignIn, DateTime now) {
    if (lastSignIn == null) return false;
    final age = now.difference(lastSignIn);
    // A negative age (clock skew) counts as recent.
    return age <= recentLoginWindow;
  }

  static DeletionStatus evaluate(DateTime? requestedAt, DateTime now) {
    if (requestedAt == null) return DeletionStatus.none;

    final executeAfter = requestedAt.add(const Duration(days: graceDays));
    final remaining = executeAfter.difference(now);

    if (remaining <= Duration.zero) {
      return DeletionStatus(
        phase: DeletionPhase.due,
        requestedAt: requestedAt,
        executeAfter: executeAfter,
      );
    }

    // Round up to whole days so "23 hours left" reads as 1 day, never 0.
    final days = (remaining.inMinutes / Duration.minutesPerDay).ceil();
    return DeletionStatus(
      phase: DeletionPhase.scheduled,
      requestedAt: requestedAt,
      executeAfter: executeAfter,
      daysLeft: days,
    );
  }
}
