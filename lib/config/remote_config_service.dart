import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

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

  // ─────────────────────────────────────────────────────────
  // Default Values (Firebase se fetch fail ho to fallback)
  // ─────────────────────────────────────────────────────────
  static const bool _defaultAiAssistantEnabled = false;
  static const int _defaultMaxMedicationsPerProfile = 50;
  static const int _defaultDefaultReminderMinutes = 30;
  static const String _defaultMinAppVersion = '1.0.0';
  static const bool _defaultMaintenanceMode = false;

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
