// M22 step 7 — the REAL local alarms on a device / emulator: the scheduler reads
// doses and settings from the local Firestore emulator and sets Android alarms;
// the test counts what the OS holds as pending.
//
// Setup (same as the other integration tests):
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//   adb shell pm grant com.medreminder.app android.permission.POST_NOTIFICATIONS
//   adb shell cmd appops set com.medreminder.app SCHEDULE_EXACT_ALARM allow
//
// Run (Android emulator):
//   flutter test integration_test/reminder_scheduler_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/profile/profile_controller.dart';
import 'package:med_remind_app/core/services/reminder_scheduler.dart';
import 'package:med_remind_app/models/notification_settings.dart';
import 'package:med_remind_app/repositories/settings_repository.dart';

const _host = '10.0.2.2';

Future<void> _rest(
  String method,
  String path, [
  Map<String, dynamic>? body,
]) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(
      method,
      Uri.parse(
        'http://$_host:8080/v1/projects/medapp-staging/databases/(default)'
        '/documents/$path',
      ),
    );
    req.headers
      ..set('Authorization', 'Bearer owner')
      ..set('Content-Type', 'application/json');
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close();
    await res.drain<void>();
    expect(res.statusCode, 200, reason: '$method $path');
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> _s(String v) => {'stringValue': v};
Map<String, dynamic> _t(DateTime t) => {
  'timestampValue': t.toUtc().toIso8601String(),
};

NotificationSettings _settings({
  bool doseEnabled = true,
  int escalation = 10,
}) => NotificationSettings(
  doseEnabled: doseEnabled,
  refillEnabled: true,
  caregiverEnabled: true,
  escalationMinutes: escalation,
  quietHoursEnabled: true, // ON: it must NOT move or stop dose reminders
  quietStartHour: 0,
  quietStartMinute: 0,
  quietEndHour: 23,
  quietEndMinute: 59,
  hideMedicineNamesOnLockScreen: true,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String uid;
  late String pid;

  Future<void> putDose(
    String id,
    Duration fromNow, {
    String status = 'pending',
    int missMin = 60,
  }) {
    final at = DateTime.now().add(fromNow);
    return _rest('PATCH', 'profiles/$pid/doses/$id', {
      'fields': {
        'profileId': _s(pid),
        'medicationId': _s('m'),
        'medName': _s('Alarm test'),
        'doseLabel': _s('1 tablet'),
        'status': _s(status),
        'scheduledAt': _t(at),
        'missDeadline': _t(at.add(Duration(minutes: missMin))),
        'createdAt': _t(DateTime.now()),
      },
    });
  }

  Future<int> reschedule() async {
    await ReminderScheduler.instance.rescheduleAll();
    return ReminderScheduler.instance.pendingCount();
  }

  setUpAll(() async {
    expect(
      const bool.fromEnvironment('USE_EMULATOR'),
      isTrue,
      reason: 'Run with --dart-define=USE_EMULATOR=true (emulators only)',
    );
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    await FirebaseAuth.instance.signOut();
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'owner2@example.com',
      password: 'Test1234!',
    );
    uid = cred.user!.uid;

    pid = 'rs_${DateTime.now().microsecondsSinceEpoch}';
    await _rest('PATCH', 'profiles/$pid', {
      'fields': {
        'ownerUid': _s(uid),
        'kind': _s('dependent'),
        'name': _s('Alarm test'),
        'timezone': _s('Asia/Karachi'),
        'missedAfterMin': {'integerValue': '60'},
        'roles': {
          'mapValue': {
            'fields': {uid: _s('owner')},
          },
        },
        'memberUids': {
          'arrayValue': {
            'values': [_s(uid)],
          },
        },
        'healthUids': {
          'arrayValue': {
            'values': [_s(uid)],
          },
        },
        'permissions': {'mapValue': <String, dynamic>{}},
      },
    });
    await ProfileController.instance.selectProfile(
      memberId: pid,
      displayName: 'Alarm test',
    );
    await ReminderScheduler.instance.init();
    await SettingsRepository.instance.saveSettings(uid, _settings());
  });

  tearDownAll(() async {
    await SettingsRepository.instance.saveSettings(
      uid,
      NotificationSettings.defaults,
    );
  });

  test(
    '3 pending doses = 3 reminders + 3 escalations each = 12 alarms',
    () async {
      await putDose('m_a', const Duration(minutes: 20));
      await putDose('m_b', const Duration(minutes: 90));
      await putDose('m_c', const Duration(hours: 5));
      expect(await reschedule(), 12);
    },
  );

  test('a second reschedule does not duplicate alarms', () async {
    expect(await reschedule(), 12);
    expect(await reschedule(), 12);
  });

  test('a taken dose loses its alarms', () async {
    await _rest(
      'PATCH',
      'profiles/$pid/doses/m_a?updateMask.fieldPaths=status',
      {
        'fields': {'status': _s('taken')},
      },
    );
    expect(await reschedule(), 8);
  });

  test('a dose beyond 48 hours gets no alarm yet', () async {
    await putDose('m_far', const Duration(hours: 50));
    expect(await reschedule(), 8);
  });

  test('a short miss window cuts the escalations', () async {
    // 25 min to the deadline: repeats at +10 and +20 only (30 is too late).
    await putDose('m_short', const Duration(hours: 3), missMin: 25);
    expect(await reschedule(), 8 + 3);
  });

  test('dose reminders switched off: nothing is scheduled', () async {
    await SettingsRepository.instance.saveSettings(
      uid,
      _settings(doseEnabled: false),
    );
    expect(await reschedule(), 0);
  });

  test(
    'switched on again: they come back (quiet hours do not matter)',
    () async {
      await SettingsRepository.instance.saveSettings(uid, _settings());
      expect(await reschedule(), 11);
    },
  );

  // Device check (run with --dart-define=FIRE=true): one dose 60 s ahead; the
  // test waits for the OS alarm to fire and looks for the posted notification.
  // The lock-screen text must not contain the medicine name (privacy on).
  test(
    'FIRE: the OS alarm posts the reminder on time, without the medicine name',
    () async {
      await putDose('m_fire', const Duration(seconds: 60), missMin: 30);
      expect(await reschedule(), greaterThanOrEqualTo(1));
      await Future<void>.delayed(const Duration(seconds: 85));
      final active = await FlutterLocalNotificationsPlugin()
          .getActiveNotifications();
      final fired = active.where((n) => n.channelId == 'dose_reminders');
      expect(fired, isNotEmpty, reason: 'the alarm did not fire');
      for (final n in fired) {
        expect('${n.title} ${n.body}'.contains('Alarm test'), isFalse);
      }
    },
    skip: !const bool.fromEnvironment('FIRE'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
