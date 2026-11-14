import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../account_deletion_policy.dart';
import '../account_deletion_summary.dart';

/// Account deletion request / cancel (M14 step 4).
///
/// Only writes `users/{uid}.deletionRequestedAt` (server time) — nothing is
/// deleted here. The delete itself runs later (step 5) once the grace period
/// is over. Security rules allow the user to set this field to the server time
/// or remove it, and nothing else in the same write.
class AccountDeletionService {
  AccountDeletionService._();
  static final AccountDeletionService instance = AccountDeletionService._();

  static const Duration _timeout = Duration(seconds: 10);

  /// Latest known status, for banners. Updated by [refresh], [request] and
  /// [cancel].
  final ValueNotifier<DeletionStatus> status = ValueNotifier(
    DeletionStatus.none,
  );

  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  /// Reads the request time from Firestore. Fails open (returns the last
  /// known status) when offline, so the app is never blocked by this check.
  Future<DeletionStatus> refresh() async {
    final ref = _userDoc();
    if (ref == null) {
      status.value = DeletionStatus.none;
      return status.value;
    }
    try {
      final snap = await ref.get().timeout(_timeout);
      final raw = snap.data()?['deletionRequestedAt'];
      final at = raw is Timestamp ? raw.toDate() : null;
      status.value = AccountDeletionPolicy.evaluate(at, DateTime.now());
    } catch (e) {
      debugPrint('AccountDeletionService.refresh failed — $e');
    }
    return status.value;
  }

  /// What deleting would remove, for the confirm sheet. Null if it cannot be
  /// loaded (offline etc.) — the sheet then simply omits the summary.
  Future<DeletionSummary?> loadSummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('memberUids', arrayContains: uid)
          .get()
          .timeout(_timeout);
      return DeletionSummary.fromProfiles(uid, [
        for (final d in snap.docs) d.data(),
      ]);
    } catch (e) {
      debugPrint('AccountDeletionService.loadSummary failed — $e');
      return null;
    }
  }

  /// Marks the account for deletion. Throws on failure (the UI shows it).
  Future<DeletionStatus> request() async {
    final ref = _userDoc();
    if (ref == null) throw StateError('Not signed in');
    await ref
        .update({
          'deletionRequestedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(_timeout);
    return refresh();
  }

  /// Cancels a pending request. Throws on failure.
  Future<DeletionStatus> cancel() async {
    final ref = _userDoc();
    if (ref == null) throw StateError('Not signed in');
    await ref
        .update({
          'deletionRequestedAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(_timeout);
    status.value = DeletionStatus.none;
    return status.value;
  }
}
