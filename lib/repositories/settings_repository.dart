/// Persists notification / reminder preferences on `users/{uid}.settings`.
///
/// `settings` is a Firestore `map` field on the user document (not a
/// subcollection) — `firestore.rules` `validUserUpdate()` already allows it,
/// so no rules change is needed for step 5a.
///
/// Reads fall back to `NotificationSettings.defaults` when the document or
/// the `settings` field is missing (first launch), so the app never throws
/// just because preferences haven't been saved yet.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/notification_settings.dart';

class SettingsRepository {
  SettingsRepository._(this._db);

  static SettingsRepository? _instance;
  static SettingsRepository get instance =>
      _instance ??= SettingsRepository._(FirebaseFirestore.instance);

  final FirebaseFirestore _db;

  /// Document path: `users/{uid}`.
  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  /// Load preferences for `uid`. Never throws — missing doc/field = defaults.
  Future<NotificationSettings> getSettings(String uid) async {
    try {
      final snap = await _userDoc(uid).get();
      if (!snap.exists) return NotificationSettings.defaults;
      final data = snap.data() as Map<String, dynamic>?;
      final settings = data?['settings'];
      if (settings == null || settings is! Map) {
        return NotificationSettings.defaults;
      }
      return NotificationSettings.fromMap(Map<String, dynamic>.from(settings));
    } on FirebaseException catch (e) {
      // Offline / permission hiccup — degrade to defaults, keep app usable.
      debugPrint('SettingsRepository: getSettings failed: $e');
      return NotificationSettings.defaults;
    }
  }

  /// Save preferences for `uid`. Merges only the `settings` field.
  Future<void> saveSettings(String uid, NotificationSettings settings) async {
    try {
      await _userDoc(uid).update({'settings': settings.toMap()});
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
