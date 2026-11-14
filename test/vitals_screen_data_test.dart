import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/vital_models.dart';
import 'package:med_remind_app/core/vitals/vital_summary.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/features/home/vitals_chart_data.dart';
import 'package:med_remind_app/features/home/vitals_data.dart';

VitalReading r(VitalKind kind, double v, {double? v2, required DateTime at}) =>
    VitalReading(kind: kind, value: v, value2: v2, measuredAt: at);

void main() {
  final now = DateTime(2026, 11, 14, 15);

  group('VitalsData.fromReadings (list cards)', () {
    test('no readings -> no cards', () {
      expect(VitalsData.fromReadings({}), isEmpty);
      expect(VitalsData.fromReadings({VitalKind.glucose: []}), isEmpty);
    });

    test('only kinds with readings get a card, in a fixed order', () {
      final cards = VitalsData.fromReadings({
        VitalKind.heartRate: [r(VitalKind.heartRate, 74, at: now)],
        VitalKind.bloodPressure: [
          r(VitalKind.bloodPressure, 120, v2: 80, at: now),
        ],
      });
      expect(cards.map((c) => c.type), [
        VitalType.bloodPressure,
        VitalType.heartRate,
      ]);
    });

    test('card shows the NEWEST reading with its unit and time', () {
      final newest = now;
      final older = now.subtract(const Duration(days: 2));
      final card = VitalsData.fromReadings({
        VitalKind.glucose: [
          r(VitalKind.glucose, 110, at: newest),
          r(VitalKind.glucose, 90, at: older),
        ],
      }).single;
      expect(card.value, '110');
      expect(card.unit, 'mg/dL');
      expect(card.recordedAt, newest);
      expect(card.title, 'Blood Glucose');
    });

    test('blood pressure value is systolic/diastolic', () {
      final card = VitalsData.fromReadings({
        VitalKind.bloodPressure: [
          r(VitalKind.bloodPressure, 128, v2: 82, at: now),
        ],
      }).single;
      expect(card.value, '128/82');
      expect(card.unit, 'mmHg');
    });

    test('sparkline history is oldest first and limited to 10 readings', () {
      final list = [
        for (var i = 0; i < 15; i++)
          r(
            VitalKind.heartRate,
            60.0 + i,
            at: now.subtract(Duration(days: i)),
          ), // newest first: 60 is the newest
      ];
      final card = VitalsData.fromReadings({VitalKind.heartRate: list}).single;
      expect(card.history.length, 10);
      expect(card.history.last, 60); // newest at the end
      expect(card.history.first, 69);
    });

    test('trend is calculated from the real readings', () {
      final rising = VitalsData.fromReadings({
        VitalKind.weight: [
          r(VitalKind.weight, 80, at: now),
          r(VitalKind.weight, 70, at: now.subtract(const Duration(days: 1))),
          r(VitalKind.weight, 70, at: now.subtract(const Duration(days: 2))),
        ],
      }).single;
      expect(rising.calculatedTrend, VitalTrend.up);

      final flat = VitalsData.fromReadings({
        VitalKind.weight: [
          r(VitalKind.weight, 70, at: now),
          r(VitalKind.weight, 70, at: now.subtract(const Duration(days: 1))),
        ],
      }).single;
      expect(flat.calculatedTrend, VitalTrend.stable);

      final single = VitalsData.fromReadings({
        VitalKind.weight: [r(VitalKind.weight, 70, at: now)],
      }).single;
      expect(single.calculatedTrend, VitalTrend.stable);
    });

    test('weight sub-line states the real change, never a made-up one', () {
      String detail(List<double> newestFirst) => VitalsData.fromReadings({
        VitalKind.weight: [
          for (var i = 0; i < newestFirst.length; i++)
            r(
              VitalKind.weight,
              newestFirst[i],
              at: now.subtract(Duration(days: i)),
            ),
        ],
      }).single.detailText;

      expect(detail([72.4]), 'First reading');
      expect(detail([72.0, 72.4]), '-0.4 kg since last reading');
      expect(detail([73.0, 72.4]), '+0.6 kg since last reading');
      expect(detail([72.4, 72.4]), 'No change since last reading');
    });

    test('type mapping works both ways', () {
      for (final k in VitalKind.values) {
        expect(VitalsData.kindOf(VitalsData.typeOf(k)), k);
      }
    });

    test('loggedToday counts cards recorded today (local time)', () {
      final cards = VitalsData.fromReadings({
        VitalKind.glucose: [
          r(VitalKind.glucose, 90, at: DateTime(2026, 11, 14, 8)),
        ],
        VitalKind.weight: [
          r(VitalKind.weight, 70, at: DateTime(2026, 11, 10, 8)),
        ],
        VitalKind.heartRate: [
          r(VitalKind.heartRate, 70, at: DateTime(2026, 11, 14, 23, 59)),
        ],
      });
      expect(VitalsData.loggedToday(cards, now: now), 2);
      expect(VitalsData.loggedToday(const [], now: now), 0);
    });
  });

  group('VitalsChartData', () {
    test('fromReadings sorts oldest first and keeps diastolic', () {
      final pts = VitalsChartData.fromReadings([
        r(VitalKind.bloodPressure, 130, v2: 85, at: DateTime(2026, 11, 14)),
        r(VitalKind.bloodPressure, 120, v2: 80, at: DateTime(2026, 11, 12)),
      ]);
      expect(pts.map((p) => p.primaryValue), [120, 130]);
      expect(pts.first.secondaryValue, 80);
    });

    test('fromDaily draws one point per day at local noon', () {
      final pts = VitalsChartData.fromDaily(const [
        VitalDaily(dayKey: '2026-11-13', count: 2, avg: 100, min: 90, max: 110),
        VitalDaily(
          dayKey: '2026-11-12',
          count: 1,
          avg: 80,
          min: 80,
          max: 80,
          avg2: 70,
          min2: 70,
          max2: 70,
        ),
        VitalDaily(dayKey: 'garbage', count: 1, avg: 1, min: 1, max: 1),
      ]);
      expect(pts.length, 2, reason: 'malformed day keys are skipped');
      expect(pts.first.recordedAt, DateTime(2026, 11, 12, 12));
      expect(pts.first.primaryValue, 80);
      expect(pts.first.secondaryValue, 70);
      expect(pts.last.recordedAt, DateTime(2026, 11, 13, 12));
    });

    test('window start counts today as day 1', () {
      expect(
        VitalsChartData.windowStart(VitalChartRange.days7, now),
        DateTime(2026, 11, 8),
      );
      expect(
        VitalsChartData.windowStart(VitalChartRange.days30, now),
        DateTime(2026, 10, 16),
      );
      expect(
        VitalsChartData.windowStart(VitalChartRange.days365, now),
        DateTime(2025, 11, 15),
      );
    });

    test('filteredHistory keeps only the window, with no dummy padding', () {
      final all = VitalsChartData.fromReadings([
        r(
          VitalKind.glucose,
          1,
          at: DateTime(2026, 11, 7, 23, 59),
        ), // just outside 7D
        r(
          VitalKind.glucose,
          2,
          at: DateTime(2026, 11, 8, 0, 0),
        ), // first moment inside
        r(VitalKind.glucose, 3, at: DateTime(2026, 11, 14, 9)),
      ]);
      final seven = VitalsChartData.filteredHistory(
        all,
        VitalChartRange.days7,
        now: now,
      );
      expect(seven.map((p) => p.primaryValue), [2, 3]);

      final thirty = VitalsChartData.filteredHistory(
        all,
        VitalChartRange.days30,
        now: now,
      );
      expect(thirty.length, 3);
    });

    test('a window with no readings stays empty (no invented points)', () {
      final old = VitalsChartData.fromReadings([
        r(VitalKind.glucose, 1, at: DateTime(2026, 1, 1)),
      ]);
      expect(
        VitalsChartData.filteredHistory(old, VitalChartRange.days7, now: now),
        isEmpty,
      );
      expect(
        VitalsChartData.filteredHistory(
          const [],
          VitalChartRange.days7,
          now: now,
        ),
        isEmpty,
      );
    });
  });
}
