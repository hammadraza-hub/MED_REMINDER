// M19 step 2 — runs the community profile store against the LOCAL Firebase
// emulators with the real firestore.rules.
//
// Same setup as integration_test/chat_repository_test.dart:
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//
// The id in users/{uid} is set once and can never be cleared (the rules), so
// this test works for a fresh user and for a user from an earlier run.
//
// Run (Android emulator):
//   flutter test integration_test/community_profile_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/repositories/firestore_community_profile_store.dart';

const _host = '10.0.2.2';

Future<String> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  final c = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
  return c.user!.uid;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final store = FirestoreCommunityProfileStore();

  setUpAll(() async {
    expect(
      const bool.fromEnvironment('USE_EMULATOR'),
      isTrue,
      reason: 'Run with --dart-define=USE_EMULATOR=true (emulators only)',
    );
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
  });

  test('create, read back, edit: id and createdAt stay', () async {
    final uid = await _signIn('owner2@example.com');
    final c = CommunityProfileController(store);

    final created = await c.save(
      pseudonym: 'calm_river',
      avatar: 'a3',
      bio: 'first bio',
    );
    expect(CommunityIds.isValid(created.id), isTrue);

    // the private user document holds the id; the public profile holds no uid
    final user = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    expect(user.data()!['communityProfileId'], created.id);
    final raw = await FirebaseFirestore.instance
        .collection('communityProfiles')
        .doc(created.id)
        .get();
    expect(raw.data()!.keys.toSet(), {
      'pseudonym',
      'avatar',
      'bio',
      'createdAt',
    });
    expect(raw.data()!.values.any((v) => v == uid), isFalse);

    // a new controller (like a new app start) finds the same profile
    final again = await CommunityProfileController(store).load();
    expect(again!.id, created.id);
    expect(again.pseudonym, 'calm_river');
    expect(again.avatar, 'a3');

    // edit
    final edited = await c.save(
      pseudonym: 'brave_otter',
      avatar: 'a7',
      bio: 'second bio',
    );
    expect(edited.id, created.id);
    final after = await store.readProfile(created.id);
    expect(after!.pseudonym, 'brave_otter');
    expect(after.bio, 'second bio');
    expect(after.createdAt, again.createdAt);
  });

  test('the id cannot be changed once it is set', () async {
    await _signIn('owner2@example.com');
    final id = await store.readMyProfileId();
    expect(id, isNotNull);
    await expectLater(
      store.saveMyProfileId(CommunityIds.newProfileId()),
      throwsA(isA<FirebaseException>()),
    );
    expect(await store.readMyProfileId(), id);
  });

  test("another user cannot write to someone else's profile", () async {
    await _signIn('owner2@example.com');
    final ownerId = await store.readMyProfileId();
    expect(ownerId, isNotNull);

    await _signIn('care@example.com');
    await expectLater(
      store.updateProfile(
        ownerId!,
        pseudonym: 'hacked_name',
        avatar: 'a1',
        bio: '',
      ),
      throwsA(isA<FirebaseException>()),
    );
    // but anyone signed in can read it (it is public)
    final read = await store.readProfile(ownerId);
    expect(read!.pseudonym, isNot('hacked_name'));
  });

  test('a user without a profile loads null', () async {
    await _signIn('care@example.com');
    final id = await store.readMyProfileId();
    if (id == null) {
      expect(await CommunityProfileController(store).load(), isNull);
    }
  });
}
