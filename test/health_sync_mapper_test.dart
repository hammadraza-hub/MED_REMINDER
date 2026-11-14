import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/health_sync_mapper.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';

RawHealthSample s(
  HealthSampleKind kind,
  double v,
  DateTime at, {
  String? uuid,
}) => RawHealthSample(kind: kind, value: v, from: at, uuid: uuid);

final t0 = DateTime.utc(2026, 11, 14, 8, 0, 0);

HealthMapResult map(List<RawHealthSample> samples, {int max = 1500}) =>
    HealthSyncMapper.map(samples, VitalSource.healthKit, maxReadings: max);

void main() {
  group('blood pressure pairing', () {
    test('systolic + diastolic at the same time become one reading', () {
      final r = map([
        s(HealthSampleKind.systolic, 121.4, t0, uuid: 'a'),
        s(HealthSampleKind.diastolic, 79.6, t0, uuid: 'b'),
      ]);
      expect(r.readings.length, 1);
      final bp = r.readings.single;
      expect(bp.kind, VitalKind.bloodPressure);
      expect(bp.value, 121);
      expect(bp.value2, 80);
      expect(bp.measuredAt, t0);
      expect(bp.source, VitalSource.healthKit);
      expect(bp.externalId, 'a+b');
      expect(r.unpairedBloodPressure, 0);
    });

    test('samples a minute apart still pair, 5 minutes apart do not', () {
      final near = map([
        s(HealthSampleKind.systolic, 120, t0),
        s(HealthSampleKind.diastolic, 80, t0.add(const Duration(minutes: 1))),
      ]);
      expect(near.readings.length, 1);

      final far = map([
        s(HealthSampleKind.systolic, 120, t0),
        s(HealthSampleKind.diastolic, 80, t0.add(const Duration(minutes: 5))),
      ]);
      expect(far.readings, isEmpty);
      expect(far.unpairedBloodPressure, 2);
    });

    test('several measurements pair with their own partner', () {
      final r = map([
        s(HealthSampleKind.systolic, 118, t0),
        s(HealthSampleKind.systolic, 130, t0.add(const Duration(hours: 6))),
        s(HealthSampleKind.diastolic, 84, t0.add(const Duration(hours: 6))),
        s(HealthSampleKind.diastolic, 76, t0),
      ]);
      expect(r.readings.length, 2);
      final byValue = {for (final b in r.readings) b.value: b.value2};
      expect(byValue[118], 76);
      expect(byValue[130], 84);
    });

    test('a diastolic is used by only one systolic', () {
      final r = map([
        s(HealthSampleKind.systolic, 120, t0),
        s(HealthSampleKind.systolic, 125, t0.add(const Duration(seconds: 30))),
        s(HealthSampleKind.diastolic, 80, t0),
      ]);
      expect(r.readings.length, 1);
      expect(r.unpairedBloodPressure, 1);
    });

    test('without platform ids the id is built from time and values', () {
      final r = map([
        s(HealthSampleKind.systolic, 120, t0),
        s(HealthSampleKind.diastolic, 80, t0),
      ]);
      expect(
        r.readings.single.externalId,
        'bp-${t0.millisecondsSinceEpoch}-120.0-80.0',
      );
    });
  });

  group('glucose and weight', () {
    test('kept one-to-one with rounding and the platform id', () {
      final r = map([
        s(HealthSampleKind.glucose, 99.04, t0, uuid: 'g1'),
        s(HealthSampleKind.weight, 72.456, t0, uuid: 'w1'),
      ]);
      final g = r.readings.firstWhere((x) => x.kind == VitalKind.glucose);
      final w = r.readings.firstWhere((x) => x.kind == VitalKind.weight);
      expect(g.value, 99.0);
      expect(g.externalId, 'g1');
      expect(w.value, 72.46);
      expect(w.externalId, 'w1');
    });

    test('NaN and infinite samples are ignored', () {
      final r = map([
        s(HealthSampleKind.weight, double.nan, t0),
        s(HealthSampleKind.glucose, double.infinity, t0),
      ]);
      expect(r.readings, isEmpty);
    });
  });

  group('heart rate', () {
    test('many samples in one hour become a single average', () {
      final r = map([
        for (var i = 0; i < 12; i++)
          s(
            HealthSampleKind.heartRate,
            60.0 + i,
            t0.add(Duration(minutes: i * 5)),
          ),
      ]);
      expect(r.readings.length, 1);
      final hr = r.readings.single;
      expect(hr.kind, VitalKind.heartRate);
      expect(hr.value, 66); // average of 60..71 = 65.5 -> 66
      expect(hr.measuredAt, DateTime.utc(2026, 11, 14, 8));
      expect(
        hr.externalId,
        'hr-${DateTime.utc(2026, 11, 14, 8).millisecondsSinceEpoch}',
      );
    });

    test('different hours stay separate', () {
      final r = map([
        s(HealthSampleKind.heartRate, 60, t0),
        s(HealthSampleKind.heartRate, 80, t0.add(const Duration(hours: 1))),
        s(
          HealthSampleKind.heartRate,
          70,
          t0.add(const Duration(hours: 1, minutes: 20)),
        ),
      ]);
      expect(r.readings.length, 2);
      expect(r.readings.first.value, 75); // newest hour first
      expect(r.readings.last.value, 60);
    });

    test('the same hour always gets the same id (re-sync is stable)', () {
      final a = map([s(HealthSampleKind.heartRate, 60, t0)]);
      final b = map([
        s(HealthSampleKind.heartRate, 60, t0),
        s(HealthSampleKind.heartRate, 90, t0.add(const Duration(minutes: 30))),
      ]);
      expect(a.readings.single.externalId, b.readings.single.externalId);
    });
  });

  group('ordering, limit and ids', () {
    test('result is newest first', () {
      final r = map([
        s(HealthSampleKind.weight, 70, t0),
        s(HealthSampleKind.weight, 71, t0.add(const Duration(days: 2))),
        s(HealthSampleKind.weight, 72, t0.add(const Duration(days: 1))),
      ]);
      expect(r.readings.map((x) => x.value), [71, 72, 70]);
    });

    test('only the newest readings are kept when over the limit', () {
      final r = map([
        for (var i = 0; i < 10; i++)
          s(HealthSampleKind.weight, 60.0 + i, t0.add(Duration(days: i))),
      ], max: 4);
      expect(r.readings.length, 4);
      expect(r.truncated, isTrue);
      expect(r.readings.first.value, 69);
      expect(r.readings.last.value, 66);
    });

    test('not truncated when within the limit', () {
      expect(
        map([s(HealthSampleKind.weight, 70, t0)], max: 4).truncated,
        isFalse,
      );
    });

    test('id without platform uuid is stable for the same data', () {
      final a = map([s(HealthSampleKind.weight, 70, t0)]).readings.single;
      final b = map([s(HealthSampleKind.weight, 70, t0)]).readings.single;
      expect(a.externalId, b.externalId);
      expect(a.externalId, startsWith('weight-'));
    });

    test('empty input gives an empty result', () {
      final r = map(const []);
      expect(r.readings, isEmpty);
      expect(r.unpairedBloodPressure, 0);
      expect(r.truncated, isFalse);
    });
  });
}
