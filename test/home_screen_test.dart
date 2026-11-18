import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/profile/profile_controller.dart';
import 'package:med_remind_app/features/home/home_dose_source.dart';
import 'package:med_remind_app/features/home/home_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/dose.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSource extends HomeDoseSource {
  final today = StreamController<List<Dose>>.broadcast();
  final calls = <String>[];
  Object? failWith;
  List<Dose> history = [];

  @override
  Stream<List<Dose>> watchTodaysDoses(String profileId) => today.stream;

  @override
  Future<List<Dose>> getDosesForDateRange(
    String profileId,
    DateTime from,
    DateTime to,
  ) async => history;

  @override
  Future<void> logDose({
    required String profileId,
    required String doseId,
    required DoseStatus status,
    required String loggedBy,
    String? reasonText,
  }) async {
    if (failWith != null) throw failWith!;
    calls.add('${status.value}:$profileId:$doseId:$loggedBy');
  }

  @override
  Future<void> undoDose({
    required String profileId,
    required String doseId,
  }) async {
    calls.add('undo:$profileId:$doseId');
  }

  @override
  Future<void> snoozeDose({
    required String profileId,
    required String doseId,
    required Duration snoozeDuration,
  }) async {
    calls.add('snooze:$doseId:${snoozeDuration.inMinutes}');
  }
}

Dose dose(
  String id,
  String name,
  int hour, {
  DoseStatus status = DoseStatus.pending,
}) {
  final now = DateTime.now();
  final at = DateTime(now.year, now.month, now.day, hour);
  return Dose(
    id: id,
    profileId: 'm1',
    medicationId: 'med',
    medName: name,
    doseLabel: '1 tablet at $hour:00',
    scheduledAt: at,
    // Far in the future so a pending dose is never "overdue" in the test.
    missDeadline: now.add(const Duration(days: 2)),
    status: status,
    createdAt: at,
  );
}

/// Home has endless animations, so pumpAndSettle never ends: two frames, so a
/// route animation starts, then a second of time.
Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(seconds: 1));
}

Future<FakeSource> open(WidgetTester t, {List<Dose>? doses}) async {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  final source = FakeSource();
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(doseSource: source, uidProvider: () => 'u1'),
    ),
  );
  await t.pump(const Duration(milliseconds: 300));
  if (doses != null) {
    source.today.add(doses);
    await t.pump(const Duration(milliseconds: 300));
  }
  return source;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileController.instance.selectProfile(
      memberId: 'm1',
      displayName: 'Mom',
    );
  });

  testWidgets('shows today\'s doses from the stream', (t) async {
    await open(
      t,
      doses: [
        dose('d1', 'Metformin', 8),
        dose('d2', 'Aspirin', 20),
        dose('d3', 'Vitamin D', 12, status: DoseStatus.taken),
      ],
    );
    expect(find.text('Metformin'), findsWidgets);
    expect(find.text('Aspirin'), findsWidgets);
    expect(find.text('Vitamin D'), findsWidgets);
  });

  testWidgets('tapping a pending dose and Mark Taken logs it', (t) async {
    final source = await open(t, doses: [dose('d1', 'Metformin', 8)]);
    await t.tap(find.text('Metformin').first);
    await settle(t);
    expect(find.text('Mark Taken'), findsOneWidget);
    await t.tap(find.text('Mark Taken'));
    await settle(t);
    expect(source.calls, ['taken:m1:d1:u1']);
  });

  testWidgets('snooze from the sheet calls snooze with 15 minutes', (t) async {
    final source = await open(t, doses: [dose('d1', 'Metformin', 8)]);
    await t.tap(find.text('Metformin').first);
    await settle(t);
    final snooze = find.text('Snooze 15 min');
    expect(snooze, findsOneWidget);
    await t.tap(snooze);
    await settle(t);
    expect(source.calls.single, startsWith('snooze:d1:'));
  });

  testWidgets('a failing write shows an error and does not crash', (t) async {
    final source = await open(t, doses: [dose('d1', 'Metformin', 8)]);
    source.failWith = Exception('boom');
    await t.tap(find.text('Metformin').first);
    await settle(t);
    await t.tap(find.text('Mark Taken'));
    await settle(t);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(source.calls, isEmpty);
  });

  testWidgets('a taken dose offers no Mark Taken', (t) async {
    await open(
      t,
      doses: [dose('d1', 'Metformin', 8, status: DoseStatus.taken)],
    );
    await t.tap(find.text('Metformin').first);
    await settle(t);
    expect(find.text('Mark Taken'), findsNothing);
  });

  testWidgets('no doses today: no crash, no dose names', (t) async {
    await open(t, doses: []);
    expect(find.text('Metformin'), findsNothing);
  });

  testWidgets('the streak chip is hidden until the streak is known and is '
      'never the old hard-coded 12', (t) async {
    final source = FakeSource();
    t.view.physicalSize = const Size(900, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    // 3 good days in a row (yesterday and before).
    final now = DateTime.now();
    source.history = [
      for (var i = 1; i <= 3; i++)
        Dose(
          id: 'h$i',
          profileId: 'm1',
          medicationId: 'med',
          medName: 'Metformin',
          doseLabel: 'x',
          scheduledAt: DateTime(now.year, now.month, now.day - i, 8),
          missDeadline: DateTime(now.year, now.month, now.day - i, 9),
          status: DoseStatus.taken,
          createdAt: now,
        ),
    ];
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(doseSource: source, uidProvider: () => 'u1'),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);

    source.today.add([dose('d1', 'Metformin', 8)]);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    expect(find.textContaining('12'), findsNothing);
  });
}
