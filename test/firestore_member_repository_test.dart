import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/members/firestore_member_repository.dart';
import 'package:med_remind_app/core/members/member_repository.dart';

Map<String, dynamic> profile({
  String name = 'Mom',
  String kind = 'dependent',
  Object? archivedAt,
  int created = 1,
  String? avatar,
  String? relationship,
}) => {
  'name': name,
  'kind': kind,
  'archivedAt': archivedAt,
  'avatarPath': avatar,
  'relationship': relationship,
  'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, created)),
  'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, created)),
};

MemberProfile mp(String id, {int day = 1}) =>
    FirestoreMemberRepository.fromProfileData(id, profile(created: day))!;

void main() {
  test('a normal profile becomes a member', () {
    final m = FirestoreMemberRepository.fromProfileData(
      'p1',
      profile(name: '  Mom ', avatar: '/a.png', relationship: 'Mother'),
    )!;
    expect(m.id, 'p1');
    expect(m.displayName, 'Mom');
    expect(m.relationship, 'Mother');
    expect(m.profileImagePath, '/a.png');
  });

  test('an archived profile is left out', () {
    expect(
      FirestoreMemberRepository.fromProfileData(
        'p1',
        profile(archivedAt: Timestamp.now()),
      ),
      isNull,
    );
  });

  test('an empty name shows as Me; kind decides the default relationship', () {
    final self = FirestoreMemberRepository.fromProfileData(
      'p1',
      profile(name: '', kind: 'self'),
    )!;
    expect(self.displayName, 'Me');
    expect(self.relationship, 'Self');
    final other = FirestoreMemberRepository.fromProfileData('p2', profile())!;
    expect(other.relationship, 'Member');
  });

  test('missing dates do not crash', () {
    final m = FirestoreMemberRepository.fromProfileData('p1', {'name': 'X'})!;
    expect(m.createdAt, isA<DateTime>());
  });

  test('the own profile comes first, then oldest first', () {
    final r = FirestoreMemberRepository.ordered(
      [mp('c', day: 3), mp('a', day: 1), mp('me', day: 9), mp('b', day: 2)],
      {'me'},
    );
    expect(r.map((m) => m.id), ['me', 'a', 'b', 'c']);
  });

  test('same date: ordered by id, so every phone shows the same order', () {
    final r = FirestoreMemberRepository.ordered([mp('z'), mp('b')], {});
    expect(r.map((m) => m.id), ['b', 'z']);
  });
}
