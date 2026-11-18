import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_engine.dart';
import 'package:med_remind_app/models/dose.dart';
import 'package:med_remind_app/models/medication.dart';
import 'package:med_remind_app/models/schedule.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// M22 step 2: the dose engine (PDF M6). Each test says which rule of the PDF
// or which finding of the M22 audit it protects.

late tz.Location karachi; // no daylight saving
late tz.Location newYork; // north, switches in March / November
late tz.Location london; // north, last Sundays of March / October
late tz.Location sydney; // south, first Sundays of October / April

final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

Medication med(
  Schedule schedule, {
  String id = 'm1',
  double? doseAmount,
  String? doseUnit,
}) => Medication(
  id: id,
  profileId: 'p1',
  name: 'Metformin',
  doseAmount: doseAmount,
  doseUnit: doseUnit,
  schedule: schedule,
  createdAt: fixedNow,
  createdBy: 'u',
  updatedAt: fixedNow,
  updatedBy: 'u',
);

Schedule daily(List<String> times, {DateTime? start, DateTime? end}) =>
    Schedule(
      type: ScheduleType.daily,
      times: times,
      startDate: start ?? DateTime(2020, 1, 1),
      endDate: end,
    );

List<Dose> gen(
  Medication m,
  DateTime from,
  DateTime to,
  tz.Location zone, {
  int missedAfterMin = 30,
}) => DoseEngine.generateDoses(
  medication: m,
  profileId: 'p1',
  missedAfterMin: missedAfterMin,
  from: from,
  to: to,
  zone: zone,
  now: fixedNow,
);

