/// ============================================================
/// VITAL TYPES — M15 step 1
///
/// Pure definitions (no Firebase / Flutter imports) shared by the validator,
/// unit conversion, summaries and later the repositories and rules.
///
/// Named `VitalKind` on purpose: the older UI-only screens already define
/// their own `VitalType` enums.
///
/// Firestore stores canonical units only (mmHg, mg/dL, kg, bpm); anything else
/// is converted for display (see vital_units.dart).
/// ============================================================
enum VitalKind {
  bloodPressure('bloodPressure', 'mmHg'),
  glucose('glucose', 'mg/dL'),
  weight('weight', 'kg'),
  heartRate('heartRate', 'bpm');

  const VitalKind(this.wireName, this.canonicalUnit);

  /// Value of the `type` field in `profiles/{pid}/vitals/{id}`.
  final String wireName;

  /// The only unit written to Firestore for this kind.
  final String canonicalUnit;

  /// Parses a stored `type`; null for unknown values.
  static VitalKind? fromWire(Object? raw) {
    for (final k in VitalKind.values) {
      if (k.wireName == raw) return k;
    }
    return null;
  }
}

/// Where a reading came from (`source` field).
enum VitalSource {
  manual('manual'),
  healthKit('healthkit'),
  healthConnect('health_connect');

  const VitalSource(this.wireName);

  final String wireName;

  /// Health sync sources carry an `externalId` and use a deterministic
  /// document id so re-syncing never duplicates a reading.
  bool get isSync => this != VitalSource.manual;

  static VitalSource? fromWire(Object? raw) {
    for (final s in VitalSource.values) {
      if (s.wireName == raw) return s;
    }
    return null;
  }
}
