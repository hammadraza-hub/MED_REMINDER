import '../../repositories/firestore_community_reaction_stores.dart';
import '../community/community_reactions.dart';
import 'community_profile_service.dart';

/// The app's vote / bookmark stores. M19 step 5.
class CommunityReactionService {
  CommunityReactionService._();

  static final CommunityVoteStore votes = FirestoreCommunityVoteStore();
  static final CommunityBookmarkStore bookmarks =
      FirestoreCommunityBookmarkStore();

  /// A fresh controller for one screen.
  static CommunityReactionsController create() => CommunityReactionsController(
    votes,
    bookmarks,
    CommunityProfileService.instance.myId,
  );
}
