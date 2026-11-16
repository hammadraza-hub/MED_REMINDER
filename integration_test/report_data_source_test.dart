// M17 step 2 — runs the report data source against the LOCAL Firebase
// emulators with the real firestore.rules and the real repositories.
//
// Needs, on the PC:
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
// (seed_report.py is in the session scratchpad; see graphify/HANDOFF.md §13)
//
//   owner2@example.com / Test1234!  owns profile "pO" (doses, vitals, side
//                                   effects) and "pV"
//   care@example.com   / Test1234!  viewer WITHOUT health access on "pV"
//
// Run (Android emulator):
//   flutter test integration_test/report_data_source_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
//
// Refuses to run without USE_EMULATOR so it can never touch a real project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/core/reports/report_options.dart';
import 'package:med_remind_app/core/reports/report_range.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/repositories/report_data_wiring.dart';

const _host = '10.0.2.2';

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
}

const all = ReportOptions({
  ReportSection.adherence,
  ReportSection.vitals,
  ReportSection.sideEffects,
});

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  test('last 7 days: adherence numbers, reasons and strength', () async {
    final range = ReportRange.lastDays(7);
    final data = await buildReportDataSource('pO')
        .load(range: range, options: all, profileName: 'Owner Two');

    final a = data.adherence!;
    // taken 4, missed 2 (1 missed + 1 overdue pending), skipped 1,
    // pending 2 (snoozed + still inside its window)
    expect(a.total.taken, 4);
    expect(a.total.missed, 2);
    expect(a.total.skipped, 1);
    expect(a.total.pending, 2);
    expect(a.total.percent, 57); // 4 / 7

    expect(a.perMedication.single.displayName, 'Metformin 500mg');
    expect(a.perDay.length, 7);
    expect(
      a.perDay.fold<int>(0, (s, d) => s + d.counts.scheduled),
      a.total.scheduled,
    );

    final reasons = {for (final r in a.reasons) r.reason: r.count};
    expect(reasons[ReportMissReason.forgot], 1);
    expect(reasons[ReportMissReason.sideEffect], 1);
    expect(reasons[ReportMissReason.unspecified], 1);

    expect(data.unavailable, isEmpty);
    expect(data.stats.doses, 9);
  });

  test(
    'last 7 days: vitals from raw readings and side effects in range',
    () async {
      final data = await buildReportDataSource('pO')
          .load(range: ReportRange.lastDays(7), options: all);

      final glucose = data.vitals![VitalKind.glucose]!;
      expect(glucose.length, 2); // two different days
      expect(glucose.fold<int>(0, (s, d) => s + d.count), 3);
      final twoReadings = glucose.firstWhere((d) => d.count == 2);
      expect(twoReadings.avg, 100);
      expect(twoReadings.min, 90);
      expect(twoReadings.max, 110);
      expect(data.vitals![VitalKind.weight], isEmpty);

      // the 40-day-old side effect is outside the week
      expect(data.symptoms!.map((s) => s.symptom), ['Nausea', 'Headache']);
    },
  );

  test('180 days: vitals come from the per-day documents', () async {
    final data = await buildReportDataSource('pO').load(
      range: ReportRange.lastDays(180),
      options: const ReportOptions({ReportSection.vitals}),
    );
    final glucose = data.vitals![VitalKind.glucose]!;
    // 100 and 120 days ago are inside; 300 days ago is outside the range
    expect(glucose.length, 2);
    expect(glucose.map((d) => d.count).toSet(), {3, 2});
    expect(data.adherence, isNull);
  });

  test('a range that has no data is reported as empty', () async {
    final data = await buildReportDataSource('pO').load(
      range: ReportRange.custom(
        DateTime.now().subtract(const Duration(days: 365)),
        DateTime.now().subtract(const Duration(days: 330)),
      ),
      options: all,
    );
    expect(data.isEmpty, isTrue);
  });

  test('without health access: adherence still works, health sections are '
      'marked unavailable', () async {
    await _signIn('care@example.com');
    try {
      final data = await buildReportDataSource('pV')
          .load(range: ReportRange.lastDays(7), options: all);
      expect(data.adherence!.total.taken, 1);
      expect(data.adherence!.total.missed, 1);
      expect(data.unavailable, {
        ReportSection.vitals,
        ReportSection.sideEffects,
      });
      expect(data.vitals, isNull);
      expect(data.symptoms, isNull);
    } finally {
      await _signIn('owner2@example.com');
    }
  });
}
