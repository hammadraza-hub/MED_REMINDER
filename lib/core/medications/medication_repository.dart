/// ============================================================
/// MEDICATION DOMAIN MODEL
///
/// UI ko Drift-generated Medication database class directly use
/// nahi karni.
///
/// CURRENT:
/// Drift / SQLite → MedicationProfile
///
/// FUTURE:
/// Firestore / Backend → MedicationProfile
///
/// 🆕 MODULE 2:
/// - discontinuedReason (discontinue modal ka reason)
/// - courseDay / courseTotalDays (course wali dawai)
/// ============================================================
class MedicationProfile {
  const MedicationProfile({
    required this.id,
    required this.memberId,
    required this.name,
    required this.strength,
    this.strengthUnit,
    this.medicineForm,
    this.colorName,
    this.instructions,
    this.imagePath,
    this.linkedPharmacyId,
    this.isActive = true,
    this.discontinuedAt,
    this.discontinuedReason,
    this.courseDay,
    this.courseTotalDays,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stable medication identity.
  ///
  /// Local seeds:
  /// local_metformin
  /// local_amlodipine
  /// etc.
  ///
  /// TODO Backend:
  /// Firebase phase mein Firestore medication document ID use hoga.
  final String id;

  /// Stable family-member ID.
  final String memberId;

  final String name;

  /// Example:
  /// 500, 5, 1000
  final String strength;

  /// Example:
  /// mg, IU
  final String? strengthUnit;

  /// Example:
  /// tablet, capsule, drops, liquid, injection
  final String? medicineForm;

  final String? colorName;
  final String? instructions;

  /// Local asset/file path now.
  /// Firebase Storage URL later.
  final String? imagePath;

  final String? linkedPharmacyId;

  final bool isActive;
  final DateTime? discontinuedAt;

  /// 🆕 MODULE 2:
  /// Discontinue modal ka selected reason.
  /// SQLite medications.discontinued_reason mein persist hota hai.
  final String? discontinuedReason;

  /// 🆕 MODULE 2:
  /// Course wali dawai ka progress (Amoxicillin type).
  /// Example: Day 4 of 10 → courseDay = 4, courseTotalDays = 10.
  ///
  /// Abhi seed/demo data fixed hai.
  /// Module 5 (DoseEvents) se ye dynamic banega.
  final int? courseDay;
  final int? courseTotalDays;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayStrength {
    final unit = strengthUnit?.trim();

    if (unit == null || unit.isEmpty) {
      return strength;
    }

    return '$strength$unit';
  }

  bool get isCourse => courseDay != null && courseTotalDays != null;

  MedicationProfile copyWith({
    String? id,
    String? memberId,
    String? name,
    String? strength,
    String? strengthUnit,
    String? medicineForm,
    String? colorName,
    String? instructions,
    String? imagePath,
    String? linkedPharmacyId,
    bool? isActive,
    DateTime? discontinuedAt,
    bool clearDiscontinuedAt = false,
    String? discontinuedReason,
    bool clearDiscontinuedReason = false,
    int? courseDay,
    int? courseTotalDays,
    bool clearCourse = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationProfile(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      medicineForm: medicineForm ?? this.medicineForm,
      colorName: colorName ?? this.colorName,
      instructions: instructions ?? this.instructions,
      imagePath: imagePath ?? this.imagePath,
      linkedPharmacyId: linkedPharmacyId ?? this.linkedPharmacyId,
      isActive: isActive ?? this.isActive,
      discontinuedAt: clearDiscontinuedAt
          ? null
          : discontinuedAt ?? this.discontinuedAt,
      discontinuedReason: clearDiscontinuedReason
          ? null
          : discontinuedReason ?? this.discontinuedReason,
      courseDay: clearCourse ? null : courseDay ?? this.courseDay,
      courseTotalDays: clearCourse
          ? null
          : courseTotalDays ?? this.courseTotalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// ============================================================
/// MEDICATION REPOSITORY CONTRACT
///
/// UI/controller → Member-independent interface.
///
/// CURRENT:
/// LocalMedicationRepository → Drift / SQLite
///
/// FUTURE:
/// FirebaseMedicationRepository → Firestore
/// ============================================================
abstract class MedicationRepository {
  /// Member ki active medicines realtime observe karo.
  Stream<List<MedicationProfile>> watchActiveMedications(String memberId);

  /// Member ki discontinued/archived medicines observe karo.
  Stream<List<MedicationProfile>> watchArchivedMedications(String memberId);

  Future<List<MedicationProfile>> getActiveMedications(String memberId);

  Future<List<MedicationProfile>> getArchivedMedications(String memberId);

  Future<MedicationProfile?> getMedicationById(String medicationId);

  /// Create/update medication.
  Future<void> saveMedication(MedicationProfile medication);

  /// Medicine archive/discontinue karo.
  ///
  /// 🆕 MODULE 2:
  /// [reason] optional hai — discontinue modal ka selected reason
  /// SQLite mein persist hota hai.
  ///
  /// Historical medication/dose records delete nahi honge.
  Future<void> discontinueMedication({
    required String medicationId,
    required DateTime discontinuedAt,
    String? reason,
  });

  /// Development/local migration ke initial medicine records.
  Future<void> seedInitialMedicationsIfNeeded(String memberId);
}
