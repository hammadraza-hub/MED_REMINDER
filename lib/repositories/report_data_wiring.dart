import '../core/reports/report_data_source.dart';
import 'dose_repository.dart';
import 'firebase_symptom_repository.dart';
import 'firebase_vitals_repository.dart';
import 'medication_repository.dart';

/// The real wiring of [ReportDataSource] for one profile (M17 step 2): the same
/// repositories and queries the app screens use, so the report numbers match.
ReportDataSource buildReportDataSource(String memberId) {
  return ReportDataSource(
    fetchDoses: (range) => DoseRepository.instance.getDosesForDateRange(
      memberId,
      range.from,
      range.to,
    ),
    fetchMedicationStrengths: () async {
      final meds = await MedicationRepository.instance
          .watchAllMedications(memberId)
          .first;
      return {for (final m in meds) m.id: m.strength};
    },
    fetchVitalReadings: (kind, since) => FirebaseVitalsRepository.instance.list(
      memberId,
      kind,
      since: since,
      limit: ReportDataSource.vitalRawLimit,
    ),
    fetchVitalDaily: (kind, from, to) => FirebaseVitalsRepository.instance
        .dailySummaries(memberId, kind, from: from, to: to),
    fetchSymptoms: (since) => FirebaseSymptomRepository.instance.list(
      memberId,
      since: since,
      limit: ReportDataSource.symptomLimit,
    ),
  );
}
