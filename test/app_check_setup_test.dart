import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/services/app_check_setup.dart';

void main() {
  group('provider choice', () {
    AppCheckPlan plan({
      bool debugBuild = false,
      bool emulator = false,
      bool production = false,
      bool force = false,
      String? token,
    }) => AppCheckSetup.plan(
      debugBuild: debugBuild,
      useEmulator: emulator,
      isProduction: production,
      forceDebug: force,
      debugToken: token,
    );

    test('a production release uses Play Integrity and DeviceCheck', () {
      final p = plan(production: true);
      expect(p.kind, AppCheckKind.production);
      expect(p.android, isA<AndroidPlayIntegrityProvider>());
      expect(p.apple, isA<AppleDeviceCheckProvider>());
    });

    test(
      'a staging release build without any flag is also production-like',
      () {
        expect(plan().kind, AppCheckKind.production);
      },
    );

    test('debug build, emulator build, or the test flag: debug provider', () {
      for (final p in [
        plan(debugBuild: true),
        plan(emulator: true),
        plan(force: true),
      ]) {
        expect(p.kind, AppCheckKind.debug);
        expect(p.android, isA<AndroidDebugProvider>());
        expect(p.apple, isA<AppleDebugProvider>());
      }
    });

    test(
      'PRODUCTION NEVER uses the debug provider, whatever the flags say',
      () {
        for (final p in [
          plan(production: true, debugBuild: true),
          plan(production: true, emulator: true),
          plan(production: true, force: true, token: 'abc'),
        ]) {
          expect(p.kind, AppCheckKind.production);
          expect(p.android, isA<AndroidPlayIntegrityProvider>());
        }
      },
    );

    test('a fixed debug token is passed on; an empty one means "make one"', () {
      final fixed = plan(debugBuild: true, token: '  1234-ABCD  ');
      expect((fixed.android as AndroidDebugProvider).debugToken, '1234-ABCD');
      expect((fixed.apple as AppleDebugProvider).debugToken, '1234-ABCD');

      for (final t in [null, '', '   ']) {
        final p = plan(debugBuild: true, token: t);
        expect((p.android as AndroidDebugProvider).debugToken, isNull);
      }
    });
  });

  group('activate never blocks or throws', () {
    test('success: the chosen plan comes back and the call ran', () async {
      AppCheckPlan? seen;
      final plan = await AppCheckSetup.activate(
        useEmulator: true,
        isProduction: false,
        run: (p) async => seen = p,
      );
      expect(seen, same(plan));
      expect(plan.kind, AppCheckKind.debug);
    });

    test('an error from the plugin is swallowed', () async {
      final plan = await AppCheckSetup.activate(
        useEmulator: false,
        isProduction: true,
        run: (_) async => throw StateError('no Play services'),
      );
      expect(plan.kind, AppCheckKind.production);
    });

    test('a call that never answers is given up on after the limit', () async {
      final never = Completer<void>();
      final sw = Stopwatch()..start();
      final plan = await AppCheckSetup.activate(
        useEmulator: false,
        isProduction: true,
        limit: const Duration(milliseconds: 50),
        run: (_) => never.future,
      );
      expect(plan.kind, AppCheckKind.production);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}
