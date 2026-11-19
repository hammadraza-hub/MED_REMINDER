import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_zone.dart';
import 'package:med_remind_app/core/home_day.dart';
import 'package:med_remind_app/core/members/member_repository.dart';
import 'package:med_remind_app/core/profile/profile_controller.dart';
import 'package:med_remind_app/core/streak_history.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:med_remind_app/features/home/home_dose_filter.dart';
import 'package:med_remind_app/features/home/home_dose_source.dart';
import 'package:med_remind_app/features/home/home_summary.dart';
import 'package:med_remind_app/features/home/home_screen.dart';
import 'package:med_remind_app/features/home/notifications_inbox_screen.dart';
import 'package:med_remind_app/features/meds/add_medication_screen.dart';
import 'package:med_remind_app/features/meds/meds_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/dose.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeMembers implements MemberRepository {
  FakeMembers(this.members);
  final List<MemberProfile> members;

  @override
  Stream<List<MemberProfile>> watchActiveMembers() => Stream.value(members);
  @override
  Future<List<MemberProfile>> getActiveMembers() async => members;
  @override
  Future<MemberProfile?> getMemberById(String id) async => null;
  @override
  Future<void> saveMember(MemberProfile member) async {}
  @override
  Future<void> setMemberActive({
    required String memberId,
    required bool isActive,
  }) async {}
  @override
  Future<void> seedInitialMembersIfNeeded() async {}
}

