import '../l10n/app_localizations.dart';
import 'app_exception.dart';

/// What the user reads when something fails, in their language, and what the
/// screen may offer next. M20 step 1.
///
/// Every screen shows errors through here instead of printing
/// `exception.message` (an English developer text) or its own wording, so the
/// same failure reads the same everywhere.
class AppErrorText {
  AppErrorText._();

  /// The message for any thrown object (mapped with [AppException.fromAny]).
  static String of(AppLocalizations l10n, Object error) {
    final e = AppException.fromAny(error);
    if (isSessionProblem(e)) return l10n.appErrorSessionExpired;
    return forType(l10n, e.type);
  }

  static String forType(AppLocalizations l10n, AppExceptionType type) {
    return switch (type) {
      AppExceptionType.network => l10n.appErrorNetwork,
      AppExceptionType.permission => l10n.appErrorPermission,
      AppExceptionType.notFound => l10n.appErrorNotFound,
      AppExceptionType.validation => l10n.appErrorValidation,
      AppExceptionType.server => l10n.appErrorServer,
      AppExceptionType.unknown => l10n.appErrorUnknown,
    };
  }

  /// Whether a "Try again" button makes sense: the same request may work
  /// later (no internet, server trouble, an unknown glitch). It does not for
  /// "no access", "not found" or "invalid", which only repeat.
  static bool canRetry(Object error) {
    final e = AppException.fromAny(error);
    if (isSessionProblem(e)) return false;
    return switch (e.type) {
      AppExceptionType.network ||
      AppExceptionType.server ||
      AppExceptionType.unknown => true,
      AppExceptionType.permission ||
      AppExceptionType.notFound ||
      AppExceptionType.validation => false,
    };
  }

  /// The sign-in is no longer valid (expired or revoked token, or a request
  /// that needs a signed-in user): the app should go back to Log In rather
  /// than show a plain "no access".
  static bool isSessionProblem(Object error) {
    final e = AppException.fromAny(error);
    if (e.type != AppExceptionType.permission) return false;
    return _sessionCodes.contains(e.code);
  }

  /// "permission-denied" from Firestore: the user is signed in but may no
  /// longer be allowed to read this (for example a caregiver whose access was
  /// removed). The screen shows the no-access message and leads back.
  static bool isAccessRevoked(Object error) {
    final e = AppException.fromAny(error);
    return e.type == AppExceptionType.permission &&
        !_sessionCodes.contains(e.code);
  }

  static const Set<String> _sessionCodes = {
    'unauthenticated',
    'user-token-expired',
    'invalid-user-token',
    'user-token-revoked',
  };
}
