import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/streak_calculator.dart';
import 'package:med_remind_app/models/dose.dart';

final now = DateTime(2026, 11, 18, 12, 0); // local noon

int _n = 0;
Dose d(
  int daysAgo,
  DoseStatus status, {
  int hour = 8,
  bool prn = false,
  int missMin = 30,
}) {
  final at = DateTime(now.year, now.month, now.day - daysAgo, hour);
  return Dose(
    id: prn ? 'm_prn_${_n++}' : 'm_${_n++}',
    profileId: 'p',
    medicationId: 'm',
    medName: 'M',
    doseLabel: 'x',
    scheduledAt: at,
    missDeadline: at.add(Duration(minutes: missMin)),
    status: status,
    createdAt: at,
  );
}

StreakResult run(List<Dose> doses, {DateTime? at}) =>
    StreakCalculator.compute(doses, now: at ?? now);

void main() {
  const taken = DoseStatus.taken;
  const missed = DoseStatus.missed;
  const skipped = DoseStatus.skipped;
  const pending = DoseStatus.pending;

  test('no doses = 0', () {
    final r = run([]);
    expect([r.current, r.longest, r.totalTaken], [0, 0, 0]);
  });

  test('5 good days in a row', () {
    final r = run([for (var i = 0; i < 5; i++) d(i, taken)]);
    expect(r.current, 5);
    expect(r.longest, 5);
    expect(r.totalTaken, 5);
  });

  test('a missed day breaks the streak; longest remembers the old run', () {
    final r = run([
      d(0, taken), d(1, taken), // current 2
      d(2, missed),
      for (var i = 3; i < 8; i++) d(i, taken), // run of 5
    ]);
    expect(r.current, 2);
    expect(r.longest, 5);
  });

  test('today with only a pending dose does not break the streak', () {
    final r = run([
      d(0, pending, hour: 20), // not yet due
      d(1, taken),
      d(2, taken),
    ]);
    expect(r.current, 2);
  });

  test('today with a taken dose and a pending one is a good day', () {
    final r = run([d(0, taken), d(0, pending, hour: 20), d(1, taken)]);
    expect(r.current, 2);
  });

  test('a pending dose past its deadline counts as missed', () {
    final r = run([d(0, pending, hour: 8), d(1, taken)]);
    expect(r.current, 0);
    expect(r.days.values.first.missed + r.days.values.last.missed, 1);
  });

  test('a day with one taken and one missed is bad', () {
    final r = run([d(0, taken, hour: 8), d(0, missed, hour: 9), d(1, taken)]);
    expect(r.current, 0);
  });

  test('skipped is neutral: neither breaks nor counts', () {
    final r = run([d(0, taken), d(1, skipped), d(2, taken)]);
    expect(r.current, 2);
    expect(r.longest, 2);
  });

  test('days without any dose (weekday medicine) keep the streak', () {
    // Doses on 0, 2, 4 days ago only.
    final r = run([d(0, taken), d(2, taken), d(4, taken)]);
    expect(r.current, 3);
  });

  test('gap days with no doses do not split the longest streak', () {
    final r = run([d(10, taken), d(12, taken), d(13, taken)]);
    expect(r.longest, 3);
  });

  test('PRN doses are ignored', () {
    final r = run([d(0, taken, prn: true), d(1, missed, prn: true)]);
    expect(r.current, 0);
    expect(r.totalTaken, 0);
  });

  test('future doses are ignored', () {
    final r = run([d(-1, taken), d(-2, missed), d(0, taken)]);
    expect(r.current, 1);
  });

  test('snoozed behaves like pending', () {
    final r = run([d(0, DoseStatus.snoozed, hour: 20), d(1, taken)]);
    expect(r.current, 1);
  });

  test('a 120-day run is counted exactly', () {
    final r = run([for (var i = 0; i < 120; i++) d(i, taken)]);
    expect(r.current, 120);
    expect(r.longest, 120);
  });

  test('daylight-saving change days are plain calendar days', () {
    // 2026-11-01 (US fall back) and 2026-03-08 (spring forward) as "now".
    for (final end in [DateTime(2026, 11, 2, 12), DateTime(2026, 3, 9, 12)]) {
      final doses = <Dose>[];
      for (var i = 0; i < 6; i++) {
        final at = DateTime(end.year, end.month, end.day - i, 8);
        doses.add(
          Dose(
            id: 'm_dst$i',
            profileId: 'p',
            medicationId: 'm',
            medName: 'M',
            doseLabel: 'x',
            scheduledAt: at,
            missDeadline: at.add(const Duration(minutes: 30)),
            status: taken,
            createdAt: at,
          ),
        );
      }
      expect(StreakCalculator.compute(doses, now: end).current, 6);
    }
  });

  test('two doses a day: all taken is one good day', () {
    final r = run([
      for (var i = 0; i < 3; i++) ...[d(i, taken), d(i, taken, hour: 20)],
    ]);
    expect(r.current, 3);
    expect(r.totalTaken, 6);
  });

  test('month adherence: taken / (taken + missed + skipped) this month', () {
    final r = run([d(0, taken), d(1, taken), d(2, missed), d(3, skipped)]);
    expect(StreakCalculator.monthAdherencePercent(r, now: now), 50);
    expect(StreakCalculator.monthAdherencePercent(run([]), now: now), 0);
  });

  test('month adherence ignores other months', () {
    final r = run([d(0, taken), d(30, missed)]);
    expect(StreakCalculator.monthAdherencePercent(r, now: now), 100);
  });
}
