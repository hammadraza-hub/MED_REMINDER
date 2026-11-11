import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/onboarding/splash_screen.dart';

// ──────────────────────────────────────────────────────────────
// FIREBASE IMPORTS (M0 + M1)
// ──────────────────────────────────────────────────────────────
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ──────────────────────────────────────────────────────────────
// APP CONFIG (M1) — env-based FirebaseOptions + emulator flag
// ──────────────────────────────────────────────────────────────
import 'config/app_config.dart';
import 'config/remote_config_service.dart';

// ──────────────────────────────────────────────────────────────
// EXISTING CONTROLLERS
// ──────────────────────────────────────────────────────────────
import 'core/accessibility/accessibility_controller.dart';
import 'core/locale/locale_controller.dart';
import 'core/profile/profile_controller.dart';
import 'core/services/reminder_action_queue.dart';
import 'core/services/reminder_scheduler.dart';
import 'core/services/push_service.dart';
import 'l10n/app_localizations.dart';
import 'repositories/auth_repository.dart';

// import 'main_shell.dart';

/// ============================================================
/// APP ENTRY POINT
///
/// Startup order:
///   0. Crashlytics error handlers (must be set before runApp)
///   1. Firebase initialize (env-specific config via AppConfig)
///   1.5. Emulator setup (only when --dart-define=USE_EMULATOR=true)
///   2. App Check activate
///   2.5. Remote Config initialize
///   3. .env load (optional — AI assistant keys)
///   4-5. Existing controllers (Profile, Accessibility, Locale)
///
/// Run flavors:
///   - Dev (staging):       flutter run --dart-define=ENV=staging
///   - Dev (emulators):     flutter run --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
///   - Prod (test):         flutter run --dart-define=ENV=prod --release
///   - Prod (release):      flutter build apk --dart-define=ENV=prod --release
/// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ───────────────────────────────────────────────────────────
  // STEP 0: Crashlytics Error Handlers (BEFORE runApp)
  // ───────────────────────────────────────────────────────────
  // These function pointers are set early — they fire later when
  // an error actually occurs (by which point Firebase is initialized).
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ───────────────────────────────────────────────────────────
  // STEP 1: Firebase Initialize (env-specific config)
  // ───────────────────────────────────────────────────────────
  // AppConfig picks correct firebase_options_staging.dart or
  // firebase_options_prod.dart based on --dart-define=ENV.
  // Default = staging (dev safety — never accidentally hit prod).
  await Firebase.initializeApp(options: AppConfig.firebaseOptions);

  // Log config summary for debugging
  debugPrint('🔥 ${AppConfig.configSummary}');

  // ───────────────────────────────────────────────────────────
  // STEP 1.5: Emulator Setup (M1 — when USE_EMULATOR=true)
  // ───────────────────────────────────────────────────────────
  // When USE_EMULATOR=true, point all Firebase services at local emulators.
  //   - Android emulator reaches PC at 10.0.2.2 (special alias)
  //   - iOS simulator / desktop uses 127.0.0.1
  //
  // Storage emulator is SKIPPED for now:
  //   - firebase_storage package not yet installed
  //   - Cloud Storage bucket not provisioned (Spark plan limitation)
  //   - Will add later when implementing image uploads
  if (AppConfig.useEmulator) {
    final String emulatorHost = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    debugPrint('🔥 Using Firebase Emulators at $emulatorHost');

    // Firestore emulator (port 8080)
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);

    // Auth emulator (port 9099)
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);

    // Functions emulator (port 5001)
    FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
  }

  // ───────────────────────────────────────────────────────────
  // STEP 2: App Check Activate
  // ───────────────────────────────────────────────────────────
  // Enforcement OFF for now. Will be enforced in M21.
  await FirebaseAppCheck.instance.activate();

  // ───────────────────────────────────────────────────────────
  // STEP 2.5: Remote Config Initialize
  // ───────────────────────────────────────────────────────────
  await RemoteConfigService.instance.initialize();

  // ───────────────────────────────────────────────────────────
  // STEP 3: .env Load (AI assistant keys — optional)
  // ───────────────────────────────────────────────────────────
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing — AI features gracefully disabled.
  }

  // ───────────────────────────────────────────────────────────
  // STEP 4: Persisted Profile / Member Selection Restore
  // ───────────────────────────────────────────────────────────
  await ProfileController.instance.initialize();

  // Resolve the signed-in account's profile so the app stops using a stale
  // local memberId (wrong name + Firestore permission-denied on dose writes).
  await AuthRepository.instance.restoreSelectedProfile();

  // ───────────────────────────────────────────────────────────
  // STEP 5d: FCM token registration (Spark: client writes devices collection;
  //          server-side sendPush is Blaze-only and deferred)
  // ───────────────────────────────────────────────────────────
  final uid = AuthRepository.instance.currentUid;
  if (uid != null && uid.isNotEmpty) {
    try {
      await pushService.registerToken(uid);
      // Re-register on token refresh.
      FirebaseMessaging.instance.onRegistered.listen((newToken) {
        unawaited(pushService.registerToken(uid));
      });
    } catch (e) {
      debugPrint('M8 step 5d: FCM token registration failed: $e');
      // Non-fatal — reminders still work locally without FCM token.
    }
  }

  // ───────────────────────────────────────────────────────────
  // STEP 5: Accessibility + Locale Restore
  // ───────────────────────────────────────────────────────────
  await AccessibilityController.instance.initialize();
  await LocaleController.instance.initialize();

  // ───────────────────────────────────────────────────────────
  // STEP 6: M8 — local dose reminders (Spark: no server involved)
  // ───────────────────────────────────────────────────────────
  await ReminderScheduler.instance.init();
  // Notification taps recorded while the app was away.
  await ReminderActionQueue.instance.replay();

  unawaited(ReminderScheduler.instance.rescheduleAll());

  // Debug-only proof: flutter run --dart-define=NOTIF_TEST=true
  if (kDebugMode && const bool.fromEnvironment('NOTIF_TEST')) {
    // Wait for the startup reschedule (its cancelAll would wipe this test).
    await ReminderScheduler.instance.rescheduleAll();
    await ReminderScheduler.instance.scheduleTestNotification();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MedRemind',
          theme: ThemeData(useMaterial3: true),
          locale: LocaleController.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return ListenableBuilder(
              listenable: AccessibilityController.instance,
              builder: (context, _) {
                final media = MediaQuery.of(context);
                final systemScale = media.textScaler.scale(1.0);
                final combined =
                    systemScale *
                    AccessibilityController.instance.textScaleFactor;

                return MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(combined).clamp(
                      minScaleFactor: AccessibilityController.minScaleFactor,
                      maxScaleFactor: AccessibilityController.maxScaleFactor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
