import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_exception.dart';
import '../core/profile/profile_repository.dart';

/// ============================================================
/// FIREBASE PROFILE REPOSITORY
/// ============================================================
///
/// Implements the same [ProfileRepository] interface as
/// [LocalProfileRepository], so UI can swap between them
/// without code changes.
///
/// Architecture decisions:
///
///   1. **Selected profile (memberId, displayName)**:
///      Still stored in SharedPreferences for fast app launch
///      (device-local UI state). Additionally synced to
///      Firestore `users/{uid}` when user is signed in
///      (for cross-device sync).
///
///   2. **Profile images**: NOT YET IMPLEMENTED.
///      Methods throw [UnimplementedError] because:
///        - `firebase_storage` package not in M1 dependencies
///        - Cloud Storage bucket not provisioned (Spark plan)
///        - `storage.rules` are deny-all
///      Will be implemented in a future phase when:
///        - Blaze plan is enabled
///        - `firebase_storage` package is added
///        - Storage bucket is created
///        - `storage.rules` allow user-scoped writes
///
/// All methods throw [AppException] on failure — never raw
/// Firebase exceptions.
/// ============================================================
class FirebaseProfileRepository implements ProfileRepository {
  // Singleton — single source of truth across the app.
  static final FirebaseProfileRepository instance =
      FirebaseProfileRepository._();
  FirebaseProfileRepository._();

  // ───────────────────────────────────────────────────────────
  // PREFERENCE KEYS
  // (Same as LocalProfileRepository for cross-compatibility)
  // ───────────────────────────────────────────────────────────

  static const String _memberIdKey = 'profile.memberId';
  static const String _displayNameKey = 'profile.displayName';
  static const String _imagePathKey = 'profile.imagePath';
  static const String _selectedMemberIdKey = 'profile.selectedMemberId';

  // ───────────────────────────────────────────────────────────
  // Firebase instances (lazy accessors)
  // ───────────────────────────────────────────────────────────

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // ============================================================
  // LOAD SELECTED PROFILE
  // ============================================================

  @override
  Future<StoredProfile?> loadSelectedProfile() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final memberId = preferences.getString(_memberIdKey);
      final displayName = preferences.getString(_displayNameKey);
      final imagePath = preferences.getString(_imagePathKey);

      if (memberId == null ||
          memberId.trim().isEmpty ||
          displayName == null ||
          displayName.trim().isEmpty) {
        return null;
      }

      return StoredProfile(
        memberId: memberId,
        displayName: displayName,
        profileImagePath: imagePath,
      );
    } catch (e) {
      throw AppException.unknown(
        'Failed to load selected profile: $e',
        originalError: e,
      );
    }
  }

  // ============================================================
  // SAVE SELECTED PROFILE
  // ============================================================

  @override
  Future<void> saveSelectedProfile(StoredProfile profile) async {
    try {
      // 1. Save to SharedPreferences (device-local UI state)
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(_memberIdKey, profile.memberId);
      await preferences.setString(_displayNameKey, profile.displayName);
      await preferences.setString(_selectedMemberIdKey, profile.memberId);

      final imagePath = profile.profileImagePath?.trim();
      if (imagePath == null || imagePath.isEmpty) {
        await preferences.remove(_imagePathKey);
      } else {
        await preferences.setString(_imagePathKey, imagePath);
      }

      // 2. Sync to Firestore users/{uid} (cross-device, optional)
      // Only sync if user is signed in.
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'selectedMemberId': profile.memberId,
          'selectedDisplayName': profile.displayName,
          'selectedProfileImageUrl': profile.profileImagePath,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(
        'Failed to save selected profile: $e',
        originalError: e,
      );
    }
  }

  // ============================================================
  // SAVE PROFILE IMAGE — NOT YET IMPLEMENTED
  // ============================================================
  //
  // ⚠️ M1 LIMITATION:
  // Image upload requires:
  //   1. `firebase_storage` package in pubspec.yaml
  //   2. Cloud Storage bucket provisioned (Blaze plan)
  //   3. `storage.rules` updated for user-scoped writes
  //
  // Until then, app should use [LocalProfileRepository] for
  // image operations, OR throw UnimplementedError here.

  @override
  Future<String> saveProfileImage({
    required String memberId,
    required String sourcePath,
  }) {
    throw UnimplementedError(
      'FirebaseProfileRepository.saveProfileImage() is not implemented yet. '
      'Image upload requires firebase_storage package + Cloud Storage bucket '
      '(Blaze plan required). For M1, use LocalProfileRepository for image '
      'operations.',
    );
  }

  // ============================================================
  // REMOVE PROFILE IMAGE — NOT YET IMPLEMENTED
  // ============================================================

  @override
  Future<void> removeProfileImage({
    required String memberId,
    String? currentImagePath,
  }) {
    throw UnimplementedError(
      'FirebaseProfileRepository.removeProfileImage() is not implemented yet. '
      'Image deletion requires firebase_storage package + Cloud Storage bucket '
      '(Blaze plan required). For M1, use LocalProfileRepository for image '
      'operations.',
    );
  }

  // ============================================================
  // SELECTED MEMBER — saveSelectedMemberId
  // ============================================================

  @override
  Future<void> saveSelectedMemberId(String memberId) async {
    try {
      // 1. Save to SharedPreferences (device-local)
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_selectedMemberIdKey, memberId);

      // 2. Sync to Firestore users/{uid}.selectedMemberId
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'selectedMemberId': memberId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(
        'Failed to save selected member ID: $e',
        originalError: e,
      );
    }
  }

  // ============================================================
  // SELECTED MEMBER — loadSelectedMemberId
  // ============================================================

  @override
  Future<String?> loadSelectedMemberId() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(_selectedMemberIdKey);
    } catch (e) {
      throw AppException.unknown(
        'Failed to load selected member ID: $e',
        originalError: e,
      );
    }
  }
}
