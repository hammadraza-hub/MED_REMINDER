/// ============================================================
/// ALLERGIES DATA — backend-ready
///
/// Backend: Firestore allergies collection — UI zero change!
///
/// Firestore document shape (future):
/// {
///   id, memberId, name, category,
///   severity, symptoms, addedAt
/// }
///
/// MEMBER ISOLATION:
/// Demo records sirf Sarah (local_sarah) ke liye seed hote hain.
/// Baaki members ke records empty se shuru hote hain.
/// ============================================================
library;

/// Allergen reaction severity — Add/Edit sheet se set hoti hai.
enum AllergySeverity { mild, moderate, high }

/// Allergen ki category — icon presentation ke liye.
enum AllergyCategory { medication, food, environmental, other }

class AllergyRecord {
  const AllergyRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.severity,
    required this.symptoms,
    required this.addedAt,
  });

  final String id;

  /// Example: Penicillin, Peanuts, Latex
  final String name;

  final AllergyCategory category;
  final AllergySeverity severity;

  /// Example: "rash, swelling"
  final String symptoms;

  final DateTime addedAt;

  // ================= COMPUTED =================

  String get severityName {
    switch (severity) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.high:
        return 'High';
    }
  }

  /// Example: "Severity: High — rash, swelling"
  String get severitySummary {
    final normalized = symptoms.trim();

    if (normalized.isEmpty) {
      return 'Severity: $severityName';
    }

    return 'Severity: $severityName — $normalized';
  }
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class AllergiesData {
  /// memberId → allergen list (in-memory, is-session).
  ///
  /// TODO Backend:
  /// Firestore allergies collection se replace hogi — UI same rahegi.
  static final Map<String?, List<AllergyRecord>> _store = {};

  static final Set<String?> _seededMembers = {};

  /// Pehli access par member ki list seed hoti hai.
  static void _ensureSeeded(String? memberId) {
    if (_seededMembers.contains(memberId)) {
      return;
    }

    _seededMembers.add(memberId);

    _store[memberId] = memberId == 'local_sarah' ? _demoRecords() : [];
  }

  /// Backend: allergies collection filtered by memberId
  static List<AllergyRecord> recordsFor(String? memberId) {
    _ensureSeeded(memberId);

    return List.unmodifiable(_store[memberId] ?? const <AllergyRecord>[]);
  }

  static int countFor(String? memberId) => recordsFor(memberId).length;

  /// Naya allergen in-memory save karta hai (list ke top par).
  static void addRecord({
    required String? memberId,
    required String name,
    required AllergyCategory category,
    required AllergySeverity severity,
    required String symptoms,
  }) {
    _ensureSeeded(memberId);

    final records = _store.putIfAbsent(memberId, () => []);

    records.insert(
      0,
      AllergyRecord(
        id: 'al_local_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: category,
        severity: severity,
        symptoms: symptoms,
        addedAt: DateTime.now(),
      ),
    );
  }

  /// Existing allergen update karta hai (addedAt preserve).
  static void updateRecord({
    required String? memberId,
    required String id,
    required String name,
    required AllergyCategory category,
    required AllergySeverity severity,
    required String symptoms,
  }) {
    _ensureSeeded(memberId);

    final records = _store[memberId];

    if (records == null) {
      return;
    }

    final index = records.indexWhere((record) => record.id == id);

    if (index == -1) {
      return;
    }

    records[index] = AllergyRecord(
      id: id,
      name: name,
      category: category,
      severity: severity,
      symptoms: symptoms,
      addedAt: records[index].addedAt,
    );
  }

  static void removeRecord({required String? memberId, required String id}) {
    _ensureSeeded(memberId);

    _store[memberId]?.removeWhere((record) => record.id == id);
  }

  /// Demo records — sirf Sarah (seed pattern).
  static List<AllergyRecord> _demoRecords() {
    return [
      AllergyRecord(
        id: 'al_sarah_penicillin',
        name: 'Penicillin',
        category: AllergyCategory.medication,
        severity: AllergySeverity.high,
        symptoms: 'rash, swelling',
        addedAt: DateTime(2026, 9, 1),
      ),
      AllergyRecord(
        id: 'al_sarah_peanuts',
        name: 'Peanuts',
        category: AllergyCategory.food,
        severity: AllergySeverity.moderate,
        symptoms: 'stomach upset',
        addedAt: DateTime(2026, 8, 12),
      ),
    ];
  }
}
