import 'package:firebase_core/firebase_core.dart';

// Environment-specific Firebase configs
// (firebase_options_staging.dart and firebase_options_prod.dart are in lib/)
import '../firebase_options_staging.dart' as staging_options;
import '../firebase_options_prod.dart' as prod_options;

/// ============================================================
/// APP CONFIG — Central Environment & Configuration Manager
/// ============================================================
///
/// Usage:
///   - Run app with: `flutter run --dart-define=ENV=staging`
///   - Run app with: `flutter run --dart-define=ENV=prod`
///   - Use emulator: `flutter run --dart-define=ENV=staging --dart-define=USE_EMULATOR=true`
///
/// In code:
///   - AppConfig.environment       → Environment.staging | Environment.production
///   - AppConfig.isProduction      → bool
///   - AppConfig.firebaseOptions   → FirebaseOptions (correct for env)
///   - AppConfig.useEmulator       → bool
///   - AppConfig.configSummary     → String (for debug logging)
/// ============================================================

/// Enum representing the current environment.
enum Environment { staging, production }

class AppConfig {
  // Private constructor — this is a static-only utility class.
  AppConfig._();

  // ───────────────────────────────────────────────────────────
  // Compile-time constants (read from --dart-define flags)
  // ───────────────────────────────────────────────────────────

  /// Environment string passed via `--dart-define=ENV=staging|prod`.
  /// Defaults to 'staging' for dev safety — never accidentally hit production.
  static const String _envString = String.fromEnvironment(
    'ENV',
    defaultValue: 'staging',
  );

  /// Whether to point at local Firebase emulators.
  /// Pass via `--dart-define=USE_EMULATOR=true`.
  /// Defaults to false — production builds never touch emulators.
  static const bool useEmulator = bool.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: false,
  );

  // ───────────────────────────────────────────────────────────
  // Derived getters
  // ───────────────────────────────────────────────────────────

  /// The current environment as an enum.
  static Environment get environment {
    switch (_envString.toLowerCase()) {
      case 'prod':
      case 'production':
        return Environment.production;
      case 'staging':
      default:
        return Environment.staging;
    }
  }

  /// True if running against production Firebase.
  static bool get isProduction => environment == Environment.production;

  /// True if running against staging Firebase.
  static bool get isStaging => environment == Environment.staging;

  /// Returns the appropriate FirebaseOptions for the current environment.
  /// Used by Firebase.initializeApp(options: AppConfig.firebaseOptions).
  static FirebaseOptions get firebaseOptions {
    switch (environment) {
      case Environment.production:
        return prod_options.DefaultFirebaseOptions.currentPlatform;
      case Environment.staging:
      default:
        return staging_options.DefaultFirebaseOptions.currentPlatform;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Cloud Functions region (matches Firestore region for latency)
  // ───────────────────────────────────────────────────────────
  /// Cloud Functions region. Matches Firestore region per environment
  /// for lowest latency:
  ///   - Staging: asia-south1 (Mumbai)
  ///   - Production: us-central1 (US — closest to Firestore nam5)
  static String get functionsRegion {
    switch (environment) {
      case Environment.production:
        return 'us-central1';
      case Environment.staging:
      default:
        return 'asia-south1';
    }
  }
  // ───────────────────────────────────────────────────────────
  // Debug helpers
  // ───────────────────────────────────────────────────────────

  /// Human-readable summary for logging at app startup.
  /// Example: "ENV: staging | Emulator: true | ProjectId: medapp-staging"
  static String get configSummary {
    final projectId = firebaseOptions.projectId ?? 'unknown';
    return 'ENV: ${environment.name} | Emulator: $useEmulator | ProjectId: $projectId';
  }
}
