/// ============================================================
/// SIDE EFFECTS DATA — backend-ready
///
/// Backend: Firestore side_effects collection — UI zero change!
///
/// Firestore document shape (future):
/// {
///   id, memberId, medicationId,
///   symptom, severity (1..5),
///   recordedAt, note?
/// }
/// ============================================================

enum SideEffectSeverityLevel { mild, moderate, severe }

class SideEffectEntry {
  const SideEffectEntry({
    required this.id,
    required this.symptom,
    required this.medicationName,
    required this.medicationStrength,
    required this.severity,
    required this.recordedAt,
    this.note,
  });

  final String id;

  /// Example: Nausea, Headache, Dizziness
  final String symptom;

  /// Linked medication — abhi name/strength text.
  /// TODO Backend: medicationId reference (Firestore).
  final String medicationName;
  final String medicationStrength;

  /// 1..5
  final int severity;

  final DateTime recordedAt;
  final String? note;

  // ================= COMPUTED =================

  /// 1-2 → Mild | 3 → Moderate | 4-5 → Severe
  SideEffectSeverityLevel get level {
    if (severity <= 2) {
      return SideEffectSeverityLevel.mild;
    }

    if (severity == 3) {
      return SideEffectSeverityLevel.moderate;
    }

    return SideEffectSeverityLevel.severe;
  }

  String get severityName {
    switch (level) {
      case SideEffectSeverityLevel.mild:
        return 'Mild';
      case SideEffectSeverityLevel.moderate:
        return 'Moderate';
      case SideEffectSeverityLevel.severe:
        return 'Severe';
    }
  }

  /// Example: "Moderate (3/5)"
  String get severityLabel => '$severityName ($severity/5)';
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class SideEffectsData {
  /// Is-session mein save ki gayi symptom entries (in-memory).
  ///
  /// TODO Backend:
  /// Firestore side_effects/{id} create se replace hogi — UI same rahegi.
  static final List<({String? memberId, SideEffectEntry entry})> _addedEntries =
      [];

  /// Naya symptom entry in-memory save karta hai.
  static void addEntry({
    required String? memberId,
    required String symptom,
    required String medicationName,
    required String medicationStrength,
    required int severity,
    String? note,
  }) {
    _addedEntries.insert(0, (
      memberId: memberId,
      entry: SideEffectEntry(
        id: 'se_local_${DateTime.now().microsecondsSinceEpoch}',
        symptom: symptom,
        medicationName: medicationName,
        medicationStrength: medicationStrength,
        severity: severity,
        recordedAt: DateTime.now(),
        note: note,
      ),
    ));
  }

  /// Backend: side_effects collection filtered by memberId
  ///
  /// Saved entries kisi bhi selected member ko milti hain.
  /// Member isolation: demo records sirf Sarah ke liye —
  /// seed pattern jaisi. Mom/Jake ko demo entries nahi milengi.
  static List<SideEffectEntry> entriesFor(String? memberId) {
    final savedEntries = _addedEntries
        .where((record) => record.memberId == memberId)
        .map((record) => record.entry)
        .toList();

    if (memberId == null || memberId != 'local_sarah') {
      return savedEntries;
    }

    return [...savedEntries, ..._demoEntries()];
  }

  /// Demo records — sirf Sarah (seed pattern).
  static List<SideEffectEntry> _demoEntries() {
    final now = DateTime.now();

    final todayMorning = DateTime(now.year, now.month, now.day, 9, 15);
    final yesterday = now.subtract(const Duration(days: 1));
    final twoDaysAgo = now.subtract(const Duration(days: 2));

    return [
      SideEffectEntry(
        id: 'se_sarah_nausea_1',
        symptom: 'Nausea',
        medicationName: 'Metformin',
        medicationStrength: '500mg',
        severity: 3,
        recordedAt: todayMorning.isBefore(now) ? todayMorning : now,
      ),
      SideEffectEntry(
        id: 'se_sarah_headache_1',
        symptom: 'Headache',
        medicationName: 'Amlodipine',
        medicationStrength: '5mg',
        severity: 2,
        recordedAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          8,
          40,
        ),
      ),
      SideEffectEntry(
        id: 'se_sarah_dizziness_1',
        symptom: 'Dizziness',
        medicationName: 'Metformin',
        medicationStrength: '500mg',
        severity: 4,
        recordedAt: DateTime(
          twoDaysAgo.year,
          twoDaysAgo.month,
          twoDaysAgo.day,
          14,
          5,
        ),
      ),
    ];
  }
}
