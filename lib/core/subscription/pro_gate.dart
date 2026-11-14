/// ============================================================
/// PRO GATE — M16 step 7
///
/// The app-side half of the Solo Pro gate for prescribers, appointments and
/// doctor notes (and health sync). The REAL gate is in firestore.rules, which
/// reads the profile OWNER's customers/{ownerUid} record; this class only
/// decides whether to show the upgrade dialog before a pointless write.
///
/// Pure Dart: everything it needs is injected, so it is unit-testable.
///
/// Rules of thumb:
/// * Not signed in, or the check fails  -> NOT Pro (fail closed).
/// * The profile belongs to someone else (a caregiver is looking at it) ->
///   we cannot read their plan (customers/{uid} is private), so we let the
///   write go ahead and the rules decide. A "permission denied" is then shown
///   as the same upgrade dialog by the screens.
/// ============================================================
class ProGate {
  ProGate({
    required this.currentUid,
    required this.hasPremiumAccess,
    required this.profileOwnerUid,
    this.debugUnlock = false,
  });

  /// Signed-in user's uid, or null.
  final String? Function() currentUid;

  /// Does this user have an active subscription right now?
  final Future<bool> Function(String uid) hasPremiumAccess;

  /// Owner of the given profile (null when unknown).
  final Future<String?> Function(String profileId) profileOwnerUid;

  /// Debug builds only; the caller passes `kDebugMode && <dart-define>`.
  final bool debugUnlock;

  /// True when the screen may let the user write to [profileId].
  Future<bool> canWrite(String profileId) async {
    if (debugUnlock) return true;

    final uid = currentUid();
    if (uid == null) return false;

    String? owner;
    try {
      owner = await profileOwnerUid(profileId);
    } catch (_) {
      owner = null;
    }
    // Someone else's profile: their plan decides, on the server.
    if (owner != null && owner != uid) return true;

    try {
      return await hasPremiumAccess(uid);
    } catch (_) {
      return false; // fail closed
    }
  }

  /// "Is my own plan Pro?" (health sync, which is always the user's own data).
  Future<bool> isPro() async {
    if (debugUnlock) return true;
    final uid = currentUid();
    if (uid == null) return false;
    try {
      return await hasPremiumAccess(uid);
    } catch (_) {
      return false;
    }
  }
}
