/// ============================================================
/// PROFILE REPOSITORY CONTRACT
///
/// UI aur ProfileController directly SharedPreferences,
/// device files, Firestore ya Firebase Storage ko access nahi karenge.
///
/// CURRENT:
/// ProfileRepository → LocalProfileRepository
///
/// FUTURE:
/// ProfileRepository → FirebaseProfileRepository
///
/// Is contract ki wajah se backend migration ke waqt screens,
/// AppAvatar aur profile UI ko rewrite nahi karna padega.
/// ============================================================

class StoredProfile {
  const StoredProfile({
    required this.memberId,
    required this.displayName,
    this.profileImagePath,
  });

  /// Stable profile/member identity.
  ///
  /// Local phase:
  /// e.g. member_sarah
  ///
  /// Firebase phase:
  /// Firestore member document ID.
  final String memberId;

  final String displayName;

  /// Local phase:
  /// Device/app documents file path.
  ///
  /// Firebase phase:
  /// Firebase Storage download URL.
  final String? profileImagePath;

  StoredProfile copyWith({
    String? memberId,
    String? displayName,
    String? profileImagePath,
    bool removeProfileImage = false,
  }) {
    return StoredProfile(
      memberId: memberId ?? this.memberId,
      displayName: displayName ?? this.displayName,
      profileImagePath: removeProfileImage
          ? null
          : profileImagePath ?? this.profileImagePath,
    );
  }
}

/// ============================================================
/// PROFILE REPOSITORY
/// ============================================================
abstract class ProfileRepository {
  /// App start par last selected profile load kare.
  Future<StoredProfile?> loadSelectedProfile();

  /// Selected/current profile metadata persist kare.
  Future<void> saveSelectedProfile(StoredProfile profile);

  /// Gallery/camera ki temporary/source image ko app ke permanent
  /// profile storage mein copy kare aur stored path return kare.
  ///
  /// Firebase implementation later:
  /// Firebase Storage upload karke download URL return karegi.
  Future<String> saveProfileImage({
    required String memberId,
    required String sourcePath,
  });

  /// Current member ki profile image remove kare.
  ///
  /// Local implementation:
  /// Saved device file delete kare.
  ///
  /// Firebase implementation:
  /// Storage file delete + Firestore profileImageUrl clear kare.
  Future<void> removeProfileImage({
    required String memberId,
    String? currentImagePath,
  });

  /// Last selected family-member/profile identity persist kare.
  Future<void> saveSelectedMemberId(String memberId);

  /// App restart par last selected member restore kare.
  Future<String?> loadSelectedMemberId();
}
