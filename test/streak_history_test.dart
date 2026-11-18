import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_engine.dart';
import 'package:med_remind_app/core/dose_zone.dart';
import 'package:med_remind_app/core/streak_calculator.dart';
import 'package:med_remind_app/core/streak_history.dart';
import 'package:med_remind_app/models/dose.dart';
import 'package:timezone/timezone.dart' as tz;

late tz.Location zone;
final now = DateTime.utc(2026, 11, 18, 7); // 12:00 in Karachi

/// A dose at 08:00 Karachi, [daysAgo] days before today.
Dose dose(int daysAgo, DoseStatus status, {String? id}) {
  final today = DoseEngine.todayIn(zone, now: now);
  final day = DateTime.utc(today.year, today.month, today.day - daysAgo);
  final at = DoseEngine.resolveSlot(zone, day.year, day.month, day.day, 8, 0);
  return Dose(
    id: id ?? 'm_$daysAgo',
    profileId: 'p',
    medicationId: 'm',
    medName: 'M',
    doseLabel: 'x',
    scheduledAt: at,
    missDeadline: at.add(const Duration(minutes: 30)),
    status: status,
    createdAt: at,
  );
}

class Store {
  Store(this.all);
  final List<Dose> all;
  final ranges = <(DateTime, DateTime)>[];

  Future<List<Dose>> read(DateTime start, DateTime end) async {
    ranges.add((start, end));
    return all
        .where(
          (d) => !d.scheduledAt.isBefore(start) && d.scheduledAt.isBefore(end),
        )
        .toList();
  }
}

