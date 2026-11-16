import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/ai/ai_consent.dart';
import 'package:med_remind_app/features/assistant/ai_consent_screen.dart';
import 'package:med_remind_app/features/assistant/assistant_gate.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

class FakeStore implements AiConsentStore {
  DateTime? at;
  bool failWrite = false;
  bool failRead = false;

  @override
  Future<DateTime?> read() async {
    if (failRead) throw Exception('offline');
    return at;
  }

  @override
  Future<void> grant() async {
    if (failWrite) throw Exception('denied');
    at = DateTime(2026, 11, 16);
  }

  @override
  Future<void> withdraw() async => at = null;
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

/// A home with one button that opens the assistant through the gate.
class Launcher extends StatelessWidget {
  const Launcher(this.consent, {super.key});
  final AiConsentController consent;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () => openAssistant(
          context,
          consent: consent,
          chatBuilder: (_) => const Scaffold(body: Text('CHAT OPEN')),
        ),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  testWidgets('consent screen explains what is and is not shared', (t) async {
    t.view.physicalSize = const Size(800, 2200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      app(AiConsentScreen(controller: AiConsentController(FakeStore()))),
    );
    expect(find.text('Before you use the AI assistant'), findsOneWidget);
    expect(find.text('What is shared'), findsOneWidget);
    expect(find.text('What is never shared'), findsOneWidget);
    expect(find.byKey(const Key('ai-consent-agree')), findsOneWidget);
    expect(find.byKey(const Key('ai-consent-not-now')), findsOneWidget);
  });

  testWidgets('without consent: the consent screen shows, chat stays shut', (
    t,
  ) async {
    final store = FakeStore();
    final c = AiConsentController(store);
    await t.pumpWidget(app(Launcher(c)));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Before you use the AI assistant'), findsOneWidget);
    expect(find.text('CHAT OPEN'), findsNothing);
  });

  testWidgets('Agree saves consent and opens the chat', (t) async {
    final store = FakeStore();
    final c = AiConsentController(store);
    await t.pumpWidget(app(Launcher(c)));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('ai-consent-agree')));
    await t.pumpAndSettle();
    expect(store.at, isNotNull);
    expect(find.text('CHAT OPEN'), findsOneWidget);
  });

  testWidgets('Not now saves nothing and the chat does not open', (t) async {
    final store = FakeStore();
    final c = AiConsentController(store);
    await t.pumpWidget(app(Launcher(c)));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('ai-consent-not-now')));
    await t.pumpAndSettle();
    expect(store.at, isNull);
    expect(find.text('CHAT OPEN'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('with consent already saved the chat opens directly', (t) async {
    final store = FakeStore()..at = DateTime(2026, 11, 1);
    final c = AiConsentController(store);
    await t.pumpWidget(app(Launcher(c)));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('CHAT OPEN'), findsOneWidget);
    expect(find.text('Before you use the AI assistant'), findsNothing);
  });

  testWidgets('a consent that cannot be read counts as not given', (t) async {
    final store = FakeStore()
      ..at = DateTime(2026, 11, 1)
      ..failRead = true;
    final c = AiConsentController(store);
    await t.pumpWidget(app(Launcher(c)));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('CHAT OPEN'), findsNothing);
    expect(find.text('Before you use the AI assistant'), findsOneWidget);
  });

  testWidgets(
    'a failed save shows a message and keeps the user on the screen',
    (t) async {
      final store = FakeStore()..failWrite = true;
      final c = AiConsentController(store);
      await t.pumpWidget(app(Launcher(c)));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('ai-consent-agree')));
      await t.pumpAndSettle();
      expect(
        find.text(
          'Could not save your choice. Please check your connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('CHAT OPEN'), findsNothing);
      expect(find.text('Before you use the AI assistant'), findsOneWidget);
    },
  );
}
