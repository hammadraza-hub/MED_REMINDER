// M19 step 7 — deleting an account removes the community pseudonym, the saved
// posts and the block list, and leaves posts / comments as "[deleted]".
// Runs the real AccountDeletionEngine against the LOCAL emulators with the
// real firestore.rules.
//
// Setup is the same as integration_test/community_moderation_test.dart
// (users, groups, demo data and the moderator account mod@example.com).
//
// Run (Android emulator):
//   flutter test integration_test/community_account_delete_test.dart \
//     -d emulator-5554 --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/account_deletion_engine.dart';
import 'package:med_remind_app/core/community/community_feed.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/core/services/account_purge_service.dart';
import 'package:med_remind_app/repositories/firestore_community_feed_store.dart';
import 'package:med_remind_app/repositories/firestore_community_post_store.dart';
import 'package:med_remind_app/repositories/firestore_community_profile_store.dart';
import 'package:med_remind_app/repositories/firestore_community_reaction_stores.dart';
import 'package:med_remind_app/repositories/firestore_community_safety_stores.dart';

const _host = '10.0.2.2';
const _group = 'general';
const _email = 'leaver@example.com';

Future<String> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  final c = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
  return c.user!.uid;
}

/// Signs in the throw-away account, creating it (and its user document) the
/// first time.
Future<String> _signInLeaver() async {
  await FirebaseAuth.instance.signOut();
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _email,
      password: 'Test1234!',
    );
  } on FirebaseAuthException catch (e) {
    if (e.code != 'email-already-in-use') rethrow;
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email,
      password: 'Test1234!',
    );
  }
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final doc = FirebaseFirestore.instance.collection('users').doc(uid);
  if (!(await doc.get()).exists) {
    await doc.set({'email': _email, 'createdAt': FieldValue.serverTimestamp()});
  }
  return uid;
}

/// The rules only let a user delete their own document after the 7 day grace
/// period of a deletion request. The test cannot wait, so it back-dates the
/// request through the emulator's admin access (header "Bearer owner", which
/// skips the rules and works on the local emulator only).
Future<void> _backdateDeletionRequest(String uid) async {
  final projectId = AppConfig.firebaseOptions.projectId;
  final when = DateTime.now().toUtc().subtract(const Duration(days: 8));
  final client = HttpClient();
  try {
    final req = await client.patchUrl(
      Uri.parse(
        'http://$_host:8080/v1/projects/$projectId/databases/(default)/documents/'
        'users/$uid?updateMask.fieldPaths=deletionRequestedAt',
      ),
    );
    req.headers
      ..set('Authorization', 'Bearer owner')
      ..set('Content-Type', 'application/json');
    req.add(
      utf8.encode(
        jsonEncode({
          'fields': {
            'deletionRequestedAt': {'timestampValue': when.toIso8601String()},
          },
        }),
      ),
    );
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    expect(res.statusCode, 200, reason: body);
  } finally {
    client.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final posts = FirestoreCommunityPostStore();
  late String postId;

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
    try {
      await _signIn('mod@example.com');
      await posts.deletePost(_group, postId);
    } catch (_) {}
  });

  test('delete the account: pseudonym, saved posts and blocks go; the post stays as [deleted]', () async {
    final uid = await _signInLeaver();
    final db = FirebaseFirestore.instance;

    // a pseudonym profile, a post, a saved post and a blocked person
    final profiles = CommunityProfileController(
      FirestoreCommunityProfileStore(),
    );
    await profiles.save(pseudonym: 'soon_gone', avatar: 'a2', bio: 'bye');
    final cpid = (await profiles.myId())!;
    postId = await posts.createPost(
      _group,
      authorId: cpid,
      body: 'my last post',
    );
    await FirestoreCommunityBookmarkStore().add('demo-c01', 'caregivers');
    await FirestoreCommunityBlockStore().block('B' * 20);

    expect(
      (await db.collection('communityProfiles').doc(cpid).get()).exists,
      isTrue,
    );
    expect(
      (await db.collection('users').doc(uid).collection('bookmarks').get())
          .size,
      1,
    );
    expect(
      (await db.collection('users').doc(uid).collection('blocks').get()).size,
      1,
    );

    // the grace period of a deletion request is over
    await _backdateDeletionRequest(uid);

    // the real purge
    final summary = await AccountDeletionEngine(FirestorePurgeStore())
        .purge(uid);
    expect(summary.deletedDocs, greaterThan(0));

    // gone: profile (read as somebody else), user document, saved posts, blocks
    expect(
      (await db.collection('users').doc(uid).collection('bookmarks').get())
          .size,
      0,
    );
    expect(
      (await db.collection('users').doc(uid).collection('blocks').get()).size,
      0,
    );
    expect((await db.collection('users').doc(uid).get()).exists, isFalse);
    await _signIn('care@example.com');
    expect(
      (await db.collection('communityProfiles').doc(cpid).get()).exists,
      isFalse,
    );

    // the post is still there, and the feed shows "[deleted]" (author null)
    final feed = CommunityFeedController(
      FirestoreCommunityFeedStore(),
      _group,
      pageSize: 50,
    );
    await feed.refresh();
    final item = feed.items.firstWhere((i) => i.post.id == postId);
    expect(item.post.body, 'my last post');
    expect(item.author, isNull);
    feed.dispose();
  });
}
