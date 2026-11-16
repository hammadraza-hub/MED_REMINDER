import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/adherence_calculator.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/core/reports/report_options.dart';
import 'package:med_remind_app/core/reports/report_range.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/features/calendar/adherence_data.dart' as screen;

final now = DateTime(2026, 11, 14, 10, 0);

ReportDose dose(
  String id,
  DateTime at,
  ReportDoseStatus status, {
  String med = 'm1',
  String name = 'Metformin',
  String? strength = '500mg',
  ReportMissReason reason = ReportMissReason.unspecified,
}) => ReportDose(
  id: id,
  medicationId: med,
  medName: name,
  strength: strength,
  scheduledAt: at,
  status: status,
  reason: reason,
);

const taken = ReportDoseStatus.taken;
const missed = ReportDoseStatus.missed;
const skipped = ReportDoseStatus.skipped;
const pending = ReportDoseStatus.pending;

void main() {
  group('ReportRange', () {
    test('lastDays includes today and counts calendar days', () {
      final r = ReportRange.lastDays(7, now: now);
      expect(r.from, DateTime(2026, 11, 8));
      expect(r.to, DateTime(2026, 11, 14));
      expect(r.dayCount, 7);
      expect(r.days.length, 7);
      expect(r.days.first, DateTime(2026, 11, 8));
      expect(r.days.last, DateTime(2026, 11, 14));
    });

    test('presets 30 and 90 days', () {
      expect(ReportRange.lastDays(30, now: now).dayCount, 30);
      expect(ReportRange.lastDays(90, now: now).dayCount, 90);
    });

    test('a valid custom range has no errors', () {
      expect(
        ReportRange.validate(
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 14),
          now: now,
        ),
        isEmpty,
      );
      // a single day
      expect(
        ReportRange.validate(
          DateTime(2026, 11, 14),
          DateTime(2026, 11, 14),
          now: now,
        ),
        isEmpty,
      );
    });

    test('from after to', () {
      expect(
        ReportRange.validate(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 9),
          now: now,
        ),
        {ReportRangeError.fromAfterTo},
      );
    });

    test('365 days is the longest; 366 is too long', () {
      final to = DateTime(2026, 11, 14);
      final ok = DateTime(2025, 11, 15); // 365 days incl. both ends
      final tooLong = DateTime(2025, 11, 14); // 366 days
      expect(ReportRange.custom(ok, to).dayCount, 365);
      expect(ReportRange.validate(ok, to, now: now), isEmpty);
      expect(ReportRange.custom(tooLong, to).dayCount, 366);
      expect(ReportRange.validate(tooLong, to, now: now), {
        ReportRangeError.tooLong,
      });
    });

    test('a range in the future is refused; today is fine', () {
      expect(
        ReportRange.validate(
          DateTime(2026, 11, 14),
          DateTime(2026, 11, 15),
          now: now,
        ),
        {ReportRangeError.inFuture},
      );
      expect(
        ReportRange.validate(
          DateTime(2026, 11, 14),
          DateTime(2026, 11, 14),
          now: now,
        ),
        isEmpty,
      );
    });

    test('time of day is ignored', () {
      final r = ReportRange.custom(
        DateTime(2026, 11, 10, 23, 59),
        DateTime(2026, 11, 12, 0, 1),
      );
      expect(r.from, DateTime(2026, 11, 10));
      expect(r.to, DateTime(2026, 11, 12));
      expect(r.dayCount, 3);
      expect(r.endExclusive, DateTime(2026, 11, 13));
    });

    test('contains works on local calendar days', () {
      final r = ReportRange.custom(
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 12),
      );
      expect(r.contains(DateTime(2026, 11, 10, 0, 0)), isTrue);
      expect(r.contains(DateTime(2026, 11, 12, 23, 59, 59)), isTrue);
      expect(r.contains(DateTime(2026, 11, 9, 23, 59, 59)), isFalse);
      expect(r.contains(DateTime(2026, 11, 13, 0, 0)), isFalse);
    });

    test('month, year and leap-day boundaries count correctly', () {
      final a = ReportRange.custom(
        DateTime(2026, 12, 30),
        DateTime(2027, 1, 2),
      );
      expect(a.dayCount, 4);
      expect(a.days.map(ReportRange.dayKey), [
        '2026-12-30',
        '2026-12-31',
        '2027-01-01',
        '2027-01-02',
      ]);
      final leap = ReportRange.custom(
        DateTime(2028, 2, 28),
        DateTime(2028, 3, 1),
      );
      expect(leap.dayCount, 3); // 28, 29, 1
    });

    test('dayKey pads month and day', () {
      expect(ReportRange.dayKey(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });

  group('ReportOptions', () {
    test('needs at least one section', () {
      expect(const ReportOptions({}).isValid, isFalse);
      expect(const ReportOptions.adherenceOnly().isValid, isTrue);
    });

    test('toggling adds and removes', () {
      var o = const ReportOptions.adherenceOnly();
      o = o.toggled(ReportSection.vitals);
      expect(o.vitals, isTrue);
      expect(o.needsHealthAccess, isTrue);
      o = o.toggled(ReportSection.vitals);
      expect(o.vitals, isFalse);
      expect(o.needsHealthAccess, isFalse);
      expect(o.toggled(ReportSection.adherence).isValid, isFalse);
    });

    test('side effects also need health access', () {
      expect(
        const ReportOptions({ReportSection.sideEffects}).needsHealthAccess,
        isTrue,
      );
    });
  });

  group('AdherenceCounts', () {
    test('percent, progress and totals', () {
      const c = AdherenceCounts(taken: 6, missed: 2, skipped: 2, pending: 5);
      expect(c.decided, 10);
      expect(c.scheduled, 15);
      expect(c.percent, 60);
      expect(c.progress, closeTo(0.6, 1e-9));
      expect(c.hasData, isTrue);
    });

    test('nothing decided gives 0 and no division by zero', () {
      const c = AdherenceCounts(pending: 3);
      expect(c.percent, 0);
      expect(c.progress, 0);
      expect(c.hasData, isTrue);
      expect(const AdherenceCounts().hasData, isFalse);
    });

    test('rounding is the same as the screen: 2 of 3 is 67', () {
      expect(const AdherenceCounts(taken: 2, missed: 1).percent, 67);
      expect(const AdherenceCounts(taken: 1, missed: 2).percent, 33);
      expect(const AdherenceCounts(taken: 1, skipped: 1).percent, 50);
    });

    test('matches the Adherence Detail screen for many combinations', () {
      for (var t = 0; t <= 12; t++) {
        for (var m = 0; m <= 6; m++) {
          for (var s = 0; s <= 4; s++) {
            final mine = AdherenceCounts(taken: t, missed: m, skipped: s);
            final theirs = screen.AdherenceSummary(
              taken: t,
              missed: m,
              skipped: s,
              previousPeriodPercent: 0,
            );
            expect(mine.percent, theirs.adherencePercent, reason: '$t/$m/$s');
          }
        }
      }
    });
  });

  group('AdherenceCalculator', () {
    final range = ReportRange.custom(
      DateTime(2026, 11, 8),
      DateTime(2026, 11, 14),
    );

    test('no doses: zero counts but every day is present', () {
      final s = AdherenceCalculator.summarize(const [], range);
      expect(s.total.scheduled, 0);
      expect(s.total.percent, 0);
      expect(s.perMedication, isEmpty);
      expect(s.reasons, isEmpty);
      expect(s.perDay.length, 7);
      expect(s.perDay.every((d) => !d.counts.hasData), isTrue);
    });

    test('counts every status', () {
      final s = AdherenceCalculator.summarize([
        dose('a', DateTime(2026, 11, 8, 8), taken),
        dose('b', DateTime(2026, 11, 9, 8), taken),
        dose('c', DateTime(2026, 11, 10, 8), missed),
        dose('d', DateTime(2026, 11, 11, 8), skipped),
        dose('e', DateTime(2026, 11, 14, 20), pending),
      ], range);
      expect(s.total.taken, 2);
      expect(s.total.missed, 1);
      expect(s.total.skipped, 1);
      expect(s.total.pending, 1);
      expect(s.total.percent, 50);
    });

    test('doses outside the range are ignored (both edges inclusive)', () {
      final s = AdherenceCalculator.summarize([
        dose('before', DateTime(2026, 11, 7, 23, 59), taken),
        dose('first', DateTime(2026, 11, 8, 0, 0), taken),
        dose('last', DateTime(2026, 11, 14, 23, 59), missed),
        dose('after', DateTime(2026, 11, 15, 0, 0), taken),
      ], range);
      expect(s.total.taken, 1);
      expect(s.total.missed, 1);
      expect(s.total.scheduled, 2);
    });

    test('a dose that arrives twice is counted once', () {
      final s = AdherenceCalculator.summarize([
        dose('a', DateTime(2026, 11, 9, 8), taken),
        dose('a', DateTime(2026, 11, 9, 8), taken),
      ], range);
      expect(s.total.taken, 1);
    });

    test('a late-evening dose belongs to its own day', () {
      final s = AdherenceCalculator.summarize([
        dose('late', DateTime(2026, 11, 9, 23, 30), taken),
        dose('early', DateTime(2026, 11, 10, 0, 30), missed),
      ], range);
      final nine = s.perDay.firstWhere((d) => d.dayKey == '2026-11-09');
      final ten = s.perDay.firstWhere((d) => d.dayKey == '2026-11-10');
      expect(nine.counts.taken, 1);
      expect(nine.counts.missed, 0);
      expect(ten.counts.missed, 1);
    });

    test('per day adds up to the total', () {
      final s = AdherenceCalculator.summarize([
        for (var i = 0; i < 7; i++)
          dose('t$i', DateTime(2026, 11, 8 + i, 8), i.isEven ? taken : missed),
        dose('x', DateTime(2026, 11, 10, 20), skipped),
      ], range);
      final sum = s.perDay.fold<int>(0, (a, d) => a + d.counts.scheduled);
      expect(sum, s.total.scheduled);
      expect(s.perDay.length, 7);
      expect(s.perDay.first.day, DateTime(2026, 11, 8));
      expect(s.perDay.last.day, DateTime(2026, 11, 14));
    });

    test('per medication adds up to the total and is best first', () {
      final s = AdherenceCalculator.summarize([
        // Metformin: 1 of 2 = 50
        dose('a', DateTime(2026, 11, 8, 8), taken),
        dose('b', DateTime(2026, 11, 9, 8), missed),
        // Aspirin: 3 of 3 = 100
        dose(
          'c',
          DateTime(2026, 11, 8, 9),
          taken,
          med: 'm2',
          name: 'Aspirin',
          strength: '',
        ),
        dose(
          'd',
          DateTime(2026, 11, 9, 9),
          taken,
          med: 'm2',
          name: 'Aspirin',
          strength: '',
        ),
        dose(
          'e',
          DateTime(2026, 11, 10, 9),
          taken,
          med: 'm2',
          name: 'Aspirin',
          strength: '',
        ),
        // Vitamin: only pending
        dose(
          'f',
          DateTime(2026, 11, 14, 9),
          pending,
          med: 'm3',
          name: 'Vitamin D',
          strength: null,
        ),
      ], range);

      expect(s.perMedication.map((m) => m.name), [
        'Aspirin',
        'Metformin',
        'Vitamin D',
      ]);
      expect(s.perMedication.map((m) => m.counts.percent), [100, 50, 0]);
      expect(s.perMedication[0].displayName, 'Aspirin');
      expect(s.perMedication[1].displayName, 'Metformin 500mg');

      final sum = s.perMedication.fold<int>(
        0,
        (a, m) => a + m.counts.scheduled,
      );
      expect(sum, s.total.scheduled);
    });

    test('ties are ordered by number of decided doses, then name', () {
      final s = AdherenceCalculator.summarize([
        dose(
          'a',
          DateTime(2026, 11, 8, 8),
          taken,
          med: 'b',
          name: 'Bravo',
          strength: '',
        ),
        dose(
          'b',
          DateTime(2026, 11, 8, 9),
          taken,
          med: 'a',
          name: 'alpha',
          strength: '',
        ),
        dose(
          'c',
          DateTime(2026, 11, 9, 9),
          taken,
          med: 'c',
          name: 'Charlie',
          strength: '',
        ),
        dose(
          'd',
          DateTime(2026, 11, 10, 9),
          taken,
          med: 'c',
          name: 'Charlie',
          strength: '',
        ),
      ], range);
      // all 100%: Charlie has 2 decided, then alpha / Bravo by name
      expect(s.perMedication.map((m) => m.name), ['Charlie', 'alpha', 'Bravo']);
    });

    test(
      'missed reasons count missed and skipped doses only, largest first',
      () {
        final s = AdherenceCalculator.summarize([
          dose(
            'a',
            DateTime(2026, 11, 8, 8),
            missed,
            reason: ReportMissReason.forgot,
          ),
          dose(
            'b',
            DateTime(2026, 11, 9, 8),
            missed,
            reason: ReportMissReason.forgot,
          ),
          dose(
            'c',
            DateTime(2026, 11, 10, 8),
            skipped,
            reason: ReportMissReason.sideEffect,
          ),
          dose('d', DateTime(2026, 11, 11, 8), missed),
          dose(
            'e',
            DateTime(2026, 11, 12, 8),
            taken,
            reason: ReportMissReason.other,
          ),
          dose(
            'f',
            DateTime(2026, 11, 13, 8),
            pending,
            reason: ReportMissReason.ranOut,
          ),
        ], range);
        expect(s.reasons.map((r) => (r.reason, r.count)), [
          (ReportMissReason.forgot, 2),
          (ReportMissReason.sideEffect, 1),
          (ReportMissReason.unspecified, 1),
        ]);
      },
    );

    test('percent of the report equals the percent shown by the screen', () {
      final doses = [
        for (var i = 0; i < 20; i++)
          dose(
            'd$i',
            DateTime(2026, 11, 8 + i % 7, 8, i),
            i % 5 == 0 ? missed : taken,
          ),
      ];
      final s = AdherenceCalculator.summarize(doses, range);
      final theirs = screen.AdherenceSummary(
        taken: s.total.taken,
        missed: s.total.missed,
        skipped: s.total.skipped,
        previousPeriodPercent: 0,
      );
      expect(s.total.percent, theirs.adherencePercent);
    });
  });

  group('ReportData', () {
    final range = ReportRange.lastDays(7, now: now);
    const options = ReportOptions.adherenceOnly();

    test('is empty when no section has anything', () {
      final d = ReportData(
        range: range,
        generatedAt: now,
        options: options,
        adherence: AdherenceCalculator.summarize(const [], range),
      );
      expect(d.isEmpty, isTrue);
    });

    test('is not empty with a dose or a side effect', () {
      final withDose = ReportData(
        range: range,
        generatedAt: now,
        options: options,
        adherence: AdherenceCalculator.summarize([
          dose('a', DateTime(2026, 11, 10, 8), pending),
        ], range),
      );
      expect(withDose.isEmpty, isFalse);

      final withSymptom = ReportData(
        range: range,
        generatedAt: now,
        options: const ReportOptions({ReportSection.sideEffects}),
        symptoms: [
          SymptomEntry(
            symptom: 'Nausea',
            severity: 2,
            occurredAt: DateTime(2026, 11, 10),
          ),
        ],
      );
      expect(withSymptom.isEmpty, isFalse);
    });

    test('sections that were not asked for are null', () {
      final d = ReportData(range: range, generatedAt: now, options: options);
      expect(d.vitals, isNull);
      expect(d.symptoms, isNull);
      expect(d.isEmpty, isTrue);
    });
  });
}
