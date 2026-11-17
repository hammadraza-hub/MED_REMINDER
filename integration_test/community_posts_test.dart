// M19 step 4 — runs the post / comment store against the LOCAL Firebase
// emulators with the real firestore.rules.
//
// Setup (same as integration_test/community_profile_test.dart), plus groups
// and demo posts:
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node tools/seed_community.js \
//       --project medapp-staging --demo
//
// Run (Android emulator):
//   flutter test integration_test/community_posts_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/community/community_posts.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/repositories/firestore_community_post_store.dart';
import 'package:med_remind_app/repositories/firestore_community_profile_store.dart';

const _host = '10.0.2.2';
const _group = 'general';

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
}

/// Makes sure the signed-in user has a pseudonym profile; returns the actions.
Future<CommunityPostActions> _actionsFor(String name) async {
  final profiles = CommunityProfileController(FirestoreCommunityProfileStore());
  if (await profiles.load() == null) {
    await profiles.save(pseudonym: name, avatar: 'a1', bio: '');
  }
  return CommunityPostActions(FirestoreCommunityPostStore(), profiles.myId);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final store = FirestoreCommunityPostStore();
  final created = <String>[];

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

  tearDownAll(() async {
    await _signIn('owner2@example.com');
    for (final id in created) {
      try {
        await store.deletePost(_group, id);
      } catch (_) {}
    }
  });

  test('post: create, read, edit text only, comments, count, delete', () async {
    await _signIn('owner2@example.com');
    final owner = await _actionsFor('owner_user');

    final id = await owner.createPost(_group, '  first post from the test  ');
    created.add(id);

    var post = (await store.getPost(_group, id))!;
    expect(post.body, 'first post from the test');
    expect(post.voteCount, 0);
    expect(post.hidden, isFalse);
    expect(post.isEdited, isFalse);

    // the public document holds a community id and no uid / email
    final raw = await FirebaseFirestore.instance
        .collection('groups')
        .doc(_group)
        .collection('posts')
        .doc(id)
        .get();
    expect(raw.data()!.keys.toSet(), {
      'authorId',
      'body',
      'createdAt',
      'editedAt',
      'voteCount',
      'hidden',
    });
    expect(post.authorId, hasLength(20));
    expect(post.authorId, isNot(FirebaseAuth.instance.currentUser!.uid));

    await owner.editPost(post, 'edited text');
    post = (await store.getPost(_group, id))!;
    expect(post.body, 'edited text');
    expect(post.isEdited, isTrue);
    expect(post.authorId, raw.data()!['authorId']);

    final c1 = await owner.createComment(_group, id, 'my own comment');
    expect(await store.commentCount(_group, id), 1);
    final page = await store.comments(_group, id, limit: 20);
    expect(page.comments.single.body, 'my own comment');

    final comment = page.comments.single;
    await owner.editComment(_group, id, comment, 'edited comment');
    expect(
      (await store.comments(_group, id, limit: 20)).comments.single.editedAt,
      isNotNull,
    );

    await owner.deleteComment(_group, id, comment);
    expect(await store.commentCount(_group, id), 0);
    expect(c1, isNotEmpty);

    await owner.deletePost(post);
    expect(await store.getPost(_group, id), isNull);
    created.remove(id);
  });

  test(
    "another user: can comment, cannot edit or delete someone else's",
    () async {
      await _signIn('owner2@example.com');
      final owner = await _actionsFor('owner_user');
      final id = await owner.createPost(_group, 'post by the owner');
      created.add(id);

      await _signIn('care@example.com');
      final other = await _actionsFor('care_user');

      // comment works, and the count goes up
      await other.createComment(_group, id, 'hello from the other user');
      expect(await store.commentCount(_group, id), 1);

      // the rules (not just the app) refuse these
      await expectLater(
        store.editPost(_group, id, 'hacked'),
        throwsA(isA<CommunityDeniedException>()),
      );
      await expectLater(
        store.deletePost(_group, id),
        throwsA(isA<CommunityDeniedException>()),
      );
      expect((await store.getPost(_group, id))!.body, 'post by the owner');

      // owner cannot touch the other user's comment either
      final theirs = (await store.comments(
        _group,
        id,
        limit: 20,
      )).comments.single;
      await _signIn('owner2@example.com');
      await expectLater(
        store.editComment(_group, id, theirs.id, 'hacked'),
        throwsA(isA<CommunityDeniedException>()),
      );
      await expectLater(
        store.deleteComment(_group, id, theirs.id),
        throwsA(isA<CommunityDeniedException>()),
      );
      expect(await store.commentCount(_group, id), 1);
    },
  );

  test(
    'a hidden post: not readable by others, and no comments on it',
    () async {
      await _signIn('care@example.com');
      await _actionsFor('care_user');
      final actions = CommunityPostActions(store, () async {
        final p = CommunityProfileController(FirestoreCommunityProfileStore());
        return p.myId();
      });
      // seeded by tools/seed_community.js --demo (hidden: true, by another id)
      expect(await store.getPost('diabetes', 'demo-hidden'), isNull);
      await expectLater(
        actions.createComment('diabetes', 'demo-hidden', 'can I comment?'),
        throwsA(isA<CommunityDeniedException>()),
      );
    },
  );

  test(
    'post limits are enforced by the rules too (not only the app)',
    () async {
      await _signIn('owner2@example.com');
      await _actionsFor('owner_user');
      final ctrl = CommunityProfileController(FirestoreCommunityProfileStore());
      final myId = (await ctrl.myId())!;
      await expectLater(
        store.createPost(_group, authorId: myId, body: 'x' * 2001),
        throwsA(isA<CommunityDeniedException>()),
      );
      // someone else's community id
      await expectLater(
        store.createPost(_group, authorId: 'A' * 20, body: 'pretend'),
        throwsA(isA<CommunityDeniedException>()),
      );
    },
  );
}
