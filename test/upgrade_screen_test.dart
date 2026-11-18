import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/subscription/subscription_repository.dart';
import 'package:med_remind_app/core/subscription/subscription_service.dart';
import 'package:med_remind_app/features/settings/payment_success_screen.dart';
import 'package:med_remind_app/features/settings/upgrade_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

Future<void> open(
  WidgetTester t, {
  String? uid,
  Future<void> Function(String, SubscriptionPlan)? subscribe,
  Future<SubscriptionInfo?> Function(String)? restore,
  String? plan,
}) async {
  t.view.physicalSize = const Size(900, 3200);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: UpgradeScreen(
        initialPlanId: plan,
        uidProvider: () => uid,
        onSubscribe: subscribe ?? (_, __) async {},
        onRestore: restore ?? (_) async => null,
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('shows the title, the trial button and restore', (t) async {
    await open(t);
    expect(find.text('Start 7-Day Free Trial'), findsOneWidget);
    expect(find.text('Restore Purchase'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
  });

  testWidgets('signed out: trial asks to sign in and buys nothing', (t) async {
    var bought = false;
    await open(t, uid: null, subscribe: (_, __) async => bought = true);
    await t.ensureVisible(find.text('Start 7-Day Free Trial'));
    await t.tap(find.text('Start 7-Day Free Trial'));
    await t.pump();
    expect(find.text('Please sign in first'), findsOneWidget);
    expect(bought, isFalse);
  });

  testWidgets('signed in: the trial buys the selected plan', (t) async {
    SubscriptionPlan? plan;
    String? who;
    await open(
      t,
      uid: 'u1',
      subscribe: (uid, p) async {
        who = uid;
        plan = p;
      },
    );
    await t.ensureVisible(find.text('Start 7-Day Free Trial'));
    await t.tap(find.text('Start 7-Day Free Trial'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600)); // the success screen
    expect(who, 'u1');
    expect(plan, isNotNull);
    expect(find.byType(PaymentSuccessScreen), findsOneWidget);
  });

  testWidgets('a failed purchase shows the error and stays on the paywall', (
    t,
  ) async {
    await open(
      t,
      uid: 'u1',
      subscribe: (_, __) async => throw Exception('store down'),
    );
    await t.ensureVisible(find.text('Start 7-Day Free Trial'));
    await t.tap(find.text('Start 7-Day Free Trial'));
    await t.pumpAndSettle();
    expect(find.textContaining('Purchase failed'), findsOneWidget);
    expect(find.text('Start 7-Day Free Trial'), findsOneWidget);
  });

  testWidgets('unavailable store shows its own message', (t) async {
    await open(
      t,
      uid: 'u1',
      subscribe: (_, __) async =>
          throw const SubscriptionUnavailableException(),
    );
    await t.ensureVisible(find.text('Start 7-Day Free Trial'));
    await t.tap(find.text('Start 7-Day Free Trial'));
    await t.pumpAndSettle();
    expect(find.text('Purchases are not available right now.'), findsOneWidget);
  });

  testWidgets('restore signed out shows the toast and calls nothing', (
    t,
  ) async {
    var called = false;
    await open(
      t,
      uid: null,
      restore: (_) async {
        called = true;
        return null;
      },
    );
    await t.ensureVisible(find.text('Restore Purchase'));
    await t.tap(find.text('Restore Purchase'));
    await t.pump();
    expect(find.textContaining('No prior subscriptions'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('restore with nothing to restore says so', (t) async {
    await open(t, uid: 'u1', restore: (_) async => null);
    await t.ensureVisible(find.text('Restore Purchase'));
    await t.tap(find.text('Restore Purchase'));
    await t.pumpAndSettle();
    expect(find.text('No purchases found to restore.'), findsOneWidget);
  });

  testWidgets('restore error is shown', (t) async {
    await open(t, uid: 'u1', restore: (_) async => throw Exception('boom'));
    await t.ensureVisible(find.text('Restore Purchase'));
    await t.tap(find.text('Restore Purchase'));
    await t.pumpAndSettle();
    expect(find.textContaining('Restore failed'), findsOneWidget);
  });

  testWidgets('billing toggle switches without errors', (t) async {
    await open(t);
    await t.tap(find.text('Monthly'));
    await t.pumpAndSettle();
    await t.tap(find.text('Annual'));
    await t.pumpAndSettle();
    expect(find.text('Start 7-Day Free Trial'), findsOneWidget);
  });
}
