import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_repository.dart';

/// ============================================================
/// LOCAL PROFILE REPOSITORY
///
/// Current development storage:
/// - SharedPreferences → profile metadata / selected member
/// - App Documents directory → actual profile image files
///
/// FUTURE:
/// Is class ko FirebaseProfileRepository se replace karna hoga.
/// UI, AppAvatar aur ProfileController ko rewrite nahi karna padega.
/// ============================================================
class LocalProfileRepository implements ProfileRepository {
  const LocalProfileRepository();

  // ============================================================
  // PREFERENCE KEYS
  // ============================================================

  static const String _memberIdKey = 'profile.memberId';
  static const String _displayNameKey = 'profile.displayName';
  static const String _imagePathKey = 'profile.imagePath';
  static const String _selectedMemberIdKey = 'profile.selectedMemberId';

  // ============================================================
  // LOAD SELECTED PROFILE
  // ============================================================

  @override
  Future<StoredProfile?> loadSelectedProfile() async {
    final preferences = await SharedPreferences.getInstance();

    final memberId = preferences.getString(_memberIdKey);
    final displayName = preferences.getString(_displayNameKey);
    var imagePath = preferences.getString(_imagePathKey);

    if (memberId == null ||
        memberId.trim().isEmpty ||
        displayName == null ||
        displayName.trim().isEmpty) {
      return null;
    }

    // Local file delete/missing ho chuki ho to stale path use na karein.
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      final imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        imagePath = null;
        await preferences.remove(_imagePathKey);
      }
    }

    return StoredProfile(
      memberId: memberId,
      displayName: displayName,
      profileImagePath: imagePath,
    );
  }

  // ============================================================
  // SAVE SELECTED PROFILE
  // ============================================================

  @override
  Future<void> saveSelectedProfile(StoredProfile profile) async {
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

    // TODO Backend:
    // FirebaseProfileRepository mein same operation stable memberId ke
    // against Firestore member document update karega.
  }

  // ============================================================
  // SAVE PROFILE IMAGE
  // ============================================================

  @override
  Future<String> saveProfileImage({
    required String memberId,
    required String sourcePath,
  }) async {
    final cleanMemberId = _safeFileName(memberId);

    if (cleanMemberId.isEmpty) {
      throw ArgumentError('memberId cannot be empty.');
    }

    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Selected profile image does not exist.',
        sourcePath,
      );
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();

    final profileDirectory = Directory(
      p.join(documentsDirectory.path, 'profiles'),
    );

    if (!await profileDirectory.exists()) {
      await profileDirectory.create(recursive: true);
    }

    final extension = _imageExtension(sourcePath);

    // Timestamp prevents Flutter image cache from continuing to show
    // an older file after the user replaces their profile image.
    final fileName =
        '${cleanMemberId}_${DateTime.now().millisecondsSinceEpoch}$extension';

    final destinationPath = p.join(profileDirectory.path, fileName);

    // Purani locally stored image files clean kar dein.
    await _deleteOldMemberImages(
      directory: profileDirectory,
      memberId: cleanMemberId,
    );

    final copiedFile = await sourceFile.copy(destinationPath);

    // TODO Backend / Firebase Storage:
    // FirebaseProfileRepository mein sourcePath ki image upload hogi,
    // Storage download URL return hoga aur Firestore profileImageUrl
    // update hoga.

    return copiedFile.path;
  }

  // ============================================================
  // REMOVE PROFILE IMAGE
  // ============================================================

  @override
  Future<void> removeProfileImage({
    required String memberId,
    String? currentImagePath,
  }) async {
    if (currentImagePath != null && currentImagePath.trim().isNotEmpty) {
      final currentFile = File(currentImagePath);

      if (await currentFile.exists()) {
        await currentFile.delete();
      }
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();

    final profileDirectory = Directory(
      p.join(documentsDirectory.path, 'profiles'),
    );

    if (await profileDirectory.exists()) {
      await _deleteOldMemberImages(
        directory: profileDirectory,
        memberId: _safeFileName(memberId),
      );
    }

    final preferences = await SharedPreferences.getInstance();

    final savedMemberId = preferences.getString(_memberIdKey);

    if (savedMemberId == memberId) {
      await preferences.remove(_imagePathKey);
    }

    // TODO Backend / Firebase Storage:
    // Firebase version:
    // - Storage image delete
    // - Firestore profileImageUrl clear
    // - selected profile stream automatically refresh
  }

  // ============================================================
  // SELECTED MEMBER
  // ============================================================

  @override
  Future<void> saveSelectedMemberId(String memberId) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_selectedMemberIdKey, memberId);
  }

  @override
  Future<String?> loadSelectedMemberId() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_selectedMemberIdKey);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _safeFileName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .toLowerCase();
  }

  String _imageExtension(String path) {
    final extension = p.extension(path).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
        return extension;

      default:
        return '.jpg';
    }
  }

  Future<void> _deleteOldMemberImages({
    required Directory directory,
    required String memberId,
  }) async {
    if (memberId.isEmpty || !await directory.exists()) {
      return;
    }

    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }

      final fileName = p.basename(entity.path);

      if (fileName.startsWith('${memberId}_')) {
        try {
          await entity.delete();
        } on FileSystemException {
          // Cleanup failure ko profile image save flow fail nahi karna chahiye.
        }
      }
    }
  }
}
