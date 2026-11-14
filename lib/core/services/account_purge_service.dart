import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../account_deletion_engine.dart';
import '../account_deletion_policy.dart';
import 'account_deletion_service.dart';

/// Firestore-backed [PurgeStore].
class FirestorePurgeStore implements PurgeStore {
  FirestorePurgeStore({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const int _page = 100;

  @override
  Future<List<String>> ownedProfileIds(String uid) async {
    // Rules only allow queries they can prove readable, so query by
    // membership and keep the profiles this user owns.
    final snap = await _db
        .collection('profiles')
        .where('memberUids', arrayContains: uid)
        .get();
    return [
      for (final d in snap.docs)
        if (d.data()['ownerUid'] == uid) d.id,
    ];
  }

  @override
  Future<List<String>> memberProfileIds(String uid) async {
    final snap = await _db
        .collection('profiles')
        .where('memberUids', arrayContains: uid)
        .get();
    return [
      for (final d in snap.docs)
        if (d.data()['ownerUid'] != uid) d.id,
    ];
  }

  @override
  Future<void> leaveProfile(String profileId, String uid) {
    // Dotted paths so only this user's entries are touched; the security rule
    // (validSelfLeave) rejects anything that changes somebody else's access.
    return _db.collection('profiles').doc(profileId).update({
      'memberUids': FieldValue.arrayRemove([uid]),
      'healthUids': FieldValue.arrayRemove([uid]),
      FieldPath(['roles', uid]): FieldValue.delete(),
      FieldPath(['permissions', uid]): FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<String>> listIds(String collectionPath) async {
    final snap = await _db.collection(collectionPath).limit(_page).get();
    return [for (final d in snap.docs) d.id];
  }

  @override
  Future<void> deleteDoc(String docPath) => _db.doc(docPath).delete();
}

enum PurgeOutcome {
  /// Everything deleted and the user is signed out.
  done,

  /// Not due (or no request): nothing was touched.
  notDue,

  /// The user must sign in again first; nothing was deleted.
  needsRecentLogin,

  /// A step failed; already-deleted data stays deleted, retry continues.
  failed,
}

/// Runs the account purge (M14 step 5): checks the request is due and the
/// login is fresh, deletes the data, then the Auth account.
class AccountPurgeService {
  AccountPurgeService._();
  static final AccountPurgeService instance = AccountPurgeService._();

  bool _running = false;

  Future<PurgeOutcome> run({
    void Function(String step)? onProgress,
    PurgeStore? store,
  }) async {
    if (_running) return PurgeOutcome.failed;
    _running = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return PurgeOutcome.failed;

      final status = await AccountDeletionService.instance.refresh();
      if (status.phase != DeletionPhase.due) return PurgeOutcome.notDue;

      // Ask for a fresh login BEFORE deleting anything: once the user
      // document is gone the request can no longer be found.
      if (!AccountDeletionPolicy.isRecentLogin(
        user.metadata.lastSignInTime,
        DateTime.now(),
      )) {
        return PurgeOutcome.needsRecentLogin;
      }

      try {
        await AccountDeletionEngine(store ?? FirestorePurgeStore())
            .purge(user.uid, onProgress: onProgress);
      } catch (e) {
        debugPrint('AccountPurgeService: purge failed — $e');
        return PurgeOutcome.failed;
      }

      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        // Data is already gone. Signing out is all that is left to do.
        debugPrint('AccountPurgeService: auth delete failed (${e.code})');
      }

      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      AccountDeletionService.instance.status.value = DeletionStatus.none;
      return PurgeOutcome.done;
    } finally {
      _running = false;
    }
  }
}
