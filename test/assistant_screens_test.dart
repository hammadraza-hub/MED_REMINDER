import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/ai/ai_chat_backend.dart';
import 'package:med_remind_app/core/ai/chat_controller.dart';
import 'package:med_remind_app/core/ai/chat_models.dart';
import 'package:med_remind_app/core/ai/fda_label.dart';
import 'package:med_remind_app/core/ai/label_question_router.dart';
import 'package:med_remind_app/features/assistant/assistant_chat_screen.dart';
import 'package:med_remind_app/features/assistant/assistant_history_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

class MemStore implements ChatStore {
  final Map<String, ChatThread> threads = {};
  final Map<String, List<ChatMessage>> messages = {};
  bool failCreate = false;
  bool failList = false;
  bool failDelete = false;
  int _n = 0;

  void seed(
    String id,
    String title,
    List<(ChatRole, String)> msgs, {
    DateTime? at,
  }) {
    final when = at ?? DateTime.now();
    threads[id] = ChatThread(
      id: id,
      profileId: 'p1',
      title: title,
      createdAt: when,
      updatedAt: when,
    );
    messages[id] = [
      for (var i = 0; i < msgs.length; i++)
        ChatMessage(
          id: 'm$i',
          role: msgs[i].$1,
          text: msgs[i].$2,
          createdAt: when,
        ),
    ];
  }

  @override
  Future<String> createThread({
    required String profileId,
    required String firstQuestion,
  }) async {
    if (failCreate) throw Exception('denied');
    final id = 'n${++_n}';
    seed(id, firstQuestion, const []);
    return id;
  }

