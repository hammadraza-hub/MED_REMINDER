import '../../repositories/firestore_community_post_store.dart';
import '../community/community_posts.dart';
import 'community_profile_service.dart';

/// The app's single post store and write actions. M19 step 4.
class CommunityPostService {
  CommunityPostService._();

  static final CommunityPostStore store = FirestoreCommunityPostStore();

  static final CommunityPostActions actions = CommunityPostActions(
    store,
    CommunityProfileService.instance.myId,
  );
}
