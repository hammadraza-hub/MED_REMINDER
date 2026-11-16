import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/dose_report_mapper.dart';
import 'package:med_remind_app/core/reports/report_data_source.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/core/reports/report_options.dart';
import 'package:med_remind_app/core/reports/report_range.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/core/vitals/vital_models.dart';
import 'package:med_remind_app/core/vitals/vital_summary.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/features/calendar/adherence_data.dart' as screen;
import 'package:med_remind_app/models/dose.dart';

final now = DateTime(2026, 11, 14, 12, 0);

Dose dose(
  String id,
  DateTime at,
  DoseStatus status, {
  String med = 'm1',
  String name = 'Metformin',
  DateTime? deadline,
  MissedDoseReason? reason,
}) => Dose(
  id: id,
  profileId: 'p',
  medicationId: med,
  medName: name,
  scheduledAt: at,
  missDeadline: deadline ?? at.add(const Duration(hours: 2)),
  status: status,
  reasonCode: reason,
  createdAt: DateTime(2026, 11, 1),
);

class Calls {
  int doses = 0, meds = 0, raw = 0, daily = 0, symptoms = 0;
}

ReportDataSource source({
  List<Dose> doses = const [],
  Map<String, String?> strengths = const {},
  List<VitalReading> Function(VitalKind kind)? readings,
  List<VitalDaily> Function(VitalKind kind)? dailyDocs,
  List<SymptomEntry> symptoms = const [],
  Calls? calls,
  Object? failDoses,
  Object? failMeds,
  Object? failVitals,
  Object? failSymptoms,
}) {
  final c = calls ?? Calls();
  return ReportDataSource(
    fetchDoses: (r) async {
      c.doses++;
      if (failDoses != null) throw failDoses;
      return doses;
    },
    fetchMedicationStrengths: () async {
      c.meds++;
      if (failMeds != null) throw failMeds;
      return strengths;
    },
    fetchVitalReadings: (kind, since) async {
      c.raw++;
      if (failVitals != null) throw failVitals;
      return readings?.call(kind) ?? const [];
    },
    fetchVitalDaily: (kind, from, to) async {
      c.daily++;
      if (failVitals != null) throw failVitals;
      return dailyDocs?.call(kind) ?? const [];
    },
    fetchSymptoms: (since) async {
      c.symptoms++;
      if (failSymptoms != null) throw failSymptoms;
      return symptoms;
    },
  );
}

final week = ReportRange.lastDays(7, now: now);
const all = ReportOptions({
  ReportSection.adherence,
  ReportSection.vitals,
  ReportSection.sideEffects,
});

