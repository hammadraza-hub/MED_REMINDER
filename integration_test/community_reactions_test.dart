// M19 step 5 — votes and saved posts against the LOCAL Firebase emulators with
// the real firestore.rules.
//
// Setup is the same as integration_test/community_posts_test.dart (users,
// groups and demo data seeded; emulators running).
//
// Run (Android emulator):
//   flutter test integration_test/community_reactions_test.dart -d emulator-5554 \
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
import 'package:med_remind_app/repositories/firestore_community_post_store.dart';
import 'package:med_remind_app/repositories/firestore_community_profile_store.dart';
import 'package:med_remind_app/repositories/firestore_community_reaction_stores.dart';

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

/// Makes sure the signed-in user has a profile; returns their community id.
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
  final votes = FirestoreCommunityVoteStore();
  final saves = FirestoreCommunityBookmarkStore();
  FirebaseFirestore db() => FirebaseFirestore.instance;
  late CommunityFeedPost post;
  late String ownerCpid;
  late String careCpid;
  late String careUid;

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
    final id = await posts.createPost(
      _group,
      authorId: ownerCpid,
      body: 'post for the vote tests',
    );
    post = (await posts.getPost(_group, id))!;
    careUid = '';
  });

  tearDownAll(() async {
    await _signIn('owner2@example.com');
    try {
      await posts.deletePost(_group, post.id);
    } catch (_) {}
  });

  Future<int> count() async =>
      (await posts.getPost(_group, post.id))!.voteCount;

  test('vote +1, again is refused, unvote -1, again is refused', () async {
    await _signIn('care@example.com');
    expect(await votes.votedAmong(careCpid, [post]), isEmpty);

    await votes.vote(post, careCpid);
    expect(await count(), 1);
    expect(await votes.votedAmong(careCpid, [post]), {'$_group/${post.id}'});

    // a second vote of the same id is refused by the rules
    await expectLater(
      votes.vote(post, careCpid),
      throwsA(isA<CommunityDeniedException>()),
    );
    expect(await count(), 1);

    await votes.unvote(post, careCpid);
    expect(await count(), 0);
    expect(await votes.votedAmong(careCpid, [post]), isEmpty);

    // taking back a vote that is not there is refused
    await expectLater(
      votes.unvote(post, careCpid),
      throwsA(isA<CommunityDeniedException>()),
    );
    expect(await count(), 0);
  });

  test('a made-up counter or a vote without the counter is refused', () async {
    await _signIn('care@example.com');
    final ref = db()
        .collection('groups')
        .doc(_group)
        .collection('posts')
        .doc(post.id);

    // +5 without any vote document
    await expectLater(
      ref.update({'voteCount': FieldValue.increment(5)}),
      throwsA(isA<FirebaseException>()),
    );
    // a vote document without moving the counter
    await expectLater(
      ref.collection('votes').doc(careCpid).set({
        'createdAt': FieldValue.serverTimestamp(),
      }),
      throwsA(isA<FirebaseException>()),
    );
    // a vote in somebody else's name (batch with the right counter)
    final batch = db().batch()
      ..set(ref.collection('votes').doc(ownerCpid), {
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(ref, {'voteCount': FieldValue.increment(1)});
    await expectLater(batch.commit(), throwsA(isA<FirebaseException>()));
    expect(await count(), 0);
  });

  test('two voters: count 2, and each can only see their own vote', () async {
    await _signIn('care@example.com');
    await votes.vote(post, careCpid);
    await _signIn('owner2@example.com');
    await votes.vote(post, ownerCpid);
    expect(await count(), 2);
    expect(await votes.votedAmong(ownerCpid, [post]), {'$_group/${post.id}'});

    // the other person's vote document cannot be read
    final ref = db()
        .collection('groups')
        .doc(_group)
        .collection('posts')
        .doc(post.id);
    await expectLater(
      ref.collection('votes').doc(careCpid).get(),
      throwsA(isA<FirebaseException>()),
    );

    // clean up: both take their vote back
    await votes.unvote(post, ownerCpid);
    await _signIn('care@example.com');
    await votes.unvote(post, careCpid);
    expect(await count(), 0);
  });

  test(
    'saved posts: add, look up, list, remove; private to the owner',
    () async {
      careUid = await _signIn('care@example.com');
      expect(await saves.savedAmong([post.id, 'other-id']), isEmpty);

      await saves.add(post.id, _group);
      expect(await saves.savedAmong([post.id, 'other-id']), {post.id});
      final page = await saves.page(limit: 20);
      expect(page.bookmarks.map((b) => b.postId), contains(post.id));
      expect(
        page.bookmarks.firstWhere((b) => b.postId == post.id).groupId,
        _group,
      );

      // another user does not see it and cannot read the other's list
      await _signIn('owner2@example.com');
      expect(await saves.savedAmong([post.id]), isEmpty);
      await expectLater(
        db()
            .collection('users')
            .doc(careUid)
            .collection('bookmarks')
            .doc(post.id)
            .get(),
        throwsA(isA<FirebaseException>()),
      );
      await expectLater(
        db()
            .collection('users')
            .doc(careUid)
            .collection('bookmarks')
            .doc('planted')
            .set({
              'groupId': _group,
              'createdAt': FieldValue.serverTimestamp(),
            }),
        throwsA(isA<FirebaseException>()),
      );

      await _signIn('care@example.com');
      await saves.remove(post.id);
      expect(await saves.savedAmong([post.id]), isEmpty);
    },
  );
}
