import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/app_preferences.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/settings_repository.dart';
import '../accessibility/accessibility_controller.dart';
import '../locale/locale_controller.dart';

/// ============================================================
/// PREFERENCES SYNC SERVICE — M13 step 3
///
/// Keeps language + accessibility preferences in sync between this
/// device and `users/{uid}.settings`, so they follow the user to a new
/// phone.
///
/// On sign-in (attach):
///   1. read the server preferences,
///   2. apply those that exist to the local controllers (server wins),
///   3. push local values the user customised on this device for fields
///      the server has no value for yet (one-time seeding; defaults are
///      never pushed, so a fresh device can't overwrite another device),
///   4. then listen to the controllers and push every later change.
///
/// Everything is best-effort and never blocks the UI: if the server is
/// unreachable the app keeps using the local values and the next sign-in
/// or app start tries again. Local changes are debounced and only the
/// changed fields are written (dotted paths), so notification settings in
/// the same map are never overwritten.
/// ============================================================
class PreferencesSyncService {
  PreferencesSyncService._();
  static final PreferencesSyncService instance = PreferencesSyncService._();

  static const Duration _pullTimeout = Duration(seconds: 8);
  static const Duration _pushDebounce = Duration(milliseconds: 600);

  /// App defaults, used to decide what counts as "customised".
  static const AppPreferences _defaults = AppPreferences(
    language: 'en',
    textSizeIndex: AccessibilityController.defaultIndex,
    highContrast: AccessibilityController.defaultHighContrast,
    simplifiedMode: AccessibilityController.defaultSimplifiedMode,
    voiceInput: AccessibilityController.defaultVoiceInput,
  );

  StreamSubscription<User?>? _authSub;
  String? _uid;
  AppPreferences _synced = const AppPreferences();
  bool _applying = false;
  Timer? _debounce;

  /// Start following the signed-in user. Call once at startup, after
  /// Firebase is initialised.
  void start() {
    _authSub ??= AuthRepository.instance.authStateChanges.listen((user) {
      if (user == null) {
        _detach();
      } else if (user.uid != _uid) {
        unawaited(_attach(user.uid));
      }
    }, onError: (Object e) => debugPrint('PreferencesSync: auth error — $e'));
  }

  AppPreferences _readLocal() => AppPreferences(
    language: LocaleController.instance.localeCode,
    textSizeIndex: AccessibilityController.instance.textSizeIndex,
    highContrast: AccessibilityController.instance.highContrast,
    simplifiedMode: AccessibilityController.instance.simplifiedMode,
    voiceInput: AccessibilityController.instance.voiceInput,
  );

  Future<void> _attach(String uid) async {
    _detach();
    try {
      final remote = await SettingsRepository.instance
          .getAppPreferences(uid)
          .timeout(_pullTimeout);

      // Signed out / switched user while we were waiting.
      if (AuthRepository.instance.currentUid != uid) return;

      final local = _readLocal();

      // 2. Server wins for fields it has.
      await _applyToControllers(remote);

      // 3. Seed server with customised local values it doesn't have.
      final seed = local.seedFor(remote: remote, defaults: _defaults);
      if (!seed.isEmpty) {
        try {
          await SettingsRepository.instance.saveAppPreferences(uid, seed);
        } catch (e) {
          debugPrint('PreferencesSync: seeding failed — $e');
        }
      }

      _uid = uid;
      _synced = local.overlay(remote);
      LocaleController.instance.addListener(_onLocalChange);
      AccessibilityController.instance.addListener(_onLocalChange);
      debugPrint('PreferencesSync: attached ($_synced)');
    } catch (e) {
      // Offline / timeout: keep local values, retry on next sign-in/start.
      debugPrint('PreferencesSync: pull failed, keeping local — $e');
    }
  }

  void _detach() {
    _debounce?.cancel();
    LocaleController.instance.removeListener(_onLocalChange);
    AccessibilityController.instance.removeListener(_onLocalChange);
    _uid = null;
    _synced = const AppPreferences();
  }

  Future<void> _applyToControllers(AppPreferences p) async {
    _applying = true;
    try {
      if (p.language != null) {
        await LocaleController.instance.setLocaleCode(p.language!);
      }
      if (p.textSizeIndex != null) {
        await AccessibilityController.instance.setTextSizeIndex(
          p.textSizeIndex!,
        );
      }
      if (p.highContrast != null) {
        await AccessibilityController.instance.setHighContrast(p.highContrast!);
      }
      if (p.simplifiedMode != null) {
        await AccessibilityController.instance.setSimplifiedMode(
          p.simplifiedMode!,
        );
      }
      if (p.voiceInput != null) {
        await AccessibilityController.instance.setVoiceInput(p.voiceInput!);
      }
    } finally {
      _applying = false;
    }
  }

  void _onLocalChange() {
    if (_applying || _uid == null) return;
    _debounce?.cancel();
    _debounce = Timer(_pushDebounce, _push);
  }

  Future<void> _push() async {
    final uid = _uid;
    if (uid == null) return;
    final current = _readLocal();
    final changed = current.changedFrom(_synced);
    if (changed.isEmpty) return;
    try {
      await SettingsRepository.instance
          .saveAppPreferences(uid, changed)
          .timeout(const Duration(seconds: 15));
      _synced = _synced.overlay(changed);
    } catch (e) {
      // Not marked as synced, so the next change (or sign-in) retries.
      debugPrint('PreferencesSync: push failed — $e');
    }
  }
}
