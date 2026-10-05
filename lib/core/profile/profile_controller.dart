import 'package:flutter/foundation.dart';

import 'local_profile_repository.dart';
import 'profile_repository.dart';

/// ============================================================
/// PROFILE CONTROLLER
///
/// App-wide selected user / family-member profile state.
///
/// UI ko storage implementation ka pata nahi:
///
/// Screens / AppAvatar
///        ↓
/// ProfileController
///        ↓
/// ProfileRepository
///        ↓
/// LocalProfileRepository        ← NOW
/// FirebaseProfileRepository     ← LATER
///
/// IMPORTANT:
/// Display name permanent identity nahi hai.
/// Stable memberId use hoga.
/// ============================================================
class ProfileController extends ChangeNotifier {
  ProfileController._({ProfileRepository? repository})
    : _repository = repository ?? const LocalProfileRepository();

  static final ProfileController instance = ProfileController._();

  final ProfileRepository _repository;

  // ============================================================
  // CURRENT PROFILE STATE
  // ============================================================

  String? _memberId;
  String _displayName = 'Sarah';
  String? _profileImagePath;

  bool _isInitialized = false;
  bool _isLoading = false;

  String? get memberId => _memberId;

  String get displayName => _displayName;

  /// Local file path now.
  ///
  /// Firebase phase:
  /// Firebase Storage download URL.
  String? get profileImagePath => _profileImagePath;

  bool get isInitialized => _isInitialized;

  bool get isLoading => _isLoading;

  // ============================================================
  // INITIALIZE
  //
  // App startup par locally persisted selected member ID aur
  // selected profile metadata restore hote hain.
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final selectedMemberId = await _repository.loadSelectedMemberId();
      final storedProfile = await _repository.loadSelectedProfile();

      // Stable selected member ID ko dedicated preference se restore
      // karna priority hai.
      //
      // Home Members SQLite record load hone ke baad name/image ko
      // exact member record ke saath sync karega.
      final cleanSelectedMemberId = selectedMemberId?.trim();

      if (cleanSelectedMemberId != null && cleanSelectedMemberId.isNotEmpty) {
        _memberId = cleanSelectedMemberId;
      }

      if (storedProfile != null) {
        // Agar dedicated selection unavailable ho to stored profile ID
        // fallback ke taur par use ho sakti hai.
        _memberId ??= storedProfile.memberId;

        // Profile metadata sirf tab apply karo jab woh currently
        // restored selected member se belong karti ho.
        if (_memberId == storedProfile.memberId) {
          _displayName = storedProfile.displayName;
          _profileImagePath = storedProfile.profileImagePath;
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Profile initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Local profile load fail hone par app fallback profile ke
      // saath usable rehni chahiye.
    } finally {
      _isLoading = false;
      _isInitialized = true;

      notifyListeners();
    }

    // TODO Backend:
    // Firebase phase mein initialization:
    // 1. Firebase Auth current account resolve karega.
    // 2. Last selected memberId restore hoga.
    // 3. Firestore member profile stream subscribe hogi.
    // 4. profileImageUrl Firebase Storage URL se aayega.
  }

  // ============================================================
  // SELECT PROFILE
  // ============================================================

  Future<void> selectProfile({
    String? memberId,
    required String displayName,
    String? profileImagePath,
  }) async {
    final cleanName = displayName.trim();

    if (cleanName.isEmpty) {
      return;
    }

    final resolvedMemberId = _resolveMemberId(
      suppliedMemberId: memberId,
      displayName: cleanName,
    );

    final normalizedImagePath = _normalizePath(profileImagePath);

    final changed =
        _memberId != resolvedMemberId ||
        _displayName != cleanName ||
        _profileImagePath != normalizedImagePath;

    if (!changed) {
      // State same hone ke bawajood selected member preference ensure
      // karte hain. Isse older/local preference states self-heal hongi.
      await _repository.saveSelectedMemberId(resolvedMemberId);
      return;
    }

    _memberId = resolvedMemberId;
    _displayName = cleanName;
    _profileImagePath = normalizedImagePath;

    notifyListeners();

    await _persistCurrentProfile();

    // TODO Backend:
    // Firebase phase mein repository selected memberId persist karegi
    // aur Firestore se us member ka current profile load karegi.
  }