List<String> ids(List<Dose> d) => [for (final x in d) x.id];
DateTime utc(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime.utc(y, m, d, h, min);

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    karachi = tz.getLocation('Asia/Karachi');
    newYork = tz.getLocation('America/New_York');
    london = tz.getLocation('Europe/London');
    sydney = tz.getLocation('Australia/Sydney');
  });

  group('one slot -> one instant (PDF M6: Luxon rules)', () {
    DateTime at(tz.Location z, int y, int m, int d, int h, int min) =>
        DoseEngine.resolveSlot(z, y, m, d, h, min);

    test('a normal time, with and without daylight saving', () {
      expect(at(karachi, 2026, 11, 17, 8, 0), utc(2026, 11, 17, 3, 0));
      expect(at(newYork, 2026, 1, 15, 8, 0), utc(2026, 1, 15, 13, 0)); // EST
      expect(at(newYork, 2026, 7, 15, 8, 0), utc(2026, 7, 15, 12, 0)); // EDT
      expect(at(london, 2026, 7, 15, 8, 0), utc(2026, 7, 15, 7, 0)); // BST
    });

    test('spring forward: a time that does not exist moves forward', () {
      // New York 2026-03-08: 02:00 -> 03:00, so 02:30 never happens.
      expect(
        at(newYork, 2026, 3, 8, 2, 30),
        utc(2026, 3, 8, 7, 30),
      ); // 03:30 EDT
      expect(at(newYork, 2026, 3, 8, 2, 0), utc(2026, 3, 8, 7, 0)); // 03:00 EDT
      expect(
        at(newYork, 2026, 3, 8, 1, 59),
        utc(2026, 3, 8, 6, 59),
      ); // still EST
      expect(at(newYork, 2026, 3, 8, 3, 0), utc(2026, 3, 8, 7, 0));
      // London 2026-03-29: 01:00 -> 02:00.
      expect(
        at(london, 2026, 3, 29, 1, 30),
        utc(2026, 3, 29, 1, 30),
      ); // 02:30 BST
      // Sydney 2026-10-04: 02:00 -> 03:00.
      expect(
        at(sydney, 2026, 10, 4, 2, 30),
        utc(2026, 10, 3, 16, 30),
      ); // 03:30 AEDT
    });

    test('fall back: an ambiguous time is the FIRST occurrence', () {
      // New York 2026-11-01: 02:00 -> 01:00, so 01:30 happens twice.
      expect(
        at(newYork, 2026, 11, 1, 1, 30),
        utc(2026, 11, 1, 5, 30),
      ); // EDT, first
      expect(at(newYork, 2026, 11, 1, 2, 30), utc(2026, 11, 1, 7, 30)); // EST
      // London 2026-10-25: 02:00 -> 01:00.
      expect(
        at(london, 2026, 10, 25, 1, 30),
        utc(2026, 10, 25, 0, 30),
      ); // BST, first
      // Sydney 2026-04-05: 03:00 -> 02:00, 02:30 happens twice.
      expect(
        at(sydney, 2026, 4, 5, 2, 30),
        utc(2026, 4, 4, 15, 30),
      ); // AEDT, first
    });

    test('midnight and end of day are fine', () {
      expect(at(newYork, 2026, 3, 8, 0, 0), utc(2026, 3, 8, 5, 0));
      expect(at(newYork, 2026, 3, 8, 23, 59), utc(2026, 3, 9, 3, 59));
      expect(at(karachi, 2026, 12, 31, 23, 59), utc(2026, 12, 31, 18, 59));
    });
  });

  group('daily', () {
    test('every day x every time, oldest first, deterministic ids', () {
      final d = gen(
        med(daily(['08:00', '20:00'])),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 19),
        karachi,
      );
      expect(ids(d), [
        'm1_202611170800',
        'm1_202611172000',
        'm1_202611180800',
        'm1_202611182000',
        'm1_202611190800',
        'm1_202611192000',
      ]);
      expect(d.first.scheduledAt, utc(2026, 11, 17, 3, 0));
      expect(d.first.scheduledAt.isUtc, isTrue);
      expect(d.every((x) => x.status == DoseStatus.pending), isTrue);
      expect(
        d.every((x) => x.profileId == 'p1' && x.medicationId == 'm1'),
        isTrue,
      );
    });

    test('three times a day', () {
      final d = gen(
        med(daily(['07:00', '13:00', '21:00'])),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
      );
      expect(d.length, 3);
    });

    test('missDeadline = scheduledAt + missedAfterMin', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
        missedAfterMin: 45,
      );
      expect(
        d.single.missDeadline.difference(d.single.scheduledAt),
        const Duration(minutes: 45),
      );
    });

    test('label: amount, unit and time (a whole number has no .0)', () {
      final withUnit = gen(
        med(daily(['08:00']), doseAmount: 1, doseUnit: 'tablet'),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
      );
      expect(withUnit.single.doseLabel, '1 tablet at 08:00');
      final half = gen(
        med(daily(['08:00']), doseAmount: 0.5, doseUnit: 'tablet'),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
      );
      expect(half.single.doseLabel, '0.5 tablet at 08:00');
      final none = gen(
        med(daily(['08:00'])),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
      );
      expect(none.single.doseLabel, 'Dose at 08:00');
      expect(none.single.medName, 'Metformin');
    });

    test('the time of day of from / to does not matter, both ends count', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2026, 11, 17, 23, 59, 59),
        DateTime(2026, 11, 19, 0, 0, 1),
        karachi,
      );
      expect(d.length, 3);
    });

    test('no times = no doses; from after to = none', () {
      expect(
        gen(
          med(daily([])),
          DateTime(2026, 11, 17),
          DateTime(2026, 11, 20),
          karachi,
        ),
        isEmpty,
      );
      expect(
        gen(
          med(daily(['08:00'])),
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 17),
          karachi,
        ),
        isEmpty,
      );
    });
  });

  group('start and end dates (inclusive)', () {
    final from = DateTime(2026, 11, 1);
    final to = DateTime(2026, 11, 30);

    test('nothing before the start date', () {
      final d = gen(
        med(daily(['08:00'], start: DateTime(2026, 11, 10))),
        from,
        to,
        karachi,
      );
      expect(ids(d).first, 'm1_202611100800');
      expect(d.length, 21); // 10th .. 30th
    });

    test('nothing after the end date; the end date itself counts', () {
      final d = gen(
        med(daily(['08:00'], end: DateTime(2026, 11, 5))),
        from,
        to,
        karachi,
      );
      expect(ids(d).last, 'm1_202611050800');
      expect(d.length, 5);
    });

    test('start = end: exactly one day', () {
      final d = gen(
        med(
          daily(
            ['08:00', '20:00'],
            start: DateTime(2026, 11, 7),
            end: DateTime(2026, 11, 7),
          ),
        ),
        from,
        to,
        karachi,
      );
      expect(ids(d), ['m1_202611070800', 'm1_202611072000']);
    });

    test('the whole window before the start, or after the end: nothing', () {
      expect(
        gen(
          med(daily(['08:00'], start: DateTime(2027, 1, 1))),
          from,
          to,
          karachi,
        ),
        isEmpty,
      );
      expect(
        gen(
          med(daily(['08:00'], end: DateTime(2026, 10, 31))),
          from,
          to,
          karachi,
        ),
        isEmpty,
      );
    });

    test('a schedule that started long ago still fills the asked window', () {
      final d = gen(
        med(daily(['08:00'], start: DateTime(2019, 6, 1))),
        from,
        DateTime(2026, 11, 3),
        karachi,
      );
      expect(d.length, 3);
    });
  });

  group('weekdays', () {
    Schedule weekdays(List<int> days, [List<String> times = const ['08:00']]) =>
        Schedule(
          type: ScheduleType.weekdays,
          times: times,
          weekdays: days,
          startDate: DateTime(2020, 1, 1),
        );

    test('Monday / Wednesday / Friday over two weeks', () {
      // 2026-11-16 is a Monday.
      final d = gen(
        med(weekdays([1, 3, 5])),
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 29),
        karachi,
      );
      expect(ids(d), [
        'm1_202611160800',
        'm1_202611180800',
        'm1_202611200800',
        'm1_202611230800',
        'm1_202611250800',
        'm1_202611270800',
      ]);
    });

    test('Sunday is 7, Monday is 1', () {
      final sun = gen(
        med(weekdays([7])),
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 22),
        karachi,
      );
      expect(ids(sun), ['m1_202611220800']);
      final mon = gen(
        med(weekdays([1])),
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 22),
        karachi,
      );
      expect(ids(mon), ['m1_202611160800']);
    });

    test('all seven days = daily; none = no doses', () {
      expect(
        gen(
          med(weekdays([1, 2, 3, 4, 5, 6, 7])),
          DateTime(2026, 11, 16),
          DateTime(2026, 11, 22),
          karachi,
        ).length,
        7,
      );
      expect(
        gen(
          med(weekdays([])),
          DateTime(2026, 11, 16),
          DateTime(2026, 11, 22),
          karachi,
        ),
        isEmpty,
      );
    });

    test('two times on each chosen day', () {
      final d = gen(
        med(weekdays([2], ['08:00', '20:00'])),
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 22),
        karachi,
      );
      expect(ids(d), ['m1_202611170800', 'm1_202611172000']);
    });

    test('a Sunday dose on the spring-forward Sunday is kept (New York 2026-03-08)', () {
      final d = gen(
        med(weekdays([7], ['08:00'])),
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 15),
        newYork,
      );
      expect(ids(d), ['m1_202603010800', 'm1_202603080800', 'm1_202603150800']);
      expect(d[0].scheduledAt, utc(2026, 3, 1, 13, 0)); // EST
      expect(d[1].scheduledAt, utc(2026, 3, 8, 12, 0)); // EDT
      expect(d[2].scheduledAt, utc(2026, 3, 15, 12, 0));
    });
  });

  group('cyclical (PDF: keep a day when daysSince(start) mod (on+off) < on)', () {
    Schedule cyc(int on, int off, DateTime start, {DateTime? scheduleStart}) =>
        Schedule(
          type: ScheduleType.cyclical,
          times: const ['08:00'],
          cycleOn: on,
          cycleOff: off,
          cycleStart: start,
          startDate: scheduleStart ?? start,
        );

    // The id ends with yyyyMMddHHmm: the day is the 6th..5th digit from the end.
    List<int> daysOn(List<Dose> d, int month) => [
      for (final x in d)
        int.parse(x.id.substring(x.id.length - 6, x.id.length - 4)),
    ];

    test('2 days on, 1 off', () {
      final d = gen(
        med(cyc(2, 1, DateTime(2026, 11, 1))),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 9),
        karachi,
      );
      expect(daysOn(d, 11), [1, 2, 4, 5, 7, 8]);
    });

    test('5 days on, 2 off (a week)', () {
      final d = gen(
        med(cyc(5, 2, DateTime(2026, 11, 2))),
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 15),
        karachi,
      );
      expect(daysOn(d, 11), [2, 3, 4, 5, 6, 9, 10, 11, 12, 13]);
    });

    test('the window starts in the middle of a cycle', () {
      final d = gen(
        med(cyc(2, 1, DateTime(2026, 11, 1))),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 8),
        karachi,
      );
      expect(daysOn(d, 11), [4, 5, 7, 8]);
    });

    test('days before the cycle starts get no dose', () {
      final d = gen(
        med(
          cyc(
            2,
            1,
            DateTime(2026, 11, 10),
            scheduleStart: DateTime(2026, 11, 1),
          ),
        ),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 13),
        karachi,
      );
      expect(daysOn(d, 11), [10, 11, 13]);
    });

    test('cycleStart missing = the schedule start', () {
      final d = gen(
        med(
          Schedule(
            type: ScheduleType.cyclical,
            times: const ['08:00'],
            cycleOn: 1,
            cycleOff: 1,
            startDate: DateTime(2026, 11, 1),
          ),
        ),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 6),
        karachi,
      );
      expect(daysOn(d, 11), [1, 3, 5]);
    });

    test('a zero-length cycle or 0 days on: nothing (and no endless loop)', () {
      expect(
        gen(
          med(cyc(0, 0, DateTime(2026, 11, 1))),
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 9),
          karachi,
        ),
        isEmpty,
      );
      expect(
        gen(
          med(cyc(0, 3, DateTime(2026, 11, 1))),
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 9),
          karachi,
        ),
        isEmpty,
      );
    });

    test(
      'counts whole calendar days across a daylight-saving change (finding 11)',
      () {
        // 3 on / 4 off from 2026-03-05, window across New York spring forward.
        final d = gen(
          med(cyc(3, 4, DateTime(2026, 3, 5))),
          DateTime(2026, 3, 5),
          DateTime(2026, 3, 25),
          newYork,
        );
        // Expected from plain calendar arithmetic, independent of the engine.
        final expected = <int>[];
        for (var day = 5; day <= 25; day++) {
          final since = DateTime.utc(
            2026,
            3,
            day,
          ).difference(DateTime.utc(2026, 3, 5)).inDays;
          if (since % 7 < 3) expected.add(day);
        }
        expect(expected, [5, 6, 7, 12, 13, 14, 19, 20, 21]);
        expect(daysOn(d, 3), expected);
      },
    );
  });

  group('taper', () {
    Schedule taper({DateTime? end}) => Schedule(
      type: ScheduleType.taper,
      startDate: DateTime(2026, 11, 1),
      endDate: end,
      taperSteps: const [
        TaperStep(days: 3, doseAmount: 2, times: ['08:00']),
        TaperStep(days: 2, doseAmount: 1, times: ['08:00', '20:00']),
      ],
    );

    test('steps follow each other, each with its own dose and times', () {
      final d = gen(
        med(taper(), doseUnit: 'mg'),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
        karachi,
      );
      expect(ids(d), [
        'm1_202611010800',
        'm1_202611020800',
        'm1_202611030800',
        'm1_202611040800',
        'm1_202611042000',
        'm1_202611050800',
        'm1_202611052000',
      ]);
      expect(d[0].doseLabel, '2 mg at 08:00');
      expect(d[3].doseLabel, '1 mg at 08:00');
    });

    test('the window starts inside a step', () {
      final d = gen(
        med(taper()),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 4),
        karachi,
      );
      expect(ids(d), ['m1_202611030800', 'm1_202611040800', 'm1_202611042000']);
    });

    test('the window ends inside a step', () {
      final d = gen(
        med(taper()),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
        karachi,
      );
      expect(ids(d), ['m1_202611010800', 'm1_202611020800']);
    });

    test('nothing after the last step, nothing before the start', () {
      expect(
        gen(
          med(taper()),
          DateTime(2026, 11, 6),
          DateTime(2026, 11, 30),
          karachi,
        ),
        isEmpty,
      );
      expect(
        gen(
          med(taper()),
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 31),
          karachi,
        ),
        isEmpty,
      );
    });

    test('an end date inside the taper cuts it', () {
      final d = gen(
        med(taper(end: DateTime(2026, 11, 2))),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
        karachi,
      );
      expect(d.length, 2);
    });

    test('no steps = no doses', () {
      final d = gen(
        med(
          Schedule(type: ScheduleType.taper, startDate: DateTime(2026, 11, 1)),
        ),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
        karachi,
      );
      expect(d, isEmpty);
    });
  });

  group('PRN', () {
    test('generates nothing, whatever the window', () {
      final prn = med(
        Schedule(type: ScheduleType.prn, startDate: DateTime(2020, 1, 1)),
      );
      expect(
        gen(prn, DateTime(2026, 1, 1), DateTime(2026, 12, 31), karachi),
        isEmpty,
      );
      expect(
        DoseEngine.generate14DayDoses(
          medication: prn,
          profileId: 'p1',
          missedAfterMin: 30,
          zone: karachi,
          now: fixedNow,
        ),
        isEmpty,
      );
    });

    test('an on-demand id is {med}_prn_{timestamp}', () {
      expect(
        DoseEngine.generatePrnDoseId('m9'),
        matches(RegExp(r'^m9_prn_\d{13}$')),
      );
    });
  });

  group('daylight saving does not lose or double a day (finding 3)', () {
    // Before the fix a "+24 hours" loop dropped the LAST day of the window
    // after a 23 h day and visited a 25 h day twice.
    List<String> dates(List<Dose> d) => [
      for (final x in d) x.id.substring(3, 11),
    ];

    test('across the New York spring-forward Sunday', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2026, 3, 6),
        DateTime(2026, 3, 11),
        newYork,
      );
      expect(dates(d), [
        '20260306',
        '20260307',
        '20260308',
        '20260309',
        '20260310',
        '20260311',
      ]);
      expect(d[1].scheduledAt, utc(2026, 3, 7, 13, 0)); // 08:00 EST
      expect(d[2].scheduledAt, utc(2026, 3, 8, 12, 0)); // 08:00 EDT
    });

    test('across the New York fall-back Sunday', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2026, 10, 30),
        DateTime(2026, 11, 4),
        newYork,
      );
      expect(dates(d), [
        '20261030',
        '20261031',
        '20261101',
        '20261102',
        '20261103',
        '20261104',
      ]);
      expect(
        d[2].scheduledAt,
        utc(2026, 11, 1, 13, 0),
      ); // 08:00 EST (the clock went back at 02:00)
      expect(d[3].scheduledAt, utc(2026, 11, 2, 13, 0)); // 08:00 EST
    });

    test(
      'the 14-day window over BOTH changes keeps its first and last day',
      () {
        for (final zone in [newYork, london, sydney]) {
          for (final start in [
            DateTime.utc(2026, 3, 1),
            DateTime.utc(2026, 3, 25),
            DateTime.utc(2026, 10, 20),
            DateTime.utc(2026, 4, 1),
            DateTime.utc(2026, 10, 1),
          ]) {
            final d = DoseEngine.generate14DayDoses(
              medication: med(daily(['08:00'])),
              profileId: 'p1',
              missedAfterMin: 30,
              zone: zone,
              now: DoseEngine.resolveSlot(
                zone,
                start.year,
                start.month,
                start.day,
                12,
                0,
              ),
            );
            expect(d.length, 15, reason: '${zone.name} from $start');
            expect(
              ids(d).toSet().length,
              15,
              reason: 'no duplicate ids ${zone.name} $start',
            );
          }
        }
      },
    );

    test('Sydney (southern hemisphere) across the October start', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 6),
        sydney,
      );
      expect(dates(d), [
        '20261002',
        '20261003',
        '20261004',
        '20261005',
        '20261006',
      ]);
      expect(
        d[1].scheduledAt,
        utc(2026, 10, 2, 22, 0),
      ); // Oct 3 08:00 AEST (+10)
      expect(
        d[2].scheduledAt,
        utc(2026, 10, 3, 21, 0),
      ); // Oct 4 08:00 AEDT (+11)
    });

    test('a daily dose at a clock time that every zone has gives the same wall time every day', () {
      final d = gen(
        med(daily(['09:30'])),
        DateTime(2026, 3, 1),
        DateTime(2026, 11, 30),
        newYork,
      );
      for (final x in d) {
        final local = tz.TZDateTime.from(x.scheduledAt, newYork);
        expect('${local.hour}:${local.minute}', '9:30', reason: x.id);
      }
      expect(d.length, 275);
    });
  });

  // PROOF of finding 3. The engine used to walk the days like this (local
  // midnight, plus 24 hours, until after the end day). The old code ran in the
  // phone's zone; here the same loop runs in New York with TZDateTime, whose
  // add(Duration) is an exact number of hours just like DateTime.add.
  group('why the old "+24 hours" day loop was wrong (finding 3, proof)', () {
    List<String> oldLoop(tz.Location zone, DateTime from, DateTime to) {
      final days = <String>[];
      var current = tz.TZDateTime(zone, from.year, from.month, from.day);
      final endDay = tz.TZDateTime(zone, to.year, to.month, to.day);
      while (!current.isAfter(endDay)) {
        days.add('${current.year}-${current.month}-${current.day}');
        current = current.add(const Duration(days: 1));
      }
      return days;
    }

    test('after a 23 h day the last day of the window is missing', () {
      final old = oldLoop(newYork, DateTime(2026, 3, 6), DateTime(2026, 3, 11));
      expect(old.length, lessThan(6)); // the engine now gives all six
      expect(old.last, isNot('2026-3-11'));
    });

    test('after a 25 h day one date is visited twice', () {
      final old = oldLoop(
        newYork,
        DateTime(2026, 10, 30),
        DateTime(2026, 11, 4),
      );
      expect(old.toSet().length, lessThan(old.length));
    });
  });

  group('a time that does not exist keeps its own id (finding 7)', () {
    test('02:30 and 03:30 on the spring-forward day do not share an id', () {
      final d = gen(
        med(daily(['02:30', '03:30'])),
        DateTime(2026, 3, 8),
        DateTime(2026, 3, 8),
        newYork,
      );
      expect(ids(d), ['m1_202603080230', 'm1_202603080330']);
      // both fall at 03:30 EDT: the person gets two reminders at the same
      // minute rather than one dose silently replacing the other
      expect(d[0].scheduledAt, d[1].scheduledAt);
      expect(ids(d).toSet().length, 2);
    });

    test('the ambiguous 01:30 on the fall-back day is ONE dose with the first instant', () {
      final d = gen(
        med(daily(['01:30'])),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 1),
        newYork,
      );
      expect(d.length, 1);
      expect(d.single.scheduledAt, utc(2026, 11, 1, 5, 30));
    });
  });

  group('leap day and year end', () {
    test('2028-02-29 exists', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2028, 2, 27),
        DateTime(2028, 3, 1),
        karachi,
      );
      expect(ids(d), [
        'm1_202802270800',
        'm1_202802280800',
        'm1_202802290800',
        'm1_202803010800',
      ]);
    });

    test('2027-02-29 does not', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2027, 2, 27),
        DateTime(2027, 3, 1),
        karachi,
      );
      expect(ids(d), ['m1_202702270800', 'm1_202702280800', 'm1_202703010800']);
    });

    test('a schedule that ends on the leap day includes it', () {
      final d = gen(
        med(daily(['08:00'], end: DateTime(2028, 2, 29))),
        DateTime(2028, 2, 28),
        DateTime(2028, 3, 5),
        karachi,
      );
      expect(ids(d), ['m1_202802280800', 'm1_202802290800']);
    });

    test('a weekly dose that falls on the leap day', () {
      // 2028-02-29 is a Tuesday.
      final d = gen(
        med(
          Schedule(
            type: ScheduleType.weekdays,
            times: const ['08:00'],
            weekdays: const [2],
            startDate: DateTime(2020, 1, 1),
          ),
        ),
        DateTime(2028, 2, 24),
        DateTime(2028, 3, 7),
        karachi,
      );
      expect(ids(d), ['m1_202802290800', 'm1_202803070800']);
    });

    test('over New Year the year changes in the ids', () {
      final d = gen(
        med(daily(['23:30'])),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
        karachi,
      );
      expect(ids(d), ['m1_202612312330', 'm1_202701012330']);
    });

    test('a 31-day month then February in a normal year', () {
      final d = gen(
        med(daily(['08:00'])),
        DateTime(2027, 1, 30),
        DateTime(2027, 2, 2),
        karachi,
      );
      expect(ids(d), [
        'm1_202701300800',
        'm1_202701310800',
        'm1_202702010800',
        'm1_202702020800',
      ]);
    });
  });

  group('regenerating gives the same documents (idempotent)', () {
    test('same input = same ids and the same fields', () {
      final m = med(
        daily(['08:00', '20:00']),
        doseAmount: 1,
        doseUnit: 'tablet',
      );
      final a = gen(m, DateTime(2026, 11, 17), DateTime(2026, 11, 30), newYork);
      final b = gen(m, DateTime(2026, 11, 17), DateTime(2026, 11, 30), newYork);
      expect(ids(a), ids(b));
      expect([for (final x in a) x.toJson()], [for (final x in b) x.toJson()]);
    });

    test('a bigger window contains the smaller one (extending never renames a dose)', () {
      final m = med(daily(['08:00', '20:00']));
      final small = gen(
        m,
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 20),
        newYork,
      );
      final big = gen(
        m,
        DateTime(2026, 11, 17),
        DateTime(2026, 12, 20),
        newYork,
      );
      expect(ids(big).take(small.length).toList(), ids(small));
    });

    test('splitting a window in two gives the same set of ids', () {
      final m = med(daily(['08:00']));
      final whole = gen(
        m,
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
        newYork,
      );
      final a = gen(m, DateTime(2026, 11, 1), DateTime(2026, 11, 14), newYork);
      final b = gen(m, DateTime(2026, 11, 15), DateTime(2026, 11, 30), newYork);
      expect([...ids(a), ...ids(b)], ids(whole));
    });

    test('the id does not depend on the time zone (only the instant does)', () {
      final m = med(daily(['08:00']));
      final ny = gen(
        m,
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        newYork,
      );
      final pk = gen(
        m,
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
      );
      expect(ids(ny), ids(pk));
      expect(ny.single.scheduledAt, isNot(pk.single.scheduledAt));
    });

    test('a different medication gets different ids', () {
      final a = gen(
        med(daily(['08:00']), id: 'mA'),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
      );
      final b = gen(
        med(daily(['08:00']), id: 'mB'),
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 17),
        karachi,
      );
      expect(ids(a), isNot(ids(b)));
    });
  });

  group(
    'the default window: today .. today + 14 days, in the profile zone',
    () {
      final m = med(daily(['08:00']));

      List<Dose> window(tz.Location z, DateTime now) =>
          DoseEngine.generate14DayDoses(
            medication: m,
            profileId: 'p1',
            missedAfterMin: 30,
            zone: z,
            now: now,
          );

      test('15 calendar days, both ends inclusive', () {
        final d = window(karachi, utc(2026, 11, 17, 6, 0));
        expect(d.length, 15);
        expect(ids(d).first, 'm1_202611170800');
        expect(ids(d).last, 'm1_202612010800');
      });

      test('"today" is the date in the PROFILE zone, not in UTC', () {
        // 20:00 UTC on the 17th is already the 18th in Karachi, still the 17th in New York.
        final now = utc(2026, 11, 17, 20, 0);
        expect(ids(window(karachi, now)).first, 'm1_202611180800');
        expect(ids(window(newYork, now)).first, 'm1_202611170800');
      });

      test('createdAt is the given moment, in UTC', () {
        final now = utc(2026, 11, 17, 6, 0);
        expect(window(karachi, now).first.createdAt, now);
      });

      test('todayIn', () {
        expect(
          DoseEngine.todayIn(karachi, now: utc(2026, 11, 17, 20, 0)),
          DateTime.utc(2026, 11, 18),
        );
        expect(
          DoseEngine.todayIn(newYork, now: utc(2026, 11, 17, 3, 0)),
          DateTime.utc(2026, 11, 16),
        );
        expect(DoseEngine.windowDays, 14);
      });
    },
  );
}
