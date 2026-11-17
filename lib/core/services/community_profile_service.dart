import '../../repositories/firestore_community_profile_store.dart';
import '../community/community_profile_controller.dart';

/// The app's single [CommunityProfileController]. M19 step 2.
class CommunityProfileService {
  CommunityProfileService._();

  static final CommunityProfileController instance = CommunityProfileController(
    FirestoreCommunityProfileStore(),
  );
}
