import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/core/vitals/vital_validator.dart';

VitalError? err(
  VitalKind k,
  double v, {
  double? v2,
  double? pulse,
  DateTime? at,
  DateTime? now,
}) => VitalValidator.validate(
  k,
  v,
  value2: v2,
  pulse: pulse,
  measuredAt: at,
  now: now,
).error;

void main() {
  group('kinds and sources', () {
    test('canonical units', () {
      expect(VitalKind.bloodPressure.canonicalUnit, 'mmHg');
      expect(VitalKind.glucose.canonicalUnit, 'mg/dL');
      expect(VitalKind.weight.canonicalUnit, 'kg');
      expect(VitalKind.heartRate.canonicalUnit, 'bpm');
    });

    test('wire names round-trip, unknown -> null', () {
      for (final k in VitalKind.values) {
        expect(VitalKind.fromWire(k.wireName), k);
      }
      expect(VitalKind.fromWire('oxygen'), isNull);
      expect(VitalKind.fromWire(null), isNull);
      for (final s in VitalSource.values) {
        expect(VitalSource.fromWire(s.wireName), s);
      }
      expect(VitalSource.fromWire('fitbit'), isNull);
    });

    test('only health sync sources are sync', () {
      expect(VitalSource.manual.isSync, isFalse);
      expect(VitalSource.healthKit.isSync, isTrue);
      expect(VitalSource.healthConnect.isSync, isTrue);
      expect(VitalSource.healthConnect.wireName, 'health_connect');
    });
  });

  group('blood pressure', () {
    test('normal reading is valid', () {
      expect(err(VitalKind.bloodPressure, 120, v2: 80), isNull);
      expect(err(VitalKind.bloodPressure, 120, v2: 80, pulse: 72), isNull);
    });

    test('systolic limits 40..300 are inclusive', () {
      expect(err(VitalKind.bloodPressure, 40, v2: 30), isNull);
      expect(err(VitalKind.bloodPressure, 300, v2: 200), isNull);
      expect(err(VitalKind.bloodPressure, 39.9, v2: 30), VitalError.outOfRange);
      expect(
        err(VitalKind.bloodPressure, 300.1, v2: 100),
        VitalError.outOfRange,
      );
    });

    test('error carries the limits for the message', () {
      final r = VitalValidator.validate(
        VitalKind.bloodPressure,
        500,
        value2: 80,
      );
      expect(r.isValid, isFalse);
      expect(r.min, 40);
      expect(r.max, 300);
    });

    test('diastolic is required, in range and lower than systolic', () {
      expect(err(VitalKind.bloodPressure, 120), VitalError.diastolicMissing);
      expect(
        err(VitalKind.bloodPressure, 120, v2: 19),
        VitalError.diastolicOutOfRange,
      );
      expect(
        err(VitalKind.bloodPressure, 250, v2: 201),
        VitalError.diastolicOutOfRange,
      );
      expect(
        err(VitalKind.bloodPressure, 80, v2: 80),
        VitalError.diastolicNotLower,
      );
      expect(
        err(VitalKind.bloodPressure, 80, v2: 90),
        VitalError.diastolicNotLower,
      );
    });

    test('pulse must be in range when given', () {
      expect(
        err(VitalKind.bloodPressure, 120, v2: 80, pulse: 10),
        VitalError.pulseOutOfRange,
      );
      expect(
        err(VitalKind.bloodPressure, 120, v2: 80, pulse: 301),
        VitalError.pulseOutOfRange,
      );
    });
  });

  group('single value kinds', () {
    test('glucose 10..1000', () {
      expect(err(VitalKind.glucose, 95), isNull);
      expect(err(VitalKind.glucose, 10), isNull);
      expect(err(VitalKind.glucose, 1000), isNull);
      expect(err(VitalKind.glucose, 9), VitalError.outOfRange);
      expect(err(VitalKind.glucose, 1001), VitalError.outOfRange);
    });

    test('weight 1..700 kg', () {
      expect(err(VitalKind.weight, 72.4), isNull);
      expect(err(VitalKind.weight, 0.5), VitalError.outOfRange);
      expect(err(VitalKind.weight, 701), VitalError.outOfRange);
    });

    test('heart rate 20..300 bpm', () {
      expect(err(VitalKind.heartRate, 74), isNull);
      expect(err(VitalKind.heartRate, 19), VitalError.outOfRange);
      expect(err(VitalKind.heartRate, 301), VitalError.outOfRange);
    });

    test('a second value or pulse is rejected for non-BP kinds', () {
      expect(
        err(VitalKind.glucose, 95, v2: 5),
        VitalError.unexpectedSecondValue,
      );
      expect(
        err(VitalKind.weight, 70, pulse: 70),
        VitalError.unexpectedSecondValue,
      );
    });
  });

  group('bad numbers and time', () {
    test('NaN and infinity are rejected everywhere', () {
      expect(err(VitalKind.weight, double.nan), VitalError.notANumber);
      expect(err(VitalKind.glucose, double.infinity), VitalError.notANumber);
      expect(
        err(VitalKind.bloodPressure, 120, v2: double.nan),
        VitalError.notANumber,
      );
      expect(
        err(VitalKind.bloodPressure, 120, v2: 80, pulse: double.nan),
        VitalError.notANumber,
      );
    });

    test('negative and zero are out of range', () {
      expect(err(VitalKind.weight, 0), VitalError.outOfRange);
      expect(err(VitalKind.heartRate, -60), VitalError.outOfRange);
    });

    test('future readings are rejected, small clock skew is fine', () {
      final now = DateTime.utc(2026, 11, 14, 12);
      expect(
        err(
          VitalKind.weight,
          70,
          at: now.add(const Duration(hours: 1)),
          now: now,
        ),
        VitalError.timeInFuture,
      );
      expect(
        err(
          VitalKind.weight,
          70,
          at: now.add(const Duration(minutes: 5)),
          now: now,
        ),
        isNull,
      );
      expect(
        err(
          VitalKind.weight,
          70,
          at: now.subtract(const Duration(days: 400)),
          now: now,
        ),
        isNull,
      );
    });
  });
}
