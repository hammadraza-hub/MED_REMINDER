import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/doctors/appointment_models.dart';
import 'package:med_remind_app/core/inventory/inventory_repository.dart';
import 'package:med_remind_app/core/notification_feed.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/features/home/notification_sources.dart';
import 'package:med_remind_app/features/home/notifications_inbox_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/dose.dart';

class FakeSources extends NotificationSources {
  FakeSources({
    this.doses = const [],
    this.stock = const [],
    this.symptomList = const [],
    this.appts = const [],
    this.risk = false,
    this.failSymptoms = false,
  });

  List<Dose> doses;
  List<InventoryItem> stock;
  List<SymptomEntry> symptomList;
  List<Appointment> appts;
  bool risk;
  bool failSymptoms;
  int loads = 0;

  @override
  String? get myUid => 'me';

  @override
  Future<List<Dose>> todayDoses(String profileId) async {
    loads++;
    return doses;
  }

  @override
  Future<List<InventoryItem>> inventory(String profileId) async => stock;

  @override
  Future<List<SymptomEntry>> symptoms(String profileId, DateTime since) async {
    if (failSymptoms) throw Exception('no health access');
    return symptomList;
  }

  @override
  Future<List<Appointment>> appointments(String p, DateTime from) async =>
      appts;

  @override
  Future<bool> remindersAtRisk() async => risk;
}

Dose missed(String id, String name) {
  final now = DateTime.now();
  final at = now.subtract(const Duration(hours: 2));
  return Dose(
    id: id,
    profileId: 'p',
    medicationId: 'm',
    medName: name,
    doseLabel: 'x',
    scheduledAt: at,
    missDeadline: at.add(const Duration(minutes: 30)),
    status: DoseStatus.missed,
    createdAt: now,
  );
}

InventoryItem lowStock(String id, String name, int qty) => InventoryItem(
  id: id,
  medicationId: id,
  memberId: 'p',
  medicineName: name,
  strength: '',
  medicineType: 'tablet',
  remainingQuantity: qty,
  unitsPerDay: 1,
);

SymptomEntry symptom(String id, String name, int severity, {String? medId}) =>
    SymptomEntry(
      id: id,
      symptom: name,
      severity: severity,
      medicationId: medId,
      occurredAt: DateTime.now().subtract(const Duration(days: 1)),
    );

Future<void> open(
  WidgetTester t,
  FakeSources sources, {
  Locale? locale,
  FeedCategory initial = FeedCategory.app,
}) async {
  t.view.physicalSize = const Size(900, 2200);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationsInboxScreen(
        profileId: 'p',
        sources: sources,
        initial: initial,
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('opens on the App chip and lists app notifications', (t) async {
    await open(t, FakeSources(doses: [missed('m_1', 'Metformin')]));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Metformin was missed'), findsOneWidget);
    expect(find.byKey(const Key('inbox-chip-app')), findsOneWidget);
    expect(find.byKey(const Key('inbox-chip-medicine')), findsOneWidget);
  });

  testWidgets('the Medicine chip shows stock and side effects', (t) async {
    await open(
      t,
      FakeSources(
        doses: [missed('m_1', 'Metformin')],
        stock: [lowStock('a', 'Aspirin', 0), lowStock('b', 'Vitamin D', 3)],
        symptomList: [symptom('s1', 'Nausea', 3, medId: 'b')],
      ),
    );
    // The App chip does not show medicine items.
    expect(find.text('Aspirin is out of stock'), findsNothing);

    await t.tap(find.byKey(const Key('inbox-chip-medicine')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Aspirin is out of stock'), findsOneWidget);
    expect(find.text('Vitamin D is running low'), findsOneWidget);
    expect(find.text('About 3 days left'), findsOneWidget);
    expect(find.text('Side effect: Nausea'), findsOneWidget);
    expect(find.text('Severity 3/5 · Vitamin D'), findsOneWidget);
    expect(find.text('Metformin was missed'), findsNothing);
  });

  testWidgets('the chips show how many items each has', (t) async {
    await open(
      t,
      FakeSources(
        doses: [missed('m_1', 'A'), missed('m_2', 'B')],
        stock: [lowStock('a', 'Aspirin', 0)],
      ),
    );
    final app = find.descendant(
      of: find.byKey(const Key('inbox-chip-app')),
      matching: find.text('2'),
    );
    final med = find.descendant(
      of: find.byKey(const Key('inbox-chip-medicine')),
      matching: find.text('1'),
    );
    expect(app, findsOneWidget);
    expect(med, findsOneWidget);
  });

  testWidgets('empty chips say so', (t) async {
    await open(t, FakeSources());
    expect(
      find.text('No app notifications. You are all caught up.'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('inbox-chip-medicine')));
    await t.pump(const Duration(milliseconds: 300));
    expect(
      find.text('No medicine alerts. Stock and side effects look fine.'),
      findsOneWidget,
    );
  });

  testWidgets('one source failing does not hide the others', (t) async {
    await open(
      t,
      FakeSources(stock: [lowStock('a', 'Aspirin', 0)], failSymptoms: true),
      initial: FeedCategory.medicine,
    );
    expect(find.byKey(const Key('inbox-partial')), findsOneWidget);
    expect(find.text('Aspirin is out of stock'), findsOneWidget);
  });

  testWidgets('reminders that may not ring show up with a way to fix them', (
    t,
  ) async {
    await open(t, FakeSources(risk: true));
    expect(find.text('Reminders may not ring on time'), findsOneWidget);
  });

  testWidgets('pull down to refresh loads again', (t) async {
    final sources = FakeSources(doses: [missed('m_1', 'Metformin')]);
    await open(t, sources);
    expect(sources.loads, 1);
    // The same thing a pull down does.
    final refresh = t.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    refresh.show();
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(sources.loads, 2);
  });

  testWidgets('a missed dose goes back to Home when tapped', (t) async {
    final sources = FakeSources(doses: [missed('m_1', 'Metformin')]);
    t.view.physicalSize = const Size(900, 2200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    NotificationsInboxScreen(profileId: 'p', sources: sources),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text('Metformin was missed'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('open'), findsOneWidget);
    expect(find.byType(NotificationsInboxScreen), findsNothing);
  });

  testWidgets('the text is translated (Spanish)', (t) async {
    await open(
      t,
      FakeSources(doses: [missed('m_1', 'Metformin')]),
      locale: const Locale('es'),
    );
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.text('Se omitió Metformin'), findsOneWidget);
    expect(find.text('Medicina'), findsOneWidget);
  });

  testWidgets('the two chips are equal halves of a phone screen', (t) async {
    t.view.physicalSize = const Size(780, 1688); // 390 x 844 dp at 2x
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationsInboxScreen(profileId: 'p', sources: FakeSources()),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    final a = t.getSize(find.byKey(const Key('inbox-chip-app')));
    final m = t.getSize(find.byKey(const Key('inbox-chip-medicine')));
    expect(a.width, m.width, reason: 'equal');
    // 390 dp, 16 dp each side, 10 dp gap: (390 - 32 - 10) / 2 = 174.
    expect(a.width, closeTo(174, 1));
    expect(a.height, greaterThanOrEqualTo(48));
  });

  testWidgets('on a wide screen the chips stay in a 560 dp column', (t) async {
    await open(t, FakeSources()); // 900 dp wide
    final a = t.getSize(find.byKey(const Key('inbox-chip-app')));
    // (560 - 32 - 10) / 2 = 259
    expect(a.width, closeTo(259, 1));
  });
}
