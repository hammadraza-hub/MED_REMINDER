import 'vital_models.dart';
import 'vital_types.dart';
import 'vital_validator.dart';

/// ============================================================
/// VITAL INPUT PARSER — M15 step 4
///
/// Pure logic: turns what the user typed on the Add Vitals screen into a
/// validated [VitalReading], or an [VitalInputIssue] saying which field is
/// wrong and why. The screen maps the issue to a localised message.
/// ============================================================
enum VitalField { primary, secondary, pulse, time }

enum VitalInputProblem {
  /// A required field is empty.
  empty,

  /// Not a number ("abc", ".", "1.2.3").
  notANumber,

  /// Primary value outside the allowed range ([VitalIssueLimits]).
  range,

  /// Blood pressure: diastolic missing.
  diastolicMissing,

  /// Blood pressure: diastolic outside the allowed range.
  diastolicRange,

  /// Blood pressure: diastolic is not lower than systolic.
  diastolicNotLower,

  /// Pulse outside the allowed range.
  pulseRange,

  /// Measured time is in the future.
  timeInFuture,
}

class VitalInputIssue {
  const VitalInputIssue(this.field, this.problem, {this.min, this.max});

  final VitalField field;
  final VitalInputProblem problem;

  /// Limits to show in the message (for the range problems).
  final double? min;
  final double? max;
}

class VitalInputResult {
  const VitalInputResult.ok(VitalReading this.reading) : issue = null;
  const VitalInputResult.issue(VitalInputIssue this.issue) : reading = null;

  final VitalReading? reading;
  final VitalInputIssue? issue;

  bool get isOk => reading != null;
}

class VitalInput {
  VitalInput._();

  /// Parses and validates the typed values in canonical units.
  /// [secondaryText] and [pulseText] only matter for blood pressure; an empty
  /// pulse simply means "no pulse".
  static VitalInputResult parse({
    required VitalKind kind,
    required String primaryText,
    String secondaryText = '',
    String pulseText = '',
    required DateTime measuredAt,
    DateTime? now,
  }) {
    final primary = _number(primaryText);
    if (primary.isEmpty) {
      return _issue(VitalField.primary, VitalInputProblem.empty);
    }
    final value = primary.value;
    if (value == null) {
      return _issue(VitalField.primary, VitalInputProblem.notANumber);
    }

    double? value2;
    double? pulse;

    if (kind == VitalKind.bloodPressure) {
      final second = _number(secondaryText);
      if (second.isEmpty) {
        return _issue(VitalField.secondary, VitalInputProblem.diastolicMissing);
      }
      value2 = second.value;
      if (value2 == null) {
        return _issue(VitalField.secondary, VitalInputProblem.notANumber);
      }

      final p = _number(pulseText);
      if (!p.isEmpty) {
        pulse = p.value;
        if (pulse == null) {
          return _issue(VitalField.pulse, VitalInputProblem.notANumber);
        }
      }
    }

    final check = VitalValidator.validate(
      kind,
      value,
      value2: value2,
      pulse: pulse,
      measuredAt: measuredAt,
      now: now,
    );

    if (check.isValid) {
      return VitalInputResult.ok(
        VitalReading(
          kind: kind,
          value: value,
          value2: value2,
          pulse: pulse,
          measuredAt: measuredAt,
        ),
      );
    }

    switch (check.error!) {
      case VitalError.outOfRange:
        return _issue(
          VitalField.primary,
          VitalInputProblem.range,
          min: check.min,
          max: check.max,
        );
      case VitalError.diastolicMissing:
        return _issue(VitalField.secondary, VitalInputProblem.diastolicMissing);
      case VitalError.diastolicOutOfRange:
        return _issue(
          VitalField.secondary,
          VitalInputProblem.diastolicRange,
          min: check.min,
          max: check.max,
        );
      case VitalError.diastolicNotLower:
        return _issue(
          VitalField.secondary,
          VitalInputProblem.diastolicNotLower,
        );
      case VitalError.pulseOutOfRange:
        return _issue(
          VitalField.pulse,
          VitalInputProblem.pulseRange,
          min: check.min,
          max: check.max,
        );
      case VitalError.timeInFuture:
        return _issue(VitalField.time, VitalInputProblem.timeInFuture);
      case VitalError.notANumber:
      case VitalError.unexpectedSecondValue:
        return _issue(VitalField.primary, VitalInputProblem.notANumber);
    }
  }

  /// Shows a number without a useless trailing ".0" (120.0 -> "120").
  static String formatNumber(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toString();
  }

  static VitalInputResult _issue(
    VitalField field,
    VitalInputProblem problem, {
    double? min,
    double? max,
  }) => VitalInputResult.issue(
    VitalInputIssue(field, problem, min: min, max: max),
  );

  /// Accepts "72", " 72.4 " and "72,4" (decimal comma).
  static ({bool isEmpty, double? value}) _number(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return (isEmpty: true, value: null);
    return (isEmpty: false, value: double.tryParse(t));
  }
}
