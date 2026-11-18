import 'package:cloud_firestore/cloud_firestore.dart';

import '../../repositories/auth_repository.dart';
import 'member_repository.dart';

/// The Home member bar, from the REAL profiles of the signed-in person.
///
/// Before M22-Home step 1 the bar came from a local SQLite table that was
/// seeded with three made-up members (Sarah, Mom, Jake). Selecting one of them
/// pointed the app at a profile that does not exist in Firestore. Now the bar
/// lists `profiles` where the person is a member (their own profile first,
/// then the people they look after or who share with them), archived ones left
/// out.
class FirestoreMemberRepository implements MemberRepository {
  FirestoreMemberRepository({FirebaseFirestore? db, String? Function()? uid})
    : _dbOverride = db,
      _uid = uid ?? (() => AuthRepository.instance.currentUid);

  final FirebaseFirestore? _dbOverride;
  final String? Function() _uid;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  /// Pure: one profile document -> one member (null = leave it out).
  static MemberProfile? fromProfileData(String id, Map<String, dynamic> data) {
    if (data['archivedAt'] != null) return null; // archived: not shown
    final name = (data['name'] as String?)?.trim() ?? '';
    DateTime when(Object? v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final kind = data['kind'] as String?;
    return MemberProfile(
      id: id,
      displayName: name.isEmpty ? 'Me' : name,
      relationship:
          (data['relationship'] as String?) ??
          (kind == 'self' ? 'Self' : 'Member'),
      profileImagePath: data['avatarPath'] as String?,
      createdAt: when(data['createdAt']),
      updatedAt: when(data['updatedAt']),
    );
  }

  /// Pure: own profile first, then oldest first (ties by id, so the order is
  /// the same on every phone).
  static List<MemberProfile> ordered(
    List<MemberProfile> members,
    Set<String> selfIds,
  ) {
    final list = [...members];
    list.sort((a, b) {
      final sa = selfIds.contains(a.id) ? 0 : 1;
      final sb = selfIds.contains(b.id) ? 0 : 1;
      if (sa != sb) return sa - sb;
      final c = a.createdAt.compareTo(b.createdAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return list;
  }

  static List<MemberProfile> fromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final members = <MemberProfile>[];
    final selfIds = <String>{};
    for (final doc in snapshot.docs) {
      final m = fromProfileData(doc.id, doc.data());
      if (m == null) continue;
      members.add(m);
      if (doc.data()['kind'] == 'self') selfIds.add(doc.id);
    }
    return ordered(members, selfIds);
  }

  Query<Map<String, dynamic>>? _query() {
    final uid = _uid();
    if (uid == null || uid.isEmpty) return null;
    return _db.collection('profiles').where('memberUids', arrayContains: uid);
  }

  @override
  Stream<List<MemberProfile>> watchActiveMembers() {
    final q = _query();
    if (q == null) return Stream.value(const []);
    return q.snapshots().map(fromSnapshot);
  }

  @override
  Future<List<MemberProfile>> getActiveMembers() async {
    final q = _query();
    if (q == null) return const [];
    return fromSnapshot(await q.get());
  }

  @override
  Future<MemberProfile?> getMemberById(String memberId) async {
    final doc = await _db.collection('profiles').doc(memberId).get();
    final data = doc.data();
    if (data == null) return null;
    return fromProfileData(doc.id, data);
  }

  /// Only the photo is saved from Home (the rules allow `avatarPath`).
  @override
  Future<void> saveMember(MemberProfile member) async {
    await _db.collection('profiles').doc(member.id).update({
      'avatarPath': member.profileImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setMemberActive({
    required String memberId,
    required bool isActive,
  }) async {
    await _db.collection('profiles').doc(memberId).update({
      'archivedAt': isActive ? null : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Nothing to seed: the profiles are the real ones.
  @override
  Future<void> seedInitialMembersIfNeeded() async {}
}
