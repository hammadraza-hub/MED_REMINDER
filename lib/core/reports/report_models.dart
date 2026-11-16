import '../vitals/symptom_entry.dart';
import '../vitals/vital_summary.dart';
import '../vitals/vital_types.dart';
import 'report_options.dart';
import 'report_range.dart';

/// Outcome of one scheduled dose, as the report counts it. M17 step 1.
/// `pending` also covers snoozed doses (not yet decided).
enum ReportDoseStatus { taken, missed, skipped, pending }

/// Why a dose was missed or skipped.
enum ReportMissReason { forgot, sideEffect, ranOut, other, unspecified }

/// One dose in plain Dart (no Firebase types). The data source converts the
/// app's `Dose` into this in step 2.
class ReportDose {
  const ReportDose({
    required this.id,
    required this.medicationId,
    required this.medName,
    required this.scheduledAt,
    required this.status,
    this.strength,
    this.reason = ReportMissReason.unspecified,
  });

  /// Dose document id (used to ignore a dose that arrives twice).
  final String id;
  final String medicationId;
  final String medName;

  /// Shown after the name, e.g. "500mg". May be empty.
  final String? strength;
  final DateTime scheduledAt;
  final ReportDoseStatus status;
  final ReportMissReason reason;
}

/// taken / missed / skipped / pending counts and the adherence percentage.
///
/// The percentage is the same one the Adherence Detail screen uses:
/// taken / (taken + missed + skipped), rounded; 0 when nothing was decided.
/// Pending doses are not part of it (they have not happened yet).
class AdherenceCounts {
  const AdherenceCounts({
    this.taken = 0,
    this.missed = 0,
    this.skipped = 0,
    this.pending = 0,
  });

  final int taken;
  final int missed;
  final int skipped;
  final int pending;

  /// Doses with an outcome.
  int get decided => taken + missed + skipped;

  /// Every dose that was scheduled in the range.
  int get scheduled => decided + pending;

  int get percent => decided == 0 ? 0 : ((taken / decided) * 100).round();

  /// 0.0 to 1.0 (progress bars).
  double get progress => decided == 0 ? 0 : (taken / decided).clamp(0.0, 1.0);

  bool get hasData => scheduled > 0;

  AdherenceCounts plus(ReportDoseStatus s) => AdherenceCounts(
    taken: taken + (s == ReportDoseStatus.taken ? 1 : 0),
    missed: missed + (s == ReportDoseStatus.missed ? 1 : 0),
    skipped: skipped + (s == ReportDoseStatus.skipped ? 1 : 0),
    pending: pending + (s == ReportDoseStatus.pending ? 1 : 0),
  );

  @override
  bool operator ==(Object other) =>
      other is AdherenceCounts &&
      other.taken == taken &&
      other.missed == missed &&
      other.skipped == skipped &&
      other.pending == pending;

  @override
  int get hashCode => Object.hash(taken, missed, skipped, pending);
}

class MedicationAdherence {
  const MedicationAdherence({
    required this.medicationId,
    required this.name,
    required this.counts,
    this.strength,
  });

  final String medicationId;
  final String name;
  final String? strength;
  final AdherenceCounts counts;

  /// "Metformin 500mg", or just the name.
  String get displayName {
    final s = strength?.trim() ?? '';
    return s.isEmpty ? name : '$name $s';
  }
}

class DailyAdherence {
  const DailyAdherence({required this.day, required this.counts});

  /// Local calendar day (00:00).
  final DateTime day;
  final AdherenceCounts counts;

  String get dayKey => ReportRange.dayKey(day);
}

class ReasonCount {
  const ReasonCount(this.reason, this.count);

  final ReportMissReason reason;
  final int count;
}

class AdherenceBreakdown {
  const AdherenceBreakdown({
    required this.total,
    required this.perMedication,
    required this.perDay,
    required this.reasons,
  });

  /// Everything in the range.
  final AdherenceCounts total;

  /// Best adherence first (the order of the Adherence Detail screen).
  final List<MedicationAdherence> perMedication;

  /// One entry for EVERY day of the range, oldest first (days without doses
  /// have empty counts).
  final List<DailyAdherence> perDay;

  /// Missed + skipped doses by reason, largest first; reasons with 0 left out.
  final List<ReasonCount> reasons;
}

/// How many documents a report read (for the Spark read budget and for a
/// "this may take a moment" hint).
class ReportLoadStats {
  const ReportLoadStats({
    this.doses = 0,
    this.medications = 0,
    this.vitals = 0,
    this.symptoms = 0,
  });

  final int doses;
  final int medications;
  final int vitals;
  final int symptoms;

  int get total => doses + medications + vitals + symptoms;
}

/// Everything a report shows. The sections that were not asked for are null.
class ReportData {
  const ReportData({
    required this.range,
    required this.generatedAt,
    required this.options,
    this.profileName,
    this.adherence,
    this.vitals,
    this.symptoms,
    this.unavailable = const {},
    this.truncated = const {},
    this.stats = const ReportLoadStats(),
  });

  final ReportRange range;
  final DateTime generatedAt;
  final ReportOptions options;
  final String? profileName;
  final AdherenceBreakdown? adherence;

  /// Per-day summaries by vital kind (M15 `VitalAnalysis.dailySummaries`).
  final Map<VitalKind, List<VitalDaily>>? vitals;

  /// Side effects inside the range, newest first.
  final List<SymptomEntry>? symptoms;

  /// Sections that were asked for but could not be loaded (no health access,
  /// or the read failed). Their data is null; the report says so.
  final Set<ReportSection> unavailable;

  /// Sections that hit a safety limit, so older entries may be missing.
  final Set<ReportSection> truncated;

  final ReportLoadStats stats;

  /// True when the report has nothing to show at all.
  bool get isEmpty {
    final a = adherence;
    final v = vitals;
    final s = symptoms;
    return (a == null || !a.total.hasData) &&
        (v == null || v.values.every((l) => l.isEmpty)) &&
        (s == null || s.isEmpty);
  }
}
