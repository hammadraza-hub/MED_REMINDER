import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/account_deletion_summary.dart';

Map<String, dynamic> profile(String owner, List<String> members, String name) =>
    {'ownerUid': owner, 'memberUids': members, 'name': name};

void main() {
  test('own profile without other members', () {
    final s = DeletionSummary.fromProfiles('u1', [
      profile('u1', ['u1'], 'Me'),
    ]);
    expect(s.owned.single.name, 'Me');
    expect(s.owned.single.otherMembers, 0);
    expect(s.memberOf, 0);
    expect(s.affectsOtherPeople, isFalse);
  });

  test('own profile shared with two people', () {
    final s = DeletionSummary.fromProfiles('u1', [
      profile('u1', ['u1', 'a', 'b'], 'Mom'),
    ]);
    expect(s.owned.single.otherMembers, 2);
    expect(s.affectsOtherPeople, isTrue);
    expect(s.totalOtherMembers, 2);
  });

  test('profiles owned by others only count as memberOf', () {
    final s = DeletionSummary.fromProfiles('u1', [
      profile('x', ['x', 'u1'], 'Dad'),
      profile('y', ['y', 'u1', 'z'], 'Aunt'),
    ]);
    expect(s.owned, isEmpty);
    expect(s.memberOf, 2);
    expect(s.affectsOtherPeople, isFalse);
  });

  test('mixed: owned + member + unrelated profile is ignored', () {
    final s = DeletionSummary.fromProfiles('u1', [
      profile('u1', ['u1', 'a'], 'Self'),
      profile('x', ['x', 'u1'], 'Dad'),
      profile('q', ['q'], 'Stranger'),
    ]);
    expect(s.owned.length, 1);
    expect(s.memberOf, 1);
    expect(s.totalOtherMembers, 1);
  });

  test('missing or blank name / malformed members do not crash', () {
    final s = DeletionSummary.fromProfiles('u1', [
      {'ownerUid': 'u1', 'memberUids': ['u1']},
      {'ownerUid': 'u1', 'memberUids': ['u1'], 'name': '   '},
      {'ownerUid': 'u1', 'memberUids': 'oops', 'name': 'Bad'},
    ]);
    expect(s.owned.length, 2);
    expect(s.owned.first.name, '—');
  });

  test('empty input', () {
    final s = DeletionSummary.fromProfiles('u1', const []);
    expect(s.owned, isEmpty);
    expect(s.memberOf, 0);
  });
}
