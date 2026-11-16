import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/ai/ai_chat_backend.dart';
import 'package:med_remind_app/core/ai/chat_controller.dart';
import 'package:med_remind_app/core/ai/chat_models.dart';
import 'package:med_remind_app/core/ai/fda_label.dart';
import 'package:med_remind_app/core/ai/label_question_router.dart';

const metformin = ChatMed(name: 'Metformin 500 MG', rxcui: '860975');
const aspirin = ChatMed(name: 'Aspirin 81 mg');

final texts = ChatTexts(
  emergency: 'EMERGENCY',
  doseChange: 'DOSE',
  diagnosis: 'DIAGNOSIS',
  replyBlocked: 'BLOCKED',
  disclaimer: 'DISCLAIMER',
  aiUnavailable: 'NO-AI',
  labelUnavailable: 'LABEL-DOWN',
  labelNotFound: (n) => 'NO-LABEL $n',
);

FdaLabel label() => const FdaLabel(
  setId: 'abc-123',
  genericName: 'Metformin Hydrochloride',
  effectiveDate: null,
  sections: {
    FdaLabelSection.adverseReactions: 'Nausea and diarrhea are common.',
    FdaLabelSection.indications: 'Used with diet for type 2 diabetes.',
  },
);

class FakeStore implements ChatStore {
  final List<String> log = [];
  final Map<String, List<ChatMessage>> saved = {};
  bool failCreate = false;
  bool failAdd = false;
  bool failLoad = false;
  int _n = 0;

  @override
  Future<String> createThread({
    required String profileId,
    required String firstQuestion,
  }) async {
    if (failCreate) throw Exception('denied');
    final id = 't${++_n}';
    log.add('create:$profileId:$firstQuestion');
    saved[id] = [];
    return id;
  }

  @override
  Future<void> addMessage({
    required String threadId,
    required ChatRole role,
    required String text,
  }) async {
    if (failAdd) throw Exception('denied');
    log.add('add:${role.name}:$text');
    saved[threadId]!.add(
      ChatMessage(
        id: 'm${saved[threadId]!.length}',
        role: role,
        text: text,
        createdAt: DateTime(2026, 11, 16),
      ),
    );
  }

  @override
  Future<List<ChatMessage>> loadMessages(String threadId) async {
    if (failLoad) throw Exception('offline');
    return saved[threadId] ?? [];
  }

  @override
  Future<List<ChatThread>> listThreads(String profileId) async => [];

  @override
  Future<void> deleteThread(String threadId) async {}
}

class FakeBackend implements AiChatBackend {
  FakeBackend({this.available = true, this.reply = 'Some AI answer.'});

  final bool available;
  String reply;
  int calls = 0;
  String? lastContext;
  List<AiChatTurn>? lastHistory;

  @override
  bool get isAvailable => available;

  @override
  Future<AiBackendResult> send({
    required String message,
    required List<AiChatTurn> history,
    required String context,
  }) async {
    calls++;
    lastContext = context;
    lastHistory = history;
    return AiBackendReply(reply);
  }
}

class Harness {
  Harness({
    FakeStore? store,
    AiChatBackend? backend,
    this.meds = const [metformin],
    this.lookup,
    this.profile = 'p1',
  }) : store = store ?? FakeStore(),
       backend = backend ?? FakeBackend() {
    c = ChatController(
      store: this.store,
      backend: this.backend,
      profileId: () => profile,
      loadMeds: () async => meds,
      lookupLabel: ({rxcui, name}) async {
        lookups.add('$rxcui|$name');
        return lookup ?? FdaLabelFound(label());
      },
      loadContext: () async {
        contextCalls++;
        return 'CONTEXT';
      },
      clock: () => DateTime(2026, 11, 16, 10),
    );
  }

  final FakeStore store;
  final AiChatBackend backend;
  final List<ChatMed> meds;
  final FdaLookupResult? lookup;
  final String? profile;
  final List<String> lookups = [];
  int contextCalls = 0;
  late final ChatController c;

  String get last => c.messages.last.text;
}

