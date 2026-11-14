import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dose.dart';
import '../../repositories/dose_repository.dart';
import '../app_exception.dart';

/// ============================================================
/// REMINDER ACTION QUEUE — M8 step 3
/// ============================================================
///
/// Notification buttons (Taken / Skip / Snooze) are handled by a
/// background isolate that has no reliable auth or profile state, so
/// it only records the tap here. [replay] applies it on the next app
/// open or resume — exactly what the M8 spec asks for ("if the isolate
/// is killed before the write syncs, save the action locally and replay
/// it on the next app open").
class ReminderActionQueue {
  ReminderActionQueue._();

  static final ReminderActionQueue instance = ReminderActionQueue._();

  static const String _key = 'reminder_actions_v1';

  /// Snooze length used by the notification button.
  static const int snoozeMinutes = 10;

  /// Retry limit so a permanently failing action cannot wedge the queue.
  static const int _maxAttempts = 10;

  bool _replaying = false;

  /// Records an action taken from a notification. Safe in a background isolate.
  Future<void> enqueue({
    required String doseId,
    required String profileId,
    required String action,
    int? snoozeMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final actions = prefs.getStringList(_key) ?? <String>[];
    actions.add(
      jsonEncode({
        'doseId': doseId,
        'profileId': profileId,
        'action': action,
        'snoozeMinutes': ?snoozeMinutes,
        'attempts': 0,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    await prefs.setStringList(_key, actions);
  }

  /// Applies every queued action. Safe to call repeatedly and concurrently.
  Future<void> replay() async {
    if (_replaying) return;
    _replaying = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued = prefs.getStringList(_key) ?? <String>[];
      if (queued.isEmpty) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // Signed out: keep the queue, it replays after the next sign-in.
        return;
      }

      final remaining = <String>[];
      for (final raw in queued) {
        if (await _apply(raw, uid)) continue;

        final entry = jsonDecode(raw) as Map<String, dynamic>;
        final attempts = (entry['attempts'] as int? ?? 0) + 1;
        if (attempts >= _maxAttempts) {
          debugPrint(
            'ReminderActionQueue: dropping $raw after $_maxAttempts attempts',
          );
          continue;
        }
        entry['attempts'] = attempts;
        remaining.add(jsonEncode(entry));
      }

      await prefs.setStringList(_key, remaining);
      final applied = queued.length - remaining.length;
      if (applied > 0) {
        debugPrint(
          'ReminderActionQueue: applied $applied action(s), '
          '${remaining.length} pending',
        );
      }
    } finally {
      _replaying = false;
    }
  }

  /// Returns true when the entry should be removed from the queue.
  Future<bool> _apply(String raw, String uid) async {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return true; // corrupt entry — drop it
    }

    final doseId = data['doseId'] as String;
    final profileId = data['profileId'] as String;
    final action = data['action'] as String;
    final repository = DoseRepository.instance;

    try {
      switch (action) {
        case 'taken':
          await repository.logDose(
            profileId: profileId,
            doseId: doseId,
            status: DoseStatus.taken,
            loggedBy: uid,
          );
        case 'skipped':
          await repository.logDose(
            profileId: profileId,
            doseId: doseId,
            status: DoseStatus.skipped,
            loggedBy: uid,
            reasonCode: MissedDoseReason.forgot,
          );
        case 'snooze':
          await repository.snoozeDose(
            profileId: profileId,
            doseId: doseId,
            snoozeDuration: Duration(
              minutes: data['snoozeMinutes'] as int? ?? snoozeMinutes,
            ),
          );
        default:
          return true; // unknown action — drop it
      }
      debugPrint('ReminderActionQueue: $action applied to $doseId');
      return true;
    } on AppException catch (e) {
      // notFound: dose deleted. validation: malformed ids/fields — retrying
      // will never succeed.
      if (e.type == AppExceptionType.notFound ||
          e.type == AppExceptionType.validation) {
        return true;
      }
      debugPrint('ReminderActionQueue: $action failed on $doseId: $e');
      return false;
    } catch (e) {
      debugPrint('ReminderActionQueue: $action failed on $doseId: $e');
      return false;
    }
  }
}
