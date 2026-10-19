import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ──────────────────────────────────────────────────────────────
// FIREBASE IMPORTS (M0)
// ──────────────────────────────────────────────────────────────
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/config/remote_config_service.dart';
import 'core/accessibility/accessibility_controller.dart';
import 'core/locale/locale_controller.dart';
import 'core/profile/profile_controller.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'main_shell.dart';

/// ============================================================
/// APP ENTRY POINT
///
/// App UI start hone se pehle:
///   0. Crashlytics error handlers set karo (sync + async errors)
///   1. Firebase initialize (staging config)
///   2. App Check activate
///   2.5. Remote Config initialize (feature flags + config values)
///   3. .env load (AI assistant ke liye, optional)
///   4. Persisted profile/member selection restore
///   5. Accessibility + Locale preferences restore
///
/// IMPORTANT:
/// Selected member ID SharedPreferences se restore hoti hai.
/// Structured health data Drift / SQLite mein hi rahega.
/// Firebase init hamesha sabse pehle — taake baqi services
/// (Auth, Firestore, Messaging, etc.) safely use ho saken.
/// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ───────────────────────────────────────────────────────────
  // STEP 0: Crashlytics Error Handlers (BEFORE runApp)
  // ───────────────────────────────────────────────────────────
  // Ye handlers pehle set karne hain — taake baad mein koi bhi
  // error (sync ya async) Firebase Crashlytics par report ho jaye.
  //
  // Flutter framework errors (sync UI exceptions) — Crashlytics
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Async errors not caught by Flutter framework — Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ───────────────────────────────────────────────────────────
  // STEP 1: Firebase Initialize (staging config)
  // ───────────────────────────────────────────────────────────
  // firebase_options.dart mein staging project ka config hai.
  // Production deploy ke time flavors use karenge (separate file).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ───────────────────────────────────────────────────────────
  // STEP 2: App Check Activate
  // ───────────────────────────────────────────────────────────
  // App Check abhi enforcement OFF hai. Simple activate() kaafi hai.
  // Baad mein jab enforcement ON karenge, tab Debug Provider properly
  // configure karenge (Console + code dono mein).
  await FirebaseAppCheck.instance.activate();

  // ───────────────────────────────────────────────────────────
  // STEP 2.5: Remote Config Initialize
  // ───────────────────────────────────────────────────────────
  // Feature flags + configuration values Firebase se fetch karo.
  // Fetch fail ho to local defaults use honge (graceful).
  await RemoteConfigService.instance.initialize();

  // ───────────────────────────────────────────────────────────
  // STEP 3: .env Load (AI assistant ke liye, optional)
  // ───────────────────────────────────────────────────────────
  // File missing ho to app na crash ho — sirf AI disabled rahe.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env available nahi — AI features gracefully disabled rahenge.
  }

  // ───────────────────────────────────────────────────────────
  // STEP 4: Persisted Profile / Member Selection Restore
  // ───────────────────────────────────────────────────────────
  // Example:
  // User ne Mom select ki →
  // local_mom SharedPreferences mein persist →
  // app fully close →
  // next launch par yahan local_mom restore →
  // Home SQLite members mein local_mom ko select karega.
  await ProfileController.instance.initialize();

  // ───────────────────────────────────────────────────────────
  // STEP 5: Accessibility + Locale Restore
  // ───────────────────────────────────────────────────────────
  // App-wide text-size preference (Accessibility screen) restore.
  await AccessibilityController.instance.initialize();

  // Selected display language (Language screen) restore.
  await LocaleController.instance.initialize();

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
          // Display language (Language screen) + RTL support:
          // supportedLocales mein Arabic bhi hai, is liye Arabic select
          // karne par layout automatically right-to-left ho jata hai.
          locale: LocaleController.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // App-wide text scaling (Accessibility screen) + overflow safeguard.
          //
          // System font-scale aur app ke apne text-size preference ko
          // multiply karke ek combined scale banaya jata hai, aur usse safe
          // bounds [0.85, 1.3] ke andar clamp kar dete hain — is tarah text
          // poore app mein scale hota hai lekin fixed-height rows/headers
          // overflow nahi karte.
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
          home: const MedRemindShell(),
        );
      },
    );
  }
}
