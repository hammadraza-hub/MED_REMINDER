/// ============================================================
/// ALLERGY MODEL
/// ============================================================
///
/// Represents a patient allergy for safety checks (M10).
///
/// Firestore Path: profiles/{memberId}/allergies/{allergyId}
///
/// Fields: name, severity, description, createdAt
/// ============================================================

class Allergy {
  /// Firestore document ID.
  final String id;

  /// Parent profile ID (profiles/{memberId}/allergies/{id})
  final String memberId;

  /// Allergy name (e.g., "Penicillin", "Peanuts", "Shellfish")
  final String name;

  /// Severity level.
  /// Used for warning modals and alert prioritization.
  final String severity; // "mild" | "moderate" | "severe"

  /// Free-text description or notes.
  final String? description;

  /// When this allergy was created.
  final DateTime createdAt;

  Allergy({
    required this.id,
    required this.memberId,
    required this.name,
    required this.severity,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory: create from Firestore map.
  factory Allergy.fromMap(String id, Map<String, dynamic> data) {
    return Allergy(
      id: id,
      memberId: data['memberId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      severity: data['severity'] as String? ?? 'mild',
      description: data['description'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'name': name,
      'severity': severity,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with modifications.
  Allergy copyWith({
    String? id,
    String? memberId,
    String? name,
    String? severity,
    String? description,
    DateTime? createdAt,
  }) {
    return Allergy(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Allergy($name, $severity)';
}