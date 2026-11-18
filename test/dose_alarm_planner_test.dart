import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reminders/dose_alarm_planner.dart';
import 'package:med_remind_app/models/dose.dart';

final now = DateTime.utc(2026, 11, 18, 8, 0);

Dose dose(
  String id,
  Duration fromNow, {
  DoseStatus status = DoseStatus.pending,
  Duration? snoozeFromNow,
  int missMin = 60,
}) {
  final at = now.add(fromNow);
  return Dose(
    id: id,
    profileId: 'p',
    medicationId: 'm',
    medName: 'Med',
    doseLabel: '1 tablet',
    scheduledAt: at,
    missDeadline: at.add(Duration(minutes: missMin)),
    status: status,
    snoozedUntil: snoozeFromNow == null ? null : now.add(snoozeFromNow),
    createdAt: now,
  );
}

List<PlannedAlarm> plan(
  List<Dose> doses, {
  int esc = 10,
  bool enabled = true,
  int cap = 200,
}) => DoseAlarmPlanner.plan(
  doses: doses,
  now: now,
  escalationMinutes: esc,
  doseEnabled: enabled,
  maxAlarms: cap,
);

void main() {
  test('one pending dose = main alarm + 3 escalations 10 min apart', () {
    final r = plan([dose('a', const Duration(hours: 1))]);
    expect(r.map((e) => e.key), ['a', 'a#1', 'a#2', 'a#3']);
    expect(r.map((e) => e.at.difference(now).inMinutes), [60, 70, 80, 90]);
  });

  test('escalation interval comes from settings', () {
    final r = plan([dose('a', const Duration(hours: 1))], esc: 5);
    expect(r.map((e) => e.at.difference(now).inMinutes), [60, 65, 70, 75]);
  });

  test('escalations stop before the miss deadline', () {
    final r = plan([dose('a', const Duration(hours: 1), missMin: 25)]);
    expect(r.map((e) => e.key), ['a', 'a#1', 'a#2']); // 70, 80 < 85; 90 not
    final tight = plan([dose('a', const Duration(hours: 1), missMin: 10)]);
    expect(tight.map((e) => e.key), ['a']); // deadline == first escalation
  });

  test('escalation 0 = no repeats', () {
    expect(plan([dose('a', const Duration(hours: 1))], esc: 0).length, 1);
  });

  test('only pending doses', () {
    final r = plan([
      dose('t', const Duration(hours: 1), status: DoseStatus.taken),
      dose('s', const Duration(hours: 1), status: DoseStatus.skipped),
      dose('m', const Duration(hours: 1), status: DoseStatus.missed),
      dose('p', const Duration(hours: 1)),
    ]);
    expect(r.map((e) => e.dose.id).toSet(), {'p'});
  });

  test('past doses and doses beyond 48 h are left out', () {
    final r = plan([
      dose('past', const Duration(minutes: -5)),
      dose('now', Duration.zero),
      dose('in', const Duration(hours: 47, minutes: 59)),
      dose('edge', const Duration(hours: 48)),
      dose('far', const Duration(hours: 60)),
    ]);
    expect(r.map((e) => e.dose.id).toSet(), {'in'});
  });

  test('a snoozed dose alerts at snoozedUntil, not scheduledAt', () {
    final r = plan([
      dose(
        'a',
        const Duration(minutes: -30),
        snoozeFromNow: const Duration(minutes: 10),
        missMin: 120,
      ),
    ]);
    expect(r.first.at, now.add(const Duration(minutes: 10)));
    expect(r.length, 4);
  });

  test('dose reminders switched off = nothing scheduled', () {
    expect(
      plan([dose('a', const Duration(hours: 1))], enabled: false),
      isEmpty,
    );
  });

  test('result is sorted by time, doses of the same minute by id', () {
    final r = plan([
      dose('c', const Duration(hours: 3)),
      dose('b', const Duration(hours: 1)),
      dose('a', const Duration(hours: 1)),
    ]);
    expect(r.where((e) => e.index == 0).map((e) => e.key), ['a', 'b', 'c']);
  });

  test('100 doses would need 400 alarms: iOS cap 64 keeps the nearest 16', () {
    final doses = [
      for (var i = 0; i < 100; i++)
        dose('d$i', Duration(minutes: 5 + i * 20), missMin: 60),
    ];
    final r = plan(doses, cap: DoseAlarmPlanner.iosAlarmCap);
    expect(r.length, 64);
    final ids = r.map((e) => e.dose.id).toSet();
    expect(ids.length, 16);
    for (var i = 0; i < 16; i++) {
      expect(ids.contains('d$i'), isTrue, reason: 'nearest doses kept');
    }
  });

  test('a dose is kept whole or not at all', () {
    final r = plan([
      dose('a', const Duration(hours: 1)),
      dose('b', const Duration(hours: 2)),
    ], cap: 6);
    expect(r.map((e) => e.dose.id).toSet(), {'a'});
    expect(r.length, 4);
  });

  test('android cap is bigger, caps are the documented numbers', () {
    expect(DoseAlarmPlanner.iosAlarmCap, 64);
    expect(DoseAlarmPlanner.androidAlarmCap, 200);
  });

  test('cap 0 or negative schedules nothing', () {
    expect(plan([dose('a', const Duration(hours: 1))], cap: 0), isEmpty);
  });

  test('no doses = no alarms', () {
    expect(plan([]), isEmpty);
  });

  test('quiet hours never move a dose reminder (no such input exists)', () {
    // The planner has no quiet-hours parameter: a 03:00 dose stays at 03:00.
    final r = plan([dose('night', const Duration(hours: 19))]);
    expect(r.first.at, now.add(const Duration(hours: 19)));
  });
}
