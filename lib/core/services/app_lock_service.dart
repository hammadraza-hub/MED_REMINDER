import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_lock_policy.dart';

/// Talks to the phone's biometric / device-credential prompt.
/// Abstracted so the service can be tested without a device.
abstract class AppLockAuthenticator {
  /// True if the phone can authenticate (biometrics or a screen lock/PIN).
  Future<bool> isSupported();

  /// Shows the system prompt. Returns true only if the user authenticated.
  Future<bool> authenticate(String reason);
}

/// Real implementation on top of `local_auth`. Device PIN / pattern is
/// allowed as a fallback (biometricOnly: false) so users are not locked out
/// when their fingerprint stops working.
class LocalAuthAuthenticator implements AppLockAuthenticator {
  LocalAuthAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('AppLock: isDeviceSupported failed — $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } catch (e) {
      // Cancelled, too many attempts, no credentials, etc.
      debugPrint('AppLock: authenticate failed — $e');
      return false;
    }
  }
}

enum AppLockEnableResult { enabled, unsupported, failed }

/// ============================================================
/// APP LOCK SERVICE — M13 step 6
///
/// Optional biometric / device-credential lock for opening the app.
/// The on/off choice is stored ONLY on this device (SharedPreferences),
/// never on the server.
///
/// When locked, a full-screen overlay (AppLockGate) covers the app until
/// [unlock] succeeds. WHEN it locks is decided by [AppLockPolicy]:
/// every cold start, and after more than 30 s in the background.
/// Reminders / notification actions do not go through the UI and are not
/// affected.
/// ============================================================
class AppLockService extends ChangeNotifier with WidgetsBindingObserver {
  AppLockService({
    AppLockAuthenticator? authenticator,
    DateTime Function()? clock,
    bool Function()? isSignedIn,
  }) : _authenticator = authenticator ?? LocalAuthAuthenticator(),
       _clock = clock ?? DateTime.now,
       _isSignedIn = isSignedIn ?? (() => false);

  /// App-wide instance. [isSignedIn] is injected in `main.dart`.
  static final AppLockService instance = AppLockService();

  static const String _enabledKey = 'app_lock_enabled';

  final AppLockAuthenticator _authenticator;
  final DateTime Function() _clock;
  bool Function() _isSignedIn;

  bool _enabled = false;
  bool _locked = false;
  bool _initialized = false;
  bool _authenticating = false;
  DateTime? _backgroundedAt;

  bool get enabled => _enabled;
  bool get locked => _locked;

  /// Lets `main.dart` provide the signed-in check after Firebase is ready.
  void bindSignedIn(bool Function() isSignedIn) => _isSignedIn = isSignedIn;

  /// Loads the saved choice and decides the cold-start lock state.
  /// Call once at startup (after Firebase init, before runApp).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      debugPrint('AppLock: could not read setting — $e');
      _enabled = false;
    }

    // The phone lost its screen lock / biometrics since the lock was turned
    // on: never trap the user behind a prompt that cannot succeed.
    if (_enabled && !await _authenticator.isSupported()) {
      await _persist(false);
      _enabled = false;
    }

    _locked = AppLockPolicy.lockOnColdStart(
      enabled: _enabled,
      signedIn: _isSignedIn(),
    );

    WidgetsBinding.instance.addObserver(this);
    notifyListeners();
  }

  Future<void> _persist(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (e) {
      debugPrint('AppLock: could not save setting — $e');
    }
  }

  /// True if this phone can show a biometric / PIN prompt.
  Future<bool> isSupported() => _authenticator.isSupported();

  /// Turns the lock on after the user proves it is them (so they cannot lock
  /// themselves out on a phone that cannot authenticate).
  Future<AppLockEnableResult> enable(String reason) async {
    if (!await _authenticator.isSupported()) {
      return AppLockEnableResult.unsupported;
    }
    if (!await _runAuth(reason)) return AppLockEnableResult.failed;
    _enabled = true;
    await _persist(true);
    notifyListeners();
    return AppLockEnableResult.enabled;
  }

  /// Turns the lock off (requires authentication). Returns false if the user
  /// did not authenticate and the lock stays on.
  Future<bool> disable(String reason) async {
    if (!await _runAuth(reason)) return false;
    _enabled = false;
    _locked = false;
    await _persist(false);
    notifyListeners();
    return true;
  }

  /// Shows the prompt to unlock. Returns true if unlocked.
  Future<bool> unlock(String reason) async {
    if (!_locked) return true;
    if (!await _runAuth(reason)) return false;
    _locked = false;
    _backgroundedAt = null;
    notifyListeners();
    return true;
  }

  /// While the system prompt is up the app briefly changes lifecycle state;
  /// those changes must not be mistaken for "went to the background".
  Future<bool> _runAuth(String reason) async {
    _authenticating = true;
    try {
      return await _authenticator.authenticate(reason);
    } finally {
      _authenticating = false;
    }
  }

  /// Call when the signed-in state changes. Signing out removes the lock
  /// (nothing left to protect). Signing in does NOT lock: the user just
  /// authenticated with their password.
  void handleAuthChanged(bool signedIn) {
    if (!signedIn && _locked) {
      _locked = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundedAt ??= _clock();
      case AppLifecycleState.resumed:
        final shouldLock = AppLockPolicy.lockOnResume(
          enabled: _enabled,
          signedIn: _isSignedIn(),
          backgroundedAt: _backgroundedAt,
          now: _clock(),
        );
        _backgroundedAt = null;
        if (shouldLock && !_locked) {
          _locked = true;
          notifyListeners();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @visibleForTesting
  void debugSetState({bool? enabled, bool? locked}) {
    if (enabled != null) _enabled = enabled;
    if (locked != null) _locked = locked;
    notifyListeners();
  }
}
