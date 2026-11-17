import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

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
import 'core/services/app_guards.dart';
import 'core/accessibility/accessibility_controller.dart';
import 'core/app_navigator.dart';
import 'core/app_startup.dart';
import 'core/locale/locale_controller.dart';
import 'core/profile/profile_controller.dart';
import 'core/services/app_info_service.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/preferences_sync_service.dart';
import 'core/services/push_service.dart';
import 'core/services/reminder_action_queue.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/reminder_scheduler.dart';
import 'core/subscription/subscription_service.dart';
import 'l10n/app_localizations.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/offline_banner.dart';
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

  // M20 step 2: start watching the network right away (it needs no Firebase),
  // so the "Offline" bar can show even while the rest of startup waits.
  unawaited(ConnectivityService.instance.start());

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
  // Installed version first: the force-update check compares against it.
  await AppInfoService.instance.initialize();
  // Local part only (settings + defaults); the fetch is a bounded startup
  // task below (M20 step 3).
  await RemoteConfigService.instance.initialize(fetch: false);

  // ───────────────────────────────────────────────────────────
  // STEP 4: Persisted Profile / Member Selection Restore
  // ───────────────────────────────────────────────────────────
  await ProfileController.instance.initialize();

  // ───────────────────────────────────────────────────────────
  // STEP 4.5: Network work, bounded (M20 step 3)
  // ───────────────────────────────────────────────────────────
  // These used to be awaited with no limit: a Firestore write never finishes
  // while the phone is offline, so the app stayed on the native splash for
  // ever. Now an offline phone skips them at once, an online one waits at most
  // a few seconds for each, and whatever was skipped or too slow runs again
  // when the network is back (see AppStartup).
  try {
    await ConnectivityService.instance.start().timeout(
      const Duration(seconds: 1),
      onTimeout: () {},
    );
  } catch (_) {
    // Unknown connectivity just means "try the tasks".
  }

  final pushService = LocalOnlyPushService();
  var pushListening = false;
  Future<void> registerPushToken() async {
    // The token is registered for whoever is signed in right now.
    final uid = AuthRepository.instance.currentUid;
    if (uid == null || uid.isEmpty) return;
    await pushService.registerToken(uid);
    // Re-register on token refresh (once).
    if (!pushListening) {
      pushListening = true;
      FirebaseMessaging.instance.onRegistered.listen((newToken) {
        final current = AuthRepository.instance.currentUid;
        if (current != null && current.isNotEmpty) {
          unawaited(pushService.registerToken(current));
        }
      });
    }
  }

  final startup = AppStartup(
    ConnectivityService.instance,
    tasks: [
      // Fresh Remote Config values (the app already has defaults / old ones).
      StartupTask('remote-config', RemoteConfigService.instance.refresh),
      // Wrong name + Firestore permission-denied on dose writes happened with
      // a stale local memberId, so the account's profile is looked up again.
      StartupTask(
        'restore-profile',
        AuthRepository.instance.restoreSelectedProfile,
      ),
      // RevenueCat (Spark: client-side); purchases stay off if it fails.
      StartupTask(
        'subscription',
        SubscriptionService.instance.initialize,
        limit: const Duration(seconds: 5),
      ),
      // FCM token: a Firestore write, so it must never block the first screen.
      StartupTask(
        'push-token',
        registerPushToken,
        limit: const Duration(seconds: 10),
        beforeApp: false,
      ),
    ],
  );
  await startup.runBeforeApp();

  // ───────────────────────────────────────────────────────────
  // STEP 5: Accessibility + Locale Restore
  // ───────────────────────────────────────────────────────────
  await AccessibilityController.instance.initialize();
  await LocaleController.instance.initialize();

  // M13 step 3: sync language + accessibility prefs with users/{uid}.settings
  // (best-effort, never blocks startup).
  PreferencesSyncService.instance.start();

  // M13 step 6: optional biometric app lock (device-only setting). Locks on
  // every cold start, and after >30 s in the background.
  AppLockService.instance.bindSignedIn(
    () => FirebaseAuth.instance.currentUser != null,
  );
  await AppLockService.instance.initialize();
  FirebaseAuth.instance.authStateChanges().listen(
    (user) => AppLockService.instance.handleAuthChanged(user != null),
  );

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

  installAppGuards();
  runApp(const MyApp());

  // After the first screen: the push token, and anything skipped while the
  // phone was offline (or too slow) runs when the network is back.
  startup.runAfterApp();
  startup.catchUpWhenOnline();
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
          navigatorKey: appNavigatorKey,
          scaffoldMessengerKey: appMessengerKey,
          title: 'MedRemind',
          theme: ThemeData(useMaterial3: true),
          locale: LocaleController.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return AppLockGate(
              child: ListenableBuilder(
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
                    child: OfflineBannerHost(child: child!),
                  );
                },
              ),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
