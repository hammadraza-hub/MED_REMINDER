import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/auth/login_screen.dart';
import '../../l10n/app_localizations.dart';
import '../app_error_text.dart';
import '../app_exception.dart';
import '../app_navigator.dart';
import '../profile/profile_controller.dart';
import '../queued_write.dart';
import 'access_guard.dart';
import 'connectivity_service.dart';
import 'session_guard.dart';

/// Connects the three "something changed behind the user's back" guards to the
/// real app. Called once from `main()`. M20 step 7.
///  * [SessionGuard]: the session ended -> back to sign in, with a notice;
///  * [AccessGuard]: access to the profile on screen was removed -> own profile;
///  * [QueuedWriteErrors]: a save reported as "queued" was refused later.
void installAppGuards() {
  AppLocalizations? l10nOrNull() {
    final ctx = appNavigatorKey.currentContext;
    return ctx == null ? null : AppLocalizations.of(ctx);
  }

  SessionGuard.instance = SessionGuard(
    signedIn: FirebaseAuth.instance.authStateChanges().map((u) => u != null),
    onLost: () async {
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      final l10n = l10nOrNull();
      if (l10n != null) showAppNotice(l10n.appErrorSessionExpired);
    },
  )..start();

  final db = FirebaseFirestore.instance;
  AccessGuard.instance = AccessGuard(
    AccessGuardPorts(
      currentProfileId: () => ProfileController.instance.memberId,
      canRead: (id) async {
        try {
          final doc = await db
              .collection('profiles')
              .doc(id)
              .get(const GetOptions(source: Source.server));
          return doc.exists;
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') return false;
          rethrow; // unknown (network, ...): the guard does nothing
        }
      },
      ownProfileId: () async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return null;
        final q = await db
            .collection('profiles')
            .where('ownerUid', isEqualTo: uid)
            .limit(5)
            .get();
        for (final d in q.docs) {
          if (d.data()['kind'] == 'self') return d.id;
        }
        return null;
      },
      select: (id) async {
        final doc = await db.collection('profiles').doc(id).get();
        final name = (doc.data()?['name'] as String?)?.trim();
        await ProfileController.instance.syncFromBackend(
          memberId: id,
          displayName: (name == null || name.isEmpty)
              ? (FirebaseAuth.instance.currentUser?.displayName ?? 'Me')
              : name,
          profileImageUrl: FirebaseAuth.instance.currentUser?.photoURL,
        );
      },
      isOffline: () => ConnectivityService.instance.isOffline,
      notice: () {
        final l10n = l10nOrNull();
        if (l10n != null) showAppNotice(l10n.accessLostNotice);
      },
    ),
  );

  QueuedWriteErrors.onLate = (error) {
    final l10n = l10nOrNull();
    if (l10n != null) {
      final reason = AppErrorText.of(l10n, error);
      showAppNotice('${l10n.queuedWriteRejected}\n$reason');
    }
    if (AppException.fromAny(error).type == AppExceptionType.permission) {
      AccessGuard.reportPermissionDenied();
    }
  };
}
