import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/vital_input.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';

final _now = DateTime.utc(2026, 11, 14, 12);
final _past = DateTime.utc(2026, 11, 14, 8);

VitalInputResult parse(
  VitalKind kind,
  String primary, {
  String secondary = '',
  String pulse = '',
  DateTime? at,
}) => VitalInput.parse(
  kind: kind,
  primaryText: primary,
  secondaryText: secondary,
  pulseText: pulse,
  measuredAt: at ?? _past,
  now: _now,
);

void expectIssue(
  VitalInputResult r,
  VitalField field,
  VitalInputProblem problem,
) {
  expect(r.isOk, isFalse);
  expect(r.issue!.field, field);
  expect(r.issue!.problem, problem);
}

void main() {
  group('valid input', () {
    test('blood pressure with pulse', () {
      final r = parse(
        VitalKind.bloodPressure,
        '120',
        secondary: '80',
        pulse: '72',
      );
      expect(r.isOk, isTrue);
      final v = r.reading!;
      expect(v.kind, VitalKind.bloodPressure);
      expect(v.value, 120);
      expect(v.value2, 80);
      expect(v.pulse, 72);
      expect(v.measuredAt, _past);
    });

    test('pulse is optional', () {
      final r = parse(VitalKind.bloodPressure, '120', secondary: '80');
      expect(r.reading!.pulse, isNull);
    });

    test('single value kinds, decimals and surrounding spaces', () {
      expect(parse(VitalKind.weight, ' 72.4 ').reading!.value, 72.4);
      expect(parse(VitalKind.glucose, '95').reading!.value, 95);
      expect(parse(VitalKind.heartRate, '74').reading!.value, 74);
    });

    test('decimal comma is accepted', () {
      expect(parse(VitalKind.weight, '72,4').reading!.value, 72.4);
    });

    test('secondary and pulse text are ignored for non-BP kinds', () {
      final r = parse(VitalKind.glucose, '95', secondary: '80', pulse: '70');
      expect(r.isOk, isTrue);
      expect(r.reading!.value2, isNull);
      expect(r.reading!.pulse, isNull);
    });
  });

  group('problems with the primary value', () {
    test('empty', () {
      expectIssue(
        parse(VitalKind.weight, ''),
        VitalField.primary,
        VitalInputProblem.empty,
      );
      expectIssue(
        parse(VitalKind.weight, '   '),
        VitalField.primary,
        VitalInputProblem.empty,
      );
    });

    test('not a number', () {
      expectIssue(
        parse(VitalKind.weight, 'abc'),
        VitalField.primary,
        VitalInputProblem.notANumber,
      );
      expectIssue(
        parse(VitalKind.weight, '.'),
        VitalField.primary,
        VitalInputProblem.notANumber,
      );
      expectIssue(
        parse(VitalKind.weight, '1.2.3'),
        VitalField.primary,
        VitalInputProblem.notANumber,
      );
    });

    test('out of range carries the limits for the message', () {
      final r = parse(VitalKind.weight, '5000');
      expectIssue(r, VitalField.primary, VitalInputProblem.range);
      expect(r.issue!.min, 1);
      expect(r.issue!.max, 700);
    });

    test('zero is out of range, not "empty"', () {
      expectIssue(
        parse(VitalKind.heartRate, '0'),
        VitalField.primary,
        VitalInputProblem.range,
      );
    });
  });

  group('blood pressure problems', () {
    test('diastolic missing / not a number', () {
      expectIssue(
        parse(VitalKind.bloodPressure, '120'),
        VitalField.secondary,
        VitalInputProblem.diastolicMissing,
      );
      expectIssue(
        parse(VitalKind.bloodPressure, '120', secondary: 'x'),
        VitalField.secondary,
        VitalInputProblem.notANumber,
      );
    });

    test('diastolic out of range and not lower than systolic', () {
      final r = parse(VitalKind.bloodPressure, '120', secondary: '10');
      expectIssue(r, VitalField.secondary, VitalInputProblem.diastolicRange);
      expect(r.issue!.min, 20);
      expect(r.issue!.max, 200);
      expectIssue(
        parse(VitalKind.bloodPressure, '80', secondary: '90'),
        VitalField.secondary,
        VitalInputProblem.diastolicNotLower,
      );
    });

    test('pulse out of range / not a number', () {
      final r = parse(
        VitalKind.bloodPressure,
        '120',
        secondary: '80',
        pulse: '5',
      );
      expectIssue(r, VitalField.pulse, VitalInputProblem.pulseRange);
      expect(r.issue!.min, 20);
      expectIssue(
        parse(VitalKind.bloodPressure, '120', secondary: '80', pulse: 'x'),
        VitalField.pulse,
        VitalInputProblem.notANumber,
      );
    });

    test('systolic is checked before diastolic', () {
      expectIssue(
        parse(VitalKind.bloodPressure, '500', secondary: '80'),
        VitalField.primary,
        VitalInputProblem.range,
      );
    });
  });

  group('time', () {
    test('a time in the future is a problem on the time field', () {
      expectIssue(
        parse(VitalKind.weight, '70', at: _now.add(const Duration(hours: 3))),
        VitalField.time,
        VitalInputProblem.timeInFuture,
      );
    });

    test('a time slightly ahead (clock skew) is fine', () {
      expect(
        parse(
          VitalKind.weight,
          '70',
          at: _now.add(const Duration(minutes: 3)),
        ).isOk,
        isTrue,
      );
    });
  });

  group('formatNumber', () {
    test('drops a trailing .0 only', () {
      expect(VitalInput.formatNumber(120), '120');
      expect(VitalInput.formatNumber(120.0), '120');
      expect(VitalInput.formatNumber(72.4), '72.4');
      expect(VitalInput.formatNumber(0.5), '0.5');
    });
  });
}
