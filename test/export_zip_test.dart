import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/export/export_builder.dart';
import 'package:med_remind_app/core/export/export_zip.dart';

void main() {
  test('zip round-trips names and unicode text', () {
    final bytes = ExportZip.encode(const [
      ExportFile(name: 'user.json', content: '{"n":"दवाई — 薬"}'),
      ExportFile(name: 'profiles/p1/doses.json', content: '[]'),
    ]);
    final out = ZipDecoder().decodeBytes(bytes);
    expect(out.files.map((f) => f.name).toSet(), {
      'user.json',
      'profiles/p1/doses.json',
    });
    final user = out.files.firstWhere((f) => f.name == 'user.json');
    expect(utf8.decode(user.content as List<int>), '{"n":"दवाई — 薬"}');
  });

  test('csv files get a UTF-8 BOM, json files do not', () {
    final bytes = ExportZip.encode(const [
      ExportFile(name: 'a.csv', content: '_id\r\n'),
      ExportFile(name: 'a.json', content: '[]'),
    ]);
    final out = ZipDecoder().decodeBytes(bytes);
    final csv = out.files.firstWhere((f) => f.name == 'a.csv').content
        as List<int>;
    final json = out.files.firstWhere((f) => f.name == 'a.json').content
        as List<int>;
    expect(csv.take(3), [0xEF, 0xBB, 0xBF]);
    expect(json.first, isNot(0xEF));
  });

  test('empty file list still gives a valid zip', () {
    final out = ZipDecoder().decodeBytes(ExportZip.encode(const []));
    expect(out.files, isEmpty);
  });

  test('fileName is timestamped in UTC', () {
    expect(
      ExportZip.fileName(DateTime.utc(2026, 11, 3, 9, 5)),
      'medremind-export-20261103-0905.zip',
    );
  });
}
