import 'package:flutter/material.dart';

import '../../core/services/legal_service.dart';
import '../../main_shell.dart';
import 'legal_reconsent_screen.dart';

/// Screen to open for a signed-in user (M13 step 2).
///
/// Normally the dashboard; if the user has not accepted the current
/// Terms / Privacy versions, the re-consent screen first (it opens the
/// dashboard after acceptance). Fails open — see [LegalService].
Future<Widget> resolvePostAuthHome(String uid) async {
  if (await LegalService.instance.needsReconsent(uid)) {
    return LegalReconsentScreen(
      uid: uid,
      next: (_) => const MedRemindShell(),
    );
  }
  return const MedRemindShell();
}
