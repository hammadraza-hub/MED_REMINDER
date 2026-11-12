/// ============================================================
/// INTERACTION CHECKER — M10 Safety Checks
/// ============================================================
///
/// Static interaction checker for common drug interactions.
/// Spark-compatible (client-side, no Cloud Functions).
///
/// Usage: checkInteractions(selectedDrugName, existingMedications)
/// Returns: InteractionWarningData? (null if no interaction)
/// ============================================================

library;

import 'interaction_warning_data.dart';

/// Severity mapping for known interactions.
/// 'severe' or 'moderate' based on clinical significance.
final Map<String, InteractionSeverity> _severityMap = {
  'warfarin-aspirin': InteractionSeverity.severe,
  'warfarin-ibuprofen': InteractionSeverity.severe,
  'warfarin-naproxen': InteractionSeverity.severe,
  'warfarin-diclofenac': InteractionSeverity.severe,
  'warfarin-clopidogrel': InteractionSeverity.severe,
  'aspirin-clopidogrel': InteractionSeverity.severe,
  'aspirin-methotrexate': InteractionSeverity.severe,
  'digoxin-furosemide': InteractionSeverity.severe,
  'digoxin-amiodarone': InteractionSeverity.severe,
  'digoxin-verapamil': InteractionSeverity.severe,
  'metformin-contrast dye': InteractionSeverity.severe,
  'fluoxetine-maois': InteractionSeverity.severe,
  'sertraline-maois': InteractionSeverity.severe,
  'tramadol-maois': InteractionSeverity.severe,
  'amitriptyline-maois': InteractionSeverity.severe,
  'carbamazepine-maois': InteractionSeverity.severe,
  'birth control-rifampin': InteractionSeverity.severe,
  'st johns wort-maois': InteractionSeverity.severe,
  'tyramine foods-maois': InteractionSeverity.severe,
  'lithium-furosemide': InteractionSeverity.severe,
  'lithium-hydrochlorothiazide': InteractionSeverity.severe,
  'insulin-alcohol': InteractionSeverity.severe,
  'metoprolol-verapamil': InteractionSeverity.severe,
  'metoprolol-diltiazem': InteractionSeverity.severe,
  'verapamil-simvastatin': InteractionSeverity.severe,
  'diltiazem-simvastatin': InteractionSeverity.severe,
  'grapefruit juice-simvastatin': InteractionSeverity.severe,
  'grapefruit juice-amlodipine': InteractionSeverity.severe,
  'grapefruit juice-verapamil': InteractionSeverity.severe,
  'grapefruit juice-diltiazem': InteractionSeverity.severe,
  'grapefruit juice-carbamazepine': InteractionSeverity.severe,
  'alcohol-maois': InteractionSeverity.severe,
  'contrast dye-metformin': InteractionSeverity.severe,
  'quinolone antibiotics-warfarin': InteractionSeverity.severe,
  'rifampin-birth control': InteractionSeverity.severe,
  'rifampin-oral contraceptives': InteractionSeverity.severe,
  'st johns wort-birth control': InteractionSeverity.severe,
  'st johns wort-oral contraceptives': InteractionSeverity.severe,
  'st johns wort-ssris': InteractionSeverity.severe,
  'st johns wort-warfarin': InteractionSeverity.severe,
  'ssris-maois': InteractionSeverity.severe,
  'ssris-tramadol': InteractionSeverity.moderate,
  'ssris-warfarin': InteractionSeverity.moderate,
  'ssris-aspirin': InteractionSeverity.moderate,
  'fluoxetine-tramadol': InteractionSeverity.moderate,
  'sertraline-tramadol': InteractionSeverity.moderate,
  'tramadol-amitriptyline': InteractionSeverity.moderate,
  'tramadol-carbamazepine': InteractionSeverity.moderate,
  'carbamazepine-valproate': InteractionSeverity.moderate,
  'carbamazepine-phenytoin': InteractionSeverity.moderate,
  'valproate-phenytoin': InteractionSeverity.moderate,
  'phenytoin-warfarin': InteractionSeverity.moderate,
  'phenytoin-birth control': InteractionSeverity.moderate,
  'valproate-warfarin': InteractionSeverity.moderate,
  'valproate-birth control': InteractionSeverity.moderate,
  'carbamazepine-birth control': InteractionSeverity.moderate,
  'carbamazepine-warfarin': InteractionSeverity.moderate,
  'metformin-furosemide': InteractionSeverity.moderate,
  'lisinopril-potassium': InteractionSeverity.moderate,
  'lisinopril-spironolactone': InteractionSeverity.moderate,
  'lisinopril-ibuprofen': InteractionSeverity.moderate,
  'lisinopril-naproxen': InteractionSeverity.moderate,
  'furosemide-lithium': InteractionSeverity.moderate,
  'furosemide-ibuprofen': InteractionSeverity.moderate,
  'furosemide-naproxen': InteractionSeverity.moderate,
  'furosemide-aspirin': InteractionSeverity.moderate,
  'hydrochlorothiazide-digoxin': InteractionSeverity.moderate,
  'hydrochlorothiazide-lithium': InteractionSeverity.moderate,
  'hydrochlorothiazide-nsaids': InteractionSeverity.moderate,
  'hydrochlorothiazide-prednisone': InteractionSeverity.moderate,
  'spironolactone-potassium': InteractionSeverity.moderate,
  'spironolactone-nsaids': InteractionSeverity.moderate,
  'potassium-nsaids': InteractionSeverity.moderate,
  'lithium-nsaids': InteractionSeverity.moderate,
  'lithium-ace inhibitors': InteractionSeverity.moderate,
  'prednisone-ibuprofen': InteractionSeverity.moderate,
  'prednisone-naproxen': InteractionSeverity.moderate,
  'prednisone-aspirin': InteractionSeverity.moderate,
  'prednisone-diabetes meds': InteractionSeverity.moderate,
  'insulin-beta blockers': InteractionSeverity.moderate,
  'insulin-sulfonylureas': InteractionSeverity.moderate,
  'metoprolol-clonidine': InteractionSeverity.moderate,
  'metoprolol-insulin': InteractionSeverity.moderate,
  'clonidine-alcohol': InteractionSeverity.moderate,
  'omeprazole-clopidogrel': InteractionSeverity.moderate,
  'omeprazole-digoxin': InteractionSeverity.moderate,
  'omeprazole-phenytoin': InteractionSeverity.moderate,
  'clopidogrel-fluoxetine': InteractionSeverity.moderate,
  'digoxin-hydrochlorothiazide': InteractionSeverity.moderate,
  'levothyroxine-calcium': InteractionSeverity.moderate,
  'levothyroxine-iron': InteractionSeverity.moderate,
  'levothyroxine-aluminum hydroxide': InteractionSeverity.moderate,
  'levothyroxine-omeprazole': InteractionSeverity.moderate,
  'calcium-iron': InteractionSeverity.moderate,
  'calcium-quinolone antibiotics': InteractionSeverity.moderate,
  'iron-tetracycline': InteractionSeverity.moderate,
  'iron-quinolone antibiotics': InteractionSeverity.moderate,
  'aluminum hydroxide-tetracycline': InteractionSeverity.moderate,
  'aluminum hydroxide-quinolone antibiotics': InteractionSeverity.moderate,
  'tetracycline-dairy products': InteractionSeverity.moderate,
  'quinolone antibiotics-dairy products': InteractionSeverity.moderate,
  'nsaids-prednisone': InteractionSeverity.moderate,
  'nsaids-diabetes meds': InteractionSeverity.moderate,
  'beta blockers-insulin': InteractionSeverity.moderate,
  'ace inhibitors-potassium': InteractionSeverity.moderate,
  'ace inhibitors-spironolactone': InteractionSeverity.moderate,
  'ace inhibitors-nsaids': InteractionSeverity.moderate,
  'birth control-carbamazepine': InteractionSeverity.moderate,
  'birth control-phenytoin': InteractionSeverity.moderate,
  'birth control-st johns wort': InteractionSeverity.moderate,
  'oral contraceptives-rifampin': InteractionSeverity.moderate,
  'oral contraceptives-carbamazepine': InteractionSeverity.moderate,
  'oral contraceptives-phenytoin': InteractionSeverity.moderate,
  'oral contraceptives-st johns wort': InteractionSeverity.moderate,
};