MemberProfile member(String id, String name) => MemberProfile(
  id: id,
  displayName: name,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class FakeSource extends HomeDoseSource {
  final today = StreamController<List<Dose>>.broadcast();
  final calls = <String>[];
  final reasons = <String?>[];
  Object? failWith;
  List<Dose> history = [];

  /// What the screen asked for (to prove the day is cut in the profile zone).
  String? zoneName;
  DateTime? askedStart;
  DateTime? askedEnd;
  int subscriptions = 0;

  @override
  Future<tz.Location> zoneOf(String profileId) async {
    DoseZone.ensureData();
    return tz.getLocation(zoneName ?? 'Asia/Karachi');
  }

  @override
  Stream<List<Dose>> watchDoses(
    String profileId,
    DateTime startUtc,
    DateTime endUtc,
  ) {
    askedStart = startUtc;
    askedEnd = endUtc;
    subscriptions++;
    return today.stream;
  }

  /// How many times the history was read (the streak must not re-read it).
  int historyReads = 0;

  @override
  Future<List<Dose>> getDosesBetween(
    String profileId,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    historyReads++;
    return history
        .where(
          (d) =>
              !d.scheduledAt.isBefore(startUtc) &&
              d.scheduledAt.isBefore(endUtc),
        )
        .toList();
  }

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
    reasons.add(reasonText);
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

Future<FakeSource> open(
  WidgetTester t, {
  List<Dose>? doses,
  String? zone,
  List<MemberProfile>? members,
  Locale? locale,
}) async {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  final source = FakeSource()..zoneName = zone;
  await t.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        doseSource: source,
        uidProvider: () => 'u1',
        memberRepository: FakeMembers(members ?? [member('m1', 'Mom')]),
      ),
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
    StreakHistoryRegistry.instance.clear();
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
        home: HomeScreen(
          doseSource: source,
          uidProvider: () => 'u1',
          memberRepository: FakeMembers([member('m1', 'Mom')]),
        ),
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

  group('step 1 bugs', () {
    testWidgets('closing the skip sheet does NOT skip the dose', (t) async {
      final source = await open(t, doses: [dose('d1', 'Metformin', 8)]);
      await t.tap(find.text('Skip').first);
      await settle(t);
      expect(find.text('Why are you skipping this dose?'), findsOneWidget);
      // Tap outside the sheet: it closes without a choice.
      await t.tapAt(const Offset(450, 60));
      await settle(t);
      expect(find.text('Why are you skipping this dose?'), findsNothing);
      expect(source.calls, isEmpty, reason: 'nothing was logged');
    });

    testWidgets('Skip without reason skips the dose', (t) async {
      final source = await open(t, doses: [dose('d1', 'Metformin', 8)]);
      await t.tap(find.text('Skip').first);
      await settle(t);
      await t.tap(find.text('Skip without reason'));
      await settle(t);
      expect(source.calls, ['skipped:m1:d1:u1']);
    });

    testWidgets('the member bar shows the real profiles, not made-up ones', (
      t,
    ) async {
      await open(
        t,
        members: [member('m1', 'Mom'), member('p2', 'Grandpa')],
        doses: [],
      );
      expect(find.text('Grandpa'), findsWidgets);
      expect(find.text('Sarah'), findsNothing);
      expect(find.text('Jake'), findsNothing);
    });

    testWidgets('a stale remembered profile falls back to the first real one', (
      t,
    ) async {
      await ProfileController.instance.selectProfile(
        memberId: 'local_mom',
        displayName: 'Mom',
      );
      final source = await open(
        t,
        members: [member('real1', 'Me'), member('real2', 'Dad')],
        doses: [],
      );
      expect(ProfileController.instance.memberId, 'real1');
      expect(source.subscriptions, greaterThan(0));
    });

    testWidgets('today is cut in the PROFILE zone, not the phone zone', (
      t,
    ) async {
      final source = await open(t, zone: 'America/New_York', doses: []);
      DoseZone.ensureData();
      final expected = HomeDay.of(tz.getLocation('America/New_York'));
      expect(source.askedStart, expected.startUtc);
      expect(source.askedEnd, expected.endUtc);
    });
  });

  group('step 2 text', () {
    testWidgets(
      'the skip sheet is translated but the stored reason is English',
      (t) async {
        final source = await open(
          t,
          locale: const Locale('es'),
          doses: [dose('d1', 'Metformin', 8)],
        );
        await t.tap(find.text('Omitir').first);
        await settle(t);
        expect(find.text('¿Por qué omites esta dosis?'), findsOneWidget);
        expect(find.text('Omitir sin motivo'), findsOneWidget);
        // Choose the Spanish chip, then Save.
        await t.tap(find.text('Se me olvidó'));
        await t.pump();
        await t.tap(find.text('Guardar'));
        await settle(t);
        expect(source.calls, ['skipped:m1:d1:u1']);
        expect(source.reasons, [
          'Forgot',
        ], reason: 'reports read the English value');
      },
    );

    testWidgets('the dose sheet buttons are translated', (t) async {
      await open(
        t,
        locale: const Locale('es'),
        doses: [dose('d1', 'Metformin', 8)],
      );
      await t.tap(find.text('Metformin').first);
      await settle(t);
      expect(find.text('Marcar como tomada'), findsOneWidget);
      expect(find.text('Posponer 15 min'), findsOneWidget);
      expect(find.text('Mark Taken'), findsNothing);
    });

    testWidgets('the empty list text is translated', (t) async {
      await open(t, locale: const Locale('es'), doses: []);
      expect(find.text('No hay dosis programadas para hoy.'), findsOneWidget);
    });
  });

  group('step 3 helpers', () {
    testWidgets('the dose time follows the phone 12 / 24 hour setting', (
      t,
    ) async {
      await open(t, doses: [dose('d1', 'Metformin', 20)]);
      expect(find.textContaining('8:00 PM'), findsWidgets);

      // A phone set to 24 hours: the same dose reads 20:00.
      t.view.physicalSize = const Size(900, 2400);
      final source = FakeSource();
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(
              doseSource: source,
              uidProvider: () => 'u1',
              memberRepository: FakeMembers([member('m1', 'Mom')]),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      source.today.add([dose('d1', 'Metformin', 20)]);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('20:00'), findsWidgets);
      expect(find.textContaining('8:00 PM'), findsNothing);
    });

    testWidgets('Taken / Skip / Snooze are real buttons of at least 48 px', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      await open(t, doses: [dose('d1', 'Metformin', 8)]);
      final skip = find.bySemanticsLabel('Skip');
      expect(skip, findsWidgets);
      final data = t.getSemantics(skip.first);
      expect(data.flagsCollection.isButton, isTrue);
      final ink = find.ancestor(
        of: find.text('Skip').first,
        matching: find.byType(InkWell),
      );
      expect(t.getSize(ink.first).height, greaterThanOrEqualTo(48));
      handle.dispose();
    });

    testWidgets('the Pending chip also shows a missed dose, Taken only taken', (
      t,
    ) async {
      await open(
        t,
        doses: [
          dose('d1', 'Alpha', 8),
          dose('d2', 'Bravo', 9, status: DoseStatus.taken),
          dose('d3', 'Charlie', 10, status: DoseStatus.missed),
        ],
      );
      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Bravo'), findsWidgets);

      await t.tap(find.text('Pending'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Charlie'), findsWidgets);
      expect(find.text('Bravo'), findsNothing);

      await t.tap(find.text('Taken').last);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Bravo'), findsWidgets);
      expect(find.text('Alpha'), findsNothing);
    });
  });

  group('step 4 performance', () {
    List<Dose> many(int n, {int takenEvery = 3}) => [
      for (var i = 0; i < n; i++)
        dose(
          'd$i',
          'Med$i',
          i % 24,
          status: i % takenEvery == 0 ? DoseStatus.taken : DoseStatus.pending,
        ),
    ];

    testWidgets('the counts are computed once per change, not per rebuild', (
      t,
    ) async {
      final source = await open(t, doses: many(60));
      HomeSummary.computeCount = 0;
      HomeDoseFilter.applyCount = 0;

      // Switching the filter filters again, but does not recount.
      await t.tap(find.text('Pending'));
      await t.pump(const Duration(milliseconds: 300));
      expect(HomeDoseFilter.applyCount, 1);
      expect(HomeSummary.computeCount, 0);

      await t.tap(find.text('All').last);
      await t.pump(const Duration(milliseconds: 300));
      expect(HomeDoseFilter.applyCount, 2);
      expect(HomeSummary.computeCount, 0);

      // New data: one count and one filter pass.
      HomeSummary.computeCount = 0;
      HomeDoseFilter.applyCount = 0;
      source.today.add(many(60, takenEvery: 2));
      await t.pump(const Duration(milliseconds: 300));
      expect(HomeSummary.computeCount, 1);
      expect(HomeDoseFilter.applyCount, 1);
    });

    testWidgets('the minute tick recounts but does not refilter', (t) async {
      await open(t, doses: many(60));
      HomeSummary.computeCount = 0;
      HomeDoseFilter.applyCount = 0;
      await t.pump(const Duration(minutes: 3));
      expect(HomeSummary.computeCount, 3, reason: 'one per minute');
      expect(HomeDoseFilter.applyCount, 0);
    });

    testWidgets('only the doses near the screen are built', (t) async {
      await open(t, doses: many(60));
      expect(find.byKey(const ValueKey<String>('d0')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('d59')),
        findsNothing,
        reason: 'far below the screen: not built yet',
      );
      // Scrolling brings it in.
      for (var i = 0; i < 8; i++) {
        await t.drag(find.byType(CustomScrollView), const Offset(0, -2000));
        await t.pump();
      }
      expect(find.byKey(const ValueKey<String>('d59')), findsOneWidget);
    });

    testWidgets('the progress card shows the counts', (t) async {
      await open(
        t,
        doses: [
          dose('d1', 'A', 8, status: DoseStatus.taken),
          dose('d2', 'B', 9, status: DoseStatus.taken),
          dose('d3', 'C', 10),
        ],
      );
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('a taken dose keeps its card identity when the list updates', (
      t,
    ) async {
      final source = await open(t, doses: many(5));
      final before = t.element(find.byKey(const ValueKey<String>('d1')));
      source.today.add([
        for (final d in many(5))
          if (d.id == 'd1')
            dose('d1', 'Med1', 1, status: DoseStatus.taken)
          else
            d,
      ]);
      await t.pump(const Duration(milliseconds: 300));
      final after = t.element(find.byKey(const ValueKey<String>('d1')));
      expect(identical(before, after), isTrue, reason: 'same element, updated');
    });
  });

  group('step 5 streak reads', () {
    testWidgets('taking doses does not re-read the history', (t) async {
      final now = DateTime.now();
      Dose past(int i) {
        final at = DateTime(now.year, now.month, now.day - i, 8);
        return Dose(
          id: 'h$i',
          profileId: 'm1',
          medicationId: 'med',
          medName: 'Metformin',
          doseLabel: 'x',
          scheduledAt: at,
          missDeadline: at.add(const Duration(hours: 1)),
          status: DoseStatus.taken,
          createdAt: now,
        );
      }

      final source = FakeSource()
        ..history = [for (var i = 1; i <= 3; i++) past(i)];
      t.view.physicalSize = const Size(900, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            doseSource: source,
            uidProvider: () => 'u1',
            memberRepository: FakeMembers([member('m1', 'Mom')]),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));

      // Five updates of today's list, each with one more dose decided.
      for (var n = 1; n <= 5; n++) {
        source.today.add([
          for (var i = 0; i < 6; i++)
            dose(
              'd$i',
              'Med$i',
              i,
              status: i < n ? DoseStatus.taken : DoseStatus.pending,
            ),
        ]);
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(
        source.historyReads,
        1,
        reason: 'the past is read once; today comes from the screen',
      );
    });
  });

  group('add button', () {
    testWidgets('the + button opens Add Medication for the shown profile', (
      t,
    ) async {
      await open(t, doses: []);
      await t.tap(find.byType(FloatingActionButton));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      final screen = t.widget<AddMedicationScreen>(
        find.byType(AddMedicationScreen),
      );
      expect(screen.profileId, 'm1');
      expect(find.byType(MedsScreen), findsNothing);
    });
  });

  group('bell', () {
    testWidgets('the bell opens the Notifications screen of the profile', (
      t,
    ) async {
      await open(t, doses: []);
      await t.tap(find.byKey(const Key('home-bell')));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      final screen = t.widget<NotificationsInboxScreen>(
        find.byType(NotificationsInboxScreen),
      );
      expect(screen.profileId, 'm1');
      expect(find.text('Notifications'), findsWidgets);
      expect(find.byKey(const Key('inbox-chip-app')), findsOneWidget);
      expect(find.byKey(const Key('inbox-chip-medicine')), findsOneWidget);
    });

    testWidgets('no dot while nothing needs attention', (t) async {
      await open(t, doses: [dose('d1', 'Metformin', 8)]);
      expect(find.byKey(const Key('home-bell-dot')), findsNothing);
    });

    testWidgets('a missed dose lights the dot', (t) async {
      await open(
        t,
        doses: [dose('d1', 'Metformin', 8, status: DoseStatus.missed)],
      );
      expect(find.byKey(const Key('home-bell-dot')), findsOneWidget);
    });

    testWidgets('the bell is a real button for screen readers', (t) async {
      final handle = t.ensureSemantics();
      await open(t, doses: []);
      final node = t.getSemantics(find.bySemanticsLabel('Notifications'));
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  testWidgets('a missed dose is badged MISSED, not SKIPPED', (t) async {
    await open(
      t,
      doses: [dose('d1', 'Metformin', 8, status: DoseStatus.missed)],
    );
    expect(find.text('MISSED'), findsOneWidget);
    expect(find.text('SKIPPED'), findsNothing);
  });
}
