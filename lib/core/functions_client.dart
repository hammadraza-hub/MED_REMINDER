import 'package:cloud_functions/cloud_functions.dart';

import '../config/app_config.dart';
import 'app_exception.dart';

/// ============================================================
/// FUNCTIONS CLIENT — Thin wrapper around FirebaseFunctions
/// ============================================================
///
/// Centralizes:
///   - Region selection (per environment via AppConfig)
///   - Error mapping (FirebaseFunctionsException → AppException)
///   - Timeout handling
///
/// All repositories in `lib/repositories/` should use this client
/// when calling Cloud Functions. Never call FirebaseFunctions
/// directly — always go through FunctionsClient.call().
///
/// Usage:
///   final result = await FunctionsClient.call<Map<String, dynamic>>(
///     functionName: 'createCaregiverInvite',
///     data: {'email': '...'},
///   );
/// ============================================================
class FunctionsClient {
  // Private constructor — static-only utility class.
  FunctionsClient._();

  // ───────────────────────────────────────────────────────────
  // Instance accessor (per-environment region)
  // ───────────────────────────────────────────────────────────

  /// Returns a FirebaseFunctions instance configured for the
  /// correct region per environment:
  ///   - Staging: asia-south1 (Mumbai)
  ///   - Production: us-central1 (US)
  static FirebaseFunctions get _instance {
    return FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);
  }

  // ───────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────

  /// Calls a Cloud Function by name with optional data payload.
  ///
  /// - [functionName]: The name of the callable function (as defined in `functions/src/index.ts`)
  /// - [data]: Optional map of arguments to pass to the function
  /// - [timeout]: Maximum time to wait for response (default: 30 seconds)
  ///
  /// Returns the function's response data, typed as [T].
  ///
  /// Throws [AppException] on failure — never raw Firebase exception.
  /// Categories:
  ///   - AppExceptionType.validation   (invalid-argument, failed-precondition, out-of-range)
  ///   - AppExceptionType.permission    (unauthenticated, permission-denied)
  ///   - AppExceptionType.notFound      (not-found)
  ///   - AppExceptionType.server       (aborted, internal, resource-exhausted)
  ///   - AppExceptionType.network       (unavailable, deadline-exceeded)
  ///   - AppExceptionType.unknown       (cancelled, unknown, anything else)
  static Future<T> call<T>({
    required String functionName,
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final result = await _instance
          .httpsCallable(functionName)
          .call<T>(data ?? {})
          .timeout(timeout);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      // Convert to typed AppException
      throw AppException.fromFunctionsException(e);
    } on AppException {
      // Already typed — pass through
      rethrow;
    } catch (e) {
      // Unknown error (timeout, network, etc.)
      throw AppException.unknown(e.toString(), originalError: e);
    }
  }

  /// Convenience method for calling a function that returns a Map.
  ///
  /// Most Cloud Functions return JSON objects, so this is the
  /// most common usage pattern.
  static Future<Map<String, dynamic>> callJson({
    required String functionName,
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await call<dynamic>(
      functionName: functionName,
      data: data,
      timeout: timeout,
    );

    // Cast to Map<String, dynamic> — Cloud Functions typically return JSON objects
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    throw AppException.validation(
      'Function "$functionName" returned unexpected type: ${result.runtimeType}',
      originalError: result,
    );
  }

  /// Convenience method for calling a function that returns a List.
  static Future<List<dynamic>> callList({
    required String functionName,
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await call<dynamic>(
      functionName: functionName,
      data: data,
      timeout: timeout,
    );

    if (result is List) {
      return List<dynamic>.from(result);
    }
    throw AppException.validation(
      'Function "$functionName" returned unexpected type: ${result.runtimeType}',
      originalError: result,
    );
  }
}
