/// ============================================================
/// INVITES DATA — backend-ready
///
/// MEMBER ISOLATION:
/// Har invite us member (inviter) ke memberId se tagged hai.
///
/// Future:
/// Backend: Firestore invites collection — UI zero change!
///
/// Firestore document shape (future):
/// {
///   id, inviterMemberId, contact, relationship,
///   permissionLevel, isDependent, managedByMe, createdAt
/// }
/// ============================================================

enum InviteType { adult, dependent }

enum PermissionLevel { viewer, coManager }

class InviteEntry {
  const InviteEntry({
    required this.id,
    required this.inviterMemberId,
    required this.type,
    required this.relationship,
    required this.createdAt,
    this.contact,
    required this.permissionLevel,
    required this.managedByMe,
  });

  /// Stable invite identity.
  ///
  /// TODO Backend: Firestore invite document ID.
  final String id;

  /// Kis member ne invite bheja.
  final String inviterMemberId;

  final InviteType type;

  /// Adult invite ke liye email/phone.
  /// Dependent ke liye null (no separate login).
  final String? contact;

  final String relationship;

  final PermissionLevel permissionLevel;

  final bool managedByMe;

  final DateTime createdAt;
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class InvitesData {
  /// TODO Backend:
  /// Firestore invites/{id} create se replace hoga.
  static final List<InviteEntry> _invites = [];

  /// Naya invite record.
  static void addInvite({
    required String inviterMemberId,
    required InviteType type,
    required String relationship,
    String? contact,
    required PermissionLevel permissionLevel,
    required bool managedByMe,
  }) {
    _invites.insert(
      0,
      InviteEntry(
        id: 'invite_local_${DateTime.now().microsecondsSinceEpoch}',
        inviterMemberId: inviterMemberId,
        type: type,
        relationship: relationship,
        contact: contact,
        permissionLevel: permissionLevel,
        managedByMe: managedByMe,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Member ke sent invites — newest pehle.
  ///
  /// MEMBER ISOLATION: sirf us member ke invites.
  static List<InviteEntry> invitesFor(String? memberId) {
    if (memberId == null || memberId.isEmpty) {
      return const [];
    }

    final memberInvites = _invites
        .where((invite) => invite.inviterMemberId == memberId)
        .toList();

    memberInvites.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return memberInvites;
  }
}
