import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/ai/chat_models.dart';
import 'package:med_remind_app/core/ai/chat_title.dart';

void main() {
  group('ChatTitle', () {
    test('first words of the question, without the trailing ?', () {
      expect(
        ChatTitle.fromQuestion('What are the side effects of metformin?'),
        'What are the side effects of metformin',
      );
    });

    test('only the first 7 words', () {
      expect(
        ChatTitle.fromQuestion('one two three four five six seven eight nine'),
        'one two three four five six seven',
      );
    });

    test('long words are cut to 50 characters', () {
      final t = ChatTitle.fromQuestion('x' * 200);
      expect(t.length, ChatTitle.maxLength);
      expect(t.endsWith('…'), isTrue);
    });

    test('empty, blank or null gives the fallback', () {
      expect(ChatTitle.fromQuestion(null), ChatTitle.fallback);
      expect(ChatTitle.fromQuestion('   '), ChatTitle.fallback);
      expect(ChatTitle.fromQuestion('???'), ChatTitle.fallback);
    });

    test('phone numbers, emails and links are removed from the title', () {
      final t = ChatTitle.fromQuestion(
        'call 0300-1234567 or mail me a@b.com https://x.org',
      );
      expect(t, isNot(contains('0300')));
      expect(t, isNot(contains('@')));
      expect(t, isNot(contains('http')));
    });

    test('never longer than the rules allow', () {
      for (final q in ['a' * 500, 'word ' * 100, 'é' * 300]) {
        expect(
          ChatTitle.fromQuestion(q).length,
          lessThanOrEqualTo(ChatLimits.maxTitleLength),
        );
      }
    });
  });

  group('models', () {
    test('ChatThread.fromMap reads Firestore timestamps', () {
      final t = ChatThread.fromMap('t1', {
        'profileId': 'p1',
        'title': 'Hello',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 11, 2)),
      });
      expect(t.id, 't1');
      expect(t.profileId, 'p1');
      expect(t.title, 'Hello');
      expect(t.createdAt, DateTime(2026, 11, 1));
      expect(t.updatedAt, DateTime(2026, 11, 2));
    });

    test('a pending server time (null) does not crash', () {
      final t = ChatThread.fromMap('t1', {
        'profileId': 'p1',
        'title': 'Hello',
        'createdAt': null,
        'updatedAt': null,
      });
      expect(t.updatedAt, t.createdAt);
    });

    test('ChatMessage roles', () {
      final u = ChatMessage.fromMap('m1', {
        'role': 'user',
        'text': 'hi',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      final a = ChatMessage.fromMap('m2', {
        'role': 'assistant',
        'text': 'hello',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      expect(u.isUser, isTrue);
      expect(a.isUser, isFalse);
      expect(ChatRole.fromString('anything else'), ChatRole.user);
    });

    test('limits match the security rules', () {
      expect(ChatLimits.maxTitleLength, 80);
      expect(ChatLimits.maxTextLength, 4000);
    });
  });
}
