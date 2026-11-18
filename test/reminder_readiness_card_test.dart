import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reminders/reminder_readiness.dart';
import 'package:med_remind_app/features/settings/reminder_readiness_card.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

Widget app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

ReminderReadiness r({
  bool n = true,
  bool e = true,
  bool b = true,
  String maker = 'google',
}) => ReminderReadiness(
  notifications: n,
  exactAlarms: e,
  batteryUnrestricted: b,
  manufacturer: maker,
);

void main() {
  testWidgets('all allowed: the card shows nothing', (t) async {
    await t.pumpWidget(app(ReminderReadinessCard(service: () async => r())));
    await t.pump();
    expect(find.byKey(const Key('reminder-readiness-card')), findsNothing);
  });

  testWidgets('notifications off: the card shows and opens the sheet', (
    t,
  ) async {
    await t.pumpWidget(
      app(ReminderReadinessCard(service: () async => r(n: false))),
    );
    await t.pump();
    expect(find.byKey(const Key('reminder-readiness-card')), findsOneWidget);
    await t.tap(find.byKey(const Key('reminder-readiness-fix')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('reminder-setup-sheet')), findsOneWidget);
    expect(
      find.byKey(const Key('reminder-allow-notifications')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reminder-step-exactAlarms')), findsOneWidget);
  });

  testWidgets('autoPrompt opens the sheet once by itself', (t) async {
    await t.pumpWidget(
      app(
        ReminderReadinessCard(
          autoPrompt: true,
          service: () async => r(e: false),
        ),
      ),
    );
    await t.pump();
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('reminder-setup-sheet')), findsOneWidget);
  });

  testWidgets('the sheet runs the tapped step and then re-checks', (t) async {
    var granted = false;
    final ran = <ReminderStep>[];
    await t.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => ReminderSetupSheet(
                check: () async => r(e: granted),
                run: (s) async {
                  ran.add(s);
                  granted = true;
                },
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byKey(const Key('reminder-allow-exactAlarms')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(ran, [ReminderStep.exactAlarms]);
    expect(find.byKey(const Key('reminder-allow-exactAlarms')), findsNothing);
    expect(find.byKey(const Key('reminder-setup-done')), findsOneWidget);
  });

  testWidgets('Xiaomi sees the autostart step in the sheet', (t) async {
    await t.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ReminderSetupSheet(
                check: () async => r(maker: 'xiaomi'),
                run: (_) async {},
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('reminder-step-autostart')), findsOneWidget);
  });
}
