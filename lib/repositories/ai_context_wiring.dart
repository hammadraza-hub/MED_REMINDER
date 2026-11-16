import '../core/ai/ai_context.dart';
import '../core/reports/dose_report_mapper.dart';
import 'allergy_repository.dart';
import 'dose_repository.dart';
import 'medication_repository.dart';

/// The real wiring of [AiContextBuilder] for one profile (M18 step 2): the
/// same repositories the app screens use, so the assistant sees the same
/// numbers as Adherence Detail and the reports.
AiContextBuilder buildAiContextBuilder(String memberId) {
  return AiContextBuilder(
    fetchMedications: () =>
        MedicationRepository.instance.watchActiveMedications(memberId).first,
    fetchAllergies: () => AllergyRepository.instance.getAllergies(memberId),
    fetchDoses: (range) async {
      final doses = await DoseRepository.instance.getDosesForDateRange(
        memberId,
        range.from,
        range.to,
      );
      final now = DateTime.now();
      return [for (final d in doses) DoseReportMapper.fromDose(d, now: now)];
    },
  );
}
