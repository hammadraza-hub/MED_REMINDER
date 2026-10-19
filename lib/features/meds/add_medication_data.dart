import '../../l10n/app_localizations.dart';

/// ============================================================
/// ADD MEDICATION DATA — backend-ready
///
/// Abhi: local medicine "database" (dummy)
/// Backend: FDA/openFDA API ya Firebase medicines collection
///
/// Flow: User search kare → results → Select → details form
/// ============================================================

/// Medicine form — stored id, display hamesha localized.
enum MedSearchForm { tablet, extendedRelease, capsule, drops, injection }

/// Medicine route — stored id, display hamesha localized.
enum MedSearchRoute { oral, subcutaneous }

/// Condition — badge "Common for: X" ke liye.
enum MedSearchCondition {
  diabetes,
  type2Diabetes,
  highBloodPressure,
  hypertension,
  heartHealth,
  highCholesterol,
  bacterialInfection,
  painInflammation,
  boneHealth,
  acidReflux,
}

/// Form label — localized.
String medSearchFormLabel(AppLocalizations l10n, MedSearchForm form) {
  return switch (form) {
    MedSearchForm.tablet => l10n.doseFormTablet,
    MedSearchForm.extendedRelease => l10n.medFormExtendedRelease,
    MedSearchForm.capsule => l10n.medsFormCapsule,
    MedSearchForm.drops => l10n.medsFormDrops,
    MedSearchForm.injection => l10n.medsFormInjection,
  };
}

/// Route label — localized.
String medSearchRouteLabel(AppLocalizations l10n, MedSearchRoute route) {
  return switch (route) {
    MedSearchRoute.oral => l10n.medRouteOral,
    MedSearchRoute.subcutaneous => l10n.medRouteSubcutaneous,
  };
}

/// Condition label — localized.
String medSearchConditionLabel(
  AppLocalizations l10n,
  MedSearchCondition condition,
) {
  return switch (condition) {
    MedSearchCondition.diabetes => l10n.medConditionDiabetes,
    MedSearchCondition.type2Diabetes => l10n.medConditionType2Diabetes,
    MedSearchCondition.highBloodPressure => l10n.medConditionHighBloodPressure,
    MedSearchCondition.hypertension => l10n.medConditionHypertension,
    MedSearchCondition.heartHealth => l10n.medConditionHeartHealth,
    MedSearchCondition.highCholesterol => l10n.medConditionHighCholesterol,
    MedSearchCondition.bacterialInfection =>
      l10n.medConditionBacterialInfection,
    MedSearchCondition.painInflammation => l10n.medConditionPainInflammation,
    MedSearchCondition.boneHealth => l10n.medConditionBoneHealth,
    MedSearchCondition.acidReflux => l10n.medConditionAcidReflux,
  };
}

/// Search result — database ki medicine
class MedSearchResult {
  const MedSearchResult({
    required this.name,
    required this.strength,
    required this.form,
    required this.route,
    required this.commonFor,
    this.isDailyDose = false,
  });

  final String name; // "Metformin"
  final String strength; // "500mg"
  final MedSearchForm form;
  final MedSearchRoute route;
  final MedSearchCondition commonFor;
  final bool isDailyDose;

  /// Backend: MedSearchResult.fromFdaJson(json)
}

class AddMedicationData {
  /// ============================================================
  /// DUMMY DATABASE — common medicines
  /// Backend: FDA database API se search
  ///
  /// Abhi humari list chhoti hai — search "smart" hai:
  /// naam se match + related variants bhi dikhata hai
  /// ============================================================
  static const List<MedSearchResult> _database = [
    MedSearchResult(
      name: 'Metformin',
      strength: '500mg',
      form: MedSearchForm.tablet,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.diabetes,
    ),
    MedSearchResult(
      name: 'Metformin HCl',
      strength: '1000mg',
      form: MedSearchForm.extendedRelease,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.type2Diabetes,
    ),
    MedSearchResult(
      name: 'Metformin ER',
      strength: '750mg',
      form: MedSearchForm.tablet,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.diabetes,
      isDailyDose: true,
    ),
    MedSearchResult(
      name: 'Amlodipine',
      strength: '5mg',
      form: MedSearchForm.tablet,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.highBloodPressure,
    ),
    MedSearchResult(
      name: 'Lisinopril',
      strength: '10mg',
      form: MedSearchForm.tablet,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.hypertension,
    ),
    MedSearchResult(
      name: 'Aspirin',
      strength: '81mg',
      form: MedSearchForm.tablet,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.heartHealth,
    ),
    MedSearchResult(
      name: 'Atorvastatin',
      strength: '20mg',
      form: MedSearchForm.tablet,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.highCholesterol,
    ),
    MedSearchResult(
      name: 'Amoxicillin',
      strength: '250mg',
      form: MedSearchForm.capsule,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.bacterialInfection,
    ),
    MedSearchResult(
      name: 'Ibuprofen',
      strength: '200mg',
      form: MedSearchForm.tablet,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.painInflammation,
    ),
    MedSearchResult(
      name: 'Vitamin D3',
      strength: '1000 IU',
      form: MedSearchForm.drops,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.boneHealth,
    ),
    MedSearchResult(
      name: 'Insulin Glargine',
      strength: '100 units/mL',
      form: MedSearchForm.injection,
      route: MedSearchRoute.subcutaneous,
      commonFor: MedSearchCondition.diabetes,
    ),
    MedSearchResult(
      name: 'Omeprazole',
      strength: '20mg',
      form: MedSearchForm.capsule,
      route: MedSearchRoute.oral,
      commonFor: MedSearchCondition.acidReflux,
    ),
  ];

  /// ============================================================
  /// SEARCH — query se matching medicines
  /// Backend: FDA API call (openFDA)
  ///
  /// Smart matching: naam se start ho YA naam mein kahin ho
  /// ============================================================
  static List<MedSearchResult> search(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) return [];

    return _database
        .where((med) => med.name.toLowerCase().contains(q))
        .toList();
  }

  /// Badge text — "Common for: X" ya "Daily Dose" (localized).
  static String badgeFor(AppLocalizations l10n, MedSearchResult med) {
    if (med.isDailyDose) return l10n.addMedDailyDose;
    return l10n.addMedCommonFor(
      medSearchConditionLabel(l10n, med.commonFor),
    );
  }
}
