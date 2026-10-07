import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/features/assistant/assistant_chat_screen.dart';

void main() {
  testWidgets('assistant chat → chip send → dummy reply → type/send',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AssistantChatScreen()),
    );
    await tester.pumpAndSettle();

    // ---- HEADER + SEED THREAD ----
    expect(find.text('Med Assistant Chat Thread'), findsOneWidget);
    expect(
      find.text('Online · Answers from your own data'),
      findsOneWidget,
    );
    expect(find.text('TODAY'), findsOneWidget);
    expect(
      find.text('How many doses did I miss this week?'),
      findsOneWidget,
    );
    expect(
      find.text('This week you took 12 of 14 doses (86%).'),
      findsOneWidget,
    );
    expect(find.text('12 TAKEN'), findsOneWidget);
    expect(find.text('1 PENDING'), findsOneWidget);
    expect(find.text('1 MISSED'), findsOneWidget);
    expect(find.text('Adherence Trend'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('SUGGESTED QUERIES'),
      40,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('SUGGESTED QUERIES'), findsOneWidget);
    expect(
      find.text(
        'Not professional medical advice. Always consult your physician.',
      ),
      findsOneWidget,
    );

    // ---- SUGGESTED CHIP TAP → auto send ----
    await tester.ensureVisible(find.text('Metformin side effects?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metformin side effects?'));
    await tester.pumpAndSettle();
    expect(find.text('What are Metformin side effects?'), findsOneWidget);

    // ---- DUMMY AI REPLY (450ms) ----
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('4-day adherence streak', findRichText: true),
      findsOneWidget,
    );

    // ---- TYPE + SEND ----
    await tester.enterText(
      find.byType(TextField),
      'What did I take today?',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('What did I take today?'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('4-day adherence streak', findRichText: true),
      findsNWidgets(2),
    );

    expect(tester.takeException(), isNull);
  });
}
