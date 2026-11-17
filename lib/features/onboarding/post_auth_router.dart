import 'package:flutter/material.dart';

import '../../core/account_deletion_policy.dart';
import '../../core/services/account_deletion_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/legal_service.dart';
import '../../main_shell.dart';
import '../settings/account_purge_screen.dart';
import 'legal_reconsent_screen.dart';

/// Screen to open for a signed-in user.
///
/// 1. M14 step 5: if the user asked to delete their account and the 7-day
///    grace period is over, the purge screen (it finishes the deletion).
/// 2. M13 step 2: if the user has not accepted the current Terms / Privacy
///    versions, the re-consent screen first (it opens the dashboard after
///    acceptance).
/// 3. Otherwise the dashboard.
///
/// Both checks fail open — see [AccountDeletionService] and [LegalService].
Future<Widget> resolvePostAuthHome(String uid) async {
  // M20 step 3: offline, both checks need the network and would only wait for
  // their time limit. They fail open anyway, so go straight to the app; the
  // next start with a connection checks again.
  if (ConnectivityService.instance.isOffline) return const MedRemindShell();

  // Online but the server may not answer (down, or a Wi-Fi without internet):
  // the two checks run side by side and each gets only a few seconds, so the
  // user is not kept on the splash for their longest timeouts added together.
  const limit = Duration(seconds: 5);
  final results = await Future.wait<Object>([
    AccountDeletionService.instance
        .refresh()
        .then<Object>((s) => s)
        .timeout(
          limit,
          onTimeout: () => AccountDeletionService.instance.status.value,
        ),
    LegalService.instance
        .needsReconsent(uid)
        .then<Object>((b) => b)
        .timeout(limit, onTimeout: () => false),
  ]);

  final deletion = results[0] as DeletionStatus;
  if (deletion.phase == DeletionPhase.due) {
    return const AccountPurgeScreen();
  }
  if (results[1] as bool) {
    return LegalReconsentScreen(uid: uid, next: (_) => const MedRemindShell());
  }
  return const MedRemindShell();
}
