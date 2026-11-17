import '../../repositories/firestore_community_feed_store.dart';
import '../community/community_feed.dart';

/// The app's single [CommunityFeedStore]. M19 step 3.
class CommunityFeedService {
  CommunityFeedService._();

  static final CommunityFeedStore instance = FirestoreCommunityFeedStore();
}
