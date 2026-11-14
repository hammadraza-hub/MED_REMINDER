/// One symptom / side-effect entry (`profiles/{pid}/symptoms/{id}`).
/// Pure data class (M15 step 3).
class SymptomEntry {
  const SymptomEntry({
    this.id,
    required this.symptom,
    required this.severity,
    this.medicationId,
    required this.occurredAt,
    this.notes,
    this.createdBy,
  });

  final String? id;
  final String symptom;

  /// 1 (very mild) to 5 (severe).
  final int severity;

  /// Medication this side effect is linked to, if any.
  final String? medicationId;
  final DateTime occurredAt;
  final String? notes;
  final String? createdBy;

  /// Fields to write on create; the repository adds `createdBy` / `createdAt`.
  Map<String, Object?> toCreateMap() {
    final n = notes?.trim();
    final med = medicationId?.trim();
    return {
      'symptom': symptom.trim(),
      'severity': severity,
      'occurredAt': occurredAt,
      if (med != null && med.isNotEmpty) 'medicationId': med,
      if (n != null && n.isNotEmpty) 'notes': n,
    };
  }

  /// Parses a stored document ([data] already has plain Dart values).
  /// Null for an unreadable document.
  static SymptomEntry? fromMap(String id, Map<String, dynamic> data) {
    final name = data['symptom'];
    final severity = data['severity'];
    final at = data['occurredAt'];
    if (name is! String || severity is! num || at is! DateTime) return null;

    return SymptomEntry(
      id: id,
      symptom: name,
      severity: severity.toInt(),
      medicationId: data['medicationId'] as String?,
      occurredAt: at,
      notes: data['notes'] as String?,
      createdBy: data['createdBy'] as String?,
    );
  }
}
