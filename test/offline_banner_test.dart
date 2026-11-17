import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/services/connectivity_service.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/widgets/offline_banner.dart';

/// A screen with some state of its own, to see that the bar does not reset it.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('count $n', key: const Key('count')),
          Text(
            'top ${MediaQuery.paddingOf(context).top.toInt()}',
            key: const Key('top'),
          ),
          TextButton(
            key: const Key('inc'),
            onPressed: () => setState(() => n++),
            child: const Text('inc'),
          ),
        ],
      ),
    );
  }
}

void main() {
  late StreamController<List<ConnectivityResult>> changes;
  late ConnectivityService service;

  setUp(() {
    changes = StreamController<List<ConnectivityResult>>.broadcast();
  });

  tearDown(() async {
    await service.dispose();
    await changes.close();
  });

  Future<void> pumpHost(
    WidgetTester tester, {
    List<ConnectivityResult> first = const [ConnectivityResult.wifi],
    Locale locale = const Locale('en'),
    Duration backOnlineFor = const Duration(seconds: 2),
  }) async {
    service = ConnectivityService(
      check: () async => first,
      changes: changes.stream,
    );
    await service.start();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => OfflineBannerHost(
          service: service,
          backOnlineFor: backOnlineFor,
          child: child!,
        ),
        home: const _Counter(),
      ),
    );
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, ConnectivityResult r) async {
    changes.add([r]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('online and unknown: no bar', (tester) async {
    await pumpHost(tester);
    expect(find.byKey(const Key('offline-banner')), findsNothing);
    expect(find.byKey(const Key('back-online-banner')), findsNothing);
  });

  testWidgets('offline at the start: the bar is there', (tester) async {
    await pumpHost(tester, first: [ConnectivityResult.none]);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(
      find.text('Offline: changes will sync when you are back online.'),
      findsOneWidget,
    );
  });

  testWidgets('going offline shows the bar at once, going online swaps it', (
    tester,
  ) async {
    await pumpHost(tester);
    await emit(tester, ConnectivityResult.none);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);

    await emit(tester, ConnectivityResult.wifi);
    expect(find.byKey(const Key('offline-banner')), findsNothing);
    expect(find.byKey(const Key('back-online-banner')), findsOneWidget);
    expect(find.text('Back online'), findsOneWidget);

    // ...and "Back online" goes away by itself
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('back-online-banner')), findsNothing);
  });

  testWidgets('a start that was never offline shows no "Back online"', (
    tester,
  ) async {
    await pumpHost(tester);
    await emit(tester, ConnectivityResult.mobile);
    expect(find.byKey(const Key('back-online-banner')), findsNothing);
  });

  testWidgets('offline again while "Back online" is shown replaces it', (
    tester,
  ) async {
    await pumpHost(tester, first: [ConnectivityResult.none]);
    await emit(tester, ConnectivityResult.wifi);
    expect(find.byKey(const Key('back-online-banner')), findsOneWidget);
    await emit(tester, ConnectivityResult.none);
    expect(find.byKey(const Key('back-online-banner')), findsNothing);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    // the old timer must not fire later and change anything
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
  });

  testWidgets('the screen keeps its state when the bar comes and goes', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const Key('inc')));
    await tester.tap(find.byKey(const Key('inc')));
    await tester.pump();
    expect(find.text('count 2'), findsOneWidget);

    await emit(tester, ConnectivityResult.none);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.text('count 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inc')));
    await tester.pump();
    expect(find.text('count 3'), findsOneWidget);

    await emit(tester, ConnectivityResult.wifi);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('count 3'), findsOneWidget);
  });

  testWidgets('the screen does not add the status bar space twice', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 40);
    tester.view.viewPadding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);

    await pumpHost(tester);
    expect(find.text('top 40'), findsOneWidget);

    await emit(tester, ConnectivityResult.none);
    // the bar is under the status bar now, so the screen's own top is 0
    expect(find.text('top 0'), findsOneWidget);

    await emit(tester, ConnectivityResult.wifi);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('top 40'), findsOneWidget);
  });

  testWidgets('text in Spanish', (tester) async {
    await pumpHost(
      tester,
      first: [ConnectivityResult.none],
      locale: const Locale('es'),
    );
    expect(find.textContaining('Sin conexión'), findsOneWidget);
  });

  testWidgets('text in Arabic (right to left)', (tester) async {
    await pumpHost(
      tester,
      first: [ConnectivityResult.none],
      locale: const Locale('ar'),
    );
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.textContaining('غير متصل'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('offline-banner'))),
      ),
      TextDirection.rtl,
    );
  });
}
