/// ============================================================
/// CAREGIVER DOMAIN MODELS
/// ============================================================
///
/// Caregiver management requires Cloud Functions (per M0 plan).
/// Client-side writes to profile.roles / memberUids are blocked
/// by Firestore security rules — only admin SDK via Cloud
/// Functions can modify these fields.
/// ============================================================

/// Role of a member in a patient profile.
enum CaregiverRole {
  /// Owner — full control (only one per profile).
  owner,

  /// Caregiver — can manage meds/doses per permissions.
  caregiver,

  /// Viewer — read-only access.
  viewer,
}

extension CaregiverRoleX on CaregiverRole {
  String get name {
    switch (this) {
      case CaregiverRole.owner:
        return 'owner';
      case CaregiverRole.caregiver:
        return 'caregiver';
      case CaregiverRole.viewer:
        return 'viewer';
    }
  }

  static CaregiverRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return CaregiverRole.owner;
      case 'viewer':
        return CaregiverRole.viewer;
      case 'caregiver':
      default:
        return CaregiverRole.caregiver;
    }
  }
}

/// Permissions granted to a caregiver.
class CaregiverPermissions {
  const CaregiverPermissions({
    this.editMedications = false,
    this.logDoses = false,
    this.viewHealth = false,
  });

  /// Can add/edit/discontinue medications.
  final bool editMedications;

  /// Can log doses (taken/skipped/missed).
  final bool logDoses;

  /// Can view sensitive health records (allergies, vitals, etc.).
  final bool viewHealth;

  Map<String, dynamic> toMap() {
    return {
      'editMedications': editMedications,
      'logDoses': logDoses,
      'viewHealth': viewHealth,
    };
  }

  factory CaregiverPermissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CaregiverPermissions();
    return CaregiverPermissions(
      editMedications: map['editMedications'] as bool? ?? false,
      logDoses: map['logDoses'] as bool? ?? false,
      viewHealth: map['viewHealth'] as bool? ?? false,
    );
  }

  static const empty = CaregiverPermissions();
}

/// Caregiver invitation status.
enum InviteStatus { pending, accepted, declined, revoked, expired }

extension InviteStatusX on InviteStatus {
  String get name {
    switch (this) {
      case InviteStatus.pending:
        return 'pending';
      case InviteStatus.accepted:
        return 'accepted';
      case InviteStatus.declined:
        return 'declined';
      case InviteStatus.revoked:
        return 'revoked';
      case InviteStatus.expired:
        return 'expired';
    }
  }

  static InviteStatus fromString(String? value) {
    switch (value) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'declined':
        return InviteStatus.declined;
      case 'revoked':
        return InviteStatus.revoked;
      case 'expired':
        return InviteStatus.expired;
      case 'pending':
      default:
        return InviteStatus.pending;
    }
  }
}

/// Caregiver invitation.
class CaregiverInvite {
  const CaregiverInvite({
    required this.id,
    required this.profileId,
    required this.ownerUid,
    required this.inviteeEmail,
    required this.role,
    required this.permissions,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.acceptedAt,
    this.acceptedByUid,
  });

  final String id;

  /// Profile this invite grants access to.
  final String profileId;

  /// UID of the profile owner who sent the invite.
  final String ownerUid;

  /// Email of the invited caregiver.
  final String inviteeEmail;

  final CaregiverRole role;
  final CaregiverPermissions permissions;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final String? acceptedByUid;
}

/// ============================================================
/// CAREGIVER REPOSITORY CONTRACT
/// ============================================================
///
/// All methods require Cloud Functions (Blaze Plan).
/// Direct Firestore writes to roles/memberUids/healthUids are
/// blocked by security rules.
/// ============================================================
abstract class CaregiverRepository {
  /// Send invitation to a caregiver via email.
  /// Cloud Function writes to invites/{id} + sends email.
  Future<String> sendInvite({
    required String profileId,
    required String inviteeEmail,
    required CaregiverRole role,
    required CaregiverPermissions permissions,
  });

  /// Accept an invitation (called by the invited caregiver).
  /// Cloud Function updates profile.roles + memberUids + permissions atomically.
  Future<void> acceptInvite({required String inviteId});

  /// Decline an invitation (called by the invited caregiver).
  Future<void> declineInvite({required String inviteId});

  /// Revoke an invitation (called by the profile owner).
  Future<void> revokeInvite({required String inviteId});

  /// Watch pending invitations for a profile (realtime).
  Stream<List<CaregiverInvite>> watchPendingInvites({
    required String profileId,
  });

  /// Watch invitations received by current user (by their email).
  Stream<List<CaregiverInvite>> watchReceivedInvites({
    required String userEmail,
  });

  /// Remove a caregiver from a profile.
  /// Cloud Function removes their uid from roles/memberUids/healthUids.
  Future<void> removeCaregiver({
    required String profileId,
    required String caregiverUid,
  });

  /// Update permissions for an existing caregiver.
  /// Cloud Function updates profile.permissions.{uid} map.
  Future<void> updateCaregiverPermissions({
    required String profileId,
    required String caregiverUid,
    required CaregiverPermissions permissions,
  });
}