void main() {
  group('DoseReportMapper (same rules as the Adherence Detail screen)', () {
    final at = DateTime(2026, 11, 10, 8);

    test('taken, skipped and missed stay as they are', () {
      expect(
        DoseReportMapper.statusOf(dose('a', at, DoseStatus.taken), now),
        ReportDoseStatus.taken,
      );
      expect(
        DoseReportMapper.statusOf(dose('a', at, DoseStatus.skipped), now),
        ReportDoseStatus.skipped,
      );
      expect(
        DoseReportMapper.statusOf(dose('a', at, DoseStatus.missed), now),
        ReportDoseStatus.missed,
      );
    });

    test('a pending dose past its deadline counts as missed', () {
      expect(
        DoseReportMapper.statusOf(dose('a', at, DoseStatus.pending), now),
        ReportDoseStatus.missed,
      );
    });

    test('a pending dose still inside its window stays pending', () {
      final d = dose(
        'a',
        now.subtract(const Duration(minutes: 10)),
        DoseStatus.pending,
        deadline: now.add(const Duration(hours: 1)),
      );
      expect(DoseReportMapper.statusOf(d, now), ReportDoseStatus.pending);
    });

    test('a snoozed dose stays pending (not part of the percentage)', () {
      expect(
        DoseReportMapper.statusOf(dose('a', at, DoseStatus.snoozed), now),
        ReportDoseStatus.pending,
      );
    });

    test('reasons map one to one', () {
      expect(DoseReportMapper.reasonOf(null), ReportMissReason.unspecified);
      expect(
        DoseReportMapper.reasonOf(MissedDoseReason.forgot),
        ReportMissReason.forgot,
      );
      expect(
        DoseReportMapper.reasonOf(MissedDoseReason.sideEffect),
        ReportMissReason.sideEffect,
      );
      expect(
        DoseReportMapper.reasonOf(MissedDoseReason.ranOut),
        ReportMissReason.ranOut,
      );
      expect(
        DoseReportMapper.reasonOf(MissedDoseReason.other),
        ReportMissReason.other,
      );
    });

    test('fromDose copies the fields and the strength', () {
      final r = DoseReportMapper.fromDose(
        dose('a', at, DoseStatus.missed, reason: MissedDoseReason.forgot),
        now: now,
        strength: '500mg',
      );
      expect(r.id, 'a');
      expect(r.medicationId, 'm1');
      expect(r.medName, 'Metformin');
      expect(r.strength, '500mg');
      expect(r.scheduledAt, at);
      expect(r.reason, ReportMissReason.forgot);
    });
  });

  group('adherence', () {
    test('numbers match the Adherence Detail screen', () async {
      final doses = [
        dose('a', DateTime(2026, 11, 8, 8), DoseStatus.taken),
        dose('b', DateTime(2026, 11, 9, 8), DoseStatus.taken),
        dose('c', DateTime(2026, 11, 10, 8), DoseStatus.missed),
        dose('d', DateTime(2026, 11, 11, 8), DoseStatus.skipped),
        dose(
          'e',
          DateTime(2026, 11, 12, 8),
          DoseStatus.pending,
        ), // overdue -> missed
        dose('f', DateTime(2026, 11, 13, 8), DoseStatus.snoozed), // not counted
        dose(
          'g',
          DateTime(2026, 11, 14, 11),
          DoseStatus.pending,
          deadline: DateTime(2026, 11, 14, 14),
        ), // still inside its window
      ];
      final data = await source(doses: doses).load(
        range: week,
        options: const ReportOptions.adherenceOnly(),
        now: now,
      );
      final t = data.adherence!.total;

      // what the screen would count: resolved doses only
      final theirs = screen.AdherenceSummary(
        taken: 2,
        missed: 2,
        skipped: 1,
        previousPeriodPercent: 0,
      );
      expect(t.taken, theirs.taken);
      expect(t.missed, theirs.missed);
      expect(t.skipped, theirs.skipped);
      expect(t.percent, theirs.adherencePercent);
      expect(t.pending, 2);
    });

    test('strength comes from the medicine list', () async {
      final data =
          await source(
            doses: [dose('a', DateTime(2026, 11, 9, 8), DoseStatus.taken)],
            strengths: {'m1': '500mg'},
          ).load(
            range: week,
            options: const ReportOptions.adherenceOnly(),
            now: now,
          );
      expect(
        data.adherence!.perMedication.single.displayName,
        'Metformin 500mg',
      );
      expect(data.stats.doses, 1);
      expect(data.stats.medications, 1);
    });

    test('a failing medicine list does not fail the report', () async {
      final data =
          await source(
            doses: [dose('a', DateTime(2026, 11, 9, 8), DoseStatus.taken)],
            failMeds: Exception('offline'),
          ).load(
            range: week,
            options: const ReportOptions.adherenceOnly(),
            now: now,
          );
      expect(data.adherence!.total.taken, 1);
      expect(data.adherence!.perMedication.single.displayName, 'Metformin');
    });

    test('if the doses cannot be read the whole load fails', () async {
      await expectLater(
        source(failDoses: Exception('offline'))
            .load(range: week, options: all, now: now),
        throwsException,
      );
    });

    test('too many doses is refused, never cut', () async {
      final many = [
        for (var i = 0; i <= ReportDataSource.maxDoses; i++)
          dose('d$i', DateTime(2026, 11, 9, 8), DoseStatus.taken),
      ];
      await expectLater(
        source(doses: many).load(
          range: week,
          options: const ReportOptions.adherenceOnly(),
          now: now,
        ),
        throwsA(isA<ReportTooLargeException>()),
      );
    });

    test('adherence is not read when it was not asked for', () async {
      final calls = Calls();
      final data = await source(calls: calls).load(
        range: week,
        options: const ReportOptions({ReportSection.sideEffects}),
        now: now,
      );
      expect(data.adherence, isNull);
      expect(calls.doses, 0);
      expect(calls.meds, 0);
    });
  });

  group('vitals', () {
    VitalReading reading(VitalKind k, DateTime at, double v, [double? v2]) =>
        VitalReading(kind: k, value: v, value2: v2, measuredAt: at);

    test(
      'up to 90 days uses the raw readings and the M15 daily summary',
      () async {
        final calls = Calls();
        final data =
            await source(
              calls: calls,
              readings: (k) => k == VitalKind.glucose
                  ? [
                      reading(k, DateTime(2026, 11, 10, 20), 110),
                      reading(k, DateTime(2026, 11, 10, 8), 90),
                      reading(k, DateTime(2026, 11, 12, 8), 100),
                    ]
                  : const [],
            ).load(
              range: week,
              options: const ReportOptions({ReportSection.vitals}),
              now: now,
            );

        expect(calls.raw, VitalKind.values.length);
        expect(calls.daily, 0);
        final g = data.vitals![VitalKind.glucose]!;
        expect(g.map((d) => d.dayKey), ['2026-11-10', '2026-11-12']);
        expect(g.first.count, 2);
        expect(g.first.avg, 100);
        expect(g.first.min, 90);
        expect(g.first.max, 110);
        expect(data.vitals![VitalKind.weight], isEmpty);
        expect(data.stats.vitals, 3);
      },
    );

    test('blood pressure keeps the diastolic summary', () async {
      final data =
          await source(
            readings: (k) => k == VitalKind.bloodPressure
                ? [reading(k, DateTime(2026, 11, 10, 8), 120, 80)]
                : const [],
          ).load(
            range: week,
            options: const ReportOptions({ReportSection.vitals}),
            now: now,
          );
      final bp = data.vitals![VitalKind.bloodPressure]!.single;
      expect(bp.avg, 120);
      expect(bp.avg2, 80);
    });

    test('readings outside the range are left out', () async {
      final data =
          await source(
            readings: (k) => k == VitalKind.weight
                ? [
                    reading(k, DateTime(2026, 11, 7, 23), 70), // day before
                    reading(k, DateTime(2026, 11, 9, 8), 71),
                    reading(k, DateTime(2026, 11, 15, 8), 72), // after
                  ]
                : const [],
          ).load(
            range: week,
            options: const ReportOptions({ReportSection.vitals}),
            now: now,
          );
      expect(data.vitals![VitalKind.weight]!.map((d) => d.dayKey), [
        '2026-11-09',
      ]);
    });

    test('hitting the raw limit marks the section truncated', () async {
      final data =
          await source(
            readings: (k) => k == VitalKind.glucose
                ? [
                    for (var i = 0; i < ReportDataSource.vitalRawLimit; i++)
                      reading(k, DateTime(2026, 11, 10, 8, 0, i % 60), 100),
                  ]
                : const [],
          ).load(
            range: week,
            options: const ReportOptions({ReportSection.vitals}),
            now: now,
          );
      expect(data.truncated, {ReportSection.vitals});
    });

    test('longer than 90 days uses the per-day documents', () async {
      final calls = Calls();
      final long = ReportRange.lastDays(180, now: now);
      final data =
          await source(
            calls: calls,
            dailyDocs: (k) => k == VitalKind.glucose
                ? [
                    const VitalDaily(
                      dayKey: '2026-10-01',
                      count: 3,
                      avg: 100,
                      min: 90,
                      max: 110,
                    ),
                    const VitalDaily(
                      dayKey: '2026-09-01',
                      count: 2,
                      avg: 95,
                      min: 90,
                      max: 100,
                    ),
                    const VitalDaily(
                      dayKey: '2025-01-01',
                      count: 1,
                      avg: 80,
                      min: 80,
                      max: 80,
                    ), // outside
                  ]
                : const [],
          ).load(
            range: long,
            options: const ReportOptions({ReportSection.vitals}),
            now: now,
          );

      expect(calls.raw, 0);
      expect(calls.daily, VitalKind.values.length);
      expect(data.vitals![VitalKind.glucose]!.map((d) => d.dayKey), [
        '2026-09-01',
        '2026-10-01',
      ]);
    });

    test('exactly 90 days is still raw, 91 is daily', () async {
      final c90 = Calls();
      await source(calls: c90).load(
        range: ReportRange.lastDays(90, now: now),
        options: const ReportOptions({ReportSection.vitals}),
        now: now,
      );
      expect(c90.raw, greaterThan(0));
      expect(c90.daily, 0);

      final c91 = Calls();
      await source(calls: c91).load(
        range: ReportRange.lastDays(91, now: now),
        options: const ReportOptions({ReportSection.vitals}),
        now: now,
      );
      expect(c91.raw, 0);
      expect(c91.daily, greaterThan(0));
    });

    test('a failing vitals read only marks vitals unavailable', () async {
      final data = await source(
        doses: [dose('a', DateTime(2026, 11, 9, 8), DoseStatus.taken)],
        symptoms: [
          SymptomEntry(
            symptom: 'Nausea',
            severity: 2,
            occurredAt: DateTime(2026, 11, 10),
          ),
        ],
        failVitals: Exception('permission-denied'),
      ).load(range: week, options: all, now: now);

      expect(data.unavailable, {ReportSection.vitals});
      expect(data.vitals, isNull);
      expect(data.adherence!.total.taken, 1);
      expect(data.symptoms!.length, 1);
    });
  });

  group('side effects', () {
    SymptomEntry sym(String name, DateTime at) =>
        SymptomEntry(symptom: name, severity: 3, occurredAt: at);

    test('only entries inside the range, newest first', () async {
      final data =
          await source(
            symptoms: [
              sym('Late', DateTime(2026, 11, 13, 9)),
              sym('Outside', DateTime(2026, 11, 20, 9)),
              sym('Early', DateTime(2026, 11, 9, 9)),
              sym('Before', DateTime(2026, 11, 7, 9)),
            ],
          ).load(
            range: week,
            options: const ReportOptions({ReportSection.sideEffects}),
            now: now,
          );
      expect(data.symptoms!.map((s) => s.symptom), ['Late', 'Early']);
      expect(data.stats.symptoms, 4);
    });

    test('hitting the limit marks the section truncated', () async {
      final data =
          await source(
            symptoms: [
              for (var i = 0; i < ReportDataSource.symptomLimit; i++)
                sym('S$i', DateTime(2026, 11, 10, 8, i % 60)),
            ],
          ).load(
            range: week,
            options: const ReportOptions({ReportSection.sideEffects}),
            now: now,
          );
      expect(data.truncated, {ReportSection.sideEffects});
    });

    test('a failing read marks only side effects unavailable', () async {
      final data = await source(failSymptoms: Exception('permission-denied'))
          .load(range: week, options: all, now: now);
      expect(data.unavailable, {ReportSection.sideEffects});
      expect(data.symptoms, isNull);
      expect(data.vitals, isNotNull);
    });
  });

  group('ReportData', () {
    test('records who, when and what was asked', () async {
      final data = await source().load(
        range: week,
        options: all,
        profileName: 'Sarah',
        now: now,
      );
      expect(data.profileName, 'Sarah');
      expect(data.generatedAt, now);
      expect(data.range, week);
      expect(data.options, all);
      expect(data.unavailable, isEmpty);
      expect(data.truncated, isEmpty);
    });

    test('an empty range is reported as empty', () async {
      final data = await source().load(range: week, options: all, now: now);
      expect(data.isEmpty, isTrue);
      expect(data.stats.total, 0);
    });
  });
}
