// M22 step 6 — the caregiver loop and one end-to-end run, through the real
// repositories and the real firestore.rules on the LOCAL emulators.
//
// Loop: the owner adds a medicine -> doses appear -> a caregiver logs one as
// taken and snoozes another -> the owner sees who did it -> a viewer cannot
// log -> a stranger cannot even read -> an overdue dose is closed as missed.
// End to end: medicine -> doses -> taken -> history -> streak -> reminder plan.
//
// Setup (same as the other integration tests):
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//
// Run (Android emulator):
//   flutter test integration_test/caregiver_loop_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/core/dose_zone.dart';
import 'package:med_remind_app/core/reminders/dose_alarm_planner.dart';
import 'package:med_remind_app/core/streak_calculator.dart';
import 'package:med_remind_app/models/dose.dart';
import 'package:med_remind_app/models/medication.dart';
import 'package:med_remind_app/models/schedule.dart';
import 'package:med_remind_app/repositories/dose_repository.dart';
import 'package:med_remind_app/repositories/medication_repository.dart';

const _host = '10.0.2.2';

FirebaseFirestore get db => FirebaseFirestore.instance;

Future<String> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
  return cred.user!.uid;
}

/// Admin REST call on the emulator (no rules).
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
Map<String, dynamic> _strings(List<String> v) => {
  'arrayValue': {
    'values': [for (final x in v) _s(x)],
  },
};

/// A throw-away profile. [roles] maps uid -> role; [perms] uid -> permissions.
Future<void> _makeProfile(
  String id, {
  required String owner,
  Map<String, String> roles = const {},
  Map<String, Map<String, bool>> perms = const {},
}) async {
  final all = {owner: 'owner', ...roles};
  await _rest('PATCH', 'profiles/$id', {
    'fields': {
      'ownerUid': _s(owner),
      'kind': _s('dependent'),
      'name': _s('Loop test'),
      'timezone': _s('Asia/Karachi'),
      'missedAfterMin': {'integerValue': '30'},
      'roles': {
        'mapValue': {
          'fields': {for (final e in all.entries) e.key: _s(e.value)},
        },
      },
      'memberUids': _strings(all.keys.toList()),
      'healthUids': _strings(all.keys.toList()),
      'permissions': {
        'mapValue': {
          'fields': {
            for (final e in perms.entries)
              e.key: {
                'mapValue': {
                  'fields': {
                    for (final p in e.value.entries)
                      p.key: {'booleanValue': p.value},
                  },
                },
              },
          },
        },
      },
    },
  });
}

