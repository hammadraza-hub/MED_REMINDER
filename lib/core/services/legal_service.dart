import 'package:flutter/foundation.dart';

import '../../config/remote_config_service.dart';
import '../../repositories/auth_repository.dart';
import '../legal_gate.dart';

/// ============================================================
/// LEGAL SERVICE — M13 step 2
///
/// Decides whether the signed-in user must re-accept the Terms /
/// Privacy Policy (Remote Config `terms_version` /
/// `privacy_version` newer than what the user accepted), and
/// records the acceptance.
///
/// Fails OPEN: any error OR a slow/hanging read (offline, Firestore
/// down, Remote Config not ready, more than [_checkTimeout]) returns
/// "no re-consent needed", so a health app is never locked or stuck on
/// the splash because of a server problem. The user is simply asked on
/// a later launch.
/// ============================================================
class LegalService {
  LegalService._();
  static final LegalService instance = LegalService._();

  static const Duration _checkTimeout = Duration(seconds: 8);

  Future<bool> needsReconsent(String uid) async {
    try {
      final rc = RemoteConfigService.instance;
      final accepted = await AuthRepository.instance
          .getAcceptedLegal(uid)
          .timeout(_checkTimeout);
      return LegalGate.needsAcceptance(
        acceptedTerms: accepted.terms,
        acceptedPrivacy: accepted.privacy,
        requiredTerms: rc.termsVersion,
        requiredPrivacy: rc.privacyVersion,
      );
    } catch (e) {
      debugPrint('LegalService: check failed, not blocking — $e');
      return false;
    }
  }

  /// Saves acceptance of the CURRENT Remote Config versions.
  Future<void> accept(String uid) {
    final rc = RemoteConfigService.instance;
    return AuthRepository.instance.acceptLegal(
      uid: uid,
      termsVersion: rc.termsVersion,
      privacyVersion: rc.privacyVersion,
    );
  }
}
