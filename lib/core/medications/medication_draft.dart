/// ============================================================
/// MEDICATION DRAFT
///
/// Add/Edit wizard ke steps ke darmiyan unsaved medication details
/// carry karta hai.
///
/// Ye database entity nahi hai.
/// Final Schedule confirmation par repository ke through SQLite
/// records create honge.
/// ============================================================
class MedicationDraft {
  const MedicationDraft({
    required this.name,
    required this.strength,
    required this.strengthUnit,
    required this.medicineForm,
    required this.colorName,
    this.instructions,
    this.imagePath,
  });

  final String name;
  final String strength;
  final String strengthUnit;
  final String medicineForm;
  final String colorName;
  final String? instructions;
  final String? imagePath;

  String get displayStrength => '$strength $strengthUnit';
}
