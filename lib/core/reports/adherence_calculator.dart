import 'report_models.dart';
import 'report_range.dart';

/// ============================================================
/// ADHERENCE CALCULATOR — M17 step 1
///
/// The one place the report's adherence numbers come from. Spark has no
/// `dailySummaries` Cloud Function, so the phone works them out from the doses
/// themselves.
///
/// Rules:
/// * A dose belongs to the local calendar day of its `scheduledAt`.
/// * Doses outside the range are ignored; a dose id seen twice counts once.
/// * percent = taken / (taken + missed + skipped), rounded (same as the
///   Adherence Detail screen). Pending / snoozed doses are counted separately.
/// ============================================================
class AdherenceCalculator {
  AdherenceCalculator._();

  static AdherenceBreakdown summarize(
    Iterable<ReportDose> doses,
    ReportRange range,
  ) {
    final seen = <String>{};
    final inRange = <ReportDose>[];
    for (final d in doses) {
      if (!range.contains(d.scheduledAt)) continue;
      if (!seen.add(d.id)) continue;
      inRange.add(d);
    }

    var total = const AdherenceCounts();
    final byMed = <String, _MedAcc>{};
    final byDay = <String, AdherenceCounts>{};
    final reasons = <ReportMissReason, int>{};

    for (final d in inRange) {
      total = total.plus(d.status);

      final med = byMed.putIfAbsent(
        d.medicationId,
        () => _MedAcc(d.medicationId, d.medName, d.strength),
      );
      med.counts = med.counts.plus(d.status);

      final key = ReportRange.dayKey(d.scheduledAt);
      byDay[key] = (byDay[key] ?? const AdherenceCounts()).plus(d.status);

      if (d.status == ReportDoseStatus.missed ||
          d.status == ReportDoseStatus.skipped) {
        reasons[d.reason] = (reasons[d.reason] ?? 0) + 1;
      }
    }

    final perMedication = [
      for (final m in byMed.values)
        MedicationAdherence(
          medicationId: m.id,
          name: m.name,
          strength: m.strength,
          counts: m.counts,
        ),
    ]..sort(_bestFirst);

    final perDay = [
      for (final day in range.days)
        DailyAdherence(
          day: day,
          counts: byDay[ReportRange.dayKey(day)] ?? const AdherenceCounts(),
        ),
    ];

    final reasonList =
        [
          for (final e in reasons.entries)
            if (e.value > 0) ReasonCount(e.key, e.value),
        ]..sort((a, b) {
          final c = b.count.compareTo(a.count);
          return c != 0 ? c : a.reason.index.compareTo(b.reason.index);
        });

    return AdherenceBreakdown(
      total: total,
      perMedication: perMedication,
      perDay: perDay,
      reasons: reasonList,
    );
  }

  /// Highest percent first, then more decided doses, then name.
  static int _bestFirst(MedicationAdherence a, MedicationAdherence b) {
    final p = b.counts.percent.compareTo(a.counts.percent);
    if (p != 0) return p;
    final n = b.counts.decided.compareTo(a.counts.decided);
    if (n != 0) return n;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }
}

class _MedAcc {
  _MedAcc(this.id, this.name, this.strength);

  final String id;
  final String name;
  final String? strength;
  AdherenceCounts counts = const AdherenceCounts();
}
