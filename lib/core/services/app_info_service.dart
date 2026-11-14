import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// ============================================================
/// APP INFO SERVICE — M13
///
/// Real version / build / package name of the installed app
/// (from pubspec.yaml via package_info_plus). Used by:
///   - the force-update check (compare with Remote Config
///     `min_app_version`)
///   - About screen
///   - support tickets (appVersion field)
///
/// If the platform call fails, safe fallbacks are used so the app
/// is never blocked because of this service.
/// ============================================================
class AppInfoService {
  AppInfoService._();
  static final AppInfoService instance = AppInfoService._();

  /// Fallbacks match pubspec.yaml `version: 1.0.0+1`.
  String version = '1.0.0';
  String buildNumber = '1';
  String packageName = '';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version.isNotEmpty ? info.version : version;
      buildNumber = info.buildNumber.isNotEmpty
          ? info.buildNumber
          : buildNumber;
      packageName = info.packageName;
      debugPrint('AppInfoService: v$version+$buildNumber ($packageName)');
    } catch (e) {
      debugPrint('AppInfoService: PackageInfo failed, using fallbacks — $e');
    }
    _initialized = true;
  }
}
