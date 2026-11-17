import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/queued_write.dart';
import 'package:med_remind_app/core/services/access_guard.dart';
import 'package:med_remind_app/core/services/session_guard.dart';

void main() {
  group('SessionGuard', () {
    late StreamController<bool> auth;
    late int lost;
    late DateTime clock;
    late SessionGuard guard;

    setUp(() {
      auth = StreamController<bool>.broadcast();
      lost = 0;
      clock = DateTime(2026, 11, 17, 12);
      guard = SessionGuard(
        signedIn: auth.stream,
        onLost: () async => lost++,
        now: () => clock,
      );
      SessionGuard.instance = guard;
      guard.start();
    });

    tearDown(() async {
      SessionGuard.instance = null;
      await guard.dispose();
      await auth.close();
    });

    Future<void> emit(bool v) async {
      auth.add(v);
      await Future<void>.delayed(Duration.zero);
    }

    test('signed out by itself after being signed in: session lost', () async {
      await emit(true);
      await emit(false);
      expect(lost, 1);
    });

    test('starting signed out (no session yet) is not a loss', () async {
      await emit(false);
      expect(lost, 0);
    });

    test('the user signing out is not a loss', () async {
      await emit(true);
      SessionGuard.expectSignOut();
      await emit(false);
      expect(lost, 0);
    });

    test('an old expectation does not hide a later real loss', () async {
      await emit(true);
      SessionGuard.expectSignOut(); // sign-out that never happened
      clock = clock.add(const Duration(minutes: 5));
      await emit(false);
      expect(lost, 1);
    });

    test('expectation is used up by one sign-out', () async {
      await emit(true);
      SessionGuard.expectSignOut();
      await emit(false);
      await emit(true);
      await emit(false);
      expect(lost, 1);
    });

    test(
      'a login that is turned away (signed in, then out on purpose)',
      () async {
        SessionGuard.expectSignOut(); // set just before signOut
        await emit(true); // the event of the sign-in arrives late
        await emit(false);
        expect(lost, 0);
      },
    );

    test('a failing onLost does not break the guard', () async {
      await guard.dispose();
      var calls = 0;
      guard = SessionGuard(
        signedIn: auth.stream,
        onLost: () async {
          calls++;
          throw StateError('x');
        },
      )..start();
      await emit(true);
      await emit(false);
      await emit(true);
      await emit(false);
      expect(calls, 2);
    });

    test('expectSignOut without a guard is harmless', () {
      SessionGuard.instance = null;
      SessionGuard.expectSignOut();
    });
  });

  group('AccessGuard', () {
    late String? current;
    late bool offline;
    late Object? canReadResult; // bool or Exception
    late String? own;
    late List<String> selected;
    late int notices;
    late int reads;

    AccessGuard make({Duration pause = const Duration(seconds: 15)}) =>
        AccessGuard(
          AccessGuardPorts(
            currentProfileId: () => current,
            canRead: (id) async {
              reads++;
              final r = canReadResult;
              if (r is Exception) throw r;
              return r! as bool;
            },
            ownProfileId: () async => own,
            select: (id) async {
              selected.add(id);
              current = id;
            },
            isOffline: () => offline,
            notice: () => notices++,
          ),
          pause: pause,
        );

    setUp(() {
      current = 'shared';
      offline = false;
      canReadResult = false;
      own = 'mine';
      selected = [];
      notices = 0;
      reads = 0;
    });

    test(
      'access removed: own profile is selected and a notice shows',
      () async {
        await make().check();
        expect(selected, ['mine']);
        expect(notices, 1);
      },
    );

    test('still readable: nothing changes', () async {
      canReadResult = true;
      await make().check();
      expect(selected, isEmpty);
      expect(notices, 0);
    });

    test('unknown answer (no network): nothing changes', () async {
      canReadResult = Exception('unavailable');
      await make().check();
      expect(selected, isEmpty);
      expect(notices, 0);
    });

    test('offline: does not even ask', () async {
      offline = true;
      await make().check();
      expect(reads, 0);
      expect(selected, isEmpty);
    });

    test('already on the own profile: no switch, no notice', () async {
      current = 'mine';
      await make().check();
      expect(selected, isEmpty);
      expect(notices, 0);
    });

    test('no own profile found: no switch', () async {
      own = null;
      await make().check();
      expect(selected, isEmpty);
      expect(notices, 0);
    });

    test('no profile on screen: nothing to check', () async {
      current = null;
      await make().check();
      expect(reads, 0);
    });

    test('many errors at once cause one check', () async {
      final g = make();
      await Future.wait([g.check(), g.check(), g.check()]);
      expect(reads, 1);
    });

    test(
      'a second check inside the pause is skipped, later ones run',
      () async {
        canReadResult = true;
        final g = make();
        final t = DateTime(2026, 11, 17, 12);
        await g.check(now: t);
        await g.check(now: t.add(const Duration(seconds: 5)));
        expect(reads, 1);
        await g.check(now: t.add(const Duration(seconds: 20)));
        expect(reads, 2);
      },
    );

    test('reportPermissionDenied without a guard is harmless', () {
      AccessGuard.instance = null;
      AccessGuard.reportPermissionDenied();
      AccessGuard.reportIfDenied(StateError('x'));
    });
  });

  group('queuedWrite late errors', () {
    tearDown(() => QueuedWriteErrors.onLate = null);

    test('an error after "queued" reaches the late handler', () async {
      final seen = <Object>[];
      QueuedWriteErrors.onLate = seen.add;
      final gate = Completer<void>();
      final r = await queuedWrite(
        () => gate.future,
        grace: const Duration(milliseconds: 20),
      );
      expect(r, SaveOutcome.queued);
      gate.completeError(StateError('refused'));
      await Future<void>.delayed(Duration.zero);
      expect(seen, hasLength(1));
    });

    test('a quick error goes to the caller, not the late handler', () async {
      final seen = <Object>[];
      QueuedWriteErrors.onLate = seen.add;
      await expectLater(
        queuedWrite(() async => throw StateError('denied')),
        throwsStateError,
      );
      expect(seen, isEmpty);
    });

    test('a late success tells nobody', () async {
      final seen = <Object>[];
      QueuedWriteErrors.onLate = seen.add;
      final gate = Completer<void>();
      await queuedWrite(
        () => gate.future,
        grace: const Duration(milliseconds: 20),
      );
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty);
    });
  });
}
