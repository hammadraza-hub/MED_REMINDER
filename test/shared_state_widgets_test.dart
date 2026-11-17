import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:med_remind_app/core/accessibility/accessibility_controller.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/core/async_state.dart';
import 'package:med_remind_app/core/queued_write.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/widgets/async_state_view.dart';
import 'package:med_remind_app/widgets/empty_state_view.dart';
import 'package:med_remind_app/widgets/error_retry_view.dart';
import 'package:med_remind_app/widgets/skeleton.dart';
import 'package:med_remind_app/features/community/community_texts.dart';

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  double scale = 1,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: c!,
    ),
    home: Scaffold(body: child),
  );
}

AppException _net() => AppException.fromAny(TimeoutException('x'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  group('ErrorRetryView', () {
    testWidgets('network error: message and Try again', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(ErrorRetryView(error: _net(), onRetry: () => taps++)),
      );
      expect(find.byKey(const Key('error-text')), findsOneWidget);
      await tester.tap(find.byKey(const Key('error-retry')));
      expect(taps, 1);
    });

    testWidgets('permission error: no Try again', (tester) async {
      await tester.pumpWidget(
        _app(
          ErrorRetryView(
            error: const AppException.permission('no'),
            onRetry: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('error-text')), findsOneWidget);
      expect(find.byKey(const Key('error-retry')), findsNothing);
    });

    testWidgets('no onRetry: no button', (tester) async {
      await tester.pumpWidget(_app(ErrorRetryView(error: _net())));
      expect(find.byKey(const Key('error-retry')), findsNothing);
    });

    for (final code in ['en', 'es', 'fr', 'ar', 'hi']) {
      testWidgets('works in $code at large text', (tester) async {
        await tester.pumpWidget(
          _app(
            ErrorRetryView(error: _net(), onRetry: () {}),
            locale: Locale(code),
            scale: 1.3,
          ),
        );
        expect(find.byKey(const Key('error-retry')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ErrorRetryView in small boxes', () {
    testWidgets('message only: shown, Try again always offered', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          ErrorRetryView(
            message: 'Could not load',
            retryLabel: 'Again',
            retryKey: const Key('r'),
            onRetry: () => taps++,
          ),
        ),
      );
      expect(find.text('Could not load'), findsOneWidget);
      await tester.tap(find.byKey(const Key('r')));
      expect(taps, 1);
    });

    testWidgets('does not overflow in a 120 px box at large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 120,
            child: ErrorRetryView(error: _net(), onRetry: () {}),
          ),
          scale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyStateView', () {
    testWidgets('title, message and action', (tester) async {
      await tester.pumpWidget(
        _app(
          EmptyStateView(
            title: 'Nothing',
            message: 'Add one',
            action: TextButton(onPressed: () {}, child: const Text('Add')),
          ),
        ),
      );
      expect(find.text('Nothing'), findsOneWidget);
      expect(find.text('Add one'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('SkeletonBox', () {
    testWidgets('still in simplified mode, pulses otherwise', (tester) async {
      final a = AccessibilityController.instance;
      final before = a.simplifiedMode;

      await a.setSimplifiedMode(true);
      await tester.pumpWidget(_app(const SkeletonBox(width: 50)));
      expect(tester.hasRunningAnimations, isFalse);

      await a.setSimplifiedMode(false);
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpWidget(_app(const SkeletonBox(width: 50)));
      expect(tester.hasRunningAnimations, isTrue);

      await a.setSimplifiedMode(before);
      await tester.pumpWidget(_app(const SizedBox()));
    });

    testWidgets('SkeletonList shows the rows', (tester) async {
      await tester.pumpWidget(_app(const SkeletonList(count: 2)));
      expect(find.byType(SkeletonBox), findsNWidgets(6));
    });
  });

  group('AsyncStateView', () {
    Widget view(AsyncState<List<int>> s, {VoidCallback? retry}) => _app(
      AsyncStateView<List<int>>(
        state: s,
        onRetry: retry,
        data: (_, v) => Text('data ${v.length}'),
        empty: (_) => const Text('empty'),
      ),
    );

    testWidgets('four states', (tester) async {
      await tester.pumpWidget(view(const AsyncState.loading()));
      expect(find.byType(SkeletonList), findsOneWidget);

      await tester.pumpWidget(view(const AsyncState.data([1, 2])));
      expect(find.text('data 2'), findsOneWidget);

      await tester.pumpWidget(view(const AsyncState.empty()));
      expect(find.text('empty'), findsOneWidget);

      var taps = 0;
      await tester.pumpWidget(
        view(AsyncState.failure(_net()), retry: () => taps++),
      );
      await tester.tap(find.byKey(const Key('error-retry')));
      expect(taps, 1);
    });
  });

  group('queuedWrite', () {
    test('fast write is saved', () async {
      expect(await queuedWrite(() async {}), SaveOutcome.saved);
    });

    test('slow write is queued, and finishing later is harmless', () async {
      final gate = Completer<void>();
      final r = await queuedWrite(
        () => gate.future,
        grace: const Duration(milliseconds: 20),
      );
      expect(r, SaveOutcome.queued);
      gate.complete();
    });

    test('a quick error is rethrown', () async {
      await expectLater(
        queuedWrite(() async => throw StateError('denied')),
        throwsStateError,
      );
    });

    test('an error after "queued" does not crash', () async {
      final gate = Completer<void>();
      final r = await queuedWrite(
        () => gate.future,
        grace: const Duration(milliseconds: 20),
      );
      expect(r, SaveOutcome.queued);
      gate.completeError(StateError('late'));
      await Future<void>.delayed(Duration.zero);
    });

    test('SaveGuard ignores a second tap while busy', () async {
      final g = SaveGuard();
      final gate = Completer<int>();
      final first = g.run(() => gate.future);
      expect(g.busy, isTrue);
      expect(await g.run(() async => 2), isNull);
      gate.complete(1);
      expect(await first, 1);
      expect(g.busy, isFalse);
      expect(await g.run(() async => 3), 3);
    });
  });

  group('communityActionError', () {
    testWidgets('a timeout says there is no connection', (tester) async {
      late String text;
      late String generic;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              text = communityActionError(l10n, TimeoutException('x'));
              generic = communityActionError(l10n, StateError('x'));
              return const SizedBox();
            },
          ),
        ),
      );
      expect(text, isNot(generic));
      expect(text.toLowerCase(), contains('connection'));
      expect(
        generic,
        AppLocalizations.of(tester.element(find.byType(SizedBox)))
            .communitySaveFailed,
      );
    });
  });
}
