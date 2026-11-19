import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/doctors/appointment_models.dart';
import 'package:med_remind_app/core/doctors/appointment_validator.dart';
import 'package:med_remind_app/core/inventory/inventory_repository.dart';
import 'package:med_remind_app/core/notification_feed.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/features/home/notification_sources.dart';
import 'package:med_remind_app/features/home/notifications_inbox_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/dose.dart';

/// A busy profile with LONG names, so every kind of tile is on screen.
class BusySources extends NotificationSources {
  @override
  String? get myUid => 'me';

  @override
  Future<List<Dose>> todayDoses(String profileId) async {
    final now = DateTime.now();
    final at = now.subtract(const Duration(hours: 2));
    return [
      Dose(
        id: 'm_1',
        profileId: 'p',
        medicationId: 'm',
        medName:
            'Amoxicillin and Clavulanate Potassium 875 mg / 125 mg tablets',
        doseLabel: 'x',
        scheduledAt: at,
        missDeadline: at.add(const Duration(minutes: 30)),
        status: DoseStatus.missed,
        createdAt: now,
      ),
    ];
  }

  @override
  Future<List<InventoryItem>> inventory(String profileId) async => [
    const InventoryItem(
      id: 'a',
      medicationId: 'a',
      memberId: 'p',
      medicineName: 'Hydrochlorothiazide and Lisinopril combination tablets',
      strength: '',
      medicineType: 'tablet',
      remainingQuantity: 0,
      unitsPerDay: 2,
    ),
    const InventoryItem(
      id: 'b',
      medicationId: 'b',
      memberId: 'p',
      medicineName: 'Vitamin D3',
      strength: '',
      medicineType: 'tablet',
      remainingQuantity: 3,
      unitsPerDay: 1,
    ),
  ];

  @override
  Future<List<SymptomEntry>> symptoms(String profileId, DateTime since) async =>
      [
        SymptomEntry(
          id: 's1',
          symptom: 'Persistent nausea with dizziness after meals',
          severity: 5,
          medicationId: 'a',
          occurredAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

  @override
  Future<List<Appointment>> appointments(String p, DateTime from) async => [
    Appointment(
      id: 'a1',
      startsAt: DateTime.now().add(const Duration(hours: 5)),
      type: AppointmentType.labReview,
    ),
  ];

  @override
  Future<bool> remindersAtRisk() async => true;
}

class Device {
  const Device(this.name, this.w, this.h, {this.ratio = 2.0});
  final String name;
  final double w;
  final double h;
  final double ratio;
}

const devices = [
  Device('small phone 320x568', 320, 568),
  Device('phone 360x640', 360, 640),
  Device('phone 390x844', 390, 844),
  Device('large phone 430x932', 430, 932),
  Device('phone landscape 844x390', 844, 390),
  Device('tablet 768x1024', 768, 1024),
  Device('wide tablet landscape 1280x800', 1280, 800),
];

Future<void> pumpAt(
  WidgetTester t,
  Device d, {
  double textScale = 1.0,
  Locale? locale,
  FeedCategory initial = FeedCategory.app,
}) async {
  t.view.physicalSize = Size(d.w * d.ratio, d.h * d.ratio);
  t.view.devicePixelRatio = d.ratio;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: NotificationsInboxScreen(
        profileId: 'p',
        sources: BusySources(),
        initial: initial,
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final d in devices) {
    for (final cat in FeedCategory.values) {
      testWidgets('${d.name}: ${cat.name} chip has no overflow', (t) async {
        await pumpAt(t, d, initial: cat);
        expect(t.takeException(), isNull);
        expect(find.byKey(const Key('inbox-chip-app')), findsOneWidget);
        // The chips fit inside the screen.
        final r = t.getRect(find.byKey(const Key('inbox-chip-app')));
        expect(r.left, greaterThanOrEqualTo(0));
        final m = t.getRect(find.byKey(const Key('inbox-chip-medicine')));
        expect(m.right, lessThanOrEqualTo(d.w + 0.5));
        expect(r.right, lessThanOrEqualTo(m.left), reason: 'no overlap');
      });
    }
  }

  for (final scale in [1.3, 2.0, 3.0]) {
    for (final cat in FeedCategory.values) {
      testWidgets('text x$scale on a small phone: ${cat.name}', (t) async {
        await pumpAt(
          t,
          const Device('small', 320, 568),
          textScale: scale,
          initial: cat,
        );
        expect(t.takeException(), isNull);
      });
    }
  }

  for (final code in ['ar', 'es', 'fr', 'hi']) {
    for (final cat in FeedCategory.values) {
      testWidgets('$code on a small phone with big text: ${cat.name}', (
        t,
      ) async {
        await pumpAt(
          t,
          const Device('small', 320, 568),
          textScale: 1.5,
          locale: Locale(code),
          initial: cat,
        );
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('Arabic (right to left): the App chip is on the right', (
    t,
  ) async {
    await pumpAt(
      t,
      const Device('phone', 390, 844),
      locale: const Locale('ar'),
    );
    final app = t.getRect(find.byKey(const Key('inbox-chip-app')));
    final med = t.getRect(find.byKey(const Key('inbox-chip-medicine')));
    expect(app.left, greaterThan(med.left));
  });

  testWidgets('on a wide screen the content does not stretch edge to edge', (
    t,
  ) async {
    await pumpAt(t, const Device('wide', 1280, 800));
    final chip = t.getSize(find.byKey(const Key('inbox-chip-app')));
    expect(
      chip.width,
      lessThanOrEqualTo(400),
      reason: 'a chip as wide as 600 px would be a stretched half-screen bar',
    );
  });

  testWidgets('long names are cut, not overflowing, in a tile', (t) async {
    await pumpAt(t, const Device('small', 320, 568), textScale: 1.0);
    expect(t.takeException(), isNull);
    expect(find.textContaining('Amoxicillin'), findsWidgets);
  });
}
