import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/daily_limits.dart';

void main() {
  group('day number', () {
    test('is the UTC day, the same as the rules compute', () {
      expect(DailyLimits.dayNumber(DateTime.utc(1970, 1, 1)), 0);
      expect(DailyLimits.dayNumber(DateTime.utc(1970, 1, 2)), 1);
      expect(DailyLimits.dayNumber(DateTime.utc(2026, 11, 17, 0, 0)), 20774);
      expect(
        DailyLimits.dayNumber(DateTime.utc(2026, 11, 17, 23, 59, 59)),
        20774,
      );
      expect(DailyLimits.dayNumber(DateTime.utc(2026, 11, 18, 0, 0)), 20775);
    });

    test('a local time is converted to UTC first', () {
      // 01:00 at UTC+5 on the 18th is still the 17th in UTC.
      final local = DateTime.parse('2026-11-18T01:00:00+05:00');
      expect(DailyLimits.dayNumber(local), 20774);
    });
  });

  group('limits', () {
    test('hasRoom: one less than the limit is fine, the limit is not', () {
      for (final kind in DailyLimitKind.values) {
        expect(DailyLimits.hasRoom(kind, 0), isTrue);
        expect(DailyLimits.hasRoom(kind, kind.max - 1), isTrue);
        expect(DailyLimits.hasRoom(kind, kind.max), isFalse);
        expect(DailyLimits.hasRoom(kind, kind.max + 5), isFalse);
      }
    });

    test('the counter field is the kind name', () {
      expect(DailyLimitKind.posts.field, 'posts');
      expect(DailyLimitKind.tickets.field, 'tickets');
    });

    test('the exception names the kind', () {
      expect(
        const DailyLimitException(DailyLimitKind.reports).toString(),
        contains('reports'),
      );
    });
  });

  // The numbers live in two places (this enum and firestore.rules). If one is
  // changed without the other, people would be refused for no visible reason.
  group('numbers match firestore.rules', () {
    final rules = File('firestore.rules').readAsStringSync();

    for (final kind in DailyLimitKind.values) {
      test('${kind.name}: ${kind.max}', () {
        final action = RegExp("bumpedOnce\\('${kind.name}', (\\d+)\\)")
            .firstMatch(rules);
        expect(action, isNotNull, reason: 'bumpedOnce(${kind.name}) missing');
        expect(int.parse(action!.group(1)!), kind.max);

        final counter = RegExp('d\\.${kind.name} <= (\\d+)').firstMatch(rules);
        expect(
          counter,
          isNotNull,
          reason: 'validLimitBump(${kind.name}) missing',
        );
        expect(int.parse(counter!.group(1)!), kind.max);
      });
    }

    test('the counter document only knows these kinds', () {
      final list = RegExp(
        r"d\.keys\(\)\.hasOnly\(\['posts', 'comments', 'reports', 'tickets'\]\)",
      );
      expect(list.hasMatch(rules), isTrue);
      expect(DailyLimitKind.values.map((k) => k.name).toSet(), {
        'posts',
        'comments',
        'reports',
        'tickets',
      });
    });
  });
}
