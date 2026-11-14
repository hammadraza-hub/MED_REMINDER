import 'vital_types.dart';

/// ============================================================
/// VITAL VALIDATOR — M15 step 1
///
/// Pure range / shape checks for a reading in CANONICAL units. The same limits
/// go into the Firestore rules (step 2), so the app and the server agree.
///
/// Returns an error CODE (not text) so the UI can localise the message and
/// show the limits ([VitalValidation.min] / [VitalValidation.max]).
/// ============================================================
enum VitalError {
  /// value is NaN / infinite.
  notANumber,

  /// primary value outside the allowed range.
  outOfRange,

  /// blood pressure needs a diastolic value.
  diastolicMissing,

  /// diastolic outside the allowed range.
  diastolicOutOfRange,

  /// diastolic must be lower than systolic.
  diastolicNotLower,

  /// pulse (optional, with BP) outside the allowed range.
  pulseOutOfRange,

  /// a second value was given for a kind that has none.
  unexpectedSecondValue,

  /// measured time is in the future.
  timeInFuture,
}

class VitalValidation {
  const VitalValidation.ok() : error = null, min = null, max = null;

  const VitalValidation.error(this.error, {this.min, this.max});

  final VitalError? error;

  /// The limits that were violated (for the message), when there are any.
  final double? min;
  final double? max;

  bool get isValid => error == null;
}

class VitalRange {
  const VitalRange(this.min, this.max);

  final double min;
  final double max;

  bool contains(double v) => v >= min && v <= max;
}

class VitalValidator {
  VitalValidator._();

  /// Allowed values in canonical units. Keep in sync with firestore.rules.
  static const VitalRange systolic = VitalRange(40, 300);
  static const VitalRange diastolic = VitalRange(20, 200);
  static const VitalRange glucose = VitalRange(10, 1000);
  static const VitalRange weight = VitalRange(1, 700);
  static const VitalRange heartRate = VitalRange(20, 300);
  static const VitalRange pulse = VitalRange(20, 300);

  /// A reading may be at most this far ahead of "now" (clock differences).
  static const Duration futureTolerance = Duration(minutes: 10);

  /// Validates one reading in canonical units.
  ///
  /// [value] is systolic for blood pressure; [value2] is the diastolic;
  /// [pulse] is the optional pulse that may accompany a BP reading.
  static VitalValidation validate(
    VitalKind kind,
    double value, {
    double? value2,
    double? pulse,
    DateTime? measuredAt,
    DateTime? now,
  }) {
    if (!_finite(value) || (value2 != null && !_finite(value2))) {
      return const VitalValidation.error(VitalError.notANumber);
    }
    if (pulse != null && !_finite(pulse)) {
      return const VitalValidation.error(VitalError.notANumber);
    }

    final range = _primaryRange(kind);
    if (!range.contains(value)) {
      return VitalValidation.error(
        VitalError.outOfRange,
        min: range.min,
        max: range.max,
      );
    }

    if (kind == VitalKind.bloodPressure) {
      if (value2 == null) {
        return const VitalValidation.error(VitalError.diastolicMissing);
      }
      if (!diastolic.contains(value2)) {
        return VitalValidation.error(
          VitalError.diastolicOutOfRange,
          min: diastolic.min,
          max: diastolic.max,
        );
      }
      if (value2 >= value) {
        return const VitalValidation.error(VitalError.diastolicNotLower);
      }
      if (pulse != null && !VitalValidator.pulse.contains(pulse)) {
        return VitalValidation.error(
          VitalError.pulseOutOfRange,
          min: VitalValidator.pulse.min,
          max: VitalValidator.pulse.max,
        );
      }
    } else if (value2 != null || pulse != null) {
      return const VitalValidation.error(VitalError.unexpectedSecondValue);
    }

    if (measuredAt != null) {
      final limit = (now ?? DateTime.now()).add(futureTolerance);
      if (measuredAt.isAfter(limit)) {
        return const VitalValidation.error(VitalError.timeInFuture);
      }
    }

    return const VitalValidation.ok();
  }

  static VitalRange _primaryRange(VitalKind kind) {
    switch (kind) {
      case VitalKind.bloodPressure:
        return systolic;
      case VitalKind.glucose:
        return glucose;
      case VitalKind.weight:
        return weight;
      case VitalKind.heartRate:
        return heartRate;
    }
  }

  static bool _finite(double v) => !v.isNaN && !v.isInfinite;
}
