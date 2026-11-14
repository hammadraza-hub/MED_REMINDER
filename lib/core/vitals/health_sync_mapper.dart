import 'vital_models.dart';
import 'vital_types.dart';

/// ============================================================
/// HEALTH SYNC MAPPER — M15 step 7
///
/// Pure logic (no plugin imports) that turns raw samples read from Apple
/// Health / Health Connect into [VitalReading]s ready for
/// `FirebaseVitalsRepository.importSynced`.
///
/// Samples must already be in canonical units (mmHg, mg/dL, kg, bpm); the
/// plugin adapter asks the platform for exactly these.
///
/// Rules:
///  - blood pressure arrives as two separate samples (systolic, diastolic);
///    they are paired when taken at (almost) the same time, unpaired ones are
///    dropped and counted;
///  - heart rate is sampled every few minutes by watches (thousands a day), so
///    it is reduced to one average per hour — this keeps Firestore writes
///    (Spark plan: 20,000 a day) and chart size sensible;
///  - glucose and weight are kept one-to-one;
///  - every reading gets a stable `externalId`, so syncing the same data again
///    produces the same document ids (no duplicates);
///  - the newest [maxReadings] are kept.
/// ============================================================
enum HealthSampleKind { systolic, diastolic, glucose, weight, heartRate }

/// One sample as read from the platform.
class RawHealthSample {
  const RawHealthSample({
    required this.kind,
    required this.value,
    required this.from,
    this.uuid,
  });

  final HealthSampleKind kind;
  final double value;

  /// Start of the measurement (the time a reading is attributed to).
  final DateTime from;

  /// Platform id of the sample, when the platform provides one.
  final String? uuid;
}

class HealthMapResult {
  const HealthMapResult({
    required this.readings,
    required this.unpairedBloodPressure,
    required this.truncated,
  });

  /// Newest first.
  final List<VitalReading> readings;

  /// Systolic or diastolic samples that had no partner.
  final int unpairedBloodPressure;

  /// True when more than the limit was available and the oldest were dropped.
  final bool truncated;
}

class HealthSyncMapper {
  HealthSyncMapper._();

  /// Two BP samples closer than this belong to the same measurement.
  static const Duration pairTolerance = Duration(minutes: 2);

  /// Default cap per sync (the newest readings are kept).
  static const int defaultMaxReadings = 1500;

  static HealthMapResult map(
    Iterable<RawHealthSample> samples,
    VitalSource source, {
    int maxReadings = defaultMaxReadings,
  }) {
    assert(source.isSync, 'health sync needs a sync source');

    final systolic = <RawHealthSample>[];
    final diastolic = <RawHealthSample>[];
    final out = <VitalReading>[];
    final heartRate = <RawHealthSample>[];

    for (final s in samples) {
      if (s.value.isNaN || s.value.isInfinite) continue;
      switch (s.kind) {
        case HealthSampleKind.systolic:
          systolic.add(s);
        case HealthSampleKind.diastolic:
          diastolic.add(s);
        case HealthSampleKind.glucose:
          out.add(_single(VitalKind.glucose, s, source, decimals: 1));
        case HealthSampleKind.weight:
          out.add(_single(VitalKind.weight, s, source, decimals: 2));
        case HealthSampleKind.heartRate:
          heartRate.add(s);
      }
    }

    final unpaired = _pairBloodPressure(systolic, diastolic, source, out);
    out.addAll(_hourlyHeartRate(heartRate, source));

    out.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final truncated = out.length > maxReadings;

    return HealthMapResult(
      readings: truncated ? out.sublist(0, maxReadings) : out,
      unpairedBloodPressure: unpaired,
      truncated: truncated,
    );
  }

  // ---- single value kinds ----

  static VitalReading _single(
    VitalKind kind,
    RawHealthSample s,
    VitalSource source, {
    required int decimals,
  }) {
    final v = _round(s.value, decimals);
    return VitalReading(
      kind: kind,
      value: v,
      measuredAt: s.from,
      source: source,
      externalId: _idFor(kind.wireName, s, v),
    );
  }

  /// The platform uuid when there is one, otherwise a stable id built from the
  /// data itself (type, start time, value).
  static String _idFor(String prefix, RawHealthSample s, double value) {
    final uuid = s.uuid?.trim();
    if (uuid != null && uuid.isNotEmpty) return uuid;
    return '$prefix-${s.from.toUtc().millisecondsSinceEpoch}-$value';
  }

  // ---- blood pressure ----

  /// Pairs each systolic with the closest unused diastolic within
  /// [pairTolerance]. Returns how many samples stayed unpaired.
  static int _pairBloodPressure(
    List<RawHealthSample> systolic,
    List<RawHealthSample> diastolic,
    VitalSource source,
    List<VitalReading> out,
  ) {
    systolic.sort((a, b) => a.from.compareTo(b.from));
    final free = [...diastolic]..sort((a, b) => a.from.compareTo(b.from));

    var unpairedSystolic = 0;
    for (final sys in systolic) {
      RawHealthSample? best;
      Duration? bestGap;
      for (final dia in free) {
        final gap = dia.from.difference(sys.from).abs();
        if (gap <= pairTolerance && (bestGap == null || gap < bestGap)) {
          best = dia;
          bestGap = gap;
        }
      }

      if (best == null) {
        unpairedSystolic++;
        continue;
      }
      free.remove(best);

      final sysValue = _round(sys.value, 0);
      final diaValue = _round(best.value, 0);
      out.add(
        VitalReading(
          kind: VitalKind.bloodPressure,
          value: sysValue,
          value2: diaValue,
          measuredAt: sys.from,
          source: source,
          externalId: _bpId(sys, best, sysValue, diaValue),
        ),
      );
    }
    return unpairedSystolic + free.length;
  }

  static String _bpId(
    RawHealthSample sys,
    RawHealthSample dia,
    double sysValue,
    double diaValue,
  ) {
    final a = sys.uuid?.trim();
    final b = dia.uuid?.trim();
    if (a != null && a.isNotEmpty && b != null && b.isNotEmpty) {
      return '$a+$b';
    }
    return 'bp-${sys.from.toUtc().millisecondsSinceEpoch}-$sysValue-$diaValue';
  }

  // ---- heart rate ----

  /// One average reading per UTC hour. The id is the hour's start, so a later
  /// sync that sees more samples of an already imported hour does not create a
  /// second reading (the existing one is kept).
  static List<VitalReading> _hourlyHeartRate(
    List<RawHealthSample> samples,
    VitalSource source,
  ) {
    final buckets = <int, List<double>>{};
    for (final s in samples) {
      final utc = s.from.toUtc();
      final hourStart = DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
      buckets
          .putIfAbsent(hourStart.millisecondsSinceEpoch, () => [])
          .add(s.value);
    }

    return [
      for (final e in buckets.entries)
        VitalReading(
          kind: VitalKind.heartRate,
          value: _round(e.value.reduce((a, b) => a + b) / e.value.length, 0),
          measuredAt: DateTime.fromMillisecondsSinceEpoch(e.key, isUtc: true),
          source: source,
          externalId: 'hr-${e.key}',
        ),
    ];
  }

  static double _round(double v, int decimals) {
    var f = 1.0;
    for (var i = 0; i < decimals; i++) {
      f *= 10;
    }
    return (v * f).roundToDouble() / f;
  }
}
