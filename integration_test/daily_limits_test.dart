// M21 step 6 — the daily limits (posts 20, support tickets 5) through the app's
// own code against the LOCAL Firebase emulators with the real firestore.rules.
//
// Setup (same as integration_test/community_posts_test.dart):
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node tools/seed_community.js \
//       --project medapp-staging --demo
//
// Run (Android emulator):
//   flutter test integration_test/daily_limits_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/core/daily_limits.dart';
import 'package:med_remind_app/models/support_ticket.dart';
import 'package:med_remind_app/repositories/firestore_community_post_store.dart';
import 'package:med_remind_app/repositories/firestore_community_profile_store.dart';
import 'package:med_remind_app/repositories/support_repository.dart';

const _host = '10.0.2.2';
const _group = 'general';

// Looked up when used: Firebase is initialised in setUpAll.
FirebaseFirestore get db => FirebaseFirestore.instance;

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
}

/// Starts the day with an empty counter (the emulator keeps data between
/// runs). Uses the emulator's admin bearer token; no rules involved.
Future<void> _resetCounter(String uid) async {
  final day = DailyLimits.dayNumber(DateTime.now());
  final client = HttpClient();
  try {
    final req = await client.deleteUrl(
      Uri.parse(
        'http://$_host:8080/v1/projects/medapp-staging/databases/(default)'
        '/documents/users/$uid/limits/$day',
      ),
    );
    req.headers.set('Authorization', 'Bearer owner');
    await (await req.close()).drain<void>();
  } finally {
    client.close(force: true);
  }
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
    await _resetCounter(FirebaseAuth.instance.currentUser!.uid);
  });

  test(
    'posts: 20 a day work, the 21st is refused with the limit error',
    () async {
      await _signIn('owner2@example.com');
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _resetCounter(uid);

      final profiles = CommunityProfileController(
        FirestoreCommunityProfileStore(),
      );
      if (await profiles.load() == null) {
        await profiles.save(pseudonym: 'limit_user', avatar: 'a1', bio: '');
      }
      final myId = (await profiles.myId())!;

      for (var i = 1; i <= DailyLimitKind.posts.max; i++) {
        created.add(
          await store.createPost(_group, authorId: myId, body: 'limit post $i'),
        );
      }
      var counter = await DailyLimits.counter(db, uid).get();
      expect(counter.data()!['posts'], DailyLimitKind.posts.max);

      // The app says so before writing...
      await expectLater(
        store.createPost(_group, authorId: myId, body: 'one too many'),
        throwsA(isA<DailyLimitException>()),
      );

      // ...and the RULES say no even to a client that skips that check.
      final batch = db.batch()
        ..set(
          db.collection('groups').doc(_group).collection('posts').doc(),
          CommunityFeedPost.createMap(authorId: myId, body: 'sneaky'),
        );
      DailyLimits.bump(batch, db, uid, DailyLimitKind.posts);
      await expectLater(
        batch.commit(),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );

      // And a post written WITHOUT the counter is refused too.
      await expectLater(
        db
            .collection('groups')
            .doc(_group)
            .collection('posts')
            .add(
              CommunityFeedPost.createMap(authorId: myId, body: 'no counter'),
            ),
        throwsA(isA<FirebaseException>()),
      );

      counter = await DailyLimits.counter(db, uid).get();
      expect(counter.data()!['posts'], DailyLimitKind.posts.max);
    },
  );

  test('support tickets: 5 a day work, the 6th is refused', () async {
    await _signIn('care@example.com');
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _resetCounter(uid);

    SupportTicket ticket(int i) => SupportTicket.fromForm(
      uid: uid,
      subject: 'Limit test $i',
      body: 'Testing the daily ticket limit',
      appVersion: '1.0.0+1',
      device: 'emulator',
      locale: 'en',
    );

    for (var i = 1; i <= DailyLimitKind.tickets.max; i++) {
      expect(
        await SupportRepository.instance.submit(ticket(i)),
        TicketSendResult.sent,
      );
    }
    await expectLater(
      SupportRepository.instance.submit(ticket(6)),
      throwsA(isA<DailyLimitException>()),
    );
    final counter = await DailyLimits.counter(db, uid).get();
    expect(counter.data()!['tickets'], DailyLimitKind.tickets.max);
    await _resetCounter(uid);
  });
}
