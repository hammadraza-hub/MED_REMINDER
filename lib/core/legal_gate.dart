import 'app_gate.dart';

/// ============================================================
/// LEGAL GATE — M13 step 2
///
/// Pure logic: does a user need to (re-)accept the Terms of
/// Service / Privacy Policy?
///
///   accepted version  vs  required version (Remote Config)
///
/// - A required version that is empty/blank is ignored (a missing
///   Remote Config value must never lock users out).
/// - A user with no recorded acceptance (legacy account) is asked
///   once.
/// - Versions are compared numerically via [AppGate.compareVersions]
///   ("1.10" > "1.9").
/// ============================================================
class LegalGate {
  LegalGate._();

  static bool needsAcceptance({
    required String? acceptedTerms,
    required String? acceptedPrivacy,
    required String requiredTerms,
    required String requiredPrivacy,
  }) {
    return _outdated(acceptedTerms, requiredTerms) ||
        _outdated(acceptedPrivacy, requiredPrivacy);
  }

  static bool _outdated(String? accepted, String required) {
    if (required.trim().isEmpty) return false;
    if (accepted == null || accepted.trim().isEmpty) return true;
    return AppGate.compareVersions(accepted, required) < 0;
  }
}
