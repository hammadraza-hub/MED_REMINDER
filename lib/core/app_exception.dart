import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_functions/cloud_functions.dart' as functions;

/// ============================================================
/// APP EXCEPTION — Typed Error Handling Layer
/// ============================================================
///
/// M1: Provides a small, consistent set of error types for the app UI.
/// M20 (User Messages module) will read `type` to show localized messages.
///
/// Maps:
///   - FirebaseAuthException → typed AppException
///   - FirebaseException (Firestore, Storage, etc.) → typed AppException
///   - FirebaseFunctionsException → typed AppException
///   - Any unknown error → AppException.unknown
/// ============================================================

/// Enum representing a small set of error types for the app UI.
enum AppExceptionType {
  /// Connection issues, timeout, offline
  network,

  /// User lacks permission to perform action
  permission,

  /// Requested resource doesn't exist
  notFound,

  /// Invalid input or state — user can fix this
  validation,

  /// Backend/server error — not user's fault
  server,

  /// Anything we don't know how to categorize
  unknown,
}

/// Typed application exception.
///
/// Use this throughout the app instead of raw Firebase exceptions.
/// M20 (User Messages module) will read `type` to show localized messages.
class AppException implements Exception {
  final AppExceptionType type;
  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? originalStackTrace;

  const AppException({
    required this.type,
    required this.message,
    this.code,
    this.originalError,
    this.originalStackTrace,
  });

  @override
  String toString() {
    final codePart = code != null ? ' [$code]' : '';
    return 'AppException: $message$codePart (type: ${type.name})';
  }

  // ───────────────────────────────────────────────────────────
  // Convenience constructors for common cases
  // ───────────────────────────────────────────────────────────

  const factory AppException.network(String message, {Object? originalError}) =
      _AppExceptionNetwork;

  const factory AppException.permission(
    String message, {
    Object? originalError,
  }) = _AppExceptionPermission;

  const factory AppException.notFound(String message, {Object? originalError}) =
      _AppExceptionNotFound;

  const factory AppException.validation(
    String message, {
    Object? originalError,
  }) = _AppExceptionValidation;

  const factory AppException.server(String message, {Object? originalError}) =
      _AppExceptionServer;

  const factory AppException.unknown(String message, {Object? originalError}) =
      _AppExceptionUnknown;

  // ───────────────────────────────────────────────────────────
  // EXCEPTION MAPPING — Firebase → AppException
  // ───────────────────────────────────────────────────────────

  /// Maps a [auth.FirebaseAuthException] to an [AppException].
  static AppException fromAuthException(auth.FirebaseAuthException e) {
    AppExceptionType type;
    String message = e.message ?? 'Authentication failed';

    switch (e.code) {
      // Validation errors (user can fix)
      case 'invalid-email':
      case 'wrong-password':
      case 'weak-password':
      case 'user-not-found':
      case 'user-disabled':
      case 'invalid-credential':
      case 'operation-not-allowed':
        type = AppExceptionType.validation;
        break;

      // Permission errors
      case 'invalid-verification-code':
      case 'invalid-verification-id':
      case 'email-already-in-use':
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
      case 'requires-recent-login':
        type = AppExceptionType.permission;
        break;

      // Network errors
      case 'network-request-failed':
      case 'too-many-requests':
        type = AppExceptionType.network;
        break;

      // Server errors
      case 'internal-error':
      case 'app-not-authorized':
      case 'operation-not-supported':
        type = AppExceptionType.server;
        break;

      default:
        type = AppExceptionType.unknown;
    }

    return AppException(
      type: type,
      message: message,
      code: e.code,
      originalError: e,
    );
  }

  /// Maps a [fs.FirebaseException] (Firestore, etc.) to an [AppException].
  static AppException fromFirebaseException(fs.FirebaseException e) {
    AppExceptionType type;
    String message = e.message ?? 'Firebase operation failed';
    final code = e.code;

    switch (code) {
      // Permission errors
      case 'permission-denied':
        type = AppExceptionType.permission;
        message = 'You do not have permission to perform this action';
        break;

      // Network errors
      case 'unavailable':
      case 'deadline-exceeded':
        type = AppExceptionType.network;
        message = 'Network unavailable. Please check your connection';
        break;

      // Not found
      case 'not-found':
        type = AppExceptionType.notFound;
        message = 'The requested data was not found';
        break;

      // Validation errors
      case 'invalid-argument':
      case 'failed-precondition':
      case 'out-of-range':
        type = AppExceptionType.validation;
        break;

      // Server errors
      case 'internal':
      case 'unimplemented':
      case 'aborted':
        type = AppExceptionType.server;
        break;

      // Conflict / already exists
      case 'already-exists':
      case 'cancelled':
        type = AppExceptionType.validation;
        break;

      // Resource exhausted
      case 'resource-exhausted':
        type = AppExceptionType.server;
        message = 'Service is busy. Please try again later';
        break;

      // Unauthenticated (similar to permission)
      case 'unauthenticated':
        type = AppExceptionType.permission;
        message = 'Please sign in to continue';
        break;

      default:
        type = AppExceptionType.unknown;
    }

    return AppException(
      type: type,
      message: message,
      code: code,
      originalError: e,
    );
  }

