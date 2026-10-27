import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// ALLERGY MODEL (M3)
/// ============================================================
///
/// Firestore Path:
///   profiles/{profileId}/allergies/{allergyId}
///
/// M3 Fields:
///   label, rxcui, classId, reaction, severity, createdAt, updatedAt
/// ============================================================

/// Allergy severity levels.
enum AllergySeverity {
  mild, // Mild reaction (rash, itching)
  moderate, // Moderate reaction (swelling, hives)
  severe; // Severe reaction (anaphylaxis — life-threatening)

  String get name {
    switch (this) {
      case AllergySeverity.mild:
        return 'mild';
      case AllergySeverity.moderate:
        return 'moderate';
      case AllergySeverity.severe:
        return 'severe';
    }
  }

  static AllergySeverity fromString(String? value) {
    switch (value) {
      case 'mild':
        return AllergySeverity.mild;
      case 'severe':
        return AllergySeverity.severe;
      case 'moderate':
      default:
        return AllergySeverity.moderate;
    }
  }
}

/// Allergy model — represents a Firestore allergy document.
class Allergy {
  const Allergy({
    required this.id,
    required this.profileId,
    required this.label,
    required this.severity,
    required this.createdAt,
    required this.updatedAt,
    this.rxcui,
    this.classId,
    this.reaction,
  });

  /// Document ID in Firestore.
  final String id;

  /// Parent profile ID.
  final String profileId;

  /// Allergy label (e.g., "Penicillin", "Peanuts", "Latex").
  final String label;

  /// RxNorm concept ID (from M4 drug database).
  /// Used for safety checks against medications.
  final String? rxcui;

  /// Drug class ID (alternative to rxcui for class-level allergies).
  final String? classId;

  /// Reaction description (e.g., "Hives", "Anaphylaxis").
  final String? reaction;

  /// Severity level (mild, moderate, severe).
  final AllergySeverity severity;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ───────────────────────────────────────────────────────────
  // Firestore serialization
  // ───────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'rxcui': rxcui,
      'classId': classId,
      'reaction': reaction,
      'severity': severity.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Allergy.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String profileId,
  }) {
    final data = doc.data() ?? {};
    return Allergy(
      id: doc.id,
      profileId: profileId,
      label: data['label'] as String? ?? '',
      rxcui: data['rxcui'] as String?,
      classId: data['classId'] as String?,
      reaction: data['reaction'] as String?,
      severity: AllergySeverity.fromString(data['severity'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Allergy copyWith({
    String? id,
    String? profileId,
    String? label,
    String? rxcui,
    String? classId,
    String? reaction,
    AllergySeverity? severity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Allergy(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      label: label ?? this.label,
      rxcui: rxcui ?? this.rxcui,
      classId: classId ?? this.classId,
      reaction: reaction ?? this.reaction,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
