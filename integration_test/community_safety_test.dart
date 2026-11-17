// M19 step 6 — reports and blocks against the LOCAL Firebase emulators with
// the real firestore.rules.
//
// Setup is the same as integration_test/community_posts_test.dart.
//
// Run (Android emulator):
//   flutter test integration_test/community_safety_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_posts.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/core/community/community_safety.dart';
import 'package:med_remind_app/repositories/firestore_community_post_store.dart';
import 'package:med_remind_app/repositories/firestore_community_profile_store.dart';
import 'package:med_remind_app/repositories/firestore_community_safety_stores.dart';

const _host = '10.0.2.2';
const _group = 'general';

Future<String> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  final c = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
  return c.user!.uid;
}

Future<String> _myCpid(String name) async {
  final profiles = CommunityProfileController(FirestoreCommunityProfileStore());
  if (await profiles.load() == null) {
    await profiles.save(pseudonym: name, avatar: 'a1', bio: '');
  }
  return (await profiles.myId())!;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final posts = FirestoreCommunityPostStore();
  final reportStore = FirestoreCommunityReportStore();
  final blockStore = FirestoreCommunityBlockStore();
  FirebaseFirestore db() => FirebaseFirestore.instance;
  late String ownerCpid;
  late String careCpid;
  late String postId;
  late String commentId;

  setUpAll(() async {
    expect(
      const bool.fromEnvironment('USE_EMULATOR'),
      isTrue,
      reason: 'Run with --dart-define=USE_EMULATOR=true (emulators only)',
    );
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);

    await _signIn('care@example.com');
    careCpid = await _myCpid('care_user');
    await _signIn('owner2@example.com');
    ownerCpid = await _myCpid('owner_user');
    postId = await posts.createPost(
      _group,
      authorId: ownerCpid,
      body: 'post for the report tests',
    );
    commentId = await posts.createComment(
      _group,
      postId,
      authorId: ownerCpid,
      body: 'comment for the report tests',
    );
  });

  tearDownAll(() async {
    await _signIn('owner2@example.com');
    try {
      await posts.deletePost(_group, postId);
    } catch (_) {}
  });

  CommunityReportActions reportsFor(String cpid) =>
      CommunityReportActions(reportStore, () async => cpid);

  test('report a post and a comment; the same one twice is refused', () async {
    await _signIn('care@example.com');
    final r = reportsFor(careCpid);
    await r.report(
      groupId: _group,
      postId: postId,
      reason: CommunityReportReason.medical,
    );
    await r.report(
      groupId: _group,
      postId: postId,
      commentId: commentId,
      reason: CommunityReportReason.abuse,
    );
    await expectLater(
      r.report(
        groupId: _group,
        postId: postId,
        reason: CommunityReportReason.spam,
      ),
      throwsA(isA<CommunityDeniedException>()),
    );
  });

  test('reports are private: nobody but a moderator can read them', () async {
    await _signIn('care@example.com');
    await expectLater(
      db().collection('reports').doc('${careCpid}_$postId').get(),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      db().collection('reports').get(),
      throwsA(isA<FirebaseException>()),
    );
    await _signIn('owner2@example.com');
    await expectLater(
      db().collection('reports').doc('${careCpid}_$postId').get(),
      throwsA(isA<FirebaseException>()),
    );
  });

  test(
    'a report in somebody else\'s name or with a made-up reason is refused',
    () async {
      await _signIn('care@example.com');
      final good = CommunityReport.createMap(
        reporterId: careCpid,
        target: CommunityReportTarget.post,
        groupId: _group,
        postId: 'whatever',
        reason: CommunityReportReason.spam,
      );
      // as the owner's community id
      await expectLater(
        reportStore.create('fake1', {...good, 'reporterId': ownerCpid}),
        throwsA(isA<CommunityDeniedException>()),
      );
      // a reason that is not in the list
      await expectLater(
        reportStore.create('fake2', {...good, 'reason': 'because'}),
        throwsA(isA<CommunityDeniedException>()),
      );
      // an extra field
      await expectLater(
        reportStore.create('fake3', {...good, 'note': 'x'}),
        throwsA(isA<CommunityDeniedException>()),
      );
      // a comment report without a comment id
      await expectLater(
        reportStore.create('fake4', {...good, 'targetType': 'comment'}),
        throwsA(isA<CommunityDeniedException>()),
      );
    },
  );

  test('blocks: add, list, remove; private; not yourself', () async {
    final careUid = await _signIn('care@example.com');
    // start clean
    for (final id in await blockStore.all()) {
      await blockStore.unblock(id);
    }
    expect(await blockStore.all(), isEmpty);

    final blocks = CommunityBlocksController(blockStore, () async => careCpid);
    await blocks.block(ownerCpid);
    await blocks.block(ownerCpid); // again: no error
    expect(await blockStore.all(), {ownerCpid});

    // yourself (the app ignores it; the rules refuse it too)
    await expectLater(
      blockStore.block(careCpid),
      throwsA(isA<CommunityDeniedException>()),
    );
    // not a community id
    await expectLater(
      blockStore.block('short'),
      throwsA(isA<CommunityDeniedException>()),
    );

    // another account cannot read or write this list
    await _signIn('owner2@example.com');
    await expectLater(
      db().collection('users').doc(careUid).collection('blocks').get(),
      throwsA(isA<FirebaseException>()),
    );
    expect(await blockStore.all(), isNot(contains(ownerCpid)));

    await _signIn('care@example.com');
    await blocks.unblock(ownerCpid);
    expect(await blockStore.all(), isEmpty);
  });
}
