// M18 step 2 — builds the AI context from the LOCAL Firebase emulators with
// the real firestore.rules and the real repositories.
//
// Same data and setup as integration_test/report_data_source_test.dart:
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//
// Run (Android emulator):
//   flutter test integration_test/ai_context_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
//
// Refuses to run without USE_EMULATOR so it can never touch a real project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/models/allergy.dart';
import 'package:med_remind_app/repositories/ai_context_wiring.dart';
import 'package:med_remind_app/repositories/allergy_repository.dart';

const _host = '10.0.2.2';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String? allergyId;

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
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'owner2@example.com',
      password: 'Test1234!',
    );
    allergyId = await AllergyRepository.instance.createAllergy(
      'pO',
      Allergy(
        id: '',
        memberId: 'pO',
        name: 'Penicillin',
        severity: 'severe',
        description: 'rash, call 0300-1234567',
      ),
    );
  });

  tearDownAll(() async {
    if (allergyId != null) {
      await AllergyRepository.instance.deleteAllergy('pO', allergyId!);
    }
  });

  test(
    'context has medicines, the same adherence as the report, allergies',
    () async {
      final ctx = await buildAiContextBuilder('pO').build();

      expect(ctx.medications, isNotNull);
      expect(ctx.medications!.any((m) => m.name.contains('Metformin')), isTrue);

      final t = ctx.adherenceTotal!;
      expect(t.taken, 4);
      expect(t.missed, 2);
      expect(t.skipped, 1);
      expect(t.pending, 2);
      expect(t.percent, 57);

      final text = ctx.toPromptText();
      expect(text, contains('Metformin'));
      expect(text, contains('57%'));
      expect(text, contains('Penicillin (severe)'));
    },
  );

  test('no name, email, phone or ids in the text', () async {
    final text = (await buildAiContextBuilder('pO').build()).toPromptText();
    expect(text, isNot(contains('owner2@example.com')));
    expect(text, isNot(contains('Owner')));
    expect(text, isNot(contains('0300')));
    expect(text, isNot(contains('1234567')));
    expect(text, isNot(contains('pO')));
  });
}