Medication _daily(String profileId, String uid, List<String> times) {
  final now = DateTime.now();
  return Medication(
    id: '',
    profileId: profileId,
    name: 'Loop medicine',
    strength: '10mg',
    form: 'tablet',
    doseAmount: 1,
    doseUnit: 'tablet',
    schedule: Schedule(
      type: ScheduleType.daily,
      times: times,
      startDate: DateTime(now.year, now.month, now.day),
    ),
    createdAt: now,
    createdBy: uid,
    updatedAt: now,
    updatedBy: uid,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String owner;
  late String caregiver;
  late String viewer;

  setUpAll(() async {
    expect(
      const bool.fromEnvironment('USE_EMULATOR'),
      isTrue,
      reason: 'Run with --dart-define=USE_EMULATOR=true (emulators only)',
    );
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    owner = await _signIn('owner2@example.com');
    caregiver = await _signIn('care@example.com');
    viewer = await _signIn('mod@example.com');
    DoseZone.ensureData();
  });

  String newId(String p) => '${p}_${DateTime.now().microsecondsSinceEpoch}';

  Future<List<Dose>> dosesOf(String pid) =>
      DoseRepository.instance.getDosesForDateRange(
        pid,
        DateTime.now(),
        DateTime.now().add(const Duration(days: 2)),
      );

  test('caregiver loop: owner adds, caregiver logs, owner sees who', () async {
    final pid = newId('cl');
    await _makeProfile(
      pid,
      owner: owner,
      roles: {caregiver: 'caregiver'},
      perms: {
        caregiver: {'logDoses': true, 'editMedications': false},
      },
    );

    // 1. The owner adds a medicine: 15 days x 2 doses.
    await _signIn('owner2@example.com');
    final medId = await MedicationRepository.instance.createMedication(
      profileId: pid,
      medication: _daily(pid, owner, ['07:00', '21:00']),
    );
    final all = await db
        .collection('profiles')
        .doc(pid)
        .collection('doses')
        .where('medicationId', isEqualTo: medId)
        .get();
    expect(all.docs.length, 30);

    // 2. The caregiver sees the doses and logs one as taken, snoozes another.
    await _signIn('care@example.com');
    final seen = await dosesOf(pid);
    expect(seen.length, greaterThanOrEqualTo(2));
    final first = seen.first;
    final second = seen[1];

    await DoseRepository.instance.logDose(
      profileId: pid,
      doseId: first.id,
      status: DoseStatus.taken,
      loggedBy: caregiver,
    );
    await DoseRepository.instance.snoozeDose(
      profileId: pid,
      doseId: second.id,
      snoozeDuration: const Duration(minutes: 10),
    );

    // 3. The owner sees who did it.
    await _signIn('owner2@example.com');
    final taken = await DoseRepository.instance.getDose(pid, first.id);
    expect(taken!.status, DoseStatus.taken);
    expect(taken.loggedBy, caregiver, reason: 'the caregiver is recorded');
    final snoozed = await DoseRepository.instance.getDose(pid, second.id);
    expect(snoozed!.snoozedUntil, isNotNull);
    expect(snoozed.status, isNot(DoseStatus.taken));

    // 4. The caregiver has no editMedications: cannot add a medicine.
    await _signIn('care@example.com');
    await expectLater(
      MedicationRepository.instance.createMedication(
        profileId: pid,
        medication: _daily(pid, caregiver, ['09:00']),
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.type,
          'type',
          AppExceptionType.permission,
        ),
      ),
    );

    // 5. Undo by the owner puts the dose back to pending.
    await _signIn('owner2@example.com');
    await DoseRepository.instance.undoDose(profileId: pid, doseId: first.id);
    final undone = await DoseRepository.instance.getDose(pid, first.id);
    expect(undone!.status, DoseStatus.pending);
  });

  test('a viewer reads but cannot log; a stranger cannot read', () async {
    final pid = newId('vw');
    await _makeProfile(pid, owner: owner, roles: {viewer: 'viewer'});
    await _signIn('owner2@example.com');
    await MedicationRepository.instance.createMedication(
      profileId: pid,
      medication: _daily(pid, owner, ['08:00']),
    );

    await _signIn('mod@example.com');
    final seen = await dosesOf(pid);
    expect(seen, isNotEmpty, reason: 'a viewer can read');
    await expectLater(
      DoseRepository.instance.logDose(
        profileId: pid,
        doseId: seen.first.id,
        status: DoseStatus.taken,
        loggedBy: viewer,
      ),
      throwsA(isA<AppException>()),
    );
    final still = await DoseRepository.instance.getDose(pid, seen.first.id);
    expect(still!.status, DoseStatus.pending, reason: 'nothing changed');

    // care@example.com is not a member of this profile.
    await _signIn('care@example.com');
    await expectLater(
      dosesOf(pid),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });

  test('overdue sweep closes only pending doses past their deadline', () async {
    final pid = newId('sw');
    await _makeProfile(pid, owner: owner);
    await _signIn('owner2@example.com');

    String ts(DateTime t) => t.toUtc().toIso8601String();
    Future<void> put(String id, String status, DateTime deadline) =>
        _rest('PATCH', 'profiles/$pid/doses/$id', {
          'fields': {
            'profileId': _s(pid),
            'medicationId': _s('m'),
            'medName': _s('Sweep'),
            'status': _s(status),
            'scheduledAt': {
              'timestampValue': ts(deadline.subtract(const Duration(hours: 1))),
            },
            'missDeadline': {'timestampValue': ts(deadline)},
            'createdAt': {'timestampValue': ts(DateTime.now())},
          },
        });

    final past = DateTime.now().subtract(const Duration(hours: 3));
    final future = DateTime.now().add(const Duration(hours: 3));
    await put('m_old_pending', 'pending', past);
    await put('m_old_taken', 'taken', past);
    await put('m_future_pending', 'pending', future);

    final n = await DoseRepository.instance.markOverdueDosesMissed(pid);
    expect(n, 1);

    Future<String?> statusOf(String id) async =>
        (await db
                    .collection('profiles')
                    .doc(pid)
                    .collection('doses')
                    .doc(id)
                    .get())
                .data()?['status']
            as String?;
    expect(await statusOf('m_old_pending'), 'missed');
    expect(await statusOf('m_old_taken'), 'taken');
    expect(await statusOf('m_future_pending'), 'pending');

    // A second run has nothing left to do.
    expect(await DoseRepository.instance.markOverdueDosesMissed(pid), 0);
  });

  test(
    'end to end: medicine -> doses -> taken -> history -> streak -> reminders',
    () async {
      final pid = newId('e2e');
      await _makeProfile(pid, owner: owner);
      await _signIn('owner2@example.com');

      // Two doses a day, one of them already past today (00:01), one later.
      final medId = await MedicationRepository.instance.createMedication(
        profileId: pid,
        medication: _daily(pid, owner, ['00:01', '23:58']),
      );

      final docs = await db
          .collection('profiles')
          .doc(pid)
          .collection('doses')
          .where('medicationId', isEqualTo: medId)
          .get();
      expect(docs.docs.length, 30);

      // Take today's 00:01 dose.
      final today = (await dosesOf(pid))
          .where((d) => d.medicationId == medId)
          .toList();
      final early = today.firstWhere((d) => d.id.endsWith('0001'));
      await DoseRepository.instance.logDose(
        profileId: pid,
        doseId: early.id,
        status: DoseStatus.taken,
        loggedBy: owner,
      );

      // History -> streak. Today has one taken and one pending that is not
      // due yet: a good day, nothing missed.
      final history = await DoseRepository.instance.getDosesForDateRange(
        pid,
        DateTime.now(),
        DateTime.now(),
      );
      final streak = StreakCalculator.compute(history, now: DateTime.now());
      expect(streak.totalTaken, 1);
      expect(streak.current, 1);

      // Reminders: the planner makes alarms from what is stored; the dose that
      // was taken gets none, and nothing is scheduled in the past.
      final now = DateTime.now();
      final plan = DoseAlarmPlanner.plan(
        doses: await DoseRepository.instance.getDosesForDateRange(
          pid,
          now,
          now.add(const Duration(days: 2)),
        ),
        now: now,
        escalationMinutes: 10,
        doseEnabled: true,
        maxAlarms: DoseAlarmPlanner.iosAlarmCap,
      );
      expect(plan, isNotEmpty);
      expect(plan.every((a) => a.at.isAfter(now)), isTrue);
      expect(plan.any((a) => a.dose.id == early.id), isFalse);
      expect(plan.length, lessThanOrEqualTo(DoseAlarmPlanner.iosAlarmCap));

      // Next day the window is topped up and nothing taken is overwritten.
      await MedicationRepository.instance.topUpDoses(pid, force: true);
      final after = await DoseRepository.instance.getDose(pid, early.id);
      expect(after!.status, DoseStatus.taken);
    },
  );
}
