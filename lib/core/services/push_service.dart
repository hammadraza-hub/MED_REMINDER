import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../repositories/device_token_repository.dart';

/// Push notification service seam.
///
/// `LocalOnlyPushService` is the Spark implementation: it registers the FCM
/// token on `users/{uid}/devices/{token}` (client-side, works on Spark) but
/// `sendPush()` is a no-op — server-side push via Cloud Functions is Blaze-only
/// and deferred. When Blaze is added, a `FirebasePushService` can implement
/// this same interface with real `sendPush`; no client UI changes needed.
abstract class PushService {
  /// Registers the FCM token for `uid`. Call after sign-in and after the user
  /// grants notification permission.
  Future<void> registerToken(String uid);

  /// Removes the FCM token for `uid` (e.g. on logout).
  Future<void> removeToken(String uid);

  /// Whether a token is currently registered for `uid`.
  Future<bool> isRegistered(String uid);

  /// Sends a push alert. No-op on Spark; real implementation on Blaze.
  /// `type` is one of: 'dose_missed', 'refill', 'caregiver_alert', 'appointment'.
  Future<void> sendPush({
    required String uid,
    required String type,
    required Map<String, dynamic> data,
  });
}

/// Spark implementation of [PushService].
class LocalOnlyPushService implements PushService {
  LocalOnlyPushService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _currentToken;
  String? _currentUid;

  @override
  Future<void> registerToken(String uid) async {
    try {
      // getToken() is deprecated in firebase_messaging ^17.x (use register() +
      // onRegistered instead), but register() returns void so we still need
      // getToken() to read the current token. Safe to keep using it on this
      // version; migrate when we upgrade firebase_messaging.
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('LocalOnlyPushService: FCM getToken returned null');
        return;
      }

      await DeviceTokenRepository.instance.saveToken(
        uid: uid,
        token: token,
        platform: Platform.operatingSystem, // 'android'
        appVersion:
            '1.0.0', // keep constant; package_info dep avoided per YAGNI
        timezone: DateTime.now().timeZoneName,
      );

      _currentToken = token;
      _currentUid = uid;
      debugPrint('LocalOnlyPushService: FCM token registered for $uid');
    } catch (e) {
      debugPrint('LocalOnlyPushService: registerToken failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeToken(String uid) async {
    if (_currentToken == null || _currentUid != uid) return;
    try {
      await DeviceTokenRepository.instance.removeToken(uid, _currentToken!);
      _currentToken = null;
      _currentUid = null;
      debugPrint('LocalOnlyPushService: FCM token removed for $uid');
    } catch (e) {
      debugPrint('LocalOnlyPushService: removeToken failed: $e');
    }
  }

  @override
  Future<bool> isRegistered(String uid) async {
    if (_currentToken == null) return false;
    return DeviceTokenRepository.instance.isRegistered(uid, _currentToken!);
  }

  @override
  Future<void> sendPush({
    required String uid,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    // No-op on Spark — server-side sendPush is Blaze-only (Cloud Functions).
    debugPrint('LocalOnlyPushService.sendPush: no-op on Spark ($type)');
  }
}

/// Singleton accessor.
PushService get pushService => LocalOnlyPushService();
