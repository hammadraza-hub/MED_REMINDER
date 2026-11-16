// M18 step 4 — runs the chat repository against the LOCAL Firebase emulators
// with the real firestore.rules.
//
// Same setup as integration_test/report_data_source_test.dart:
//   firebase emulators:start --only auth,firestore --project medapp-staging
//   python seed_m16.py && python verify_users.py && python seed_report.py
//
//   owner2@example.com / Test1234!  owns profile "pO"
//   care@example.com   / Test1234!  not a member of "pO"; has NOT agreed to AI
//
// Run (Android emulator):
//   flutter test integration_test/chat_repository_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
//
// Refuses to run without USE_EMULATOR so it can never touch a real project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/ai/chat_models.dart';
import 'package:med_remind_app/core/export/export_builder.dart';
import 'package:med_remind_app/core/export/export_collector.dart';
import 'package:med_remind_app/core/export/export_data_source.dart';
import 'package:med_remind_app/repositories/chat_repository.dart';
import 'package:med_remind_app/repositories/firestore_ai_consent_store.dart';

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

  final repo = ChatRepository.instance;
  late String ownerUid;

  setUpAll(() async {
    expect(
      const bool.fromEnvironment('USE_EMULATOR'),
      isTrue,
      reason: 'Run with --dart-define=USE_EMULATOR=true (emulators only)',
    );
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);

    ownerUid = await _signIn('owner2@example.com');
    await FirestoreAiConsentStore().grant();
  });

  tearDownAll(() async {
    await _signIn('owner2@example.com');
    for (final t in await repo.listThreads('pO')) {
      await repo.deleteThread(t.id);
    }
  });

  test('create a thread, add messages, read them back in order', () async {
    final id = await repo.createThread(
      profileId: 'pO',
      firstQuestion: 'What are the side effects of metformin?',
    );
    await repo.addMessage(
      threadId: id,
      role: ChatRole.user,
      text: 'What are the side effects of metformin?',
    );
    await repo.addMessage(
      threadId: id,
      role: ChatRole.assistant,
      text: 'Common ones are nausea and an upset stomach.',
    );

    final threads = await repo.listThreads('pO');
    final t = threads.firstWhere((x) => x.id == id);
    expect(t.title, 'What are the side effects of metformin');
    expect(t.profileId, 'pO');

    final messages = await repo.loadMessages(id);
    expect(messages.map((m) => m.role), [ChatRole.user, ChatRole.assistant]);
    expect(messages.first.text, contains('metformin'));
  });

  test('the thread with the newest message comes first', () async {
    final a = await repo.createThread(
      profileId: 'pO',
      firstQuestion: 'First topic',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final b = await repo.createThread(
      profileId: 'pO',
      firstQuestion: 'Second topic',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.addMessage(threadId: a, role: ChatRole.user, text: 'more');

    final ids = (await repo.listThreads('pO')).map((t) => t.id).toList();
    expect(ids.indexOf(a), lessThan(ids.indexOf(b)));
  });

  test('a very long message is cut to the limit the rules allow', () async {
    final id = await repo.createThread(
      profileId: 'pO',
      firstQuestion: 'long one',
    );
    await repo.addMessage(
      threadId: id,
      role: ChatRole.assistant,
      text: 'x' * 9000,
    );
    final m = (await repo.loadMessages(id)).single;
    expect(m.text.length, ChatLimits.maxTextLength);
  });

  test('a thread cannot be started for a profile the user is not in', () async {
    expect(
      repo.createThread(profileId: 'pF', firstQuestion: 'hello'),
      throwsA(anything),
    );
  });

  test('another user cannot read these chats', () async {
    final id = await repo.createThread(
      profileId: 'pO',
      firstQuestion: 'private question',
    );
    await _signIn('care@example.com');
    final snap = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('chatThreads')
        .doc(id)
        .get();
    await expectLater(snap, throwsA(isA<FirebaseException>()));
    await _signIn('owner2@example.com');
  });

  test('without AI consent no thread can be started', () async {
    await _signIn('care@example.com');
    await expectLater(
      repo.createThread(profileId: 'pF', firstQuestion: 'hello'),
      throwsA(anything),
    );
    await _signIn('owner2@example.com');
  });

  test('the data export includes the chats with their messages', () async {
    final id = await repo.createThread(
      profileId: 'pO',
      firstQuestion: 'export me',
    );
    await repo.addMessage(threadId: id, role: ChatRole.user, text: 'export me');

    final bundle = await ExportCollector(FirestoreExportSource())
        .collect(uid: ownerUid, appVersion: 'test');
    final chat = bundle.chats.firstWhere((c) => c.id == id);
    expect((chat.data['messages'] as List).length, 1);
    expect(
      ExportBuilder.build(bundle).any((f) => f.name == 'chats.json'),
      isTrue,
    );
  });

  test('deleting a thread removes its messages too', () async {
    final id = await repo.createThread(
      profileId: 'pO',
      firstQuestion: 'delete me',
    );
    for (var i = 0; i < 3; i++) {
      await repo.addMessage(threadId: id, role: ChatRole.user, text: 'm$i');
    }
    await repo.deleteThread(id);

    expect((await repo.listThreads('pO')).any((t) => t.id == id), isFalse);
    final left = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('chatThreads')
        .doc(id)
        .collection('messages')
        .get();
    expect(left.docs, isEmpty);
  });
}
