/// ============================================================
/// INTERACTION WARNING — DATA
///
/// PURPOSE:
/// Add Medication flow ke dauraan milne wale drug interaction
/// ya duplicate-therapy risk ki information.
///
/// KEY ELEMENTS:
/// - Severity (moderate / severe)
/// - Affected medications (named)
/// - Plain-language explanation
/// - "Consult your doctor/pharmacist" disclaimer
///
/// USER ACTIONS:
/// - Acknowledge and proceed
/// - Go back and edit
///
/// TODO Backend:
/// Ye data interaction engine / rule set se build hoga.
/// Abhi [InteractionWarningData.sample] placeholder hai.
/// ============================================================
library;

/// Interaction ki severity level.
enum InteractionSeverity { moderate, severe }

/// User ka decision jab warning dismiss ho.
enum InteractionWarningAction { proceed, goBack }

/// Ek medication jo interaction mein involved hai.
class InteractionMedication {
  const InteractionMedication({
    required this.name,
    required this.strength,
    required this.form,
    this.imageAsset,
  });

  final String name;
  final String strength;
  final String form;

  /// Optional pill/tablet image asset.
  final String? imageAsset;

  /// Chip label, e.g. "Metformin 500mg".
  String get chipLabel => '$name $strength';
}

/// Interaction Warning screen ki saari copy + data.
class InteractionWarningData {
  const InteractionWarningData({
    required this.severity,
    required this.medications,
    required this.explanation,
    required this.disclaimer,
  });

  final InteractionSeverity severity;
  final List<InteractionMedication> medications;
  final String explanation;
  final String disclaimer;

  // ---- Fixed labels (single source of truth) ----
  static const String screenTitle = 'Interaction Warning';
  static const String cardTitle = 'Possible Drug Interaction';
  static const String proceedLabel = 'I Understand, Proceed Anyway';
  static const String goBackLabel = 'Go Back and Edit';
  static const String footerNote = 'Your safety always comes first';

  /// Severity badge label.
  String get severityLabel {
    switch (severity) {
      case InteractionSeverity.moderate:
        return 'Moderate Interaction';

      case InteractionSeverity.severe:
        return 'Severe Interaction';
    }
  }

  /// Placeholder — jab tak interaction engine wire na ho jaye.
  static const InteractionWarningData sample = InteractionWarningData(
    severity: InteractionSeverity.moderate,

    medications: [
      InteractionMedication(
        name: 'Metformin',
        strength: '500mg',
        form: 'Oral Tablet',
        imageAsset: 'assets/images/tablet.jpg',
      ),
      InteractionMedication(
        name: 'Amlodipine',
        strength: '5mg',
        form: 'Oral Tablet',
        imageAsset: 'assets/images/tablet.jpg',
      ),
    ],

    explanation:
        'These two medications may affect each other when taken together. '
        'Your blood pressure or blood sugar could drop lower than expected.',

    disclaimer:
        'This is not medical advice. Consult your doctor or pharmacist '
        'before making any changes.',
  );
}
