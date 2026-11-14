import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/services/app_lock_service.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/widgets/app_lock_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthenticator implements AppLockAuthenticator {
  bool supported = true;
  bool authResult = true;
  int authCalls = 0;
  String? lastReason;

  /// Runs during authenticate() to simulate lifecycle noise from the prompt.
  void Function()? duringAuth;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    authCalls++;
    lastReason = reason;
    duringAuth?.call();
    return authResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthenticator auth;
  late DateTime now;
  late bool signedIn;

  AppLockService make() => AppLockService(
        authenticator: auth,
        clock: () => now,
        isSignedIn: () => signedIn,
      );

  Future<bool> storedEnabled() async =>
      (await SharedPreferences.getInstance()).getBool('app_lock_enabled') ??
      false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthenticator();
    now = DateTime(2026, 11, 13, 12);
    signedIn = true;
  });

  group('initialize / cold start', () {
    test('off by default and not locked', () async {
      final s = make();
      await s.initialize();
      expect(s.enabled, isFalse);
      expect(s.locked, isFalse);
    });

    test('enabled + signed in -> locked on cold start', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final s = make();
      await s.initialize();
      expect(s.enabled, isTrue);
      expect(s.locked, isTrue);
    });

    test('enabled but signed out -> not locked', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      signedIn = false;
      final s = make();
      await s.initialize();
      expect(s.locked, isFalse);
    });

    test('phone lost its screen lock -> lock disables itself', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      auth.supported = false;
      final s = make();
      await s.initialize();
      expect(s.enabled, isFalse);
      expect(s.locked, isFalse);
      expect(await storedEnabled(), isFalse);
    });
  });

  group('enable / disable', () {
    test('enable on unsupported phone is refused', () async {
      auth.supported = false;
      final s = make();
      await s.initialize();
      expect(await s.enable('why'), AppLockEnableResult.unsupported);
      expect(s.enabled, isFalse);
      expect(auth.authCalls, 0);
    });

    test('enable needs successful authentication', () async {
      final s = make();
      await s.initialize();

      auth.authResult = false;
      expect(await s.enable('Turn on'), AppLockEnableResult.failed);
      expect(s.enabled, isFalse);
      expect(await storedEnabled(), isFalse);

      auth.authResult = true;
      expect(await s.enable('Turn on'), AppLockEnableResult.enabled);
      expect(s.enabled, isTrue);
      expect(s.locked, isFalse); // user just authenticated
      expect(await storedEnabled(), isTrue);
      expect(auth.lastReason, 'Turn on');
    });

    test('disable needs authentication and unlocks', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final s = make();
      await s.initialize();

      auth.authResult = false;
      expect(await s.disable('Turn off'), isFalse);
      expect(s.enabled, isTrue);

      auth.authResult = true;
      expect(await s.disable('Turn off'), isTrue);
      expect(s.enabled, isFalse);
      expect(s.locked, isFalse);
      expect(await storedEnabled(), isFalse);
    });
  });

  group('unlock', () {
    test('failed auth keeps it locked, success unlocks', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final s = make();
      await s.initialize();
      expect(s.locked, isTrue);

      auth.authResult = false;
      expect(await s.unlock('Unlock'), isFalse);
      expect(s.locked, isTrue);

      auth.authResult = true;
      expect(await s.unlock('Unlock'), isTrue);
      expect(s.locked, isFalse);
    });

    test('unlock when not locked is a no-op', () async {
      final s = make();
      await s.initialize();
      expect(await s.unlock('Unlock'), isTrue);
      expect(auth.authCalls, 0);
    });
  });

  group('background / resume (30 s grace)', () {
    Future<AppLockService> enabledService() async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final s = make();
      await s.initialize();
      auth.authResult = true;
      await s.unlock('Unlock'); // past the cold-start lock
      return s;
    }

    test('back within 30 s does not lock', () async {
      final s = await enabledService();
      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 20));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(s.locked, isFalse);
    });

    test('back after more than 30 s locks', () async {
      final s = await enabledService();
      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 31));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(s.locked, isTrue);
    });

    test('time counts from the FIRST background event (paused then hidden)',
        () async {
      final s = await enabledService();
      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 25));
      s.didChangeAppLifecycleState(AppLifecycleState.hidden);
      now = now.add(const Duration(seconds: 10));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(s.locked, isTrue); // 35 s since the first event
    });

    test('inactive alone (e.g. system dialog) never locks', () async {
      final s = await enabledService();
      s.didChangeAppLifecycleState(AppLifecycleState.inactive);
      now = now.add(const Duration(minutes: 5));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(s.locked, isFalse);
    });

    test('lock off -> never locks', () async {
      final s = make();
      await s.initialize();
      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(hours: 1));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(s.locked, isFalse);
    });

    test('lifecycle noise while the prompt is up is ignored', () async {
      final s = await enabledService();
      auth.duringAuth = () {
        s.didChangeAppLifecycleState(AppLifecycleState.paused);
        now = now.add(const Duration(minutes: 2));
        s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      };
      // e.g. turning the lock off shows the prompt
      expect(await s.disable('Turn off'), isTrue);
      expect(s.locked, isFalse);
    });

    test('after unlock the next background starts a fresh timer', () async {
      final s = await enabledService();
      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 1));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(s.locked, isTrue);

      await s.unlock('Unlock');
      expect(s.locked, isFalse);

      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 5));
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(s.locked, isFalse);
    });
  });

  group('sign in / out', () {
    test('signing out removes the lock; signing in does not lock', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final s = make();
      await s.initialize();
      expect(s.locked, isTrue);

      s.handleAuthChanged(true);
      expect(s.locked, isTrue); // unchanged, not toggled by sign-in

      s.handleAuthChanged(false);
      expect(s.locked, isFalse);

      s.handleAuthChanged(true);
      expect(s.locked, isFalse); // logging in never locks
    });
  });

  group('AppLockGate widget', () {
    Widget host(AppLockService s) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppLockGate(
            service: s,
            child: const Scaffold(body: Center(child: Text('APP CONTENT'))),
          ),
        );

    testWidgets('unlocked: only the app content is shown', (tester) async {
      final s = make();
      await s.initialize();
      await tester.pumpWidget(host(s));
      await tester.pumpAndSettle();
      expect(find.text('APP CONTENT'), findsOneWidget);
      expect(find.text('MedRemind is locked'), findsNothing);
    });

    testWidgets('locked: lock screen covers the app and prompts automatically',
        (tester) async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      auth.authResult = false; // user cancels the prompt
      final s = make();
      await s.initialize();

      await tester.pumpWidget(host(s));
      await tester.pumpAndSettle();

      expect(find.text('MedRemind is locked'), findsOneWidget);
      expect(auth.authCalls, 1); // auto prompt
      expect(auth.lastReason, 'Unlock MedRemind');
      // cancelled -> shows the hint, stays locked
      expect(find.textContaining('verify'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('Unlock button prompts again and removes the lock screen',
        (tester) async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      auth.authResult = false;
      final s = make();
      await s.initialize();
      await tester.pumpWidget(host(s));
      await tester.pumpAndSettle();
      expect(s.locked, isTrue);

      auth.authResult = true;
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(auth.authCalls, 2);
      expect(s.locked, isFalse);
      expect(find.text('MedRemind is locked'), findsNothing);
      expect(find.text('APP CONTENT'), findsOneWidget);
    });
  });
}
