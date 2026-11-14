/// ============================================================
/// ACCOUNT DELETION ENGINE — M14 step 5
///
/// Pure logic (no Firebase / Flutter imports): deletes everything a user owns
/// through a [PurgeStore]. Order matters because Firestore rules check the
/// parent profile before allowing a child delete:
///
///   0. leave every profile owned by somebody else (remove only this user's
///      own access), so no dangling membership is left behind
///   1. for every owned profile: nested `inventoryEvents`, then every
///      collection, then the profile document itself (always last)
///   2. `users/{uid}/devices`, then `users/{uid}`
///
/// The Firebase Auth account is removed by the caller afterwards.
///
/// It is safe to run again after a failure: it lists what is still there and
/// deletes that, so a half-finished purge simply continues.
/// ============================================================
abstract class PurgeStore {
  /// Ids of profiles whose `ownerUid` is [uid].
  Future<List<String>> ownedProfileIds(String uid);

  /// Ids of profiles this user is a member of but does NOT own.
  Future<List<String>> memberProfileIds(String uid);

  /// Removes [uid]'s own access from [profileId] (memberUids, healthUids,
  /// roles, permissions). Must not touch anybody else's access.
  Future<void> leaveProfile(String profileId, String uid);

  /// Ids of documents currently in the collection at [collectionPath]
  /// (a page is enough; the engine lists again until the collection is empty).
  Future<List<String>> listIds(String collectionPath);

  /// Deletes the document at [docPath]. Missing documents are not an error.
  Future<void> deleteDoc(String docPath);
}

class PurgeSummary {
  const PurgeSummary({
    required this.deletedDocs,
    required this.profiles,
    this.leftProfiles = 0,
  });

  final int deletedDocs;
  final int profiles;

  /// Profiles owned by others that this user was removed from.
  final int leftProfiles;
}

/// The purge could not make progress (e.g. delete silently did nothing).
class PurgeStalledException implements Exception {
  PurgeStalledException(this.path);
  final String path;

  @override
  String toString() => 'PurgeStalledException: $path';
}

class AccountDeletionEngine {
  AccountDeletionEngine(this._store);

  final PurgeStore _store;

  /// Collections directly under `profiles/{id}` (matches the export list).
  static const List<String> profileCollections = [
    'doses',
    'dailySummaries',
    'allergies',
    'pharmacies',
    'safetyWarnings',
    'vitals',
    'vitalsDaily',
    'symptoms',
    'prescribers',
    'appointments',
    'doctorNotes',
  ];

  int _deleted = 0;

  Future<PurgeSummary> purge(
    String uid, {
    void Function(String step)? onProgress,
  }) async {
    _deleted = 0;

    // Leave shared profiles first: if this fails nothing has been deleted yet.
    final memberOf = await _store.memberProfileIds(uid);
    for (final id in memberOf) {
      onProgress?.call('leave:$id');
      await _store.leaveProfile(id, uid);
    }

    final profileIds = await _store.ownedProfileIds(uid);
    for (final id in profileIds) {
      onProgress?.call('profile:$id');
      await _purgeProfile(id, onProgress);
    }

    onProgress?.call('account');
    await _purgeCollection('users/$uid/devices');
    await _delete('users/$uid');

    return PurgeSummary(
      deletedDocs: _deleted,
      profiles: profileIds.length,
      leftProfiles: memberOf.length,
    );
  }

  Future<void> _purgeProfile(
    String profileId,
    void Function(String step)? onProgress,
  ) async {
    final base = 'profiles/$profileId';

    // medications (each with its own inventoryEvents) — events first.
    String? lastBatchKey;
    while (true) {
      final meds = await _store.listIds('$base/medications');
      if (meds.isEmpty) break;
      final key = meds.join(',');
      if (key == lastBatchKey) throw PurgeStalledException('$base/medications');
      lastBatchKey = key;

      for (final medId in meds) {
        await _purgeCollection('$base/medications/$medId/inventoryEvents');
        await _delete('$base/medications/$medId');
      }
    }

    for (final name in profileCollections) {
      onProgress?.call('$profileId/$name');
      await _purgeCollection('$base/$name');
    }

    // The profile document must go last: rules look it up for every child.
    await _delete(base);
  }

  Future<void> _purgeCollection(String path) async {
    String? lastBatchKey;
    while (true) {
      final ids = await _store.listIds(path);
      if (ids.isEmpty) return;

      final key = ids.join(',');
      if (key == lastBatchKey) throw PurgeStalledException(path);
      lastBatchKey = key;

      for (final id in ids) {
        await _delete('$path/$id');
      }
    }
  }

  Future<void> _delete(String docPath) async {
    await _store.deleteDoc(docPath);
    _deleted++;
  }
}
