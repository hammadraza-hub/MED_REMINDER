import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_zone.dart';
import 'package:med_remind_app/core/home_day.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(DoseZone.ensureData);

  test('a normal day in Karachi is 24 h and starts at local midnight', () {
    final zone = tz.getLocation('Asia/Karachi');
    final d = HomeDay.of(zone, now: DateTime.utc(2026, 11, 18, 10));
    expect(d.startUtc, DateTime.utc(2026, 11, 17, 19)); // 00:00 PKT
    expect(d.endUtc, DateTime.utc(2026, 11, 18, 19));
  });

  test('the day is cut by the PROFILE zone, not by UTC', () {
    final ny = tz.getLocation('America/New_York');
    // 02:00 UTC on Nov 18 is still Nov 17 evening in New York.
    final d = HomeDay.of(ny, now: DateTime.utc(2026, 11, 18, 2));
    expect(d.startUtc, DateTime.utc(2026, 11, 17, 5)); // 00:00 EST
    expect(d.endUtc, DateTime.utc(2026, 11, 18, 5));
  });

  test('spring-forward day is 23 h, fall-back day is 25 h', () {
    final ny = tz.getLocation('America/New_York');
    final spring = HomeDay.of(ny, now: DateTime.utc(2026, 3, 8, 12));
    expect(
      spring.endUtc.difference(spring.startUtc),
      const Duration(hours: 23),
    );
    final fall = HomeDay.of(ny, now: DateTime.utc(2026, 11, 1, 12));
    expect(fall.endUtc.difference(fall.startUtc), const Duration(hours: 25));
  });

  test('untilEnd counts to the end of the day, never below a second', () {
    final zone = tz.getLocation('Asia/Karachi');
    final now = DateTime.utc(2026, 11, 18, 10);
    final d = HomeDay.of(zone, now: now);
    expect(d.untilEnd(now: now), const Duration(hours: 9));
    expect(
      d.untilEnd(now: d.endUtc.add(const Duration(hours: 1))),
      const Duration(seconds: 1),
    );
  });

  test('the next day starts exactly where this one ends', () {
    final zone = tz.getLocation('Asia/Karachi');
    final a = HomeDay.of(zone, now: DateTime.utc(2026, 11, 18, 10));
    final b = HomeDay.of(zone, now: a.endUtc.add(const Duration(minutes: 1)));
    expect(b.startUtc, a.endUtc);
  });
}