/// Interaction Checker — checks if a selected medication
/// interacts with existing medications.
class InteractionChecker {
  /// Check if [selectedDrug] interacts with any of [existingMeds].
  /// Returns list of interacting drug names.
  static List<String> checkInteractions(
    String selectedDrug,
    List<String> existingMeds,
  ) {
    final interactions = <String>[];
    final selectedLower = selectedDrug.toLowerCase();

    for (final med in existingMeds) {
      final medLower = med.toLowerCase();
      final key1 = '$selectedLower-$medLower';
      final key2 = '$medLower-$selectedLower';

      if (_severityMap.containsKey(key1) || _severityMap.containsKey(key2)) {
        interactions.add(med);
      }
    }

    return interactions;
  }

  /// Get severity for an interaction between two drugs.
  static InteractionSeverity getSeverity(String drug1, String drug2) {
    final key1 = '${drug1.toLowerCase()}-${drug2.toLowerCase()}';
    final key2 = '${drug2.toLowerCase()}-${drug1.toLowerCase()}';

    return _severityMap[key1] ?? _severityMap[key2] ?? InteractionSeverity.moderate;
  }

  /// Check if [selectedDrug] is already in [existingMeds].
  /// Returns true if a duplicate is found.
  static bool checkDuplicate(String selectedDrug, List<String> existingMeds) {
    final selectedLower = selectedDrug.toLowerCase().trim();
    return existingMeds.any((med) => med.toLowerCase().trim() == selectedLower);
  }

  /// Build InteractionWarningData from interactions found.
  static InteractionWarningData? buildWarningData(
    String selectedDrug,
    List<String> interactingMeds,
  ) {
    if (interactingMeds.isEmpty) return null;

    final medications = [
      InteractionMedication(
        name: selectedDrug,
        strength: '',
        form: 'Oral Tablet',
      ),
      ...interactingMeds.map((med) => InteractionMedication(
            name: med,
            strength: '',
            form: 'Oral Tablet',
          )),
    ];

    final severity = getSeverity(selectedDrug, interactingMeds.first);

    return InteractionWarningData(
      severity: severity,
      medications: medications,
      explanation:
          '$selectedDrug may interact with ${interactingMeds.join(", ")}. '
          'Taking these together could cause unexpected side effects.',
      disclaimer:
          'This is not medical advice. Consult your doctor or pharmacist '
          'before making any changes.',
    );
  }
}