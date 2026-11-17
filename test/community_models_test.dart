import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_validator.dart';

void main() {
  group('CommunityIds', () {
    test('20 letters or digits', () {
      final id = CommunityIds.newProfileId();
      expect(id.length, 20);
      expect(CommunityIds.isValid(id), isTrue);
    });

    test('random: 1000 ids are all different', () {
      final ids = {for (var i = 0; i < 1000; i++) CommunityIds.newProfileId()};
      expect(ids.length, 1000);
    });

    test('a seeded generator is repeatable (for tests)', () {
      expect(
        CommunityIds.newProfileId(Random(1)),
        CommunityIds.newProfileId(Random(1)),
      );
    });

    test('validity check matches the rules (20 letters / digits)', () {
      expect(CommunityIds.isValid('A' * 20), isTrue);
      expect(CommunityIds.isValid('A' * 19), isFalse);
      expect(CommunityIds.isValid('A' * 21), isFalse);
      expect(CommunityIds.isValid('${'A' * 19}!'), isFalse);
      expect(CommunityIds.isValid(null), isFalse);
    });
  });

  group('CommunityValidator (same limits as the rules)', () {
    test('pseudonym', () {
      expect(CommunityValidator.pseudonym('calm_river'), isNull);
      expect(CommunityValidator.pseudonym('a.b-c_1'), isNull);
      expect(CommunityValidator.pseudonym(''), CommunityInputError.empty);
      expect(CommunityValidator.pseudonym(null), CommunityInputError.empty);
      expect(CommunityValidator.pseudonym('ab'), CommunityInputError.tooShort);
      expect(
        CommunityValidator.pseudonym('x' * 25),
        CommunityInputError.tooLong,
      );
      expect(
        CommunityValidator.pseudonym('has space'),
        CommunityInputError.badCharacters,
      );
      expect(
        CommunityValidator.pseudonym('me@mail.com'),
        CommunityInputError.badCharacters,
      );
      expect(CommunityValidator.pseudonym('x' * 24), isNull);
      expect(CommunityValidator.pseudonym('abc'), isNull);
    });

    test('bio', () {
      expect(CommunityValidator.bio(null), isNull);
      expect(CommunityValidator.bio('x' * 160), isNull);
      expect(CommunityValidator.bio('x' * 161), CommunityInputError.tooLong);
    });

    test('post and comment text', () {
      expect(CommunityValidator.postBody('hello'), isNull);
      expect(CommunityValidator.postBody('   '), CommunityInputError.empty);
      expect(
        CommunityValidator.postBody('x' * 2001),
        CommunityInputError.tooLong,
      );
      expect(CommunityValidator.postBody('x' * 2000), isNull);
      expect(CommunityValidator.commentBody('x' * 800), isNull);
      expect(
        CommunityValidator.commentBody('x' * 801),
        CommunityInputError.tooLong,
      );
    });

    test('limits equal the numbers in the rules', () {
      expect(CommunityLimits.pseudonymMin, 3);
      expect(CommunityLimits.pseudonymMax, 24);
      expect(CommunityLimits.bioMax, 160);
      expect(CommunityLimits.postBodyMax, 2000);
      expect(CommunityLimits.commentBodyMax, 800);
      expect(CommunityLimits.idLength, 20);
    });
  });

  group('models', () {
    test('profile and group', () {
      final p = CommunityProfile.fromMap('P', {
        'pseudonym': 'calm_river',
        'avatar': 'a1',
        'bio': 'hi',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      expect(p.pseudonym, 'calm_river');
      expect(p.createdAt, DateTime(2026, 11, 1));

      final g = CommunityGroup.fromMap('g1', {
        'name': 'Diabetes',
        'description': 'd',
        'order': 2,
      });
      expect(g.name, 'Diabetes');
      expect(g.order, 2);
    });

    test('post: edited flag, null time and hidden', () {
      final fresh = CommunityFeedPost.fromMap('g1', 'p1', {
        'authorId': 'A' * 20,
        'body': 'x',
        'createdAt': null,
        'editedAt': null,
        'voteCount': 3,
        'hidden': false,
      });
      expect(fresh.isEdited, isFalse);
      expect(fresh.voteCount, 3);
      expect(fresh.groupId, 'g1');

      final edited = CommunityFeedPost.fromMap('g1', 'p1', {
        'authorId': 'A' * 20,
        'body': 'x',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
        'editedAt': Timestamp.fromDate(DateTime(2026, 11, 2)),
        'voteCount': 0,
        'hidden': true,
      });
      expect(edited.isEdited, isTrue);
      expect(edited.hidden, isTrue);
    });

    test('create maps hold exactly the fields the rules allow', () {
      expect(
        CommunityFeedPost.createMap(authorId: 'A' * 20, body: 'x').keys.toSet(),
        {'authorId', 'body', 'createdAt', 'editedAt', 'voteCount', 'hidden'},
      );
      expect(
        CommunityComment.createMap(authorId: 'A' * 20, body: 'x').keys.toSet(),
        {'authorId', 'body', 'createdAt', 'editedAt'},
      );
      expect(
        CommunityProfile.createMap(
          pseudonym: 'abc',
          avatar: 'a1',
          bio: '',
        ).keys.toSet(),
        {'pseudonym', 'avatar', 'bio', 'createdAt'},
      );
      final post = CommunityFeedPost.createMap(authorId: 'A' * 20, body: 'x');
      expect(post['voteCount'], 0);
      expect(post['hidden'], false);
      expect(post['editedAt'], isNull);
    });

    test('no model has a uid, email or name field', () {
      final maps = [
        CommunityFeedPost.createMap(authorId: 'A' * 20, body: 'x'),
        CommunityComment.createMap(authorId: 'A' * 20, body: 'x'),
        CommunityProfile.createMap(pseudonym: 'abc', avatar: 'a', bio: ''),
        CommunityReport.createMap(
          reporterId: 'A' * 20,
          target: CommunityReportTarget.post,
          groupId: 'g1',
          postId: 'p1',
          reason: CommunityReportReason.spam,
        ),
      ];
      for (final m in maps) {
        for (final k in m.keys) {
          expect(k.toLowerCase(), isNot(contains('uid')));
          expect(k.toLowerCase(), isNot(contains('email')));
          expect(k.toLowerCase(), isNot(contains('name')), reason: k);
        }
      }
    });

    test('report: post and comment targets', () {
      final post = CommunityReport.createMap(
        reporterId: 'A' * 20,
        target: CommunityReportTarget.post,
        groupId: 'g1',
        postId: 'p1',
        reason: CommunityReportReason.medical,
      );
      expect(post.containsKey('commentId'), isFalse);
      expect(post['targetType'], 'post');
      expect(post['reason'], 'medical');

      final comment = CommunityReport.createMap(
        reporterId: 'A' * 20,
        target: CommunityReportTarget.comment,
        groupId: 'g1',
        postId: 'p1',
        commentId: 'c1',
        reason: CommunityReportReason.abuse,
      );
      expect(comment['commentId'], 'c1');

      final read = CommunityReport.fromMap('r1', {
        ...comment,
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      expect(read.target, CommunityReportTarget.comment);
      expect(read.reason, CommunityReportReason.abuse);
      expect(CommunityReportReason.byName('nonsense'), isNull);
    });
  });
}
