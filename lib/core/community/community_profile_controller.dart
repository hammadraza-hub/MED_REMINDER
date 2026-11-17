import 'package:flutter/foundation.dart';

import 'community_models.dart';
import 'community_validator.dart';

/// Where the profile lives (Firestore in the app). M19 step 2.
///
/// The rules check `communityProfiles/{id}` against the id saved in
/// `users/{uid}` BEFORE the write, so the two writes cannot share one batch:
/// the id is saved first, the profile second.
abstract class CommunityProfileStore {
  /// `users/{uid}.communityProfileId`, or null when never set.
  Future<String?> readMyProfileId();

  /// Saves the id once. Throws when an id is already saved (rules).
  Future<void> saveMyProfileId(String id);

  /// `communityProfiles/{id}`, or null when it does not exist.
  Future<CommunityProfile?> readProfile(String id);

  Future<void> createProfile(
    String id, {
    required String pseudonym,
    required String avatar,
    required String bio,
  });

  Future<void> updateProfile(
    String id, {
    required String pseudonym,
    required String avatar,
    required String bio,
  });
}

/// The input was not valid. [field] says which field, [error] why.
class CommunityInputException implements Exception {
  const CommunityInputException(this.field, this.error);

  final CommunityField field;
  final CommunityInputError error;

  @override
  String toString() => 'CommunityInputException($field, $error)';
}

enum CommunityField { pseudonym, bio, body }

/// Loads, creates and edits the user's own pseudonym profile.
class CommunityProfileController {
  CommunityProfileController(this._store, {String Function()? newId})
    : _newId = newId ?? CommunityIds.newProfileId;

  final CommunityProfileStore _store;
  final String Function() _newId;

  /// The cached profile after [load] or [save]; null before or when none.
  final ValueNotifier<CommunityProfile?> profile = ValueNotifier(null);

  /// The user's profile, or null when they have none yet. Throws when it
  /// cannot be read (offline), so the screen can show "try again".
  Future<CommunityProfile?> load() async {
    final id = await _store.readMyProfileId();
    if (id == null) {
      profile.value = null;
      return null;
    }
    final p = await _store.readProfile(id);
    profile.value = p;
    return p;
  }

  /// Creates the profile (first time) or edits it. Throws
  /// [CommunityInputException] for bad input and any store error otherwise;
  /// nothing changes locally when it throws.
  ///
  /// If an earlier attempt saved the id but not the profile (the app was
  /// closed in between), the same id is reused.
  Future<CommunityProfile> save({
    required String pseudonym,
    required String avatar,
    required String bio,
  }) async {
    final nameError = CommunityValidator.pseudonym(pseudonym);
    if (nameError != null) {
      throw CommunityInputException(CommunityField.pseudonym, nameError);
    }
    final bioError = CommunityValidator.bio(bio);
    if (bioError != null) {
      throw CommunityInputException(CommunityField.bio, bioError);
    }

    final name = pseudonym.trim();
    final text = bio.trim();
    final safeAvatar = _avatar(avatar);

    var id = await _store.readMyProfileId();
    if (id == null) {
      final fresh = _newId();
      try {
        await _store.saveMyProfileId(fresh);
        id = fresh;
      } catch (_) {
        // Another phone of the same account may have saved an id a moment ago.
        id = await _store.readMyProfileId();
        if (id == null) rethrow;
      }
    }

    final existing = await _store.readProfile(id);
    if (existing == null) {
      await _store.createProfile(
        id,
        pseudonym: name,
        avatar: safeAvatar,
        bio: text,
      );
    } else {
      await _store.updateProfile(
        id,
        pseudonym: name,
        avatar: safeAvatar,
        bio: text,
      );
    }

    final saved = CommunityProfile(
      id: id,
      pseudonym: name,
      avatar: safeAvatar,
      bio: text,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    profile.value = saved;
    return saved;
  }

  String _avatar(String key) {
    final k = key.trim();
    return k.isEmpty || k.length > CommunityLimits.avatarMax ? 'a1' : k;
  }

  /// The user's community id for writing posts and comments, or null when
  /// they have no profile yet. Uses the cached profile when there is one.
  Future<String?> myId() async {
    final cached = profile.value;
    if (cached != null) return cached.id;
    return (await load())?.id;
  }

  /// Forget everything (sign-out).
  void reset() => profile.value = null;
}
