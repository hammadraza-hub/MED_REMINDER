import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/export/export_builder.dart';

ExportDoc doc(String path, Map<String, dynamic> data) =>
    ExportDoc(path: path, data: data);

void main() {
  group('toJson', () {
    test('sorts keys, indents, and is deterministic', () {
      final a = ExportBuilder.toJson({'b': 1, 'a': 2});
      final b = ExportBuilder.toJson({'a': 2, 'b': 1});
      expect(a, b);
      expect(a, '{\n  "a": 2,\n  "b": 1\n}');
    });

    test('DateTime becomes ISO-8601 UTC', () {
      final json = ExportBuilder.toJson({
        't': DateTime.utc(2026, 11, 13, 9, 5),
      });
      expect(jsonDecode(json)['t'], '2026-11-13T09:05:00.000Z');
    });

    test('local DateTime is converted to UTC', () {
      final local = DateTime(2026, 1, 2, 3, 4, 5);
      final json = ExportBuilder.toJson({'t': local});
      expect(jsonDecode(json)['t'], local.toUtc().toIso8601String());
    });

    test('NaN / Infinity become null instead of breaking the export', () {
      final json = ExportBuilder.toJson({
        'n': double.nan,
        'i': double.infinity,
        'ok': 1.5,
      });
      final m = jsonDecode(json) as Map;
      expect(m['n'], isNull);
      expect(m['i'], isNull);
      expect(m['ok'], 1.5);
    });

    test('nested maps/lists are normalised recursively', () {
      final json = ExportBuilder.toJson({
        'schedule': {
          'times': ['08:00', '20:00'],
          'start': DateTime.utc(2026, 1, 1),
        },
      });
      final m = jsonDecode(json) as Map;
      expect(m['schedule']['times'], ['08:00', '20:00']);
      expect(m['schedule']['start'], '2026-01-01T00:00:00.000Z');
    });

    test('unknown objects fall back to toString (never throws)', () {
      final json = ExportBuilder.toJson({'x': Object()});
      expect(jsonDecode(json)['x'], startsWith("Instance of"));
    });

    test('keeps unicode text as is', () {
      final json = ExportBuilder.toJson({'name': 'दवाई — 薬'});
      expect(jsonDecode(json)['name'], 'दवाई — 薬');
    });
  });

  group('toCsv', () {
    test('header is _id,_path plus sorted union of keys', () {
      final csv = ExportBuilder.toCsv([
        doc('doses/d1', {'b': 1, 'a': 2}),
        doc('doses/d2', {'c': 3}),
      ]);
      final lines = csv.trimRight().split('\r\n');
      expect(lines.first, '_id,_path,a,b,c');
      expect(lines[1], 'd1,doses/d1,2,1,');
      expect(lines[2], 'd2,doses/d2,,,3');
    });

    test('rows end with CRLF', () {
      final csv = ExportBuilder.toCsv([
        doc('x/1', {'a': 1}),
      ]);
      expect(csv.endsWith('\r\n'), isTrue);
      expect(csv.contains('\n') && csv.split('\r\n').length == 3, isTrue);
    });

    test('quotes cells with comma, quote or newline (RFC 4180)', () {
      final csv = ExportBuilder.toCsv([
        doc('m/1', {'n': 'a, b', 'q': 'say "hi"', 'l': 'line1\nline2'}),
      ]);
      final row = csv.trimRight().split('\r\n')[1];
      expect(row, contains('"a, b"'));
      expect(row, contains('"say ""hi"""'));
      expect(row, contains('"line1\nline2"'));
    });

    test('formula-looking text is neutralised with a leading apostrophe', () {
      final csv = ExportBuilder.toCsv([
        doc('m/1', {'a': '=SUM(A1)', 'b': '+1', 'c': '-1+1', 'd': '@cmd'}),
      ]);
      final row = csv.trimRight().split('\r\n')[1];
      expect(row, contains("'=SUM(A1)"));
      expect(row, contains("'+1"));
      expect(row, contains("'-1+1"));
      expect(row, contains("'@cmd"));
    });

    test('real negative numbers are not touched (only strings are)', () {
      final csv = ExportBuilder.toCsv([
        doc('v/1', {'delta': -5}),
      ]);
      expect(csv.trimRight().split('\r\n')[1], '1,v/1,-5');
    });

    test('bool, null, DateTime and nested values', () {
      final csv = ExportBuilder.toCsv([
        doc('m/1', {
          'active': true,
          'note': null,
          'when': DateTime.utc(2026, 5, 6),
          'schedule': {
            'times': ['08:00'],
          },
        }),
      ]);
      final row = csv.trimRight().split('\r\n')[1];
      expect(row, contains(',true,'));
      expect(row, contains('2026-05-06T00:00:00.000Z'));
      // nested map written as quoted JSON
      expect(row, contains('"{""times"":[""08:00""]}"'));
    });

    test('empty list -> header only', () {
      expect(ExportBuilder.toCsv(const []), '_id,_path\r\n');
    });

    test('nested document id is the last path segment', () {
      final csv = ExportBuilder.toCsv([
        doc('medications/m1/inventoryEvents/ev9', {'delta': -1}),
      ]);
      expect(
        csv.trimRight().split('\r\n')[1],
        startsWith('ev9,medications/m1/inventoryEvents/ev9,'),
      );
    });
  });

  group('safeName', () {
    test('keeps safe chars, replaces the rest', () {
      expect(ExportBuilder.safeName('abc_DEF-12'), 'abc_DEF-12');
      expect(ExportBuilder.safeName('../etc/passwd'), '___etc_passwd');
      expect(ExportBuilder.safeName('a b/c'), 'a_b_c');
    });

    test('empty becomes underscore', () {
      expect(ExportBuilder.safeName(''), '_');
    });
  });

  group('build', () {
    final generated = DateTime.utc(2026, 11, 13, 12);

    ExportBundle bundle({
      List<ExportProfile>? profiles,
      List<String> notes = const [],
    }) => ExportBundle(
      generatedAt: generated,
      appVersion: '1.0.0+1',
      userId: 'uid1',
      userData: {'email': 'a@b.c', 'createdAt': DateTime.utc(2026, 1, 1)},
      profiles:
          profiles ??
          [
            ExportProfile(
              profileId: 'p1',
              data: {'name': 'Self', 'kind': 'self'},
              collections: {
                'doses': [
                  doc('doses/d1', {'status': 'taken'}),
                  doc('doses/d2', {'status': 'pending'}),
                ],
                'allergies': const [],
              },
            ),
          ],
      notes: notes,
    );

    test('produces the documented file layout', () {
      final names = ExportBuilder.build(bundle()).map((f) => f.name).toList();
      expect(names, [
        'export-info.txt',
        'user.json',
        'profiles/p1/profile.json',
        'profiles/p1/allergies.json',
        'profiles/p1/allergies.csv',
        'profiles/p1/doses.json',
        'profiles/p1/doses.csv',
      ]);
    });

    test('empty collections still produce files (json [] / csv header)', () {
      final files = ExportBuilder.build(bundle());
      final json = files.firstWhere((f) => f.name.endsWith('allergies.json'));
      final csv = files.firstWhere((f) => f.name.endsWith('allergies.csv'));
      expect(jsonDecode(json.content), isEmpty);
      expect(csv.content, '_id,_path\r\n');
    });

    test('collection JSON includes each document path', () {
      final files = ExportBuilder.build(bundle());
      final json = files.firstWhere((f) => f.name.endsWith('doses.json'));
      final list = jsonDecode(json.content) as List;
      expect(list.length, 2);
      expect(list.first['_path'], 'doses/d1');
      expect(list.first['status'], 'taken');
    });

    test('info file lists counts, version and notes', () {
      final files = ExportBuilder.build(
        bundle(notes: ['vitals: not readable']),
      );
      final info = files.first.content;
      expect(info, contains('MedRemind data export'));
      expect(info, contains('2026-11-13T12:00:00.000Z'));
      expect(info, contains('1.0.0+1'));
      expect(info, contains('Profile p1 (Self)'));
      expect(info, contains('doses: 2 record(s)'));
      expect(info, contains('allergies: 0 record(s)'));
      expect(info, contains('vitals: not readable'));
    });

    test('hostile profile / collection names cannot escape the folder', () {
      final files = ExportBuilder.build(
        bundle(
          profiles: [
            ExportProfile(
              profileId: '../../evil',
              data: const {},
              collections: {
                '../x': [
                  doc('a/1', {'k': 1}),
                ],
              },
            ),
          ],
        ),
      );
      for (final f in files) {
        expect(f.name.contains('..'), isFalse, reason: f.name);
        expect(f.name.startsWith('/'), isFalse);
      }
    });

    test('colliding sanitised names get a suffix instead of overwriting', () {
      final files = ExportBuilder.build(
        bundle(
          profiles: [
            ExportProfile(
              profileId: 'a b',
              data: const {},
              collections: const {},
            ),
            ExportProfile(
              profileId: 'a/b',
              data: const {},
              collections: const {},
            ),
          ],
        ),
      );
      final profileFiles = files
          .where((f) => f.name.endsWith('profile.json'))
          .map((f) => f.name);
      expect(profileFiles.toSet().length, 2);
    });

    test('no profiles -> only info and user.json', () {
      final names = ExportBuilder.build(bundle(profiles: const []))
          .map((f) => f.name)
          .toList();
      expect(names, ['export-info.txt', 'user.json']);
    });

    test('user data is exported with ISO dates', () {
      final user = ExportBuilder.build(bundle())
          .firstWhere((f) => f.name == 'user.json');
      final m = jsonDecode(user.content) as Map;
      expect(m['email'], 'a@b.c');
      expect(m['createdAt'], '2026-01-01T00:00:00.000Z');
    });
  });
}
