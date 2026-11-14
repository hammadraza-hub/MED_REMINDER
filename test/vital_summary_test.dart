import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/symptom_validator.dart';
import 'package:med_remind_app/core/vitals/vital_summary.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';

VitalPoint pt(int day, int hour, double v, [double? v2]) =>
    VitalPoint(at: DateTime(2026, 11, day, hour), value: v, value2: v2);

void main() {
  group('latest', () {
    test('empty -> null', () {
      expect(VitalAnalysis.latest(const []), isNull);
    });

    test('picks the newest by time, not by list order', () {
      final newest = pt(10, 9, 75);
      final l = VitalAnalysis.latest([pt(9, 9, 70), newest, pt(8, 9, 72)]);
      expect(l, same(newest));
    });
  });

  group('trend', () {
    test('fewer than two readings is stable', () {
      expect(VitalAnalysis.trend(const []), VitalTrendDirection.stable);
      expect(VitalAnalysis.trend([pt(1, 8, 70)]), VitalTrendDirection.stable);
    });

    test('rising and falling', () {
      expect(
        VitalAnalysis.trend([pt(1, 8, 70), pt(2, 8, 70), pt(3, 8, 78)]),
        VitalTrendDirection.up,
      );
      expect(
        VitalAnalysis.trend([pt(1, 8, 80), pt(2, 8, 80), pt(3, 8, 72)]),
        VitalTrendDirection.down,
      );
    });

    test('small changes (under 2 percent) are stable', () {
      expect(
        VitalAnalysis.trend([pt(1, 8, 100), pt(2, 8, 100), pt(3, 8, 101.5)]),
        VitalTrendDirection.stable,
      );
      expect(
        VitalAnalysis.trend([pt(1, 8, 100), pt(2, 8, 98.5)]),
        VitalTrendDirection.stable,
      );
    });

    test('exactly 2 percent counts as a change', () {
      expect(
        VitalAnalysis.trend([pt(1, 8, 100), pt(2, 8, 102)]),
        VitalTrendDirection.up,
      );
    });

    test('order of the input list does not matter', () {
      expect(
        VitalAnalysis.trend([pt(3, 8, 78), pt(1, 8, 70), pt(2, 8, 70)]),
        VitalTrendDirection.up,
      );
    });

    test('only the last 3 earlier readings form the baseline', () {
      // old low values must not drag the baseline down
      final pts = [
        pt(1, 8, 10),
        pt(2, 8, 10),
        pt(3, 8, 100),
        pt(4, 8, 100),
        pt(5, 8, 100),
        pt(6, 8, 100.5),
      ];
      expect(VitalAnalysis.trend(pts), VitalTrendDirection.stable);
    });

    test('blood pressure trend uses systolic', () {
      expect(
        VitalAnalysis.trend([pt(1, 8, 120, 80), pt(2, 8, 135, 70)]),
        VitalTrendDirection.up,
      );
    });
  });

  group('daily summaries', () {
    test('empty -> empty', () {
      expect(VitalAnalysis.dailySummaries(const []), isEmpty);
    });

    test('groups by local day with avg, min, max and count', () {
      final out = VitalAnalysis.dailySummaries([
        pt(10, 8, 90),
        pt(10, 20, 110),
        pt(10, 13, 100),
        pt(11, 9, 130),
      ]);
      expect(out.length, 2);
      expect(out[0].dayKey, '2026-11-10');
      expect(out[0].count, 3);
      expect(out[0].avg, 100);
      expect(out[0].min, 90);
      expect(out[0].max, 110);
      expect(out[1].dayKey, '2026-11-11');
      expect(out[1].count, 1);
    });

    test('result is ordered by day even if input is not', () {
      final out = VitalAnalysis.dailySummaries([pt(12, 8, 1), pt(3, 8, 1)]);
      expect(out.map((d) => d.dayKey), ['2026-11-03', '2026-11-12']);
    });

    test('average is rounded to one decimal', () {
      final out = VitalAnalysis.dailySummaries([
        pt(10, 8, 70),
        pt(10, 9, 71),
        pt(10, 10, 71),
      ]);
      expect(out.single.avg, 70.7);
    });

    test('blood pressure keeps a diastolic summary too', () {
      final out = VitalAnalysis.dailySummaries([
        pt(10, 8, 120, 80),
        pt(10, 20, 140, 90),
      ]);
      final d = out.single;
      expect(d.avg, 130);
      expect(d.avg2, 85);
      expect(d.min2, 80);
      expect(d.max2, 90);
    });

    test('single-value kinds have no diastolic fields', () {
      final d = VitalAnalysis.dailySummaries([pt(10, 8, 95)]).single;
      expect(d.avg2, isNull);
      expect(d.toMap(VitalKind.glucose).containsKey('avg2'), isFalse);
    });

    test('document id and map match the documented shape', () {
      final d = VitalAnalysis.dailySummaries([pt(5, 8, 95)]).single;
      expect(d.docId(VitalKind.glucose), 'glucose_2026-11-05');
      final m = d.toMap(VitalKind.glucose);
      expect(m['type'], 'glucose');
      expect(m['day'], '2026-11-05');
      expect(m['count'], 1);
      expect(m['avg'], 95);
    });

    test('dayKey pads month and day', () {
      expect(VitalAnalysis.dayKey(DateTime(2026, 1, 2)), '2026-01-02');
    });
  });

  group('symptom validator', () {
    SymptomError? err({
      String name = 'Nausea',
      int severity = 3,
      String? notes,
      DateTime? at,
      DateTime? now,
    }) => SymptomValidator.validate(
      name: name,
      severity: severity,
      notes: notes,
      occurredAt: at,
      now: now,
    ).error;

    test('a normal symptom is valid', () {
      expect(err(), isNull);
      expect(err(notes: 'After lunch'), isNull);
    });

    test('name must not be empty or only spaces, and has a limit', () {
      expect(err(name: ''), SymptomError.nameEmpty);
      expect(err(name: '   '), SymptomError.nameEmpty);
      expect(err(name: 'a' * 100), isNull);
      expect(err(name: 'a' * 101), SymptomError.nameTooLong);
    });

    test('severity must be 1 to 5', () {
      expect(err(severity: 1), isNull);
      expect(err(severity: 5), isNull);
      expect(err(severity: 0), SymptomError.severityOutOfRange);
      expect(err(severity: 6), SymptomError.severityOutOfRange);
    });

    test('notes are limited to 500 characters', () {
      expect(err(notes: 'n' * 500), isNull);
      expect(err(notes: 'n' * 501), SymptomError.notesTooLong);
    });

    test('future time is rejected, small skew is fine', () {
      final now = DateTime.utc(2026, 11, 14, 12);
      expect(
        err(at: now.add(const Duration(hours: 2)), now: now),
        SymptomError.timeInFuture,
      );
      expect(err(at: now.add(const Duration(minutes: 5)), now: now), isNull);
    });
  });
}
