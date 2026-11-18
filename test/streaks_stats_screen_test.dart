import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_engine.dart';
import 'package:med_remind_app/core/dose_zone.dart';
import 'package:med_remind_app/core/streak_history.dart';
import 'package:med_remind_app/features/home/home_dose_source.dart';
import 'package:med_remind_app/features/home/streaks_stats_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/dose.dart';
import 'package:timezone/timezone.dart' as tz;

class FakeSource extends HomeDoseSource {
  FakeSource(this.all, {this.zoneName = 'Asia/Karachi'});
  final List<Dose> all;
  final String zoneName;
  final reads = <(DateTime, DateTime)>[];

  @override
  Future<tz.Location> zoneOf(String profileId) async {
    DoseZone.ensureData();
    return tz.getLocation(zoneName);
  }

  @override
  Stream<List<Dose>> watchDoses(String p, DateTime a, DateTime b) =>
      const Stream.empty();

  @override
  Future<List<Dose>> getDosesBetween(String p, DateTime a, DateTime b) async {
    reads.add((a, b));
    return all
        .where((d) => !d.scheduledAt.isBefore(a) && d.scheduledAt.isBefore(b))
        .toList();
  }

  @override
  Future<void> logDose({
    required String profileId,
    required String doseId,
    required DoseStatus status,
    required String loggedBy,
    String? reasonText,
  }) async {}

  @override
  Future<void> undoDose({
    required String profileId,
    required String doseId,
  }) async {}

  @override
  Future<void> snoozeDose({
    required String profileId,
    required String doseId,
    required Duration snoozeDuration,
  }) async {}
}

Dose dose(tz.Location zone, int daysAgo, DoseStatus status) {
  final today = DoseEngine.todayIn(zone);
  final day = DateTime.utc(today.year, today.month, today.day - daysAgo);
  final at = DoseEngine.resolveSlot(zone, day.year, day.month, day.day, 8, 0);
  return Dose(
    id: 'm_${at.millisecondsSinceEpoch}',
    profileId: 'p1',
    medicationId: 'm',
    medName: 'M',
    doseLabel: 'x',
    scheduledAt: at,
    missDeadline: at.add(const Duration(minutes: 30)),
    status: status,
    createdAt: at,
  );
}

Future<void> open(WidgetTester t, FakeSource source) async {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StreaksStatsScreen(
        userName: 'Mom',
        profileId: 'p1',
        doseSource: source,
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  late tz.Location zone;

  setUp(() {
    DoseZone.ensureData();
    zone = tz.getLocation('Asia/Karachi');
    StreakHistoryRegistry.instance.clear();
  });

  testWidgets('it shows the streak from the profile history', (t) async {
    final source = FakeSource([
      for (var i = 1; i <= 3; i++) dose(zone, i, DoseStatus.taken),
      dose(zone, 0, DoseStatus.taken),
    ]);
    await open(t, source);
    expect(find.textContaining('Failed'), findsNothing);
    expect(
      find.textContaining('4', findRichText: true),
      findsWidgets,
      reason: '3 past days + today',
    );
  });

  testWidgets('opening it again does not read the past again', (t) async {
    final source = FakeSource([
      for (var i = 1; i <= 3; i++) dose(zone, i, DoseStatus.taken),
    ]);
    await open(t, source);
    // 1 read of the past + 1 small read of today.
    expect(source.reads.length, 2);

    await t.pumpWidget(const SizedBox());
    await open(t, source);
    expect(
      source.reads.length,
      3,
      reason: 'only today is read again; the past is shared',
    );
  });

  testWidgets('it uses the history Home already read', (t) async {
    final source = FakeSource([
      for (var i = 1; i <= 3; i++) dose(zone, i, DoseStatus.taken),
    ]);
    // Home reads the past through the shared registry...
    final history = StreakHistoryRegistry.instance.forProfile(
      'p1',
      zone,
      (a, b) => source.getDosesBetween('p1', a, b),
    );
    await history.current(const []);
    expect(source.reads.length, 1);

    // ...and the Streaks screen reads only today.
    await open(t, source);
    expect(source.reads.length, 2);
  });

  testWidgets('a past dose changed elsewhere makes the screen read again', (
    t,
  ) async {
    final past = dose(zone, 2, DoseStatus.missed);
    final source = FakeSource([past]);
    await open(t, source);
    expect(source.reads.length, 2);

    // The dose is marked taken from the calendar (a day before today).
    StreakHistoryRegistry.instance.noteDoseChange('p1', _idFor(zone, 2));
    await t.pumpWidget(const SizedBox());
    await open(t, source);
    expect(source.reads.length, 4, reason: 'past + today, again');
  });
}

/// An id shaped like the real ones for the day [daysAgo] (08:00 Karachi).
String _idFor(tz.Location zone, int daysAgo) {
  final today = DoseEngine.todayIn(zone);
  final d = DateTime.utc(today.year, today.month, today.day - daysAgo);
  String two(int v) => v.toString().padLeft(2, '0');
  return 'm_${d.year}${two(d.month)}${two(d.day)}0800';
}
