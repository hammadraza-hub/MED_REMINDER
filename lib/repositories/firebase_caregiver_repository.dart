import '../core/caregiver/caregiver_repository.dart';

/// ============================================================
/// FIREBASE CAREGIVER REPOSITORY — STUB (M1)
/// ============================================================
///
/// ⚠️ NOT IMPLEMENTED IN M1.
///
/// Caregiver management requires Cloud Functions because:
///   - Security rules block direct client writes to
///     profile.roles / memberUids / healthUids / permissions
///   - Cloud Functions use Admin SDK to perform these operations
///     with privileged access
///   - Email sending for invites requires Cloud Functions
///
/// To fully implement:
///   1. Upgrade Firebase project to Blaze Plan
///   2. Deploy Cloud Functions (TypeScript code in functions/)
///   3. Use FunctionsClient.call() to invoke each operation
///
/// All methods throw [UnimplementedError] with clear messaging.
/// ============================================================
class FirebaseCaregiverRepository implements CaregiverRepository {
  // Singleton
  static final FirebaseCaregiverRepository instance =
      FirebaseCaregiverRepository._();
  FirebaseCaregiverRepository._();

  static const String _notImplementedMessage =
      'Caregiver operations require Cloud Functions (Blaze Plan). '
      'Deploy the Cloud Functions then implement these methods using '
      'FunctionsClient.call(). See M0 plan: "Cloud Functions perform '
      'privileged backend operations".';

  @override
  Future<String> sendInvite({
    required String profileId,
    required String inviteeEmail,
    required CaregiverRole role,
    required CaregiverPermissions permissions,
  }) {
    throw UnimplementedError(
      'sendInvite not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<void> acceptInvite({required String inviteId}) {
    throw UnimplementedError(
      'acceptInvite not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<void> declineInvite({required String inviteId}) {
    throw UnimplementedError(
      'declineInvite not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<void> revokeInvite({required String inviteId}) {
    throw UnimplementedError(
      'revokeInvite not implemented. $_notImplementedMessage',
    );
  }

  @override
  Stream<List<CaregiverInvite>> watchPendingInvites({
    required String profileId,
  }) {
    throw UnimplementedError(
      'watchPendingInvites not implemented. $_notImplementedMessage',
    );
  }

  @override
  Stream<List<CaregiverInvite>> watchReceivedInvites({
    required String userEmail,
  }) {
    throw UnimplementedError(
      'watchReceivedInvites not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<void> removeCaregiver({
    required String profileId,
    required String caregiverUid,
  }) {
    throw UnimplementedError(
      'removeCaregiver not implemented. $_notImplementedMessage',
    );
  }

  @override
  Future<void> updateCaregiverPermissions({
    required String profileId,
    required String caregiverUid,
    required CaregiverPermissions permissions,
  }) {
    throw UnimplementedError(
      'updateCaregiverPermissions not implemented. $_notImplementedMessage',
    );
  }
}
