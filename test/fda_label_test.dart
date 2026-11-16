import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:med_remind_app/core/ai/fda_label.dart';
import 'package:med_remind_app/core/ai/fda_label_client.dart';

String fixture() => File('test/data/openfda_metformin.json').readAsStringSync();

http.Response ok(String body) =>
    http.Response.bytes(utf8.encode(body), 200, headers: {});

const notFoundBody =
    '{"error":{"code":"NOT_FOUND","message":"No matches found!"}}';

class Calls {
  final List<Uri> uris = [];
}

FdaLabelClient clientWith(
  Calls calls,
  http.Response Function(Uri uri) answer, {
  FdaLabelCache? cache,
  DateTime Function()? clock,
}) {
  return FdaLabelClient(
    client: MockClient((req) async {
      calls.uris.add(req.url);
      return answer(req.url);
    }),
    cache: cache,
    clock: clock,
  );
}

void main() {
  group('FdaTextCleaner', () {
    test('removes the section number and heading at the start', () {
      expect(
        FdaTextCleaner.clean(
          '1 INDICATIONS AND USAGE Metformin is used with diet and exercise.',
        ),
        'Metformin is used with diet and exercise.',
      );
      expect(
        FdaTextCleaner.clean('5 WARNINGS AND PRECAUTIONS N/A Lactic acidosis.'),
        'Lactic acidosis.',
      );
    });

    test('removes cross references and "see" notes', () {
      expect(
        FdaTextCleaner.clean(
          'Lactic Acidosis [see Boxed Warning and Warnings (5.1) ] can occur ( 5.1 , 5.2 ).',
        ),
        'Lactic Acidosis can occur.',
      );
    });

    test('a "[see ...]" note with a missing closing bracket is removed', () {
      expect(
        FdaTextCleaner.clean(
          'Hypoglycemia [ see Warnings and Precautions (5.3) For metformin, the most common reactions are diarrhea.',
        ),
        'Hypoglycemia For metformin, the most common reactions are diarrhea.',
      );
    });

    test('bullets become dashes, spaces are collapsed', () {
      expect(FdaTextCleaner.clean('A • one   • two'), 'A - one - two');
    });

    test('long text is cut at a sentence end', () {
      final long = '${'This is a sentence about safety. ' * 60}tail';
      final out = FdaTextCleaner.clean(long, maxChars: 100);
      expect(out.length, lessThanOrEqualTo(100));
      expect(out.endsWith('.'), isTrue);
    });

    test('long text without sentence ends is cut at a word with …', () {
      final out = FdaTextCleaner.clean('word ' * 100, maxChars: 50);
      expect(out.length, lessThanOrEqualTo(51));
      expect(out.endsWith('…'), isTrue);
    });
  });

  group('FdaQuery', () {
    test('generic name from a catalogue name', () {
      expect(FdaQuery.genericName('Metformin 500 MG Oral Tablet'), 'metformin');
      expect(
        FdaQuery.genericName('Amoxicillin / Clavulanate 875 MG'),
        'amoxicillin clavulanate',
      );
      expect(FdaQuery.genericName('Aspirin (Ecotrin) 81 mg'), 'aspirin');
    });

    test('nothing left -> null', () {
      expect(FdaQuery.genericName(null), isNull);
      expect(FdaQuery.genericName('500 mg tablet'), isNull);
      expect(FdaQuery.genericName('   '), isNull);
    });

    test('a hostile name cannot add anything to the query', () {
      final n = FdaQuery.genericName('x" OR openfda.rxcui:"1');
      expect(n, isNot(contains('"')));
      expect(n, isNot(contains(':')));
    });

    test('ingredient key ignores salts, strengths, forms and order', () {
      expect(FdaQuery.ingredientKey('METFORMIN HYDROCHLORIDE'), 'metformin');
      expect(
        FdaQuery.ingredientKey('Metformin 500 MG Oral Tablet'),
        'metformin',
      );
      expect(
        FdaQuery.ingredientKey('Sitagliptin And Metformin Hydrochloride'),
        'metformin sitagliptin',
      );
      expect(
        FdaQuery.ingredientKey('Amoxicillin and Clavulanate Potassium'),
        FdaQuery.ingredientKey('clavulanate amoxicillin'),
      );
      expect(FdaQuery.ingredientKey(null), isNull);
    });

    test('a single ingredient search leaves out combination products', () {
      expect(
        FdaQuery.searchByName('metformin'),
        'openfda.generic_name:"metformin" AND NOT openfda.generic_name:and',
      );
      expect(
        FdaQuery.searchByName('amoxicillin clavulanate'),
        'openfda.generic_name:"amoxicillin clavulanate"',
      );
    });

    test('rxcui must be digits only', () {
      expect(FdaQuery.rxcui('860975'), '860975');
      expect(FdaQuery.rxcui(' 6809 '), '6809');
      expect(FdaQuery.rxcui('12;DROP'), isNull);
      expect(FdaQuery.rxcui('"1"'), isNull);
      expect(FdaQuery.rxcui(''), isNull);
      expect(FdaQuery.rxcui(null), isNull);
    });
  });

  group('FdaLabel.fromOpenFda (real openFDA shape)', () {
    late FdaLabel label;
    setUp(() {
      final json = jsonDecode(fixture()) as Map<String, dynamic>;
      label = FdaLabel.fromOpenFda(
        (json['results'] as List).first as Map<String, dynamic>,
      )!;
    });

    test('keeps the allowed sections', () {
      expect(
        label.sections.keys,
        containsAll([
          FdaLabelSection.indications,
          FdaLabelSection.contraindications,
          FdaLabelSection.warnings,
          FdaLabelSection.adverseReactions,
          FdaLabelSection.interactions,
          FdaLabelSection.boxedWarning,
        ]),
      );
    });

    test('NEVER includes the dosage section', () {
      final all = label.sections.values.join(' ').toLowerCase();
      expect(all, isNot(contains('recommended dosage')));
      expect(all, isNot(contains('dosage and administration')));
      for (final s in FdaLabelSection.values) {
        expect(s.fieldKeys, isNot(contains('dosage_and_administration')));
      }
    });

    test('storage falls back to how_supplied', () {
      expect(label.sections.containsKey(FdaLabelSection.storage), isTrue);
    });

    test('text is cleaned and short', () {
      for (final t in label.sections.values) {
        expect(t.length, lessThanOrEqualTo(FdaTextCleaner.defaultMaxChars + 1));
        expect(t, isNot(contains('�')));
        expect(t, isNot(contains('N/A')));
      }
      expect(
        label.sections[FdaLabelSection.indications],
        isNot(startsWith('1 ')),
      );
    });

    test('names, date and source link', () {
      expect(label.genericName, isNotNull);
      expect(label.effectiveDate, DateTime(2026, 9, 9));
      expect(
        label.sourceUrl,
        contains('setid=05999192-ebc6-4198-bd1e-f46abbfb4f8a'),
      );
      expect(label.citation, startsWith('FDA drug label (openFDA)'));
      expect(label.citation, contains('2026-09-09'));
    });

    test('prompt text has the facts and the source', () {
      final t = label.toPromptText();
      expect(t, contains('Side effects:'));
      expect(t, contains('Source: https://dailymed.nlm.nih.gov'));
      final only = label.toPromptText(only: {FdaLabelSection.indications});
      expect(only, contains('What it is used for:'));
      expect(only, isNot(contains('Side effects:')));
    });

    test('survives a JSON round trip (cache)', () {
      final again = FdaLabel.fromJson(
        jsonDecode(jsonEncode(label.toJson())) as Map<String, dynamic>,
      );
      expect(again.sections, label.sections);
      expect(again.setId, label.setId);
      expect(again.effectiveDate, label.effectiveDate);
    });

    test('a result with no usable section gives null', () {
      expect(FdaLabel.fromOpenFda({'set_id': 'x'}), isNull);
      expect(
        FdaLabel.fromOpenFda({
          'dosage_and_administration': ['only dosing text'],
        }),
        isNull,
      );
    });
  });

  group('FdaLabelClient', () {
    test('finds a label by rxcui with one request', () async {
      final calls = Calls();
      final c = clientWith(calls, (_) => ok(fixture()));
      final r = await c.lookup(rxcui: '860975', name: 'Metformin 500 MG');
      expect(r, isA<FdaLabelFound>());
      expect(calls.uris.length, 1);
      expect(calls.uris.single.host, 'api.fda.gov');
      expect(
        calls.uris.single.queryParameters['search'],
        'openfda.rxcui:"860975"',
      );
    });

    test(
      'falls back to the generic name when the rxcui has no label',
      () async {
        final calls = Calls();
        final c = clientWith(calls, (uri) {
          return uri.queryParameters['search']!.startsWith('openfda.rxcui')
              ? http.Response(notFoundBody, 404)
              : ok(fixture());
        });
        final r = await c.lookup(rxcui: '6809', name: 'Metformin');
        expect(r, isA<FdaLabelFound>());
        expect(calls.uris.length, 2);
        expect(
          calls.uris.last.queryParameters['search'],
          'openfda.generic_name:"metformin" AND NOT openfda.generic_name:and',
        );
      },
    );

    test(
      'by name, a combination product is NOT used for a single medicine',
      () async {
        final json = jsonDecode(fixture()) as Map<String, dynamic>;
        final combo = Map<String, dynamic>.from(
          (json['results'] as List).first as Map,
        );
        combo['openfda'] = {
          'generic_name': ['SITAGLIPTIN AND METFORMIN HYDROCHLORIDE'],
        };
        final body = jsonEncode({
          'results': [combo],
        });
        final c = clientWith(Calls(), (_) => ok(body));
        expect(await c.lookup(name: 'Metformin'), isA<FdaLabelNotFound>());
      },
    );

    test('by rxcui the label is exact, whatever its name', () async {
      final json = jsonDecode(fixture()) as Map<String, dynamic>;
      final combo = Map<String, dynamic>.from(
        (json['results'] as List).first as Map,
      );
      combo['openfda'] = {
        'generic_name': ['SITAGLIPTIN AND METFORMIN HYDROCHLORIDE'],
      };
      final body = jsonEncode({
        'results': [combo],
      });
      final c = clientWith(Calls(), (_) => ok(body));
      expect(
        await c.lookup(rxcui: '861002', name: 'Sitagliptin Metformin'),
        isA<FdaLabelFound>(),
      );
    });

    test(
      'a salt in the label name still matches (metformin hydrochloride)',
      () async {
        final json = jsonDecode(fixture()) as Map<String, dynamic>;
        final salt = Map<String, dynamic>.from(
          (json['results'] as List).first as Map,
        );
        salt['openfda'] = {
          'generic_name': ['METFORMIN HYDROCHLORIDE'],
        };
        final body = jsonEncode({
          'results': [salt],
        });
        final c = clientWith(Calls(), (_) => ok(body));
        expect(await c.lookup(name: 'Metformin 500 MG'), isA<FdaLabelFound>());
      },
    );

    test('nothing found anywhere -> notFound', () async {
      final c = clientWith(Calls(), (_) => http.Response(notFoundBody, 404));
      expect(
        await c.lookup(rxcui: '1', name: 'Nodrug'),
        isA<FdaLabelNotFound>(),
      );
    });

    test('no id and no usable name -> notFound without any request', () async {
      final calls = Calls();
      final c = clientWith(calls, (_) => ok(fixture()));
      expect(await c.lookup(name: '500 mg'), isA<FdaLabelNotFound>());
      expect(await c.lookup(), isA<FdaLabelNotFound>());
      expect(calls.uris, isEmpty);
    });

    test(
      'rate limit, server error, bad JSON and network error are unavailable',
      () async {
        for (final answer in <http.Response Function(Uri)>[
          (_) => http.Response('{}', 429),
          (_) => http.Response('oops', 503),
          (_) => ok('not json'),
          (_) => ok('[1,2]'),
        ]) {
          final c = clientWith(Calls(), answer);
          expect(await c.lookup(name: 'metformin'), isA<FdaLabelUnavailable>());
        }

        final broken = FdaLabelClient(
          client: MockClient(
            (_) async => throw const SocketException('offline'),
          ),
        );
        final r = await broken.lookup(name: 'metformin');
        expect(r, isA<FdaLabelUnavailable>());
        expect((r as FdaLabelUnavailable).reason, 'network');
      },
    );

    test('a slow answer times out as unavailable', () async {
      final c = FdaLabelClient(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return ok(fixture());
        }),
        timeout: const Duration(milliseconds: 50),
      );
      final r = await c.lookup(name: 'metformin');
      expect(r, isA<FdaLabelUnavailable>());
      expect((r as FdaLabelUnavailable).reason, 'timeout');
    });

    test('an unavailable answer is not cached', () async {
      var fail = true;
      final calls = Calls();
      final c = clientWith(
        calls,
        (_) => fail ? http.Response('x', 503) : ok(fixture()),
      );
      expect(await c.lookup(name: 'metformin'), isA<FdaLabelUnavailable>());
      fail = false;
      expect(await c.lookup(name: 'metformin'), isA<FdaLabelFound>());
      expect(calls.uris.length, 2);
    });

    test('a found label is cached for 7 days', () async {
      final calls = Calls();
      var now = DateTime(2026, 11, 16);
      final c = clientWith(calls, (_) => ok(fixture()), clock: () => now);

      await c.lookup(rxcui: '860975', name: 'Metformin');
      await c.lookup(rxcui: '860975', name: 'Metformin');
      expect(calls.uris.length, 1);

      now = now.add(const Duration(days: 6));
      await c.lookup(rxcui: '860975', name: 'Metformin');
      expect(calls.uris.length, 1);

      now = now.add(const Duration(days: 2));
      await c.lookup(rxcui: '860975', name: 'Metformin');
      expect(calls.uris.length, 2);
    });

    test('"no label" is remembered for a day only', () async {
      final calls = Calls();
      var now = DateTime(2026, 11, 16);
      final c = clientWith(
        calls,
        (_) => http.Response(notFoundBody, 404),
        clock: () => now,
      );
      await c.lookup(name: 'nodrug');
      await c.lookup(name: 'nodrug');
      expect(calls.uris.length, 1);

      now = now.add(const Duration(days: 2));
      await c.lookup(name: 'nodrug');
      expect(calls.uris.length, 2);
    });

    test('the fullest of several labels is used', () async {
      final json = jsonDecode(fixture()) as Map<String, dynamic>;
      final full = (json['results'] as List).first as Map<String, dynamic>;
      final thin = <String, dynamic>{
        'set_id': 'thin',
        'indications_and_usage': ['1 INDICATIONS AND USAGE Short label.'],
      };
      final body = jsonEncode({
        'results': [thin, full],
      });
      final c = clientWith(Calls(), (_) => ok(body));
      final r = await c.lookup(name: 'metformin') as FdaLabelFound;
      expect(r.label.setId, full['set_id']);
    });

    test('a broken cache never breaks the lookup', () async {
      final c = FdaLabelClient(
        client: MockClient((_) async => ok(fixture())),
        cache: _BrokenCache(),
      );
      expect(await c.lookup(name: 'metformin'), isA<FdaLabelFound>());
    });
  });
}

class _BrokenCache implements FdaLabelCache {
  @override
  Future<String?> read(String key) async => throw Exception('disk');

  @override
  Future<void> write(String key, String value) async => throw Exception('disk');
}
