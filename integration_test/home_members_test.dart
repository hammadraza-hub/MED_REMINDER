// Home member bar from REAL profiles, through the real rules (emulators).
//
// Run: flutter test integration_test/home_members_test.dart -d emulator-5554 \
//   --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/members/firestore_member_repository.dart';

const _host = '10.0.2.2';

Future<String> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
  return cred.user!.uid;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(const bool.fromEnvironment('USE_EMULATOR'), isTrue);
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
  });

  test(
    'the bar lists the real profiles of the signed-in person only',
    () async {
      final uid = await _signIn('owner2@example.com');
      final repo = FirestoreMemberRepository();
      final members = await repo.getActiveMembers();
      expect(members, isNotEmpty, reason: 'owner2 owns seeded profiles');
      for (final m in members) {
        expect(
          m.id.startsWith('local_'),
          isFalse,
          reason: 'no made-up members',
        );
        final doc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(m.id)
            .get();
        expect(
          (doc.data()!['memberUids'] as List).contains(uid),
          isTrue,
          reason: '${m.id} must really include this person',
        );
      }
      final names = members.map((m) => m.displayName).toSet();
      expect(names.contains('Sarah') && names.contains('Jake'), isFalse);
    },
  );

  test('another person sees a different list', () async {
    await _signIn('owner2@example.com');
    final a = (await FirestoreMemberRepository().getActiveMembers())
        .map((m) => m.id)
        .toSet();
    await _signIn('care@example.com');
    final b = (await FirestoreMemberRepository().getActiveMembers())
        .map((m) => m.id)
        .toSet();
    expect(b.difference(a).length + a.difference(b).length, greaterThan(0));
  });

  test('signed out: an empty list, no crash', () async {
    await FirebaseAuth.instance.signOut();
    expect(await FirestoreMemberRepository().getActiveMembers(), isEmpty);
  });
}
