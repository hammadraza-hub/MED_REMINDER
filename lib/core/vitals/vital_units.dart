import 'vital_types.dart';

/// ============================================================
/// VITAL UNITS & IDS — M15 step 1
///
/// Pure helpers. Firestore keeps canonical units; these convert for display
/// and back, and build deterministic document ids for synced readings.
/// ============================================================
enum GlucoseUnit { mgPerDl, mmolPerL }

enum WeightUnit { kg, lb }

class VitalUnits {
  VitalUnits._();

  /// 1 mmol/L of glucose = 18.0156 mg/dL.
  static const double _mgPerDlPerMmol = 18.0156;

  /// 1 kg = 2.2046226218 lb.
  static const double _lbPerKg = 2.2046226218;

  // ---- glucose ----

  /// Canonical mg/dL -> value shown in [unit], rounded for display.
  static double glucoseToDisplay(double mgPerDl, GlucoseUnit unit) {
    switch (unit) {
      case GlucoseUnit.mgPerDl:
        return _round(mgPerDl, 0);
      case GlucoseUnit.mmolPerL:
        return _round(mgPerDl / _mgPerDlPerMmol, 1);
    }
  }

  /// Value typed in [unit] -> canonical mg/dL (1 decimal).
  static double glucoseToCanonical(double value, GlucoseUnit unit) {
    switch (unit) {
      case GlucoseUnit.mgPerDl:
        return _round(value, 1);
      case GlucoseUnit.mmolPerL:
        return _round(value * _mgPerDlPerMmol, 1);
    }
  }

  // ---- weight ----

  static double weightToDisplay(double kg, WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return _round(kg, 1);
      case WeightUnit.lb:
        return _round(kg * _lbPerKg, 1);
    }
  }

  static double weightToCanonical(double value, WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return _round(value, 2);
      case WeightUnit.lb:
        return _round(value / _lbPerKg, 2);
    }
  }

  static String glucoseUnitLabel(GlucoseUnit unit) =>
      unit == GlucoseUnit.mgPerDl ? 'mg/dL' : 'mmol/L';

  static String weightUnitLabel(WeightUnit unit) =>
      unit == WeightUnit.kg ? 'kg' : 'lb';

  // ---- document ids ----

  /// Document id for a synced reading: `{source}_{externalId}`.
  ///
  /// Deterministic, so syncing the same reading again overwrites the same
  /// document instead of creating a duplicate. The external id is escaped so
  /// that it is a valid Firestore id and two different external ids can never
  /// produce the same document id (`~` is the escape character).
  ///
  /// Returns null for manual readings: they get a random id from Firestore.
  static String? documentId(VitalSource source, String? externalId) {
    if (!source.isSync) return null;
    final raw = externalId?.trim() ?? '';
    if (raw.isEmpty) {
      throw ArgumentError('externalId is required for ${source.wireName}');
    }
    return '${source.wireName}_${_escape(raw)}';
  }

  static final RegExp _safe = RegExp(r'[A-Za-z0-9_-]');

  /// Keeps letters, digits, `_` and `-`; every other character becomes
  /// `~<hex code unit>;` (for example `/` -> `~2f;`). `~` itself is escaped
  /// too, so the mapping is one-to-one.
  static String _escape(String raw) {
    final b = StringBuffer();
    for (final unit in raw.codeUnits) {
      final c = String.fromCharCode(unit);
      if (_safe.hasMatch(c)) {
        b.write(c);
      } else {
        b.write('~${unit.toRadixString(16)};');
      }
    }
    return b.toString();
  }

  static double _round(double v, int decimals) {
    final f = _pow10(decimals);
    return (v * f).roundToDouble() / f;
  }

  static double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
