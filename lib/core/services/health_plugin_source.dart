import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/firebase_subscription_repository.dart';
import '../../repositories/firebase_vitals_repository.dart';
import '../vitals/health_sync_mapper.dart';
import '../vitals/vital_types.dart';
import 'health_sync_service.dart';

/// ============================================================
/// HEALTH PLUGIN SOURCE — M15 step 7
///
/// The only file that talks to the `health` plugin (Apple Health on iOS,
/// Health Connect on Android). Read-only: the app never writes health data.
/// ============================================================
class PluginHealthDataSource implements HealthDataSource {
  PluginHealthDataSource({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.WEIGHT,
    HealthDataType.HEART_RATE,
  ];

  /// Ask the platform for exactly the canonical units we store.
  static const Map<HealthDataType, HealthDataUnit> _units = {
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        HealthDataUnit.MILLIMETER_OF_MERCURY,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        HealthDataUnit.MILLIMETER_OF_MERCURY,
    HealthDataType.BLOOD_GLUCOSE: HealthDataUnit.MILLIGRAM_PER_DECILITER,
    HealthDataType.WEIGHT: HealthDataUnit.KILOGRAM,
    HealthDataType.HEART_RATE: HealthDataUnit.BEATS_PER_MINUTE,
  };

  @override
  VitalSource get source =>
      Platform.isIOS ? VitalSource.healthKit : VitalSource.healthConnect;

  @override
  Future<HealthAccess> ensureAccess() async {
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }

    if (Platform.isAndroid && !await _health.isHealthConnectAvailable()) {
      return HealthAccess.unavailable;
    }

    // Read permission only.
    final granted = await _health.requestAuthorization(
      _types,
      permissions: List.filled(_types.length, HealthDataAccess.READ),
    );
    return granted ? HealthAccess.granted : HealthAccess.denied;
  }

  @override
  Future<List<RawHealthSample>> read(DateTime from, DateTime to) async {
    final points = await _health.getHealthDataFromTypes(
      types: _types,
      startTime: from,
      endTime: to,
      preferredUnits: _units,
    );

    final out = <RawHealthSample>[];
    for (final p in points) {
      final kind = _kindOf(p.type);
      final value = p.value;
      if (kind == null || value is! NumericHealthValue) continue;

      out.add(
        RawHealthSample(
          kind: kind,
          value: value.numericValue.toDouble(),
          from: p.dateFrom,
          uuid: p.uuid,
        ),
      );
    }
    return out;
  }

  static HealthSampleKind? _kindOf(HealthDataType type) {
    switch (type) {
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        return HealthSampleKind.systolic;
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return HealthSampleKind.diastolic;
      case HealthDataType.BLOOD_GLUCOSE:
        return HealthSampleKind.glucose;
      case HealthDataType.WEIGHT:
        return HealthSampleKind.weight;
      case HealthDataType.HEART_RATE:
        return HealthSampleKind.heartRate;
      default:
        return null;
    }
  }
}

/// Remembers the last successful sync per signed-in user and profile, on this
/// device only.
class PrefsHealthSyncStateStore implements HealthSyncStateStore {
  String _key(String memberId) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    return 'health_sync_last_${uid}_$memberId';
  }

  @override
  Future<DateTime?> lastSync(String memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_key(memberId));
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null; // worst case: the first-sync window is read again
    }
  }

  @override
  Future<void> saveLastSync(String memberId, DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(memberId), at.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Health sync: could not save the sync time — $e');
    }
  }
}

/// Debug builds only: `--dart-define=HEALTH_SYNC_DEBUG_UNLOCK=true` skips the
/// Pro check so the feature can be tried without a subscription. It is a
/// compile-time constant guarded by [kDebugMode], so it can never be active in
/// a release build.
const bool _debugUnlock = bool.fromEnvironment('HEALTH_SYNC_DEBUG_UNLOCK');

Future<bool> _isPro() async {
  if (kDebugMode && _debugUnlock) return true;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  try {
    return await FirebaseSubscriptionRepository.instance.hasPremiumAccess(uid);
  } catch (_) {
    return false; // fail closed
  }
}

/// The real wiring used by the app.
HealthSyncService buildHealthSyncService() => HealthSyncService(
  source: PluginHealthDataSource(),
  store: PrefsHealthSyncStateStore(),
  isPro: _isPro,
  importer: FirebaseVitalsRepository.instance.importSynced,
);
