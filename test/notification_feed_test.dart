import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/doctors/appointment_models.dart';
import 'package:med_remind_app/core/doctors/appointment_validator.dart';
import 'package:med_remind_app/core/inventory/inventory_repository.dart';
import 'package:med_remind_app/core/notification_feed.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/models/dose.dart';

final now = DateTime.utc(2026, 11, 19, 12);

Dose dose(
  String id,
  DoseStatus status, {
  int deadlineMin = 30,
  String? loggedBy,
  String name = 'Metformin',
}) {
  final at = now.add(Duration(minutes: deadlineMin - 30));
  return Dose(
    id: id,
    profileId: 'p',
    medicationId: 'm',
    medName: name,
    doseLabel: 'x',
    scheduledAt: at,
    missDeadline: now.add(Duration(minutes: deadlineMin)),
    status: status,
    loggedBy: loggedBy,
    loggedAt: loggedBy == null ? null : now,
    createdAt: now,
  );
}

InventoryItem stock(
  String id, {
  int qty = 10,
  int? perDay = 1,
  int threshold = 7,
  DateTime? adjusted,
  int? pack,
}) => InventoryItem(
  id: id,
  medicationId: id,
  memberId: 'p',
  medicineName: 'Med $id',
  strength: '',
  medicineType: 'tablet',
  remainingQuantity: qty,
  unitsPerDay: perDay,
  lowStockThresholdDays: threshold,
  lastAdjustedAt: adjusted,
  packageQuantity: pack,
);

SymptomEntry symptom(
  String id,
  int severity, {
  int daysAgo = 1,
  String? medId,
  String name = 'Nausea',
}) => SymptomEntry(
  id: id,
  symptom: name,
  severity: severity,
  medicationId: medId,
  occurredAt: now.subtract(Duration(days: daysAgo)),
);

Appointment appt(String id, int hoursAhead) => Appointment(
  id: id,
  startsAt: now.add(Duration(hours: hoursAhead)),
  type: AppointmentType.checkup,
);

List<FeedItem> build({
  List<Dose> doses = const [],
  List<InventoryItem> inv = const [],
  List<SymptomEntry> sym = const [],
  List<Appointment> appts = const [],
  bool risk = false,
  String? me = 'me',
  Map<String, String> names = const {},
}) => NotificationFeed.build(
  now: now,
  myUid: me,
  todayDoses: doses,
  inventory: inv,
  symptoms: sym,
  appointments: appts,
  remindersAtRisk: risk,
  medicineNames: names,
);

