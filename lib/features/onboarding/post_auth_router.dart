import 'package:flutter/material.dart';

import '../../core/account_deletion_policy.dart';
import '../../core/services/account_deletion_service.dart';
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
  final deletion = await AccountDeletionService.instance.refresh();
  if (deletion.phase == DeletionPhase.due) {
    return const AccountPurgeScreen();
  }

  if (await LegalService.instance.needsReconsent(uid)) {
    return LegalReconsentScreen(uid: uid, next: (_) => const MedRemindShell());
  }
  return const MedRemindShell();
}
