import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/app_lock_policy.dart';

void main() {
  final t0 = DateTime(2026, 11, 13, 12, 0, 0);

  group('lockOnColdStart', () {
    test('locks when enabled and signed in', () {
      expect(
        AppLockPolicy.lockOnColdStart(enabled: true, signedIn: true),
        isTrue,
      );
    });

    test('never when disabled or signed out', () {
      expect(
        AppLockPolicy.lockOnColdStart(enabled: false, signedIn: true),
        isFalse,
      );
      expect(
        AppLockPolicy.lockOnColdStart(enabled: true, signedIn: false),
        isFalse,
      );
    });
  });

  group('lockOnResume (30 s grace)', () {
    bool lock(Duration away, {bool enabled = true, bool signedIn = true}) =>
        AppLockPolicy.lockOnResume(
          enabled: enabled,
          signedIn: signedIn,
          backgroundedAt: t0,
          now: t0.add(away),
        );

    test('quick return does not lock', () {
      expect(lock(const Duration(seconds: 5)), isFalse);
      expect(lock(const Duration(seconds: 29)), isFalse);
    });

    test('exactly 30 s does not lock, more than 30 s does', () {
      expect(lock(const Duration(seconds: 30)), isFalse);
      expect(lock(const Duration(seconds: 31)), isTrue);
      expect(lock(const Duration(minutes: 10)), isTrue);
    });

    test('disabled or signed out never locks', () {
      expect(lock(const Duration(hours: 1), enabled: false), isFalse);
      expect(lock(const Duration(hours: 1), signedIn: false), isFalse);
    });

    test('unknown background time does not lock', () {
      expect(
        AppLockPolicy.lockOnResume(
          enabled: true,
          signedIn: true,
          backgroundedAt: null,
          now: t0,
        ),
        isFalse,
      );
    });

    test('clock moved backwards locks (safe side)', () {
      expect(lock(const Duration(seconds: -5)), isTrue);
    });

    test('custom grace period is respected', () {
      expect(
        AppLockPolicy.lockOnResume(
          enabled: true,
          signedIn: true,
          backgroundedAt: t0,
          now: t0.add(const Duration(seconds: 61)),
          gracePeriod: const Duration(minutes: 2),
        ),
        isFalse,
      );
    });
  });
}
