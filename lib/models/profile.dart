import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// PROFILE MODEL (M3)
/// ============================================================
///
/// Full Firestore profile document model.
/// Different from StoredProfile (which is local UI state for
/// SharedPreferences — just memberId + displayName + imagePath).
///
/// Firestore Path:
///   profiles/{profileId}
///
/// M3 Fields:
///   ownerUid, kind, name, dob, relationship, color, avatarPath,
///   timezone, missedAfterMin, conditions[], roles{}, memberUids[],
///   healthUids[], permissions{}, archivedAt, createdAt, updatedAt
/// ============================================================

/// Profile kind — who is this profile for?
enum ProfileKind {
  self, // User's own profile
  dependent, // A dependent (child, elderly parent, etc.)
  adult; // A linked adult (spouse, partner, etc.)

  String get name {
    switch (this) {
      case ProfileKind.self:
        return 'self';
      case ProfileKind.dependent:
        return 'dependent';
      case ProfileKind.adult:
        return 'adult';
    }
  }

  static ProfileKind fromString(String? value) {
    switch (value) {
      case 'dependent':
        return ProfileKind.dependent;
      case 'adult':
        return ProfileKind.adult;
      case 'self':
      default:
        return ProfileKind.self;
    }
  }
}

/// Profile role — what access level does a user have?
enum ProfileRole {
  owner, // Full control (only one per profile)
  caregiver, // Can manage meds/doses per permissions
  viewer; // Read-only access

  String get name {
    switch (this) {
      case ProfileRole.owner:
        return 'owner';
      case ProfileRole.caregiver:
        return 'caregiver';
      case ProfileRole.viewer:
        return 'viewer';
    }
  }

  static ProfileRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return ProfileRole.owner;
      case 'viewer':
        return ProfileRole.viewer;
      case 'caregiver':
      default:
        return ProfileRole.caregiver;
    }
  }
}

/// Full Profile model — represents a Firestore profile document.
class Profile {
  const Profile({
    required this.id,
    required this.ownerUid,
    required this.kind,
    required this.name,
    required this.timezone,
    required this.roles,
    required this.memberUids,
    required this.healthUids,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.dob,
    this.relationship,
    this.color,
    this.avatarPath,
    this.missedAfterMin = 60,
    this.conditions = const [],
    this.archivedAt,
  });

  /// Document ID in Firestore.
  final String id;

  /// UID of the profile owner.
  final String ownerUid;

  /// Profile kind (self, dependent, adult).
  final ProfileKind kind;

  /// Display name (e.g., "Sarah Johnson").
  final String name;

  /// Date of birth (optional — for dependents).
  final DateTime? dob;

  /// Relationship to owner (e.g., "Mother", "Son", "Spouse").
  final String? relationship;

  /// UI color identifier (e.g., "blue", "green").
  final String? color;

  /// Avatar path — local file path or Firebase Storage URL.
  final String? avatarPath;

  /// IANA timezone (e.g., "Asia/Karachi", "America/New_York").
  final String timezone;

  /// Minutes after scheduled time before a dose is marked "missed".
  final int missedAfterMin;

  /// Medical conditions (small array, no subcollection).
  /// e.g., ["Diabetes Type 2", "Hypertension"]
  final List<String> conditions;

  /// Role map: {uid: "owner" | "caregiver" | "viewer"}
  final Map<String, String> roles;

  /// UIDs of all profile members.
  final List<String> memberUids;

  /// UIDs of users with health data access.
  final List<String> healthUids;

  /// Permission map: {uid: {editMedications: bool, logDoses: bool}}
  final Map<String, Map<String, dynamic>> permissions;

  /// When the profile was archived (null if active).
  /// Profiles are never deleted — just archived.
  final DateTime? archivedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ───────────────────────────────────────────────────────────
  // Convenience getters
  // ───────────────────────────────────────────────────────────

  /// Whether this profile is archived.
  bool get isArchived => archivedAt != null;

  /// Whether this profile is the user's own "self" profile.
  bool get isSelf => kind == ProfileKind.self;

  // ───────────────────────────────────────────────────────────
  // Firestore serialization
  // ───────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'kind': kind.name,
      'name': name,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'relationship': relationship,
      'color': color,
      'avatarPath': avatarPath,
      'timezone': timezone,
      'missedAfterMin': missedAfterMin,
      'conditions': conditions,
      'roles': roles,
      'memberUids': memberUids,
      'healthUids': healthUids,
      'permissions': permissions,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Profile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Profile(
      id: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      kind: ProfileKind.fromString(data['kind'] as String?),
      name: data['name'] as String? ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate(),
      relationship: data['relationship'] as String?,
      color: data['color'] as String?,
      avatarPath: data['avatarPath'] as String?,
      timezone: data['timezone'] as String? ?? 'UTC',
      missedAfterMin: (data['missedAfterMin'] as num?)?.toInt() ?? 60,
      conditions: List<String>.from(data['conditions'] as List? ?? []),
      roles: Map<String, String>.from(data['roles'] as Map? ?? {}),
      memberUids: List<String>.from(data['memberUids'] as List? ?? []),
      healthUids: List<String>.from(data['healthUids'] as List? ?? []),
      permissions: Map<String, Map<String, dynamic>>.from(
        (data['permissions'] as Map? ?? {}).map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        ),
      ),
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Profile copyWith({
    String? id,
    String? ownerUid,
    ProfileKind? kind,
    String? name,
    DateTime? dob,
    bool clearDob = false,
    String? relationship,
    bool clearRelationship = false,
    String? color,
    String? avatarPath,
    String? timezone,
    int? missedAfterMin,
    List<String>? conditions,
    Map<String, String>? roles,
    List<String>? memberUids,
    List<String>? healthUids,
    Map<String, Map<String, dynamic>>? permissions,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      dob: clearDob ? null : (dob ?? this.dob),
      relationship: clearRelationship
          ? null
          : (relationship ?? this.relationship),
      color: color ?? this.color,
      avatarPath: avatarPath ?? this.avatarPath,
      timezone: timezone ?? this.timezone,
      missedAfterMin: missedAfterMin ?? this.missedAfterMin,
      conditions: conditions ?? this.conditions,
      roles: roles ?? this.roles,
      memberUids: memberUids ?? this.memberUids,
      healthUids: healthUids ?? this.healthUids,
      permissions: permissions ?? this.permissions,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
