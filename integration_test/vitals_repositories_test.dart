// M15 step 3 — runs the vitals / symptom repositories against the LOCAL
// Firebase emulators with the real firestore.rules.
//
// Needs, on the PC:
//   firebase emulators:start --only auth,firestore --project medapp-staging
// and a seeded owner (see graphify/HANDOFF.md §11):
//   owner2@example.com / Test1234!  owner of profile "pO" with medication "mo1"
//   care@example.com   / Test1234!  NOT a member of "pO" (must be denied)
//
// Run (Android emulator):
//   flutter test integration_test/vitals_repositories_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
//
// Refuses to run without USE_EMULATOR so it can never touch a real project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/core/vitals/vital_models.dart';
import 'package:med_remind_app/core/vitals/vital_summary.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/repositories/firebase_symptom_repository.dart';
import 'package:med_remind_app/repositories/firebase_vitals_repository.dart';

const _pid = 'pO';
const _host = '10.0.2.2';

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final vitals = FirebaseVitalsRepository.instance;
  final symptoms = FirebaseSymptomRepository.instance;

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
  });

  final now = DateTime.now();
  DateTime today(int hour) => DateTime(now.year, now.month, now.day, hour, 0);
  // Keep every reading in the past so the "future" rule never interferes.
  final base = now.subtract(const Duration(hours: 1));
  final dayKey = VitalAnalysis.dayKey(base.toLocal());

  test('manual reading is saved, listed, summarised and deleted', () async {
    final a = await vitals.addManual(
      _pid,
      VitalReading(
        kind: VitalKind.glucose,
        value: 90,
        measuredAt: base.subtract(const Duration(minutes: 30)),
      ),
    );
    final b = await vitals.addManual(
      _pid,
      VitalReading(
        kind: VitalKind.glucose,
        value: 110,
        measuredAt: base,
        note: 'after lunch',
      ),
    );
    expect(a.id, isNotNull);
    expect(b.id, isNotNull);

    final list = await vitals.list(_pid, VitalKind.glucose);
    final ids = list.map((r) => r.id).toList();
    expect(ids.indexOf(b.id), lessThan(ids.indexOf(a.id)), reason: 'newest first');
    expect(list.firstWhere((r) => r.id == b.id).note, 'after lunch');

    final latest = await vitals.latest(_pid, VitalKind.glucose);
    expect(latest!.id, b.id);

    // daily summary (written by the app, checked through the rules)
    var days = await vitals.dailySummaries(
      _pid,
      VitalKind.glucose,
      from: base.subtract(const Duration(days: 1)),
      to: base.add(const Duration(days: 1)),
    );
    var d = days.firstWhere((x) => x.dayKey == dayKey);
    expect(d.count, 2);
    expect(d.avg, 100);
    expect(d.min, 90);
    expect(d.max, 110);

    await vitals.delete(_pid, a);
    days = await vitals.dailySummaries(
      _pid,
      VitalKind.glucose,
      from: base.subtract(const Duration(days: 1)),
      to: base.add(const Duration(days: 1)),
    );
    d = days.firstWhere((x) => x.dayKey == dayKey);
    expect(d.count, 1);
    expect(d.avg, 110);

    await vitals.updateNote(_pid, b.id!, 'edited');
    expect((await vitals.latest(_pid, VitalKind.glucose))!.note, 'edited');

    await vitals.delete(_pid, b);
    days = await vitals.dailySummaries(
      _pid,
      VitalKind.glucose,
      from: base.subtract(const Duration(days: 1)),
      to: base.add(const Duration(days: 1)),
    );
    expect(days.where((x) => x.dayKey == dayKey), isEmpty,
        reason: 'summary removed when the day has no readings');
  });

  test('blood pressure keeps systolic and diastolic summaries', () async {
    final r = await vitals.addManual(
      _pid,
      VitalReading(
        kind: VitalKind.bloodPressure,
        value: 120,
        value2: 80,
        pulse: 70,
        measuredAt: base,
      ),
    );
    final days = await vitals.dailySummaries(
      _pid,
      VitalKind.bloodPressure,
      from: base,
      to: base,
    );
    final d = days.firstWhere((x) => x.dayKey == dayKey);
    expect(d.avg, 120);
    expect(d.avg2, 80);
    await vitals.delete(_pid, r);
  });

  test('invalid readings are rejected before reaching Firestore', () async {
    await expectLater(
      vitals.addManual(
        _pid,
        VitalReading(kind: VitalKind.weight, value: 5000, measuredAt: base),
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      vitals.addManual(
        _pid,
        VitalReading(
          kind: VitalKind.weight,
          value: 70,
          measuredAt: DateTime.now().add(const Duration(days: 2)),
        ),
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('health sync never creates duplicates', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    List<VitalReading> batch() => [
      for (var i = 0; i < 3; i++)
        VitalReading(
          kind: VitalKind.heartRate,
          value: 60.0 + i,
          measuredAt: base.subtract(Duration(minutes: 10 * i)),
          source: VitalSource.healthKit,
          externalId: 'it-$stamp-$i',
        ),
      // not importable: out of range
      VitalReading(
        kind: VitalKind.heartRate,
        value: 5000,
        measuredAt: base,
        source: VitalSource.healthKit,
        externalId: 'it-$stamp-bad',
      ),
      // same id again inside the batch
      VitalReading(
        kind: VitalKind.heartRate,
        value: 60,
        measuredAt: base,
        source: VitalSource.healthKit,
        externalId: 'it-$stamp-0',
      ),
    ];

    final first = await vitals.importSynced(_pid, batch());
    expect(first.written, 3);
    expect(first.rejected, 1);
    expect(first.duplicatesInBatch, 1);

    final second = await vitals.importSynced(_pid, batch());
    expect(second.written, 0, reason: 're-sync must write nothing');
    expect(second.skippedExisting, 3);

    final stored = (await vitals.list(_pid, VitalKind.heartRate))
        .where((r) => r.externalId?.startsWith('it-$stamp') ?? false)
        .toList();
    expect(stored.length, 3);
    expect(stored.every((r) => r.id!.startsWith('healthkit_it-$stamp')), isTrue);

    final days = await vitals.dailySummaries(
      _pid,
      VitalKind.heartRate,
      from: base,
      to: base,
    );
    expect(days.firstWhere((x) => x.dayKey == dayKey).count,
        greaterThanOrEqualTo(3));

    for (final r in stored) {
      await vitals.delete(_pid, r);
    }
  });

  test('symptoms: add with a medication link, edit notes, delete', () async {
    final s = await symptoms.add(
      _pid,
      SymptomEntry(
        symptom: 'Nausea',
        severity: 3,
        medicationId: 'mo1',
        occurredAt: base,
        notes: 'after dose',
      ),
    );
    expect(s.id, isNotNull);

    final list = await symptoms.list(_pid);
    final saved = list.firstWhere((e) => e.id == s.id);
    expect(saved.medicationId, 'mo1');
    expect(saved.severity, 3);

    await symptoms.updateNotes(_pid, s.id!, 'updated');
    expect((await symptoms.list(_pid)).firstWhere((e) => e.id == s.id).notes,
        'updated');

    await expectLater(
      symptoms.add(
        _pid,
        SymptomEntry(
          symptom: 'Rash',
          severity: 2,
          medicationId: 'does-not-exist',
          occurredAt: base,
        ),
      ),
      throwsA(isA<AppException>()),
      reason: 'rules require the linked medication to exist',
    );
    await expectLater(
      symptoms.add(
        _pid,
        SymptomEntry(symptom: '', severity: 3, occurredAt: base),
      ),
      throwsA(isA<AppException>()),
    );

    await symptoms.delete(_pid, s.id!);
    expect((await symptoms.list(_pid)).any((e) => e.id == s.id), isFalse);
  });

  test('a user who is not a member of the profile is refused', () async {
    await _signIn('care@example.com');
    try {
      await expectLater(
        vitals.addManual(
          _pid,
          VitalReading(kind: VitalKind.weight, value: 70, measuredAt: base),
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        symptoms.add(
          _pid,
          SymptomEntry(symptom: 'Nausea', severity: 3, occurredAt: base),
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        vitals.list(_pid, VitalKind.weight),
        throwsA(isA<AppException>()),
      );
    } finally {
      await _signIn('owner2@example.com');
    }
  });

  test('today helper stays within the same local day', () {
    expect(VitalAnalysis.dayKey(today(8)), VitalAnalysis.dayKey(today(20)));
  });
}