void main() {
  group('LabelQuestionRouter', () {
    test('side effects of a named medicine', () {
      final q = LabelQuestionRouter.route(
        'What are the side effects of metformin?',
        [metformin, aspirin],
      );
      expect(q!.med.name, metformin.name);
      expect(q.section, FdaLabelSection.adverseReactions);
    });

    test('other sections', () {
      FdaLabelSection? s(String t) =>
          LabelQuestionRouter.route(t, [metformin, aspirin])?.section;
      expect(s('What is aspirin used for?'), FdaLabelSection.indications);
      expect(s('Any warnings for metformin?'), FdaLabelSection.warnings);
      expect(
        s('Does metformin interact with aspirin?'),
        FdaLabelSection.interactions,
      );
      expect(s('How should I store aspirin?'), FdaLabelSection.storage);
      expect(
        s('Who should not take metformin? contraindications'),
        FdaLabelSection.contraindications,
      );
      expect(s('metformin boxed warning'), FdaLabelSection.boxedWarning);
    });

    test('other languages', () {
      FdaLabelSection? s(String t) =>
          LabelQuestionRouter.route(t, [metformin, aspirin])?.section;
      expect(
        s('¿Cuáles son los efectos secundarios de metformin?'),
        FdaLabelSection.adverseReactions,
      );
      expect(
        s('Quels sont les effets secondaires de metformin ?'),
        FdaLabelSection.adverseReactions,
      );
      expect(s('¿Para qué sirve metformin?'), FdaLabelSection.indications);
      expect(s('À quoi sert metformin ?'), FdaLabelSection.indications);
      expect(
        s('metformin के दुष्प्रभाव क्या हैं?'),
        FdaLabelSection.adverseReactions,
      );
      expect(
        s('metformin kis liye hoti hai? kis kaam'),
        FdaLabelSection.indications,
      );
      expect(
        s('ما هي الآثار الجانبية لـ metformin؟'),
        FdaLabelSection.adverseReactions,
      );
    });

    test('a question with no medicine named needs exactly one medicine', () {
      expect(
        LabelQuestionRouter.route('What are the side effects?', [
          metformin,
        ])?.med.name,
        metformin.name,
      );
      expect(
        LabelQuestionRouter.route('What are the side effects?', [
          metformin,
          aspirin,
        ]),
        isNull,
      );
    });

    test('not a label question -> null', () {
      for (final t in [
        'What time is my next dose?',
        'How is my adherence?',
        'Hello',
        'side effects',
      ]) {
        expect(LabelQuestionRouter.route(t, const []), isNull, reason: t);
      }
      expect(
        LabelQuestionRouter.route('How is my adherence?', [metformin]),
        isNull,
      );
    });
  });

  group('ChatController: how a question is answered', () {
    test('a dose question gets the safe message, no label, no AI', () async {
      final h = Harness();
      await h.c.init();
      await h.c.send('Can I double my dose of metformin?', texts);
      expect(h.last, 'DOSE');
      expect(h.lookups, isEmpty);
      expect((h.backend as FakeBackend).calls, 0);
    });

    test('emergency and diagnosis messages', () async {
      final h = Harness();
      await h.c.init();
      await h.c.send('I have chest pain', texts);
      expect(h.last, 'EMERGENCY');
      await h.c.send('What is this rash?', texts);
      expect(h.last, 'DIAGNOSIS');
    });

    test(
      'a label question is answered from the FDA label with its source',
      () async {
        final h = Harness();
        await h.c.init();
        await h.c.send('What are the side effects of metformin?', texts);
        expect(h.lookups, ['860975|Metformin 500 MG']);
        expect(h.last, contains('Side effects'));
        expect(h.last, contains('Nausea and diarrhea are common.'));
        expect(h.last, contains('FDA drug label (openFDA)'));
        expect(
          h.last,
          contains(
            'https://dailymed.nlm.nih.gov/dailymed/lookup.cfm?setid=abc-123',
          ),
        );
        expect(h.last, endsWith('DISCLAIMER'));
        expect((h.backend as FakeBackend).calls, 0);
      },
    );

    test(
      'a label with no such section, no label, and a failed lookup',
      () async {
        final h1 = Harness();
        await h1.c.init();
        await h1.c.send('Any warnings for metformin?', texts); // label has none
        expect(h1.last, startsWith('NO-LABEL Metformin 500 MG'));

        final h2 = Harness(lookup: const FdaLabelNotFound());
        await h2.c.init();
        await h2.c.send('Side effects of metformin?', texts);
        expect(h2.last, startsWith('NO-LABEL'));

        final h3 = Harness(lookup: const FdaLabelUnavailable('network'));
        await h3.c.init();
        await h3.c.send('Side effects of metformin?', texts);
        expect(h3.last, startsWith('LABEL-DOWN'));
      },
    );

    test(
      'any other question with no AI says so and builds no context',
      () async {
        final h = Harness(backend: const UnavailableAiBackend());
        await h.c.init();
        await h.c.send('How is my adherence this month?', texts);
        expect(h.last, 'NO-AI\n\nDISCLAIMER');
        expect(h.contextCalls, 0);
      },
    );

    test(
      'with an AI backend the answer is checked and the context is given',
      () async {
        final backend = FakeBackend(reply: 'Your adherence is 75%.');
        final h = Harness(backend: backend);
        await h.c.init();
        await h.c.send('How is my adherence this month?', texts);
        expect(backend.lastContext, 'CONTEXT');
        expect(h.last, 'Your adherence is 75%.\n\nDISCLAIMER');

        backend.reply = 'You should double your dose tonight.';
        await h.c.send('And tonight?', texts);
        expect(h.last, startsWith('BLOCKED'));
        expect(h.last, isNot(contains('double your dose')));
      },
    );

    test('earlier messages are given to the AI as history', () async {
      final backend = FakeBackend();
      final h = Harness(backend: backend);
      await h.c.init();
      await h.c.send('How is my adherence?', texts);
      await h.c.send('And last week?', texts);
      expect(backend.lastHistory!.length, 2);
      expect(backend.lastHistory!.first.isUser, isTrue);
      expect(backend.lastHistory!.last.isUser, isFalse);
    });
  });

  group('ChatController: saving', () {
    test('the first message starts a thread, every message is saved', () async {
      final h = Harness(backend: const UnavailableAiBackend());
      await h.c.init();
      await h.c.send('How is my adherence?', texts);

      expect(h.store.log.first, 'create:p1:How is my adherence?');
      expect(h.store.log, contains('add:user:How is my adherence?'));
      expect(h.store.log.last, startsWith('add:assistant:NO-AI'));
      expect(h.c.threadId, 't1');
      expect(h.store.saved['t1']!.length, 2);

      await h.c.send('Another question', texts);
      expect(h.store.log.where((l) => l.startsWith('create')).length, 1);
      expect(h.store.saved['t1']!.length, 4);
    });

    test('safe fixed answers are saved too', () async {
      final h = Harness();
      await h.c.init();
      await h.c.send('Can I double my dose?', texts);
      expect(h.store.saved['t1']!.last.text, 'DOSE');
    });

    test('a failing save keeps the chat going and warns once', () async {
      final store = FakeStore()..failCreate = true;
      final h = Harness(store: store, backend: const UnavailableAiBackend());
      await h.c.init();
      await h.c.send('Question one', texts);
      expect(h.c.messages.length, 2); // chat still works
      expect(h.c.takeSaveWarning(), isTrue);
      expect(h.c.takeSaveWarning(), isFalse);

      store.failCreate = false;
      await h.c.send('Question two', texts); // tried again, now it works
      expect(h.c.threadId, isNotNull);
      expect(h.c.takeSaveWarning(), isFalse);
    });

    test('no profile selected -> nothing is saved, no warning', () async {
      final h = Harness(profile: null, backend: const UnavailableAiBackend());
      await h.c.init();
      await h.c.send('Question', texts);
      expect(h.store.log, isEmpty);
      expect(h.c.takeSaveWarning(), isFalse);
    });
  });

  group('ChatController: threads and limits', () {
    test('open an old thread, then continue it', () async {
      final store = FakeStore();
      final first = Harness(
        store: store,
        backend: const UnavailableAiBackend(),
      );
      await first.c.init();
      await first.c.send('Old question', texts);

      final h = Harness(store: store, backend: const UnavailableAiBackend());
      await h.c.init();
      await h.c.openThread('t1');
      expect(h.c.messages.length, 2);
      expect(h.c.threadId, 't1');

      await h.c.send('New question', texts);
      expect(store.saved['t1']!.length, 4);
      expect(store.log.where((l) => l.startsWith('create')).length, 1);
    });

    test('a thread that cannot be loaded is reported', () async {
      final store = FakeStore()..failLoad = true;
      final h = Harness(store: store);
      await h.c.openThread('t1');
      expect(h.c.loadFailed, isTrue);
      expect(h.c.isLoadingThread, isFalse);
    });

    test('newChat clears everything', () async {
      final h = Harness(backend: const UnavailableAiBackend());
      await h.c.init();
      await h.c.send('Question', texts);
      h.c.newChat();
      expect(h.c.messages, isEmpty);
      expect(h.c.threadId, isNull);
      await h.c.send('Again', texts);
      expect(h.store.log.where((l) => l.startsWith('create')).length, 2);
    });

    test('a full thread accepts nothing more', () async {
      final h = Harness(backend: const UnavailableAiBackend());
      await h.c.init();
      for (var i = 0; i < ChatLimits.maxMessagesPerThread ~/ 2; i++) {
        await h.c.send('q$i', texts);
      }
      expect(h.c.isFull, isTrue);
      final before = h.c.messages.length;
      await h.c.send('one too many', texts);
      expect(h.c.messages.length, before);
    });

    test('empty text and a second send while replying are ignored', () async {
      final h = Harness(backend: const UnavailableAiBackend());
      await h.c.init();
      await h.c.send('   ', texts);
      expect(h.c.messages, isEmpty);

      final a = h.c.send('first', texts);
      final b = h.c.send('second', texts); // ignored: still replying
      await Future.wait([a, b]);
      expect(h.c.messages.where((m) => m.isUser).length, 1);
    });
  });
}
