import '../../models/dose.dart';
import '../vitals/symptom_entry.dart';
import '../vitals/vital_models.dart';
import '../vitals/vital_summary.dart';
import '../vitals/vital_types.dart';
import 'adherence_calculator.dart';
import 'dose_report_mapper.dart';
import 'report_models.dart';
import 'report_options.dart';
import 'report_range.dart';

/// The report would be too big to build safely (safety limit, never a silent
/// cut: a cut report would show wrong numbers).
class ReportTooLargeException implements Exception {
  ReportTooLargeException(this.doseCount);

  final int doseCount;

  @override
  String toString() => 'ReportTooLargeException($doseCount doses)';
}

/// ============================================================
/// REPORT DATA SOURCE — M17 step 2
///
/// Reads what a report needs and turns it into [ReportData]. Spark has no
/// server call (`reportData` would be a Blaze Cloud Function), so the phone
/// reads the data itself. Every Firestore read is injected as a function, so
/// this class has no Firebase of its own and is unit-testable; the real wiring
/// lives in lib/repositories/report_data_wiring.dart.
///
/// * Adherence is required: if it cannot be read the whole load fails.
/// * Vitals and side effects are loaded on their own: if one cannot be read
///   (no health access, offline) it is listed in `unavailable` and the rest of
///   the report is still produced.
/// * Vitals follow the M15 chart rule: up to 90 days from the raw readings,
///   longer ranges from the per-day documents (so a year never reads
///   thousands of documents).
/// ============================================================
class ReportDataSource {
  ReportDataSource({
    required this.fetchDoses,
    required this.fetchMedicationStrengths,
    required this.fetchVitalReadings,
    required this.fetchVitalDaily,
    required this.fetchSymptoms,
  });

  /// Doses scheduled inside the range (the same query the Adherence Detail
  /// screen uses).
  final Future<List<Dose>> Function(ReportRange range) fetchDoses;

  /// medicationId -> strength (may be empty / null).
  final Future<Map<String, String?>> Function() fetchMedicationStrengths;

  /// Raw readings of one kind, newest first, at most [vitalRawLimit], from
  /// [since] on.
  final Future<List<VitalReading>> Function(VitalKind kind, DateTime since)
  fetchVitalReadings;

  /// Per-day summary documents of one kind between two days.
  final Future<List<VitalDaily>> Function(
    VitalKind kind,
    DateTime from,
    DateTime to,
  )
  fetchVitalDaily;

  /// Side effects from [since] on, newest first, at most [symptomLimit].
  final Future<List<SymptomEntry>> Function(DateTime since) fetchSymptoms;

  /// Ranges up to this many days use raw vital readings.
  static const int rawVitalsMaxDays = 90;

  /// Raw readings read per kind (same as the M15 chart).
  static const int vitalRawLimit = 500;

  /// Side effects read per report.
  static const int symptomLimit = 200;

  /// Safety limit on doses; above it the load refuses instead of cutting.
  static const int maxDoses = 15000;

  Future<ReportData> load({
    required ReportRange range,
    required ReportOptions options,
    String? profileName,
    DateTime? now,
  }) async {
    final generatedAt = now ?? DateTime.now();

    AdherenceBreakdown? adherence;
    var doseCount = 0;
    var medCount = 0;

    if (options.adherence) {
      final doses = await fetchDoses(range);
      if (doses.length > maxDoses) {
        throw ReportTooLargeException(doses.length);
      }
      doseCount = doses.length;

      // The strength is only a label; a failure here must not fail the report.
      Map<String, String?> strengths;
      try {
        strengths = await fetchMedicationStrengths();
      } catch (_) {
        strengths = const {};
      }
      medCount = strengths.length;

      adherence = AdherenceCalculator.summarize([
        for (final d in doses)
          DoseReportMapper.fromDose(
            d,
            now: generatedAt,
            strength: strengths[d.medicationId],
          ),
      ], range);
    }

    final unavailable = <ReportSection>{};
    final truncated = <ReportSection>{};

    Map<VitalKind, List<VitalDaily>>? vitals;
    var vitalsRead = 0;
    if (options.vitals) {
      try {
        final result = await _loadVitals(range);
        vitals = result.data;
        vitalsRead = result.read;
        if (result.truncated) truncated.add(ReportSection.vitals);
      } catch (_) {
        unavailable.add(ReportSection.vitals);
      }
    }

    List<SymptomEntry>? symptoms;
    var symptomsRead = 0;
    if (options.sideEffects) {
      try {
        final fetched = await fetchSymptoms(range.from);
        symptomsRead = fetched.length;
        symptoms = [
          for (final s in fetched)
            if (range.contains(s.occurredAt)) s,
        ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        if (fetched.length >= symptomLimit) {
          truncated.add(ReportSection.sideEffects);
        }
      } catch (_) {
        unavailable.add(ReportSection.sideEffects);
      }
    }

    return ReportData(
      range: range,
      generatedAt: generatedAt,
      options: options,
      profileName: profileName,
      adherence: adherence,
      vitals: vitals,
      symptoms: symptoms,
      unavailable: unavailable,
      truncated: truncated,
      stats: ReportLoadStats(
        doses: doseCount,
        medications: medCount,
        vitals: vitalsRead,
        symptoms: symptomsRead,
      ),
    );
  }

  Future<({Map<VitalKind, List<VitalDaily>> data, int read, bool truncated})>
  _loadVitals(ReportRange range) async {
    final data = <VitalKind, List<VitalDaily>>{};
    var read = 0;
    var truncated = false;
    final useRaw = range.dayCount <= rawVitalsMaxDays;

    for (final kind in VitalKind.values) {
      if (useRaw) {
        final readings = await fetchVitalReadings(kind, range.from);
        read += readings.length;
        if (readings.length >= vitalRawLimit) truncated = true;
        data[kind] = VitalAnalysis.dailySummaries([
          for (final r in readings)
            if (range.contains(r.measuredAt)) r.toPoint(),
        ]);
      } else {
        final days = await fetchVitalDaily(kind, range.from, range.to);
        read += days.length;
        data[kind] = [
          for (final d in days)
            if (_dayInRange(d.dayKey, range)) d,
        ]..sort((a, b) => a.dayKey.compareTo(b.dayKey));
      }
    }
    return (data: data, read: read, truncated: truncated);
  }

  static bool _dayInRange(String dayKey, ReportRange range) {
    final b = VitalAnalysis.dayBounds(dayKey);
    return b != null && range.contains(b.start);
  }
}
