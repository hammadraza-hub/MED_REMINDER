// M19 step 7 — moderation against the LOCAL Firebase emulators with the real
// firestore.rules.
//
// Setup is the same as integration_test/community_posts_test.dart, plus a
// moderator account:
//   set FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
//   node tools/set_moderator.js --project medapp-staging \
//       --email mod@example.com --create
//
// Run (Android emulator):
//   flutter test integration_test/community_moderation_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/community/community_feed.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_moderation.dart';
import 'package:med_remind_app/core/community/community_posts.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/core/community/community_safety.dart';
import 'package:med_remind_app/repositories/firestore_community_moderation_store.dart';
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
  final moderation = FirestoreCommunityModerationStore();
  FirebaseFirestore db() => FirebaseFirestore.instance;
  late String ownerCpid;
  late String careCpid;
  late String postId;
  late String commentId;

  CommunityReportActions reportsFor(String cpid) =>
      CommunityReportActions(FirestoreCommunityReportStore(), () async => cpid);

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
      body: 'post to be moderated',
    );
    commentId = await posts.createComment(
      _group,
      postId,
      authorId: ownerCpid,
      body: 'comment to be moderated',
    );
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
  });

  tearDownAll(() async {
    try {
      await _signIn('owner2@example.com');
      await posts.deletePost(_group, postId);
    } catch (_) {}
  });

  Future<bool> isModerator() async {
    final t = await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
    return t.claims?['moderator'] == true;
  }

  test('only the moderator account has the claim', () async {
    await _signIn('mod@example.com');
    expect(await isModerator(), isTrue);
    await _signIn('care@example.com');
    expect(await isModerator(), isFalse);
  });

  test('a normal user cannot read, hide, delete or clear anything', () async {
    await _signIn('care@example.com');
    await expectLater(
      moderation.reports(limit: 20),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      moderation.setHidden(_group, postId, true),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      moderation.deleteReportsFor(_group, postId),
      throwsA(isA<FirebaseException>()),
    );
    expect((await posts.getPost(_group, postId))!.hidden, isFalse);
  });

  test(
    'the moderator lists reports as controller entries, with the content',
    () async {
      await _signIn('mod@example.com');
      final c = CommunityModerationController(
        moderation,
        posts,
        _ProfilesOnly(),
      );
      await c.refresh();
      expect(c.status, CommunityModerationStatus.ready);
      final entries = c.entries.where((e) => e.postId == postId).toList();
      expect(entries.length, 2);
      final post = entries.firstWhere((e) => !e.isComment);
      final comment = entries.firstWhere((e) => e.isComment);
      expect(post.post!.body, 'post to be moderated');
      expect(post.reports.single.reason, CommunityReportReason.medical);
      expect(comment.comment!.body, 'comment to be moderated');
      c.dispose();
    },
  );

  test('hide: gone from the feed, still readable by author and moderator; no comments on it; show again', () async {
    await _signIn('mod@example.com');
    await moderation.setHidden(_group, postId, true);

    // another user: not readable, and not in the feed query either
    await _signIn('care@example.com');
    expect(await posts.getPost(_group, postId), isNull);
    final feed = await db()
        .collection('groups')
        .doc(_group)
        .collection('posts')
        .where('hidden', isEqualTo: false)
        .get();
    expect(feed.docs.map((d) => d.id), isNot(contains(postId)));
    await expectLater(
      CommunityPostActions(
        posts,
        () async => careCpid,
      ).createComment(_group, postId, 'can I comment?'),
      throwsA(isA<CommunityDeniedException>()),
    );

    // the author still sees it
    await _signIn('owner2@example.com');
    expect((await posts.getPost(_group, postId))!.hidden, isTrue);

    // the moderator can show it again
    await _signIn('mod@example.com');
    await moderation.setHidden(_group, postId, false);
    await _signIn('care@example.com');
    expect((await posts.getPost(_group, postId))!.hidden, isFalse);
  });

  test('the moderator can change only "hidden", nothing else', () async {
    await _signIn('mod@example.com');
    final ref = db()
        .collection('groups')
        .doc(_group)
        .collection('posts')
        .doc(postId);
    await expectLater(
      ref.update({'body': 'rewritten by a moderator'}),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      ref.update({'voteCount': 50}),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      ref.update({'hidden': true, 'body': 'x'}),
      throwsA(isA<FirebaseException>()),
    );
    expect((await posts.getPost(_group, postId))!.body, 'post to be moderated');
  });

  test(
    'delete a comment and a post as the moderator; reports are cleared',
    () async {
      await _signIn('mod@example.com');
      final c = CommunityModerationController(
        moderation,
        posts,
        _ProfilesOnly(),
      );
      await c.refresh();

      final commentEntry = c.entries.firstWhere(
        (e) => e.postId == postId && e.isComment,
      );
      await c.deleteTarget(commentEntry);
      expect(await posts.commentCount(_group, postId), 0);

      final postEntry = c.entries.firstWhere(
        (e) => e.postId == postId && !e.isComment,
      );
      await c.deleteTarget(postEntry);
      expect(await posts.getPost(_group, postId), isNull);

      final left = await moderation.reports(limit: 50);
      expect(left.reports.where((r) => r.postId == postId), isEmpty);
      c.dispose();
    },
  );
}

/// The controller only asks the feed store for profiles.
class _ProfilesOnly implements CommunityFeedStore {
  @override
  Future<Map<String, CommunityProfile>> profiles(Set<String> ids) async {
    final out = <String, CommunityProfile>{};
    for (final id in ids) {
      final s = await FirebaseFirestore.instance
          .collection('communityProfiles')
          .doc(id)
          .get();
      if (s.exists) out[id] = CommunityProfile.fromMap(id, s.data()!);
    }
    return out;
  }

  @override
  Future<List<CommunityGroup>> groups() => throw UnimplementedError();

  @override
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  }) => throw UnimplementedError();
}
