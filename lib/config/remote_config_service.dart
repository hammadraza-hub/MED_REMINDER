import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/app_gate.dart';
import '../core/services/app_info_service.dart';

/// ============================================================
/// REMOTE CONFIG SERVICE
///
/// Firebase Remote Config se values fetch karta hai aur cached
/// rakhta hai. Agar Firebase unavailable ho, to local defaults
/// use hote hain (graceful fallback).
///
/// Usage:
///   await RemoteConfigService.instance.initialize();
///   if (RemoteConfigService.instance.aiAssistantEnabled) { ... }
/// ============================================================
class RemoteConfigService {
  // ─────────────────────────────────────────────────────────
  // Singleton
  // ─────────────────────────────────────────────────────────
  static final RemoteConfigService instance = RemoteConfigService._();
  RemoteConfigService._();

  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  // ─────────────────────────────────────────────────────────
  // Parameter Keys (Firebase Console se match karne chahiye)
  // ─────────────────────────────────────────────────────────
  static const String _kAiAssistantEnabled = 'ai_assistant_enabled';
  static const String _kMaxMedicationsPerProfile =
      'max_medications_per_profile';
  static const String _kDefaultReminderMinutes = 'default_reminder_minutes';
  static const String _kMinAppVersion = 'min_app_version';
  static const String _kMaintenanceMode = 'maintenance_mode';
  // M13 — legal versions + disclaimer (plan: terms_version, privacy_version,
  // disclaimer_text). min_app_version above is the plan's min_supported_version.
  static const String _kTermsVersion = 'terms_version';
  static const String _kPrivacyVersion = 'privacy_version';
  static const String _kDisclaimerText = 'disclaimer_text';

  // ─────────────────────────────────────────────────────────
  // Default Values (Firebase se fetch fail ho to fallback)
  // ─────────────────────────────────────────────────────────
  static const bool _defaultAiAssistantEnabled = false;
  static const int _defaultMaxMedicationsPerProfile = 50;
  static const int _defaultDefaultReminderMinutes = 30;
  static const String _defaultMinAppVersion = '1.0.0';
  static const bool _defaultMaintenanceMode = false;
  static const String _defaultTermsVersion = '1.0';
  static const String _defaultPrivacyVersion = '1.0';
  static const String _defaultDisclaimerText = '';

  // ─────────────────────────────────────────────────────────
  // Public Getters
  // ─────────────────────────────────────────────────────────
  bool get aiAssistantEnabled => _remoteConfig.getBool(_kAiAssistantEnabled);

  int get maxMedicationsPerProfile =>
      _remoteConfig.getInt(_kMaxMedicationsPerProfile);

  int get defaultReminderMinutes =>
      _remoteConfig.getInt(_kDefaultReminderMinutes);

  String get minAppVersion => _remoteConfig.getString(_kMinAppVersion);

  bool get maintenanceMode => _remoteConfig.getBool(_kMaintenanceMode);

  /// Current required Terms / Privacy versions (M13). Compare with
  /// users/{uid}.legal to decide whether to re-prompt acceptance.
  String get termsVersion => _remoteConfig.getString(_kTermsVersion);
  String get privacyVersion => _remoteConfig.getString(_kPrivacyVersion);

  /// Medical disclaimer text editable without an app release.
  /// Empty string -> callers should fall back to the bundled text.
  String get disclaimerText => _remoteConfig.getString(_kDisclaimerText);

  /// Whether the app may be used right now (maintenance / force update).
  /// Fails open: if Remote Config was never initialized the app is allowed.
  AppGateStatus get gateStatus {
    if (!_initialized) return AppGateStatus.ok;
    return AppGate.evaluate(
      currentVersion: AppInfoService.instance.version,
      minVersion: minAppVersion,
      maintenanceMode: maintenanceMode,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Initialize
  // ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    // Config settings — fetch timeout + minimum fetch interval
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Default values set karo (fallback)
    await _remoteConfig.setDefaults({
      _kAiAssistantEnabled: _defaultAiAssistantEnabled,
      _kMaxMedicationsPerProfile: _defaultMaxMedicationsPerProfile,
      _kDefaultReminderMinutes: _defaultDefaultReminderMinutes,
      _kMinAppVersion: _defaultMinAppVersion,
      _kMaintenanceMode: _defaultMaintenanceMode,
      _kTermsVersion: _defaultTermsVersion,
      _kPrivacyVersion: _defaultPrivacyVersion,
      _kDisclaimerText: _defaultDisclaimerText,
    });

    // Fetch + activate (background mein, app block na ho)
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config: fetched and activated');
    } catch (e) {
      debugPrint('⚠️ Remote Config: fetch failed, using defaults — $e');
    }

    _initialized = true;
  }

  // ─────────────────────────────────────────────────────────
  // Manual Refresh (settings screen par "Refresh config" button)
  // ─────────────────────────────────────────────────────────
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config: refreshed');
    } catch (e) {
      debugPrint('⚠️ Remote Config: refresh failed — $e');
    }
  }
}
