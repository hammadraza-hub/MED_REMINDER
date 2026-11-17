import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/community/community_models.dart';
import '../core/community/community_profile_controller.dart';

/// Firestore side of the community profile. M19 step 2.
class FirestoreCommunityProfileStore implements CommunityProfileStore {
  static const Duration _timeout = Duration(seconds: 10);

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String id) =>
      FirebaseFirestore.instance.collection('communityProfiles').doc(id);

  @override
  Future<String?> readMyProfileId() async {
    final snap = await _userDoc().get().timeout(_timeout);
    final id = snap.data()?['communityProfileId'];
    return CommunityIds.isValid(id is String ? id : null) ? id as String : null;
  }

  @override
  Future<void> saveMyProfileId(String id) => _userDoc()
      .update({
        'communityProfileId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      .timeout(_timeout);

  @override
  Future<CommunityProfile?> readProfile(String id) async {
    final snap = await _profileDoc(id).get().timeout(_timeout);
    final data = snap.data();
    return data == null ? null : CommunityProfile.fromMap(id, data);
  }

  @override
  Future<void> createProfile(
    String id, {
    required String pseudonym,
    required String avatar,
    required String bio,
  }) => _profileDoc(id)
      .set(
        CommunityProfile.createMap(
          pseudonym: pseudonym,
          avatar: avatar,
          bio: bio,
        ),
      )
      .timeout(_timeout);

  @override
  Future<void> updateProfile(
    String id, {
    required String pseudonym,
    required String avatar,
    required String bio,
  }) =>
      _profileDoc(id)
          .update({'pseudonym': pseudonym, 'avatar': avatar, 'bio': bio})
          .timeout(_timeout);
}
