import '../../repositories/firestore_community_safety_stores.dart';
import '../community/community_safety.dart';
import 'community_profile_service.dart';

/// The app's single report actions and block list. M19 step 6.
class CommunitySafetyService {
  CommunitySafetyService._();

  static final CommunityBlocksController blocks = CommunityBlocksController(
    FirestoreCommunityBlockStore(),
    CommunityProfileService.instance.myId,
  );

  static final CommunitySafety instance = CommunitySafety(
    reports: CommunityReportActions(
      FirestoreCommunityReportStore(),
      CommunityProfileService.instance.myId,
    ),
    blocks: blocks,
  );
}