void main() {
  test('nothing to report: an empty list', () {
    expect(build(), isEmpty);
  });

  group('app chip', () {
    test('a missed dose and a pending dose past its deadline are urgent', () {
      final r = build(
        doses: [
          dose('m_1', DoseStatus.missed),
          dose('m_2', DoseStatus.pending, deadlineMin: -5),
          dose('m_3', DoseStatus.pending), // not late yet
        ],
      );
      expect(r.map((e) => e.id).toSet(), {'missed_m_1', 'missed_m_2'});
      expect(r.every((e) => e.level == FeedLevel.urgent), isTrue);
      expect(r.every((e) => e.category == FeedCategory.app), isTrue);
    });

    test('a dose logged by someone else is shown; my own is not', () {
      final r = build(
        doses: [
          dose('m_1', DoseStatus.taken, loggedBy: 'other'),
          dose('m_2', DoseStatus.skipped, loggedBy: 'other'),
          dose('m_3', DoseStatus.taken, loggedBy: 'me'),
          dose('m_4', DoseStatus.taken), // no logger
        ],
      );
      expect(r.map((e) => e.kind).toSet(), {
        FeedKind.caregiverTaken,
        FeedKind.caregiverSkipped,
      });
      expect(r.length, 2);
      expect(r.every((e) => e.level == FeedLevel.info), isTrue);
    });

    test('as-needed (PRN) doses are never listed', () {
      expect(build(doses: [dose('m_prn_1', DoseStatus.missed)]), isEmpty);
    });

    test('reminders at risk is one warning', () {
      final r = build(risk: true);
      expect(r.single.kind, FeedKind.remindersAtRisk);
      expect(r.single.level, FeedLevel.warning);
    });

    test('appointments: only the next 48 hours; under 24 h is a warning', () {
      final r = build(
        appts: [
          appt('a_soon', 5),
          appt('a_tomorrow', 30),
          appt('a_far', 72),
          appt('a_past', -2),
        ],
      );
      expect(r.map((e) => e.id).toSet(), {'appt_a_soon', 'appt_a_tomorrow'});
      expect(
        r.firstWhere((e) => e.id == 'appt_a_soon').level,
        FeedLevel.warning,
      );
      expect(
        r.firstWhere((e) => e.id == 'appt_a_tomorrow').level,
        FeedLevel.info,
      );
      expect(r.first.subject, AppointmentType.checkup.code);
    });
  });

  group('medicine chip', () {
    test('out of stock is urgent, low stock is a warning with the days', () {
      final r = build(
        inv: [
          stock('a', qty: 0),
          stock('b', qty: 3), // 3 days, threshold 7
          stock('c', qty: 30), // fine
        ],
      );
      expect(r.map((e) => e.id).toSet(), {'out_a', 'low_b'});
      expect(r.firstWhere((e) => e.id == 'out_a').level, FeedLevel.urgent);
      final low = r.firstWhere((e) => e.id == 'low_b');
      expect(low.level, FeedLevel.warning);
      expect(low.number, 3);
    });

    test('a medicine whose stock is not tracked is not "out of stock"', () {
      final r = build(inv: [stock('a', qty: 0, perDay: null)]);
      expect(r, isEmpty);
    });

    test('tracked by a package size or an adjustment counts', () {
      expect(
        build(inv: [stock('a', qty: 0, perDay: null, pack: 30)]).length,
        1,
      );
      expect(
        build(inv: [stock('b', qty: 0, perDay: null, adjusted: now)]).length,
        1,
      );
    });

    test('no daily use known: low stock cannot be told, only out of stock', () {
      final r = build(inv: [stock('a', qty: 2, perDay: null, pack: 30)]);
      expect(r, isEmpty);
    });

    test('side effects: last 7 days; severity 4-5 is urgent', () {
      final r = build(
        sym: [
          symptom('s1', 2, daysAgo: 1),
          symptom('s2', 5, daysAgo: 3, name: 'Rash'),
          symptom('s3', 3, daysAgo: 8), // too old
        ],
      );
      expect(r.map((e) => e.id).toSet(), {'se_s1', 'se_s2'});
      expect(r.first.id, 'se_s2', reason: 'urgent first');
      expect(r.first.level, FeedLevel.urgent);
      expect(r.last.level, FeedLevel.info);
    });

    test('a side effect carries the medicine it was linked to', () {
      final r = build(
        sym: [symptom('s1', 3, medId: 'mx')],
        names: {'mx': 'Metformin'},
      );
      expect(r.single.detail, 'Metformin');
      expect(r.single.number, 3);
      expect(build(sym: [symptom('s2', 3)]).single.detail, isNull);
    });
  });

  group('the whole list', () {
    test('urgent first, then warnings, then info', () {
      final r = build(
        doses: [
          dose('m_1', DoseStatus.missed),
          dose('m_2', DoseStatus.taken, loggedBy: 'other'),
        ],
        risk: true,
        inv: [stock('a', qty: 0)],
      );
      expect(r.first.level, FeedLevel.urgent);
      expect(r.last.level, FeedLevel.info);
      final levels = r.map((e) => e.level.index).toList();
      expect(levels, [...levels]..sort((a, b) => b.compareTo(a)));
    });

    test('`of` splits the two chips', () {
      final r = build(
        doses: [dose('m_1', DoseStatus.missed)],
        inv: [stock('a', qty: 0)],
        sym: [symptom('s1', 2)],
      );
      expect(NotificationFeed.of(r, FeedCategory.app).length, 1);
      expect(NotificationFeed.of(r, FeedCategory.medicine).length, 2);
    });

    test('needsAttention: only warnings and urgent items count', () {
      expect(NotificationFeed.needsAttention(const []), isFalse);
      expect(
        NotificationFeed.needsAttention(build(sym: [symptom('s1', 2)])),
        isFalse,
      );
      expect(NotificationFeed.needsAttention(build(risk: true)), isTrue);
    });

    test('the list is capped', () {
      final r = build(
        sym: [for (var i = 0; i < 100; i++) symptom('s$i', 2, daysAgo: 1)],
      );
      expect(r.length, NotificationFeed.maxItems);
    });

    test('the same input gives the same order', () {
      final doses = [
        dose('m_2', DoseStatus.missed),
        dose('m_1', DoseStatus.missed),
      ];
      expect(
        build(doses: doses).map((e) => e.id).toList(),
        build(doses: doses.reversed.toList()).map((e) => e.id).toList(),
      );
    });
  });
}
