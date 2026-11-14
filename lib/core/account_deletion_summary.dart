/// ============================================================
/// ACCOUNT DELETION SUMMARY — M14 step 6
///
/// Pure logic: what deleting the account will remove, shown in the confirm
/// sheet. Built from the raw profile documents the user is a member of.
///
///   owned    profiles the user owns -> deleted completely, together with
///            everything in them. [OwnedProfileInfo.otherMembers] tells how
///            many OTHER people lose access (caregivers, viewers).
///   memberOf profiles owned by somebody else -> the user is only removed
///            from them; the data stays with its owner.
/// ============================================================
class OwnedProfileInfo {
  const OwnedProfileInfo({required this.name, required this.otherMembers});

  final String name;
  final int otherMembers;
}

class DeletionSummary {
  const DeletionSummary({required this.owned, required this.memberOf});

  static const DeletionSummary empty = DeletionSummary(owned: [], memberOf: 0);

  final List<OwnedProfileInfo> owned;
  final int memberOf;

  /// True when deleting also removes access of other people.
  bool get affectsOtherPeople => owned.any((p) => p.otherMembers > 0);

  int get totalOtherMembers => owned.fold(0, (sum, p) => sum + p.otherMembers);

  factory DeletionSummary.fromProfiles(
    String uid,
    Iterable<Map<String, dynamic>> profiles,
  ) {
    final owned = <OwnedProfileInfo>[];
    var memberOf = 0;

    for (final p in profiles) {
      final members = p['memberUids'];
      final memberList = members is List ? members : const [];
      if (!memberList.contains(uid)) continue;

      if (p['ownerUid'] == uid) {
        final name = p['name'];
        owned.add(
          OwnedProfileInfo(
            name: name is String && name.trim().isNotEmpty ? name.trim() : '—',
            otherMembers: memberList.where((m) => m != uid).length,
          ),
        );
      } else {
        memberOf++;
      }
    }
    return DeletionSummary(owned: owned, memberOf: memberOf);
  }
}
