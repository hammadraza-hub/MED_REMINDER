import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reminders/quiet_hours.dart';

void main() {
  const night = QuietHours(
    enabled: true,
    startMinutes: 22 * 60,
    endMinutes: 7 * 60,
  );
  const day = QuietHours(
    enabled: true,
    startMinutes: 13 * 60,
    endMinutes: 15 * 60,
  );

  test('disabled or empty window never shifts', () {
    final t = DateTime(2026, 11, 18, 23, 0);
    expect(QuietHours.off.shift(t), t);
    const empty = QuietHours(enabled: true, startMinutes: 600, endMinutes: 600);
    expect(empty.shift(DateTime(2026, 11, 18, 10)), DateTime(2026, 11, 18, 10));
  });

  test('before midnight moves to next morning', () {
    expect(
      night.shift(DateTime(2026, 11, 18, 23, 30)),
      DateTime(2026, 11, 19, 7),
    );
    expect(night.shift(DateTime(2026, 11, 18, 22)), DateTime(2026, 11, 19, 7));
  });

  test('after midnight moves to the same morning', () {
    expect(night.shift(DateTime(2026, 11, 19, 3)), DateTime(2026, 11, 19, 7));
  });

  test('boundaries: end is outside, start is inside', () {
    final end = DateTime(2026, 11, 19, 7);
    expect(night.shift(end), end);
    final before = DateTime(2026, 11, 18, 21, 59);
    expect(night.shift(before), before);
    expect(night.contains(DateTime(2026, 11, 18, 22)), isTrue);
  });

  test('month and year end roll over', () {
    expect(night.shift(DateTime(2026, 12, 31, 23)), DateTime(2027, 1, 1, 7));
    expect(night.shift(DateTime(2026, 11, 30, 23)), DateTime(2026, 12, 1, 7));
  });

  test('same-day window', () {
    expect(day.shift(DateTime(2026, 11, 18, 14)), DateTime(2026, 11, 18, 15));
    final t = DateTime(2026, 11, 18, 15);
    expect(day.shift(t), t);
  });

  test('fromParts', () {
    final q = QuietHours.fromParts(
      enabled: true,
      startHour: 22,
      startMinute: 30,
      endHour: 6,
      endMinute: 45,
    );
    expect(q.shift(DateTime(2026, 11, 18, 23)), DateTime(2026, 11, 19, 6, 45));
  });
}
