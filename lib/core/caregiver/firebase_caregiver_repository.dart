/// ============================================================
/// FIREBASE CAREGIVER REPOSITORY
/// ============================================================
///
/// Spark-compatible implementation of CaregiverRepository.
/// Only implements client-side watch queries.
/// All mutations (send/accept/decline/revoke) require
/// Blaze Cloud Functions — deferred.
/// ============================================================

library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/caregiver/caregiver_repository.dart';

class FirebaseCaregiverRepository implements CaregiverRepository {
  FirebaseCaregiverRepository._();
  static final FirebaseCaregiverRepository instance =
      FirebaseCaregiverRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _invitesRef =>
      _firestore.collection('invites');

  /// Watch pending invitations for a profile (realtime).
  /// Spark-compatible: client-side Firestore query.
  @override
  Stream<List<CaregiverInvite>> watchPendingInvites({
    required String profileId,
  }) {
    return _invitesRef
        .where('profileId', isEqualTo: profileId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _inviteFromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Watch invitations received by current user (by their email).
  /// Spark-compatible: client-side Firestore query.
  @override
  Stream<List<CaregiverInvite>> watchReceivedInvites({
    required String userEmail,
  }) {
    return _invitesRef
        .where('inviteeEmail', isEqualTo: userEmail)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _inviteFromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ============================================================
  // BLAZE-ONLY METHODS (deferred — throw UnimplementedError)
  // ============================================================

  @override
  Future<String> sendInvite({
    required String profileId,
    required String inviteeEmail,
    required CaregiverRole role,
    required CaregiverPermissions permissions,
  }) {
    throw UnimplementedError('sendInvite requires Blaze Cloud Function');
  }

  @override
  Future<void> acceptInvite({required String inviteId}) {
    throw UnimplementedError('acceptInvite requires Blaze Cloud Function');
  }

  @override
  Future<void> declineInvite({required String inviteId}) {
    throw UnimplementedError('declineInvite requires Blaze Cloud Function');
  }

  @override
  Future<void> revokeInvite({required String inviteId}) {
    throw UnimplementedError('revokeInvite requires Blaze Cloud Function');
  }

  @override
  Future<void> removeCaregiver({
    required String profileId,
    required String caregiverUid,
  }) {
    throw UnimplementedError('removeCaregiver requires Blaze Cloud Function');
  }

  @override
  Future<void> updateCaregiverPermissions({
    required String profileId,
    required String caregiverUid,
    required CaregiverPermissions permissions,
  }) {
    throw UnimplementedError(
      'updateCaregiverPermissions requires Blaze Cloud Function',
    );
  }

  // ============================================================
  // HELPER
  // ============================================================

  CaregiverInvite _inviteFromMap(String id, Map<String, dynamic> data) {
    return CaregiverInvite(
      id: id,
      profileId: data['profileId'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      inviteeEmail: data['inviteeEmail'] as String? ?? '',
      role: CaregiverRoleX.fromString(data['role'] as String?),
      permissions: CaregiverPermissions.fromMap(
        data['permissions'] as Map<String, dynamic>?,
      ),
      status: InviteStatusX.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      acceptedByUid: data['acceptedByUid'] as String?,
    );
  }
}
