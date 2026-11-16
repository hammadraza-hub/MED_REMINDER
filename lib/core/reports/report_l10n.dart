import '../../l10n/app_localizations.dart';
import 'report_csv_labels.dart';
import 'report_pdf_labels.dart';

/// Fills the report's labels (CSV and PDF) from the app language. M17 step 5.
class ReportL10n {
  ReportL10n._();

  static ReportCsvLabels csv(AppLocalizations l) => ReportCsvLabels(
    title: l.rptLTitle,
    profile: l.rptLProfile,
    dateRange: l.rptLDateRange,
    generatedAt: l.rptLGeneratedAt,
    disclaimerLabel: l.rptLDisclaimerLabel,
    disclaimer: l.rptLDisclaimer,
    adherenceSummary: l.rptLAdherenceSummary,
    adherenceByDay: l.rptLAdherenceByDay,
    adherenceByMedication: l.rptLAdherenceByMedication,
    missedReasons: l.rptLMissedReasons,
    vitals: l.rptLVitals,
    sideEffects: l.rptLSideEffects,
    date: l.rptLDate,
    dateTime: l.rptLDateTime,
    medication: l.rptLMedication,
    taken: l.rptLTaken,
    missed: l.rptLMissed,
    skipped: l.rptLSkipped,
    pending: l.rptLPending,
    adherencePercent: l.rptLAdherencePercent,
    reason: l.rptLReason,
    count: l.rptLCount,
    type: l.rptLType,
    readings: l.rptLReadings,
    average: l.rptLAverage,
    min: l.rptLMin,
    max: l.rptLMax,
    unit: l.rptLUnit,
    symptom: l.rptLSymptom,
    severity: l.rptLSeverity,
    notes: l.rptLNotes,
    reasonForgot: l.rptLReasonForgot,
    reasonSideEffect: l.rptLReasonSideEffect,
    reasonRanOut: l.rptLReasonRanOut,
    reasonOther: l.rptLReasonOther,
    reasonUnspecified: l.rptLReasonUnspecified,
    vitalBloodPressure: l.rptLVitalBloodPressure,
    vitalGlucose: l.rptLVitalGlucose,
    vitalWeight: l.rptLVitalWeight,
    vitalHeartRate: l.rptLVitalHeartRate,
    noData: l.rptLNoData,
    notAvailable: l.rptLNotAvailable,
    truncatedNote: l.rptLTruncated,
  );

  static ReportPdfLabels pdf(AppLocalizations l) => ReportPdfLabels(
    subtitle: l.rptLSubtitle,
    overallAdherence: l.rptLOverallAdherence,
    decidedDoses: l.rptLDecidedDoses,
    dayOverview: l.rptLDayOverview,
    legendAllTaken: l.rptLLegendAllTaken,
    legendMissed: l.rptLLegendMissed,
    legendSkipped: l.rptLLegendSkipped,
    legendPending: l.rptLLegendPending,
    legendNoDoses: l.rptLLegendNoDoses,
    // The page label is a template with {page} / {pages}; the generated
    // function takes numbers, so two markers are swapped back.
    page: l
        .rptLPage(1111111, 2222222)
        .replaceAll('1111111', '{page}')
        .replaceAll('2222222', '{pages}'),
  );
}
