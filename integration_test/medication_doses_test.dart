// M22 step 2 — creating a medicine writes its first 14 days of doses, in the
// PROFILE's time zone, through the real firestore.rules on the LOCAL emulators.
//
// Setup (same as the other integration tests):
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//
// Run (Android emulator):
//   flutter test integration_test/medication_doses_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/dose_engine.dart';
import 'package:med_remind_app/core/dose_zone.dart';
import 'package:med_remind_app/models/medication.dart';
import 'package:med_remind_app/models/schedule.dart';
import 'package:med_remind_app/repositories/medication_repository.dart';
import 'package:timezone/timezone.dart' as tz;

const _host = '10.0.2.2';

// Looked up when used: Firebase is initialised in setUpAll.
FirebaseFirestore get db => FirebaseFirestore.instance;

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
}

/// A throw-away profile owned by [ownerUid], written with the emulator's admin
/// bearer token (no rules involved), so these tests never touch the seeded ones.
Future<void> _makeProfile(String id, String ownerUid, String timezone) async {
  final client = HttpClient();
  try {
    final req = await client.patchUrl(
      Uri.parse(
        'http://$_host:8080/v1/projects/medapp-staging/databases/(default)'
        '/documents/profiles/$id',
      ),
    );
    req.headers
      ..set('Authorization', 'Bearer owner')
      ..set('Content-Type', 'application/json');
    String s(String v) => '{"stringValue":"$v"}';
    final body = jsonEncode({
      'fields': {
        'ownerUid': {'stringValue': ownerUid},
        'kind': {'stringValue': 'dependent'},
        'name': {'stringValue': 'Dose zone test'},
        'timezone': {'stringValue': timezone},
        'missedAfterMin': {'integerValue': '30'},
        'roles': {
          'mapValue': {
            'fields': {ownerUid: jsonDecode(s('owner'))},
          },
        },
        'memberUids': {
          'arrayValue': {
            'values': [jsonDecode(s(ownerUid))],
          },
        },
        'healthUids': {
          'arrayValue': {
            'values': [jsonDecode(s(ownerUid))],
          },
        },
        'permissions': {'mapValue': <String, dynamic>{}},
      },
    });
    req.write(body);
    final res = await req.close();
    await res.drain<void>();
    expect(res.statusCode, 200);
  } finally {
    client.close(force: true);
  }
}

/// Admin REST call on the emulator (no rules).
Future<void> _rest(
  String method,
  String path, [
  Map<String, dynamic>? body,
]) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(
      'http://$_host:8080/v1/projects/medapp-staging/databases/(default)/documents/$path',
    );
    final req = await client.openUrl(method, uri);
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

