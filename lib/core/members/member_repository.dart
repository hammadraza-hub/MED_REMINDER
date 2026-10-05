/// ============================================================
/// MEMBER MODEL
///
/// App/domain layer ka family-member model.
///
/// IMPORTANT:
/// UI ko Drift generated `Member` class directly use nahi karni.
/// Is domain model ki wajah se:
///
/// Local DB now      → MemberProfile
/// Firebase later    → MemberProfile
///
/// UI same rahegi.
/// ============================================================
class MemberProfile {
  const MemberProfile({
    required this.id,
    required this.displayName,
    this.accountId,
    this.relationship,
    this.profileImagePath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stable identity.
  ///
  /// Local:
  /// local_sarah / UUID-like id
  ///
  /// Firebase:
  /// Firestore member document ID.
  final String id;

  final String? accountId;
  final String displayName;
  final String? relationship;

  /// Local file path now.
  /// Firebase Storage URL later.
  final String? profileImagePath;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemberProfile copyWith({
    String? id,
    String? accountId,
    String? displayName,
    String? relationship,
    String? profileImagePath,
    bool removeProfileImage = false,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberProfile(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      profileImagePath: removeProfileImage
          ? null
          : profileImagePath ?? this.profileImagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// ============================================================
/// MEMBER REPOSITORY CONTRACT
///
/// CURRENT:
/// LocalMemberRepository → Drift SQLite
///
/// FUTURE:
/// FirebaseMemberRepository → Firestore
/// ============================================================
abstract class MemberRepository {
  /// Active members continuously observe karo.
  Stream<List<MemberProfile>> watchActiveMembers();

  /// One-time active member load.
  Future<List<MemberProfile>> getActiveMembers();

  /// Stable ID se member load.
  Future<MemberProfile?> getMemberById(String memberId);

  /// Create ya existing member update.
  Future<void> saveMember(MemberProfile member);

  /// Member profile/archive state update.
  Future<void> setMemberActive({
    required String memberId,
    required bool isActive,
  });

  /// Development/local first-run ke liye initial members create.
  ///
  /// Existing DB members hon to duplicate create nahi hone chahiye.
  Future<void> seedInitialMembersIfNeeded();
}
