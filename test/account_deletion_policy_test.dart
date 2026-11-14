import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/account_deletion_policy.dart';

void main() {
  final requested = DateTime.utc(2026, 11, 1, 10);

  test('no request -> none', () {
    final s = AccountDeletionPolicy.evaluate(null, DateTime.utc(2026, 11, 2));
    expect(s.phase, DeletionPhase.none);
    expect(s.isPending, isFalse);
    expect(s.daysLeft, 0);
  });

  test('right after the request: 7 days left', () {
    final s = AccountDeletionPolicy.evaluate(requested, requested);
    expect(s.phase, DeletionPhase.scheduled);
    expect(s.daysLeft, 7);
    expect(s.executeAfter, DateTime.utc(2026, 11, 8, 10));
    expect(s.isPending, isTrue);
  });

  test('days round up: 6 days 1 hour left -> 7', () {
    final now = requested.add(const Duration(hours: 23));
    expect(AccountDeletionPolicy.evaluate(requested, now).daysLeft, 7);
  });

  test('1 day left on day 6', () {
    final now = requested.add(const Duration(days: 6));
    final s = AccountDeletionPolicy.evaluate(requested, now);
    expect(s.phase, DeletionPhase.scheduled);
    expect(s.daysLeft, 1);
  });

  test('last minute is still scheduled with 1 day shown, never 0', () {
    final now = requested
        .add(const Duration(days: 7))
        .subtract(const Duration(minutes: 1));
    final s = AccountDeletionPolicy.evaluate(requested, now);
    expect(s.phase, DeletionPhase.scheduled);
    expect(s.daysLeft, 1);
  });

  test('exactly at 7 days -> due', () {
    final now = requested.add(const Duration(days: 7));
    final s = AccountDeletionPolicy.evaluate(requested, now);
    expect(s.phase, DeletionPhase.due);
    expect(s.daysLeft, 0);
  });

  test('long after -> due', () {
    final s = AccountDeletionPolicy.evaluate(
      requested,
      DateTime.utc(2027, 1, 1),
    );
    expect(s.phase, DeletionPhase.due);
  });

  test('clock set before the request time still counts as scheduled', () {
    final now = requested.subtract(const Duration(days: 2));
    final s = AccountDeletionPolicy.evaluate(requested, now);
    expect(s.phase, DeletionPhase.scheduled);
    expect(s.daysLeft, 9);
  });

  group('isRecentLogin', () {
    final now = DateTime.utc(2026, 11, 14, 12);

    test('null -> false', () {
      expect(AccountDeletionPolicy.isRecentLogin(null, now), isFalse);
    });

    test('1 minute ago -> true', () {
      expect(
        AccountDeletionPolicy.isRecentLogin(
          now.subtract(const Duration(minutes: 1)),
          now,
        ),
        isTrue,
      );
    });

    test('exactly at the window -> true, a minute later -> false', () {
      final edge = now.subtract(AccountDeletionPolicy.recentLoginWindow);
      expect(AccountDeletionPolicy.isRecentLogin(edge, now), isTrue);
      expect(
        AccountDeletionPolicy.isRecentLogin(
          edge.subtract(const Duration(minutes: 1)),
          now,
        ),
        isFalse,
      );
    });

    test('yesterday -> false; future (clock skew) -> true', () {
      expect(
        AccountDeletionPolicy.isRecentLogin(
          now.subtract(const Duration(days: 1)),
          now,
        ),
        isFalse,
      );
      expect(
        AccountDeletionPolicy.isRecentLogin(
          now.add(const Duration(minutes: 5)),
          now,
        ),
        isTrue,
      );
    });
  });
}