  // ============================================================
  // SAVE NEW PROFILE IMAGE
  // ============================================================

  Future<void> saveProfileImage(String sourcePath) async {
    final currentMemberId = _memberId;

    if (currentMemberId == null || currentMemberId.isEmpty) {
      throw StateError(
        'Profile image cannot be saved before a member is selected.',
      );
    }

    final storedPath = await _repository.saveProfileImage(
      memberId: currentMemberId,
      sourcePath: sourcePath,
    );

    _profileImagePath = storedPath;

    notifyListeners();

    await _persistCurrentProfile();

    // TODO Backend / Firebase Storage:
    // FirebaseProfileRepository saveProfileImage():
    // - selected image upload karegi
    // - download URL return karegi
    // - Firestore profileImageUrl update karegi
    //
    // Controller/UI contract same rahega.
  }

  // ============================================================
  // UPDATE PROFILE IMAGE VALUE
  // ============================================================

  Future<void> updateProfileImage(String? imagePath) async {
    final normalizedPath = _normalizePath(imagePath);

    if (_profileImagePath == normalizedPath) {
      return;
    }

    _profileImagePath = normalizedPath;

    notifyListeners();

    await _persistCurrentProfile();
  }

  // ============================================================
  // PROFILE NAME UPDATE
  // ============================================================

  Future<void> updateDisplayName(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty || cleanName == _displayName) {
      return;
    }

    _displayName = cleanName;

    notifyListeners();

    await _persistCurrentProfile();

    // TODO Backend:
    // FirebaseProfileRepository stable memberId ke against
    // Firestore displayName update karegi.
  }

  // ============================================================
  // REMOVE PROFILE IMAGE
  // ============================================================

  Future<void> removeProfileImage() async {
    final currentMemberId = _memberId;

    if (currentMemberId == null || currentMemberId.isEmpty) {
      return;
    }

    final oldImagePath = _profileImagePath;

    if (oldImagePath == null) {
      return;
    }

    await _repository.removeProfileImage(
      memberId: currentMemberId,
      currentImagePath: oldImagePath,
    );

    _profileImagePath = null;

    notifyListeners();

    await _persistCurrentProfile();

    // TODO Backend / Firebase Storage:
    // Firebase repository Storage file delete + Firestore
    // profileImageUrl clear karegi.
  }

  // ============================================================
  // BACKEND / REPOSITORY SYNC
  // ============================================================

  Future<void> syncFromBackend({
    required String memberId,
    required String displayName,
    String? profileImageUrl,
  }) async {
    _memberId = memberId;
    _displayName = displayName.trim();
    _profileImagePath = _normalizePath(profileImageUrl);

    notifyListeners();

    await _persistCurrentProfile();

    // TODO Backend:
    // Firestore profile stream future mein is method/controller
    // state ko repository result ke through update karegi.
  }

  // ============================================================
  // PERSISTENCE
  // ============================================================

  Future<void> _persistCurrentProfile() async {
    final currentMemberId = _memberId;

    if (currentMemberId == null || currentMemberId.isEmpty) {
      return;
    }

    final profile = StoredProfile(
      memberId: currentMemberId,
      displayName: _displayName,
      profileImagePath: _profileImagePath,
    );

    await _repository.saveSelectedProfile(profile);
    await _repository.saveSelectedMemberId(currentMemberId);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _resolveMemberId({
    required String? suppliedMemberId,
    required String displayName,
  }) {
    final cleanId = suppliedMemberId?.trim();

    if (cleanId != null && cleanId.isNotEmpty) {
      return cleanId;
    }

    // Temporary frontend-only ID.
    //
    // TODO Backend:
    // Firebase phase mein FamilyMember ke actual Firestore document ID
    // ko pass karna hai. Display name se ID generate nahi karni.
    final normalizedName = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return 'local_$normalizedName';
  }

  String? _normalizePath(String? path) {
    final cleanPath = path?.trim();

    if (cleanPath == null || cleanPath.isEmpty) {
      return null;
    }

    return cleanPath;
  }
}
