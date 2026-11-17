import '../../repositories/firestore_community_moderation_store.dart';
import '../community/community_moderation.dart';

/// The app's moderation store and moderator check. M19 step 7.
class CommunityModerationService {
  CommunityModerationService._();

  static final CommunityModerationStore store =
      FirestoreCommunityModerationStore();

  /// True when the signed-in account has the `moderator` claim.
  static Future<bool> isModerator() => readModeratorClaim();
}