  @override
  Future<void> addMessage({
    required String threadId,
    required ChatRole role,
    required String text,
  }) async {
    messages[threadId]!.add(
      ChatMessage(
        id: 'x${messages[threadId]!.length}',
        role: role,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<ChatMessage>> loadMessages(String threadId) async =>
      messages[threadId] ?? [];

  @override
  Future<List<ChatThread>> listThreads(String profileId) async {
    if (failList) throw Exception('offline');
    final list = threads.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> deleteThread(String threadId) async {
    if (failDelete) throw Exception('denied');
    threads.remove(threadId);
    messages.remove(threadId);
  }
}

const metformin = ChatMed(name: 'Metformin 500 MG', rxcui: '860975');

ChatController controller(
  MemStore store, {
  List<ChatMed> meds = const [metformin],
}) {
  return ChatController(
    store: store,
    backend: const UnavailableAiBackend(),
    profileId: () => 'p1',
    loadMeds: () async => meds,
    lookupLabel: ({rxcui, name}) async => const FdaLabelFound(
      FdaLabel(
        setId: 'set-1',
        genericName: 'Metformin Hydrochloride',
        sections: {
          FdaLabelSection.adverseReactions: 'Nausea and diarrhea are common.',
        },
      ),
    ),
    loadContext: () async => 'CONTEXT',
  );
}

Widget app(Widget home) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: home,
);

void bigScreen(WidgetTester t) {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> typeAndSend(WidgetTester t, String text) async {
  await t.enterText(find.byKey(const Key('chat-input')), text);
  await t.tap(find.byKey(const Key('chat-send')));
  await t.pumpAndSettle();
}

void main() {
  group('chat screen', () {
    testWidgets(
      'an empty chat shows a hint and questions about the first medicine',
      (t) async {
        bigScreen(t);
        await t.pumpWidget(
          app(AssistantChatScreen(controller: controller(MemStore()))),
        );
        await t.pumpAndSettle();

        expect(find.text('AI assistant'), findsOneWidget);
        expect(
          find.textContaining('Ask about one of your medicines'),
          findsOneWidget,
        );
        expect(
          find.text('What are the side effects of Metformin?'),
          findsOneWidget,
        );
        expect(find.text('What is Metformin used for?'), findsOneWidget);
        expect(
          find.text('What are the warnings for Metformin?'),
          findsOneWidget,
        );
      },
    );

    testWidgets('no medicines -> no suggestions', (t) async {
      bigScreen(t);
      await t.pumpWidget(
        app(
          AssistantChatScreen(
            controller: controller(MemStore(), meds: const []),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('side effects of'), findsNothing);
    });

    testWidgets(
      'a suggested question is answered from the FDA label and saved',
      (t) async {
        bigScreen(t);
        final store = MemStore();
        await t.pumpWidget(
          app(AssistantChatScreen(controller: controller(store))),
        );
        await t.pumpAndSettle();

        await t.tap(find.text('What are the side effects of Metformin?'));
        await t.pumpAndSettle();

        expect(
          find.textContaining('Nausea and diarrhea are common.'),
          findsOneWidget,
        );
        expect(find.textContaining('FDA drug label (openFDA)'), findsOneWidget);
        expect(find.textContaining('dailymed.nlm.nih.gov'), findsOneWidget);
        expect(find.textContaining('General information only'), findsOneWidget);

        final saved = store.messages.values.single;
        expect(saved.length, 2);
        expect(saved.first.isUser, isTrue);
        // suggestions are gone once the chat has started
        expect(find.text('What is Metformin used for?'), findsNothing);
      },
    );

    testWidgets('a dose question gets the safe message', (t) async {
      bigScreen(t);
      await t.pumpWidget(
        app(AssistantChatScreen(controller: controller(MemStore()))),
      );
      await t.pumpAndSettle();
      await typeAndSend(t, 'Can I double my dose today?');
      expect(find.textContaining('cannot advise on changing'), findsOneWidget);
    });

    testWidgets('any other question says AI answers are not available yet', (
      t,
    ) async {
      bigScreen(t);
      await t.pumpWidget(
        app(AssistantChatScreen(controller: controller(MemStore()))),
      );
      await t.pumpAndSettle();
      await typeAndSend(t, 'How is my adherence this month?');
      expect(
        find.textContaining('AI-written answers are not available yet'),
        findsOneWidget,
      );
    });

    testWidgets('a saved thread opens with its messages and continues', (
      t,
    ) async {
      bigScreen(t);
      final store = MemStore()
        ..seed('old', 'Old chat', [
          (ChatRole.user, 'Earlier question'),
          (ChatRole.assistant, 'Earlier answer'),
        ]);
      await t.pumpWidget(
        app(
          AssistantChatScreen(threadId: 'old', controller: controller(store)),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Earlier question'), findsOneWidget);
      expect(find.text('Earlier answer'), findsOneWidget);

      await typeAndSend(t, 'How is my adherence?');
      expect(store.messages['old']!.length, 4);
      expect(store.threads.length, 1);
    });

    testWidgets('a failed save shows a message but the chat goes on', (
      t,
    ) async {
      bigScreen(t);
      final store = MemStore()..failCreate = true;
      await t.pumpWidget(
        app(AssistantChatScreen(controller: controller(store))),
      );
      await t.pumpAndSettle();
      await typeAndSend(t, 'How is my adherence?');
      expect(
        find.text('This message could not be saved to your history.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('AI-written answers are not available yet'),
        findsOneWidget,
      );
    });

    testWidgets('New chat clears the conversation', (t) async {
      bigScreen(t);
      await t.pumpWidget(
        app(AssistantChatScreen(controller: controller(MemStore()))),
      );
      await t.pumpAndSettle();
      await typeAndSend(t, 'How is my adherence?');
      expect(find.textContaining('AI-written answers'), findsOneWidget);

      await t.tap(find.byKey(const Key('chat-new')));
      await t.pumpAndSettle();
      expect(find.textContaining('AI-written answers'), findsNothing);
      expect(
        find.textContaining('Ask about one of your medicines'),
        findsOneWidget,
      );
    });

    testWidgets('a full thread shows the banner and New chat starts again', (
      t,
    ) async {
      bigScreen(t);
      final store = MemStore()
        ..seed('full', 'Full', [
          for (var i = 0; i < ChatLimits.maxMessagesPerThread; i++)
            (i.isEven ? ChatRole.user : ChatRole.assistant, 'msg $i'),
        ]);
      await t.pumpWidget(
        app(
          AssistantChatScreen(threadId: 'full', controller: controller(store)),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text('This chat is full. Please start a new chat.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-input')), findsNothing);

      await t.tap(find.byKey(const Key('chat-full-new')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chat-input')), findsOneWidget);
    });
  });

  group('history screen', () {
    Future<AssistantHistoryChoice?> openAndPick(
      WidgetTester t,
      MemStore store,
      Future<void> Function() act,
    ) async {
      bigScreen(t);
      AssistantHistoryChoice? result;
      var popped = false;
      await t.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context)
                        .push<AssistantHistoryChoice>(
                          MaterialPageRoute(
                            builder: (_) => AssistantHistoryScreen(
                              store: store,
                              profileId: 'p1',
                            ),
                          ),
                        );
                    popped = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await act();
      expect(popped || result == null, isTrue);
      return result;
    }

    testWidgets('lists the saved chats, newest first, with date labels', (
      t,
    ) async {
      final store = MemStore()
        ..seed(
          'a',
          'Older chat',
          const [],
          at: DateTime.now().subtract(const Duration(days: 1)),
        )
        ..seed('b', 'Newest chat', const []);
      await openAndPick(t, store, () async {
        expect(find.text('Newest chat'), findsOneWidget);
        expect(find.text('Older chat'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Yesterday'), findsOneWidget);
        expect(
          t.getTopLeft(find.text('Newest chat')).dy,
          lessThan(t.getTopLeft(find.text('Older chat')).dy),
        );
      });
    });

    testWidgets('no chats -> empty message', (t) async {
      await openAndPick(t, MemStore(), () async {
        expect(find.text('No conversations yet'), findsOneWidget);
      });
    });

    testWidgets('a load error shows Try again, which reloads', (t) async {
      final store = MemStore()..failList = true;
      await openAndPick(t, store, () async {
        expect(find.byKey(const Key('error-text')), findsOneWidget);
        store.failList = false;
        store.seed('a', 'Back again', const []);
        await t.tap(find.byKey(const Key('history-retry')));
        await t.pumpAndSettle();
        expect(find.text('Back again'), findsOneWidget);
      });
    });

    testWidgets('tapping a chat returns it, New chat returns "new"', (t) async {
      final store = MemStore()..seed('a', 'Pick me', const []);
      final picked = await openAndPick(t, store, () async {
        await t.tap(find.byKey(const Key('history-thread-a')));
        await t.pumpAndSettle();
      });
      expect(picked!.threadId, 'a');

      final fresh = await openAndPick(t, store, () async {
        await t.tap(find.byKey(const Key('history-new')));
        await t.pumpAndSettle();
      });
      expect(fresh!.threadId, isNull);
    });

    testWidgets('delete asks first, then removes the chat', (t) async {
      final store = MemStore()..seed('a', 'Delete me', const []);
      await openAndPick(t, store, () async {
        await t.tap(find.byKey(const Key('history-delete-a')));
        await t.pumpAndSettle();
        expect(find.text('Delete this chat?'), findsOneWidget);

        await t.tap(find.text('Cancel'));
        await t.pumpAndSettle();
        expect(find.text('Delete me'), findsOneWidget);
        expect(store.threads, isNotEmpty);

        await t.tap(find.byKey(const Key('history-delete-a')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('history-confirm-delete')));
        await t.pumpAndSettle();
        expect(find.text('Delete me'), findsNothing);
        expect(find.text('Chat deleted'), findsOneWidget);
        expect(store.threads, isEmpty);
      });
    });

    testWidgets('a failed delete keeps the chat and says so', (t) async {
      final store = MemStore()
        ..seed('a', 'Keep me', const [])
        ..failDelete = true;
      await openAndPick(t, store, () async {
        await t.tap(find.byKey(const Key('history-delete-a')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('history-confirm-delete')));
        await t.pumpAndSettle();
        expect(find.text('Keep me'), findsOneWidget);
        expect(find.text('Could not delete the chat.'), findsOneWidget);
      });
    });
  });
}
