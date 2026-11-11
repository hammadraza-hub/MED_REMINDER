import 'package:cloud_firestore/cloud_firestore.dart';

/// Persists FCM device tokens on `users/{uid}/devices/{token}`.
///
/// Spark-compatible: the client writes the token document itself. The
/// server-side `sendPush` (Cloud Functions) is Blaze-only and deferred —
/// this repository only handles client-side token registration.
///
/// Fields per M8 spec: platform, appVersion, timezone, lastSeen.
class DeviceTokenRepository {
  DeviceTokenRepository._(this._db);

  static DeviceTokenRepository? _instance;
  static DeviceTokenRepository get instance =>
      _instance ??= DeviceTokenRepository._(FirebaseFirestore.instance);

  final FirebaseFirestore _db;

  DocumentReference _tokenDoc(String uid, String token) =>
      _db.collection('users').doc(uid).collection('devices').doc(token);

  /// Saves (or merges) the FCM token for `uid`.
  Future<void> saveToken({
    required String uid,
    required String token,
    String platform = 'android',
    String appVersion = '1.0.0',
    String? timezone,
  }) async {
    final data = <String, dynamic>{
      'platform': platform,
      'appVersion': appVersion,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (timezone != null) data['timezone'] = timezone;

    await _tokenDoc(uid, token).set(data, SetOptions(merge: true));
  }

  /// Removes the FCM token (e.g. on logout).
  Future<void> removeToken(String uid, String token) async {
    await _tokenDoc(uid, token).delete();
  }

  /// Whether `token` is registered for `uid`.
  Future<bool> isRegistered(String uid, String token) async {
    final snap = await _tokenDoc(uid, token).get();
    return snap.exists;
  }
}
