import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/app_startup.dart';
import 'package:med_remind_app/core/services/connectivity_service.dart';

void main() {
  late StreamController<List<ConnectivityResult>> changes;
  late ConnectivityService connectivity;
  late List<String> log;

  setUp(() {
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    log = [];
  });

  tearDown(() async {
    await connectivity.dispose();
    await changes.close();
  });

  Future<void> makeConnectivity(
    WidgetTester tester,
    List<ConnectivityResult> first,
  ) async {
    connectivity = ConnectivityService(
      check: () async => first,
      changes: changes.stream,
    );
    await connectivity.start();
  }

  Future<void> flip(WidgetTester tester, ConnectivityResult r) async {
    changes.add([r]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
  }

  AppStartup make(
    List<StartupTask> tasks, {
    Duration catchUp = const Duration(seconds: 30),
    List<Duration> retry = const [Duration(seconds: 30)],
  }) => AppStartup(
    connectivity,
    tasks: tasks,
    catchUpLimit: catchUp,
    retryDelays: retry,
    log: log.add,
  );

  group('bounded', () {
    testWidgets('finished, failed and too slow', (tester) async {
      await makeConnectivity(tester, [ConnectivityResult.wifi]); // for tearDown
      expect(
        await AppStartup.bounded(
          'ok',
          () async {},
          const Duration(seconds: 1),
          log: log.add,
        ),
        isTrue,
      );
      expect(
        await AppStartup.bounded(
          'bad',
          () async => throw StateError('x'),
          const Duration(seconds: 1),
          log: log.add,
        ),
        isFalse,
      );
      final never = Completer<void>();
      final f = AppStartup.bounded(
        'never',
        () => never.future,
        const Duration(seconds: 2),
        log: log.add,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(await f, isFalse);
      expect(log.any((l) => l.contains('never: no answer in 2s')), isTrue);
      expect(log.any((l) => l.contains('bad: failed')), isTrue);
    });
  });

  group('before the first screen', () {
    testWidgets('offline: nothing is tried and nothing waits', (tester) async {
      await makeConnectivity(tester, [ConnectivityResult.none]);
      var ran = 0;
      final s = make([
        StartupTask('a', () async => ran++),
        StartupTask('b', () async => ran++),
      ]);
      await s.runBeforeApp(); // returns at once, no timers needed
      expect(ran, 0);
      expect(s.pendingNames, ['a', 'b']);
      s.dispose();
    });

    testWidgets('online and fast: all run, nothing pending', (tester) async {
      await makeConnectivity(tester, [ConnectivityResult.wifi]);
      final ran = <String>[];
      final s = make([
        StartupTask('a', () async => ran.add('a')),
        StartupTask('b', () async => ran.add('b')),
      ]);
      await s.runBeforeApp();
      expect(ran.toSet(), {'a', 'b'});
      expect(s.pendingNames, isEmpty);
      s.dispose();
    });

    testWidgets('a task that never finishes is given up on at its limit', (
      tester,
    ) async {
      await makeConnectivity(tester, [ConnectivityResult.wifi]);
      final never = Completer<void>();
      final s = make([
        StartupTask('fast', () async {}),
        StartupTask(
          'stuck',
          () => never.future,
          limit: const Duration(seconds: 4),
        ),
      ]);
      var done = false;
      final f = s.runBeforeApp().then((_) => done = true);

      await tester.pump(const Duration(seconds: 3));
      expect(done, isFalse); // still inside the limit
      await tester.pump(const Duration(seconds: 2));
      await f;
      expect(done, isTrue);
      expect(s.pendingNames, ['stuck']);
      s.dispose();
    });

    testWidgets(
      'the tasks run side by side: the wait is the longest, not the sum',
      (tester) async {
        await makeConnectivity(tester, [ConnectivityResult.wifi]);
        final s = make([
          StartupTask(
            'a',
            () => Future<void>.delayed(const Duration(seconds: 3)),
            limit: const Duration(seconds: 5),
          ),
          StartupTask(
            'b',
            () => Future<void>.delayed(const Duration(seconds: 3)),
            limit: const Duration(seconds: 5),
          ),
          StartupTask(
            'c',
            () => Future<void>.delayed(const Duration(seconds: 3)),
            limit: const Duration(seconds: 5),
          ),
        ]);
        var done = false;
        final f = s.runBeforeApp().then((_) => done = true);
        await tester.pump(const Duration(seconds: 3, milliseconds: 100));
        await f;
        expect(done, isTrue);
        expect(s.pendingNames, isEmpty);
        s.dispose();
      },
    );

    testWidgets('a failing task does not stop the others', (tester) async {
      await makeConnectivity(tester, [ConnectivityResult.mobile]);
      final ran = <String>[];
      final s = make([
        StartupTask('bad', () async => throw StateError('x')),
        StartupTask('good', () async => ran.add('good')),
      ]);
      await s.runBeforeApp();
      expect(ran, ['good']);
      expect(s.pendingNames, ['bad']);
      s.dispose();
    });

    testWidgets(
      'unknown connectivity is treated like online (tries the tasks)',
      (tester) async {
        connectivity = ConnectivityService(
          check: () async => throw Exception('plugin'),
          changes: changes.stream,
        );
        await connectivity.start();
        expect(connectivity.status.value, ConnectionStatus.unknown);
        var ran = 0;
        final s = make([StartupTask('a', () async => ran++)]);
        await s.runBeforeApp();
        expect(ran, 1);
        s.dispose();
      },
    );

    testWidgets(
      'after-app tasks are not waited for and not run before the app',
      (tester) async {
        await makeConnectivity(tester, [ConnectivityResult.wifi]);
        var pushRan = 0;
        final s = make([
          StartupTask('push', () async => pushRan++, beforeApp: false),
        ]);
        await s.runBeforeApp();
        expect(pushRan, 0);
        s.runAfterApp();
        await tester.pump();
        expect(pushRan, 1);
        s.dispose();
      },
    );
  });

  group('catching up', () {
    testWidgets('offline start: the skipped tasks run once when back online', (
      tester,
    ) async {
      await makeConnectivity(tester, [ConnectivityResult.none]);
      final ran = <String>[];
      final s = make([
        StartupTask('a', () async => ran.add('a')),
        StartupTask('push', () async => ran.add('push'), beforeApp: false),
      ]);
      await s.runBeforeApp();
      s.runAfterApp();
      s.catchUpWhenOnline();
      expect(ran, isEmpty);
      expect(s.pendingNames.toSet(), {'a', 'push'});

      await flip(tester, ConnectivityResult.wifi);
      expect(ran.toSet(), {'a', 'push'});
      expect(s.pendingNames, isEmpty);

      // going offline and online again runs nothing a second time
      await flip(tester, ConnectivityResult.none);
      await flip(tester, ConnectivityResult.mobile);
      expect(ran.length, 2);
      s.dispose();
    });

    testWidgets(
      'flapping online/offline/online does not run a task twice at once',
      (tester) async {
        await makeConnectivity(tester, [ConnectivityResult.none]);
        var started = 0;
        final gate = Completer<void>();
        final s = make([
          StartupTask('slow', () {
            started++;
            return gate.future;
          }),
        ]);
        await s.runBeforeApp();
        s.catchUpWhenOnline();

        await flip(tester, ConnectivityResult.wifi);
        expect(started, 1);
        await flip(tester, ConnectivityResult.none);
        await flip(tester, ConnectivityResult.wifi);
        expect(started, 1); // the first catch-up is still running
        gate.complete();
        await tester.pump();
        s.dispose();
      },
    );

    testWidgets('a task that fails while online is retried after a pause', (
      tester,
    ) async {
      await makeConnectivity(tester, [ConnectivityResult.wifi]);
      var attempts = 0;
      final s = make(
        [
          StartupTask('flaky', () async {
            attempts++;
            if (attempts < 2) throw StateError('server busy');
          }),
        ],
        retry: const [Duration(seconds: 30), Duration(seconds: 60)],
      );
      await s.runBeforeApp();
      expect(attempts, 1);
      expect(s.pendingNames, ['flaky']);
      s.catchUpWhenOnline();

      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      expect(attempts, 2);
      expect(s.pendingNames, isEmpty);
      s.dispose();
    });

    testWidgets('retries stop after the last pause', (tester) async {
      await makeConnectivity(tester, [ConnectivityResult.wifi]);
      var attempts = 0;
      final s = make(
        [
          StartupTask('broken', () async {
            attempts++;
            throw StateError('always');
          }),
        ],
        retry: const [Duration(seconds: 10), Duration(seconds: 10)],
      );
      await s.runBeforeApp();
      s.catchUpWhenOnline();
      await tester.pump(const Duration(seconds: 11));
      await tester.pump(const Duration(seconds: 11));
      await tester.pump(const Duration(seconds: 60));
      // 1 start + 2 retries, then it gives up until the network changes
      expect(attempts, 3);
      expect(s.pendingNames, ['broken']);

      // a new "online" still gets another try
      await flip(tester, ConnectivityResult.none);
      await flip(tester, ConnectivityResult.wifi);
      expect(attempts, 4);
      s.dispose();
    });

    testWidgets('no retry while offline', (tester) async {
      await makeConnectivity(tester, [ConnectivityResult.wifi]);
      var attempts = 0;
      final s = make([
        StartupTask('bad', () async {
          attempts++;
          throw StateError('x');
        }),
      ]);
      await s.runBeforeApp();
      s.catchUpWhenOnline();
      await flip(tester, ConnectivityResult.none);
      await tester.pump(const Duration(minutes: 5));
      expect(attempts, 1);
      s.dispose();
    });

    testWidgets('after dispose nothing runs any more', (tester) async {
      await makeConnectivity(tester, [ConnectivityResult.none]);
      var ran = 0;
      final s = make([StartupTask('a', () async => ran++)]);
      await s.runBeforeApp();
      s.catchUpWhenOnline();
      s.dispose();
      await flip(tester, ConnectivityResult.wifi);
      await tester.pump(const Duration(minutes: 5));
      expect(ran, 0);
    });
  });
}
