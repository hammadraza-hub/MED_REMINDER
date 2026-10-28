/// Drug model — represents a medication from RxNorm (or local Pakistani drug list).
///
/// M4 — Drug Catalog & Label Scan
/// Used by:
///   • Add Medication – Search screen (autocomplete)
///   • Add Medication – Scan screen (label OCR result)
///   • Add Allergy screen (autocomplete by drug name / class)
///
/// Data Sources (Spark plan / Phase A):
///   • assets/data/drugs.json  — bundled JSON (200 common drugs)
///   • RxNorm REST API         — for full info on demand (https://rxnav.nlm.nih.gov/REST/)
///
/// Data Sources (Blaze plan / Phase B — future):
///   • Firestore drugs/{rxcui}  — populated by syncRxnorm Cloud Function
///
/// Fields match the M4 plan:
///   • rxcui           — RxNorm ID (primary key, e.g., "860975")
///   • name            — display name (e.g., "Metformin 500 MG Oral Tablet")
///   • nameLower       — lowercase name for prefix search
///   • termType         — RxNorm term type (IN = ingredient, BN = brand name,
///                       SCD = semantic clinical drug, etc.)
///   • strength        — e.g., "500 MG" (nullable — IN/BN don't have strength)
///   • doseForm        — e.g., "Tablet", "Capsule", "Solution" (nullable)
///   • ingredientRxcuis — list of ingredient RxCUIs (for duplicate therapy checks)
///   • classIds        — list of drug class IDs (for allergy checks, e.g., "Penicillins")
///   • synonyms        — alternative names (e.g., brand names for generics)
///   • imageUrl        — pill image URL (DailyMed or null if not available)
///   • isPakistani     — true if from local Pakistani list (RxNorm = false)
class Drug {
  final String rxcui;
  final String name;
  final String nameLower;
  final String termType;
  final String? strength;
  final String? doseForm;
  final List<String> ingredientRxcuis;
  final List<String> classIds;
  final List<String> synonyms;
  final String? imageUrl;
  final bool isPakistani;

  const Drug({
    required this.rxcui,
    required this.name,
    required this.nameLower,
    required this.termType,
    this.strength,
    this.doseForm,
    this.ingredientRxcuis = const [],
    this.classIds = const [],
    this.synonyms = const [],
    this.imageUrl,
    this.isPakistani = false,
  });

  /// Construct from JSON (loaded from assets/data/drugs.json or RxNorm REST API).
  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(
      rxcui: json['rxcui'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameLower: (json['nameLower'] as String? ?? json['name'] as String? ?? '')
          .toLowerCase(),
      termType: json['termType'] as String? ?? 'IN',
      strength: json['strength'] as String?,
      doseForm: json['doseForm'] as String?,
      ingredientRxcuis: List<String>.from(
        json['ingredientRxcuis'] as List? ?? [],
      ),
      classIds: List<String>.from(json['classIds'] as List? ?? []),
      synonyms: List<String>.from(json['synonyms'] as List? ?? []),
      imageUrl: json['imageUrl'] as String?,
      isPakistani: json['isPakistani'] as bool? ?? false,
    );
  }

  /// Serialize to JSON (for Firestore write in Phase B, or caching in memory).
  Map<String, dynamic> toJson() {
    return {
      'rxcui': rxcui,
      'name': name,
      'nameLower': nameLower,
      'termType': termType,
      'strength': strength,
      'doseForm': doseForm,
      'ingredientRxcuis': ingredientRxcuis,
      'classIds': classIds,
      'synonyms': synonyms,
      'imageUrl': imageUrl,
      'isPakistani': isPakistani,
    };
  }

  bool get hasStrength => strength != null && strength!.isNotEmpty;
  bool get hasDoseForm => doseForm != null && doseForm!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool matchesPrefix(String query) {
    final q = query.toLowerCase();
    if (nameLower.startsWith(q)) return true;
    for (final s in synonyms) {
      if (s.toLowerCase().startsWith(q)) return true;
    }
    return false;
  }

  bool isInClass(String className) {
    final c = className.toLowerCase();
    for (final classId in classIds) {
      if (classId.toLowerCase().contains(c)) return true;
    }
    return false;
  }

  @override
  String toString() => 'Drug(rxcui: $rxcui, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Drug && other.rxcui == rxcui);

  @override
  int get hashCode => rxcui.hashCode;
}
