import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/doctors/note_day.dart';

void main() {
  final now = DateTime(2026, 11, 14, 1, 0);

  test('same calendar day is today', () {
    expect(
      NoteDayResolver.of(DateTime(2026, 11, 14, 0, 5), now: now),
      NoteDay.today,
    );
    expect(
      NoteDayResolver.of(DateTime(2026, 11, 14, 23, 59), now: now),
      NoteDay.today,
    );
  });

  test('11 pm the day before is yesterday even when under 24 hours ago', () {
    expect(
      NoteDayResolver.of(DateTime(2026, 11, 13, 23, 0), now: now),
      NoteDay.yesterday,
    );
  });

  test('two or more days ago is other', () {
    expect(
      NoteDayResolver.of(DateTime(2026, 11, 12, 23, 0), now: now),
      NoteDay.other,
    );
    expect(
      NoteDayResolver.of(DateTime(2025, 11, 13, 10, 0), now: now),
      NoteDay.other,
    );
  });

  test('works across a month boundary', () {
    final first = DateTime(2026, 12, 1, 9, 0);
    expect(
      NoteDayResolver.of(DateTime(2026, 11, 30, 20, 0), now: first),
      NoteDay.yesterday,
    );
  });
}
