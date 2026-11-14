import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/models/faq_item.dart';

void main() {
  Map<String, dynamic> doc(List<Object?> items) => {'items': items};

  group('FaqItem.parseDoc', () {
    test('picks the requested language', () {
      final r = FaqItem.parseDoc(
        doc([
          {
            'id': 'a',
            'q': {'en': 'Q en', 'hi': 'Q hi'},
            'a': {'en': 'A en', 'hi': 'A hi'},
          }
        ]),
        'hi',
      );
      expect(r.single.question, 'Q hi');
      expect(r.single.answer, 'A hi');
    });

    test('falls back to English per field', () {
      final r = FaqItem.parseDoc(
        doc([
          {
            'id': 'a',
            'q': {'en': 'Q en', 'hi': 'Q hi'},
            'a': {'en': 'A en'}, // no hi answer
          }
        ]),
        'hi',
      );
      expect(r.single.question, 'Q hi');
      expect(r.single.answer, 'A en');
    });

    test('plain strings apply to every language', () {
      final r = FaqItem.parseDoc(
        doc([
          {'id': 'a', 'q': 'Q?', 'a': 'A.'}
        ]),
        'fr',
      );
      expect(r.single.question, 'Q?');
      expect(r.single.answer, 'A.');
    });

    test('skips items without a usable question or answer', () {
      final r = FaqItem.parseDoc(
        doc([
          {'id': 'noA', 'q': 'Q?'},
          {'id': 'noQ', 'a': 'A.'},
          {'id': 'blank', 'q': '  ', 'a': 'A.'},
          {'id': 'wrongLang', 'q': {'es': 'Q'}, 'a': {'es': 'A'}}, // no en
          'not a map',
          null,
          {'id': 'ok', 'q': 'Q?', 'a': 'A.'},
        ]),
        'hi',
      );
      expect(r.map((e) => e.id), ['ok']);
    });

    test('sorts by order; unordered items come last in original order', () {
      final r = FaqItem.parseDoc(
        doc([
          {'id': 'u1', 'q': 'q', 'a': 'a'},
          {'id': 'b', 'order': 2, 'q': 'q', 'a': 'a'},
          {'id': 'u2', 'q': 'q', 'a': 'a'},
          {'id': 'a', 'order': 1, 'q': 'q', 'a': 'a'},
        ]),
        'en',
      );
      expect(r.map((e) => e.id), ['a', 'b', 'u1', 'u2']);
    });

    test('missing id gets a generated one', () {
      final r = FaqItem.parseDoc(
        doc([
          {'q': 'q', 'a': 'a'}
        ]),
        'en',
      );
      expect(r.single.id, 'faq_0');
    });

    test('null / invalid document -> empty, never throws', () {
      expect(FaqItem.parseDoc(null, 'en'), isEmpty);
      expect(FaqItem.parseDoc({}, 'en'), isEmpty);
      expect(FaqItem.parseDoc({'items': 'nope'}, 'en'), isEmpty);
      expect(FaqItem.parseDoc({'items': []}, 'en'), isEmpty);
    });

    test('trims whitespace', () {
      final r = FaqItem.parseDoc(
        doc([
          {'q': '  Q?  ', 'a': '\nA.\n'}
        ]),
        'en',
      );
      expect(r.single.question, 'Q?');
      expect(r.single.answer, 'A.');
    });
  });
}