void main() {
  setUpAll(() {
    DoseZone.ensureData();
    zone = tz.getLocation('Asia/Karachi');
  });

  test(
    'the first call reads the past once; later calls read nothing',
    () async {
      final store = Store([
        for (var i = 1; i <= 3; i++) dose(i, DoseStatus.taken),
      ]);
      final h = StreakHistory(zone: zone, loader: store.read);

      expect(await h.current([dose(0, DoseStatus.taken)], now: now), 4);
      expect(h.loads, 1);

      // A dose taken today, then another: the streak is recomputed, no read.
      for (var i = 0; i < 10; i++) {
        await h.current([dose(0, DoseStatus.taken)], now: now);
      }
      expect(h.loads, 1, reason: 'today comes from the screen, not Firestore');
    },
  );

  test('today is not read: its doses come from the caller', () async {
    final store = Store([dose(0, DoseStatus.taken), dose(1, DoseStatus.taken)]);
    final h = StreakHistory(zone: zone, loader: store.read);
    await h.current(const [], now: now);
    final (start, end) = store.ranges.single;
    final todayStart = DoseEngine.resolveSlot(zone, 2026, 11, 18, 0, 0);
    expect(end, todayStart, reason: 'the read stops where today starts');
    expect(start, DoseEngine.resolveSlot(zone, 2026, 8, 21, 0, 0)); // 89 days
  });

  test(
    'a streak broken inside the window never triggers a second read',
    () async {
      final store = Store([
        dose(1, DoseStatus.taken),
        dose(2, DoseStatus.missed),
        for (var i = 3; i <= 20; i++) dose(i, DoseStatus.taken),
      ]);
      final h = StreakHistory(zone: zone, loader: store.read);
      expect(await h.current([dose(0, DoseStatus.taken)], now: now), 2);
      expect(h.loads, 1);
    },
  );

  test(
    'a streak that fills the window reads 120 older days once (no 60 cap)',
    () async {
      // 100 good days in a row, before today.
      final store = Store([
        for (var i = 1; i <= 100; i++) dose(i, DoseStatus.taken),
      ]);
      final h = StreakHistory(zone: zone, loader: store.read);
      final n = await h.current([dose(0, DoseStatus.taken)], now: now);
      expect(n, 101, reason: '100 past days + today');
      expect(h.loads, 2);

      // Asking again does not read again.
      await h.current([dose(0, DoseStatus.taken)], now: now);
      expect(h.loads, 2);
    },
  );

  test('a new day reads the history again', () async {
    final store = Store([
      for (var i = 1; i <= 3; i++) dose(i, DoseStatus.taken),
    ]);
    final h = StreakHistory(zone: zone, loader: store.read);
    await h.current(const [], now: now);
    await h.current(const [], now: now.add(const Duration(hours: 1)));
    expect(h.loads, 1, reason: 'still the same day');
    await h.current(const [], now: now.add(const Duration(days: 1)));
    expect(h.loads, 2);
  });

  test('a failed read is not cached: the next call tries again', () async {
    var fail = true;
    final h = StreakHistory(
      zone: zone,
      loader: (a, b) async {
        if (fail) throw Exception('offline');
        return [dose(1, DoseStatus.taken)];
      },
    );
    await expectLater(h.current(const [], now: now), throwsException);
    fail = false;
    expect(await h.current(const [], now: now), 1);
    expect(h.loads, 2);
  });

  test('two calls at once share one read', () async {
    final store = Store([dose(1, DoseStatus.taken)]);
    final h = StreakHistory(zone: zone, loader: store.read);
    final results = await Future.wait([
      h.current(const [], now: now),
      h.current(const [], now: now),
    ]);
    expect(results, [1, 1]);
    expect(h.loads, 1);
  });

  group('days are cut in the zone', () {
    test('a dose at 02:00 UTC is the evening before in New York', () {
      final ny = tz.getLocation('America/New_York');
      expect(
        StreakCalculator.dayIn(DateTime.utc(2026, 11, 18, 2), ny),
        DateTime.utc(2026, 11, 17),
      );
      expect(
        StreakCalculator.dayIn(DateTime.utc(2026, 11, 18, 2), zone),
        DateTime.utc(2026, 11, 18),
      );
    });

    test('the streak counts two doses of one New York day as one day', () {
      final ny = tz.getLocation('America/New_York');
      final late = DateTime.utc(2026, 11, 18, 3); // Nov 17, 22:00 NY
      final early = DateTime.utc(2026, 11, 17, 15); // Nov 17, 10:00 NY
      Dose at(DateTime t, String id) => Dose(
        id: id,
        profileId: 'p',
        medicationId: 'm',
        medName: 'M',
        doseLabel: 'x',
        scheduledAt: t,
        missDeadline: t.add(const Duration(minutes: 30)),
        status: DoseStatus.taken,
        createdAt: t,
      );
      final r = StreakCalculator.compute(
        [at(early, 'm_1'), at(late, 'm_2')],
        now: DateTime.utc(2026, 11, 18, 4),
        zone: ny,
      );
      expect(r.days.length, 1, reason: 'same New York day');
      expect(r.current, 1);
    });
  });

  test('reachedStart is true only when the streak runs to the oldest day', () {
    final all = [for (var i = 0; i < 5; i++) dose(i, DoseStatus.taken)];
    expect(
      StreakCalculator.compute(all, now: now, zone: zone).reachedStart,
      isTrue,
    );
    all.add(dose(5, DoseStatus.missed));
    expect(
      StreakCalculator.compute(all, now: now, zone: zone).reachedStart,
      isFalse,
    );
    expect(
      StreakCalculator.compute(const [], now: now, zone: zone).reachedStart,
      isFalse,
    );
  });

  group('registry and changes', () {
    test('the same profile and zone share one history', () {
      final reg = StreakHistoryRegistry.instance..clear();
      Future<List<Dose>> a(DateTime x, DateTime y) async => const [];
      final h1 = reg.forProfile('p1', zone, a);
      final h2 = reg.forProfile('p1', zone, a);
      expect(identical(h1, h2), isTrue);
      expect(identical(h1, reg.forProfile('p2', zone, a)), isFalse);
      reg.clear();
    });

    test('a different zone starts a new history', () {
      final reg = StreakHistoryRegistry.instance..clear();
      Future<List<Dose>> a(DateTime x, DateTime y) async => const [];
      final h1 = reg.forProfile('p1', zone, a);
      final h2 = reg.forProfile('p1', tz.getLocation('America/New_York'), a);
      expect(identical(h1, h2), isFalse);
      reg.clear();
    });

    test('the second caller loader is used from then on', () async {
      final reg = StreakHistoryRegistry.instance..clear();
      var first = 0, second = 0;
      final h = reg.forProfile('p1', zone, (a, b) async {
        first++;
        return const [];
      });
      reg.forProfile('p1', zone, (a, b) async {
        second++;
        return const [];
      });
      await h.current(const [], now: now);
      expect([first, second], [0, 1]);
      reg.clear();
    });

    test('a changed PAST dose makes the next call read again', () async {
      final store = Store([dose(1, DoseStatus.missed)]);
      final h = StreakHistory(zone: zone, loader: store.read);
      await h.current(const [], now: now);
      expect(h.loads, 1);

      h.noteDoseChange('m_20261117 0800'.replaceAll(' ', ''), now: now);
      await h.current(const [], now: now);
      expect(h.loads, 2, reason: 'yesterday changed: read it again');
    });

    test(
      'a changed dose of TODAY, an as-needed dose or a bad id cost nothing',
      () async {
        final store = Store([dose(1, DoseStatus.taken)]);
        final h = StreakHistory(zone: zone, loader: store.read);
        await h.current(const [], now: now);

        h.noteDoseChange('m_202611180800', now: now); // today
        h.noteDoseChange('m_prn_202611170800', now: now); // as-needed
        h.noteDoseChange('garbage', now: now);
        await h.current(const [], now: now);
        expect(h.loads, 1);
      },
    );

    test('result gives current, longest and the loaded past', () async {
      final store = Store([
        dose(1, DoseStatus.taken),
        dose(2, DoseStatus.taken),
        dose(3, DoseStatus.missed),
        for (var i = 4; i <= 9; i++) dose(i, DoseStatus.taken),
      ]);
      final h = StreakHistory(zone: zone, loader: store.read);
      final r = await h.result([dose(0, DoseStatus.taken)], now: now);
      expect(r.current, 3);
      expect(r.longest, 6);
      expect(h.past.length, 9);
    });

    test('the first read covers 89 days, so with today the 90 days shown', () {
      expect(StreakHistory.firstWindowDays, 89);
    });
  });
}
