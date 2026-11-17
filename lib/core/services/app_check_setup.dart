import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Which App Check providers the app uses. M21 step 5.
///
/// App Check proves to Firebase that a request comes from the real app on a
/// real device, so scripts and modified copies cannot call Firestore with a
/// stolen key. It only protects data once ENFORCEMENT is switched on in the
/// Firebase console (see HANDOFF, M21 step 5); until then it only collects
/// the numbers that show whether it is safe to switch on.
///
/// Rule of thumb:
///  * a normal release build (Play Store / App Store, production): Play
///    Integrity on Android, DeviceCheck on iOS;
///  * a debug build, a build against the emulators, or a TEST build that sets
///    `--dart-define=APP_CHECK_DEBUG=true` (never honoured in production):
///    the debug provider, whose token is added by hand to the console's list.
enum AppCheckKind { debug, production }

class AppCheckPlan {
  const AppCheckPlan({
    required this.kind,
    required this.android,
    required this.apple,
  });

  final AppCheckKind kind;
  final AndroidAppCheckProvider android;
  final AppleAppCheckProvider apple;
}

class AppCheckSetup {
  AppCheckSetup._();

  /// A test build (staging only) can ask for the debug provider.
  static const bool forceDebugFromBuild = bool.fromEnvironment(
    'APP_CHECK_DEBUG',
  );

  /// A fixed debug token for CI or a shared test phone (optional). Without
  /// it the plugin makes a random one and prints it in the log once.
  static const String debugTokenFromBuild = String.fromEnvironment(
    'APP_CHECK_DEBUG_TOKEN',
  );

  /// Pure choice of providers (tested).
  static AppCheckPlan plan({
    required bool debugBuild,
    required bool useEmulator,
    required bool isProduction,
    bool forceDebug = false,
    String? debugToken,
  }) {
    // Production never uses the debug provider, whatever the flags say: a
    // debug token in a production build would be a key to the door.
    final debug = !isProduction && (debugBuild || useEmulator || forceDebug);
    if (debug) {
      final token = (debugToken ?? '').trim();
      return AppCheckPlan(
        kind: AppCheckKind.debug,
        android: AndroidDebugProvider(debugToken: token.isEmpty ? null : token),
        apple: AppleDebugProvider(debugToken: token.isEmpty ? null : token),
      );
    }
    return const AppCheckPlan(
      kind: AppCheckKind.production,
      android: AndroidPlayIntegrityProvider(),
      apple: AppleDeviceCheckProvider(),
    );
  }

  /// Turns App Check on. Never throws and never waits long: the app must start
  /// (also offline, also when the phone cannot be attested). While enforcement
  /// is off a failure costs nothing; when it is on, requests without a token
  /// are refused by the server and the screens show their normal error state.
  static Future<AppCheckPlan> activate({
    required bool useEmulator,
    required bool isProduction,
    Duration limit = const Duration(seconds: 5),
    Future<void> Function(AppCheckPlan plan)? run,
  }) async {
    final chosen = plan(
      debugBuild: kDebugMode,
      useEmulator: useEmulator,
      isProduction: isProduction,
      forceDebug: forceDebugFromBuild,
      debugToken: debugTokenFromBuild,
    );
    try {
      await (run ?? _activateReal)(chosen).timeout(limit);
    } catch (e) {
      debugPrint('AppCheck: activation failed (${e.runtimeType}), going on');
    }
    return chosen;
  }

  static Future<void> _activateReal(AppCheckPlan chosen) async {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: chosen.android,
      providerApple: chosen.apple,
    );
    // Renew the token in the background; no screen waits for it.
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  }
}