Medication _daily(String profileId, String uid, List<String> times) {
  final now = DateTime.now();
  return Medication(
    id: '',
    profileId: profileId,
    name: 'Zone test medicine',
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

  late String uid;

  setUpAll(() async {
    expect(
      const bool.fromEnvironment('USE_EMULATOR'),
      isTrue,
      reason: 'Run with --dart-define=USE_EMULATOR=true (emulators only)',
    );
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    await _signIn('owner2@example.com');
    uid = FirebaseAuth.instance.currentUser!.uid;
    DoseZone.ensureData();
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> dosesOf(
    String profileId,
    String medId,
  ) async {
    final snap = await db
        .collection('profiles')
        .doc(profileId)
        .collection('doses')
        .where('medicationId', isEqualTo: medId)
        .get();
    return snap.docs..sort((a, b) => a.id.compareTo(b.id));
  }

  test(
    'a new medicine gets today + 14 days of doses in the profile zone',
    () async {
      final pid = 'zt_ny_${DateTime.now().millisecondsSinceEpoch}';
      await _makeProfile(pid, uid, 'America/New_York');
      final medId = await MedicationRepository.instance.createMedication(
        profileId: pid,
        medication: _daily(pid, uid, ['08:00', '20:00']),
      );

      final docs = await dosesOf(pid, medId);
      expect(docs.length, 15 * 2, reason: '15 calendar days x 2 times');

      // Every id is {med}_{yyyyMMddHHmm}; every instant is that wall time in New York.
      final ny = tz.getLocation('America/New_York');
      for (final d in docs) {
        final m = RegExp(r'^(.+)_(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})$')
            .firstMatch(d.id)!;
        final expected = DoseEngine.resolveSlot(
          ny,
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
          int.parse(m.group(4)!),
          int.parse(m.group(5)!),
          int.parse(m.group(6)!),
        );
        final at = (d.data()['scheduledAt'] as Timestamp).toDate().toUtc();
        expect(at, expected, reason: d.id);
        expect(d.data()['status'], 'pending');
        expect(d.data()['profileId'], pid);
      }

      // The window starts on today's date in the PROFILE zone.
      final today = DoseEngine.todayIn(ny);
      final first = docs.first.id.split('_').last;
      expect(
        first,
        '${today.year}${today.month.toString().padLeft(2, '0')}'
        '${today.day.toString().padLeft(2, '0')}0800',
      );
    },
  );

  test(
    'an old profile that stored "PKT" falls back to the phone zone',
    () async {
      final pid = 'zt_pkt_${DateTime.now().millisecondsSinceEpoch}';
      await _makeProfile(pid, uid, 'PKT');
      final medId = await MedicationRepository.instance.createMedication(
        profileId: pid,
        medication: _daily(pid, uid, ['09:15']),
      );
      final docs = await dosesOf(pid, medId);
      expect(docs.length, 15);
      // No exception, valid timestamps, every dose at 09:15 in SOME real zone.
      final phone = await DoseZone.forProfile('PKT');
      for (final d in docs) {
        final at = tz.TZDateTime.from(
          (d.data()['scheduledAt'] as Timestamp).toDate().toUtc(),
          phone,
        );
        expect('${at.hour}:${at.minute}', '9:15', reason: d.id);
      }
    },
  );

  test('the stored doses are exactly the ones the engine computes', () async {
    final pid = 'zt_same_${DateTime.now().millisecondsSinceEpoch}';
    await _makeProfile(pid, uid, 'Asia/Karachi');
    final medication = _daily(pid, uid, ['07:00']);
    final medId = await MedicationRepository.instance.createMedication(
      profileId: pid,
      medication: medication,
    );
    final stored = (await dosesOf(pid, medId)).map((d) => d.id).toList();

    final zone = tz.getLocation('Asia/Karachi');
    final expected = DoseEngine.generate14DayDoses(
      medication: medication.copyWith(id: medId),
      profileId: pid,
      missedAfterMin: 30,
      zone: zone,
    ).map((d) => d.id).toList()..sort();
    expect(stored, expected);
    expect(stored.length, 15);
  });

  test('top-up: doses that ran out are written again, nothing else', () async {
    final pid = 'zt_top_${DateTime.now().millisecondsSinceEpoch}';
    await _makeProfile(pid, uid, 'Asia/Karachi');
    final medId = await MedicationRepository.instance.createMedication(
      profileId: pid,
      medication: _daily(pid, uid, ['07:00']),
    );
    var docs = await dosesOf(pid, medId);
    expect(docs.length, 15);

    // The last 10 days vanish (as if the window had been used up).
    for (final d in docs.skip(5)) {
      await _rest('DELETE', 'profiles/$pid/doses/${d.id}');
    }
    expect((await dosesOf(pid, medId)).length, 5);

    final written = await MedicationRepository.instance.topUpDoses(
      pid,
      force: true,
    );
    expect(written, 10);
    docs = await dosesOf(pid, medId);
    expect(docs.length, 15);

    // A second run finds nothing to do.
    expect(await MedicationRepository.instance.topUpDoses(pid, force: true), 0);
    expect((await dosesOf(pid, medId)).length, 15);
  });

  test('top-up never overwrites a dose that was already logged', () async {
    final pid = 'zt_keep_${DateTime.now().millisecondsSinceEpoch}';
    await _makeProfile(pid, uid, 'Asia/Karachi');
    final medId = await MedicationRepository.instance.createMedication(
      profileId: pid,
      medication: _daily(pid, uid, ['07:00']),
    );
    final first = (await dosesOf(pid, medId)).first;
    await _rest(
      'PATCH',
      'profiles/$pid/doses/${first.id}?updateMask.fieldPaths=status',
      {
        'fields': {
          'status': {'stringValue': 'taken'},
        },
      },
    );
    await MedicationRepository.instance.topUpDoses(pid, force: true);
    final after = await db
        .collection('profiles')
        .doc(pid)
        .collection('doses')
        .doc(first.id)
        .get();
    expect(after.data()!['status'], 'taken');
  });

  test('a schedule change keeps a taken dose of today (finding 2)', () async {
    final pid = 'zt_chg_${DateTime.now().millisecondsSinceEpoch}';
    await _makeProfile(pid, uid, 'Asia/Karachi');
    final medication = _daily(pid, uid, ['00:01']);
    final medId = await MedicationRepository.instance.createMedication(
      profileId: pid,
      medication: medication,
    );
    final todays = (await dosesOf(pid, medId)).first;
    await _rest(
      'PATCH',
      'profiles/$pid/doses/${todays.id}?updateMask.fieldPaths=status',
      {
        'fields': {
          'status': {'stringValue': 'taken'},
        },
      },
    );

    await MedicationRepository.instance.updateMedication(
      profileId: pid,
      medication: medication.copyWith(
        id: medId,
        updatedAt: DateTime.now().add(const Duration(seconds: 1)),
        schedule: medication.schedule.copyWith(times: ['00:01', '23:59']),
      ),
    );

    final docs = await dosesOf(pid, medId);
    final byId = {for (final d in docs) d.id: d.data()['status']};
    expect(byId[todays.id], 'taken', reason: 'history must survive');
    expect(byId.keys.any((k) => k.endsWith('2359')), isTrue);
    expect(docs.length, 30);
  });
}