  /// Maps a [functions.FirebaseFunctionsException] to an [AppException].
  /// Note: cloud_functions v7.0.0+ uses String codes (e.g. 'permission-denied')
  /// instead of the deprecated FunctionsErrorCode enum.
  static AppException fromFunctionsException(
    functions.FirebaseFunctionsException e,
  ) {
    AppExceptionType type;
    String message = e.message ?? 'Cloud function failed';
    final code = e.code; // String in v7.0.0+

    switch (code) {
      // Validation errors
      case 'invalid-argument':
      case 'failed-precondition':
      case 'out-of-range':
        type = AppExceptionType.validation;
        break;

      // Permission / auth errors
      case 'unauthenticated':
        type = AppExceptionType.permission;
        message = 'Please sign in to continue';
        break;
      case 'permission-denied':
        type = AppExceptionType.permission;
        message = 'You do not have permission to perform this action';
        break;

      // Not found
      case 'not-found':
        type = AppExceptionType.notFound;
        break;

      // Server errors
      case 'aborted':
      case 'internal':
        type = AppExceptionType.server;
        break;

      // Network errors
      case 'unavailable':
      case 'deadline-exceeded':
        type = AppExceptionType.network;
        break;

      // Resource exhausted
      case 'resource-exhausted':
        type = AppExceptionType.server;
        message = 'Service is busy. Please try again later';
        break;

      // Cancelled / unknown
      case 'cancelled':
      case 'unknown':
        type = AppExceptionType.unknown;
        break;

      default:
        type = AppExceptionType.unknown;
    }

    return AppException(
      type: type,
      message: message,
      code: code, // String directly
      originalError: e,
    );
  }

  /// Generic catch-all mapper — detects known Firebase exceptions,
  /// otherwise falls back to "unknown".
  ///
  /// Usage:
  /// ```dart
  /// try {
  ///   await someFirebaseCall();
  /// } catch (e) {
  ///   throw AppException.fromAny(e);
  /// }
  /// ```
  static AppException fromAny(Object error) {
    if (error is AppException) return error; // already typed

    if (error is auth.FirebaseAuthException) {
      return fromAuthException(error);
    }

    if (error is functions.FirebaseFunctionsException) {
      return fromFunctionsException(error);
    }

    if (error is fs.FirebaseException) {
      return fromFirebaseException(error);
    }

    // Generic unknown error
    return AppException.unknown(error.toString(), originalError: error);
  }
}

// Private factory implementations (needed for const factory constructors)
class _AppExceptionNetwork extends AppException {
  const _AppExceptionNetwork(String message, {Object? originalError})
    : super(
        type: AppExceptionType.network,
        message: message,
        originalError: originalError,
      );
}

class _AppExceptionPermission extends AppException {
  const _AppExceptionPermission(String message, {Object? originalError})
    : super(
        type: AppExceptionType.permission,
        message: message,
        originalError: originalError,
      );
}

class _AppExceptionNotFound extends AppException {
  const _AppExceptionNotFound(String message, {Object? originalError})
    : super(
        type: AppExceptionType.notFound,
        message: message,
        originalError: originalError,
      );
}

class _AppExceptionValidation extends AppException {
  const _AppExceptionValidation(String message, {Object? originalError})
    : super(
        type: AppExceptionType.validation,
        message: message,
        originalError: originalError,
      );
}

class _AppExceptionServer extends AppException {
  const _AppExceptionServer(String message, {Object? originalError})
    : super(
        type: AppExceptionType.server,
        message: message,
        originalError: originalError,
      );
}

class _AppExceptionUnknown extends AppException {
  const _AppExceptionUnknown(String message, {Object? originalError})
    : super(
        type: AppExceptionType.unknown,
        message: message,
        originalError: originalError,
      );
}
