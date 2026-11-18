import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/features/home/home_summary.dart';
import 'package:med_remind_app/models/dose.dart';

final now = DateTime.utc(2026, 11, 18, 12);

Dose d(
  String id,
  DoseStatus status, {
  int deadlineMin = 30, // minutes after now
}) {
  final deadline = now.add(Duration(minutes: deadlineMin));
  return Dose(
    id: id,
    profileId: 'p',
    medicationId: 'm',
    medName: 'M',
    doseLabel: 'x',
    scheduledAt: deadline.subtract(const Duration(minutes: 30)),
    missDeadline: deadline,
    status: status,
    createdAt: now,
  );
}

void main() {
  test('empty list: zeros and progress 0', () {
    final s = HomeSummary.of(const [], now: now);
    expect(s, HomeSummary.empty);
    expect(s.progress, 0.0);
  });

  test('counts taken, pending and missed', () {
    final s = HomeSummary.of([
      d('m_1', DoseStatus.taken),
      d('m_2', DoseStatus.taken),
      d('m_3', DoseStatus.pending),
      d('m_4', DoseStatus.missed),
    ], now: now);
    expect([s.taken, s.pending, s.missed], [2, 1, 1]);
    expect(s.progress, 0.5);
  });

  test('a pending dose past its deadline is missed, not counted twice', () {
    final s = HomeSummary.of([
      d('m_1', DoseStatus.pending, deadlineMin: -5),
      d('m_2', DoseStatus.taken),
    ], now: now);
    expect([s.taken, s.pending, s.missed], [1, 0, 1]);
    expect(s.total, 2);
  });

  test('deadline exactly now is not late yet', () {
    final s = HomeSummary.of([
      d('m_1', DoseStatus.pending, deadlineMin: 0),
    ], now: now);
    expect(s.pending, 1);
  });

  test('a snoozed dose is still to do until its deadline passes', () {
    expect(HomeSummary.of([d('m_1', DoseStatus.snoozed)], now: now).pending, 1);
    expect(
      HomeSummary.of([
        d('m_1', DoseStatus.snoozed, deadlineMin: -1),
      ], now: now).missed,
      1,
    );
  });

  test('skipped doses and as-needed doses are not counted', () {
    final s = HomeSummary.of([
      d('m_1', DoseStatus.skipped),
      d('m_prn_2', DoseStatus.taken),
      d('m_3', DoseStatus.taken),
    ], now: now);
    expect([s.taken, s.pending, s.missed], [1, 0, 0]);
  });

  test('time makes the summary change: the same list, a later clock', () {
    final doses = [d('m_1', DoseStatus.pending, deadlineMin: 10)];
    final before = HomeSummary.of(doses, now: now);
    final after = HomeSummary.of(
      doses,
      now: now.add(const Duration(minutes: 11)),
    );
    expect(before.pending, 1);
    expect(after.missed, 1);
    expect(before == after, isFalse);
  });

  test('equal numbers are equal (so an unchanged tick does not rebuild)', () {
    expect(
      const HomeSummary(taken: 1, pending: 2, missed: 3),
      const HomeSummary(taken: 1, pending: 2, missed: 3),
    );
    expect(
      const HomeSummary(taken: 1, pending: 2, missed: 3).hashCode,
      const HomeSummary(taken: 1, pending: 2, missed: 3).hashCode,
    );
  });

  test('a large list is counted in one pass', () {
    final doses = [
      for (var i = 0; i < 500; i++)
        d('m_$i', i.isEven ? DoseStatus.taken : DoseStatus.pending),
    ];
    HomeSummary.computeCount = 0;
    final s = HomeSummary.of(doses, now: now);
    expect(s.taken, 250);
    expect(s.pending, 250);
    expect(HomeSummary.computeCount, 1);
  });
}
