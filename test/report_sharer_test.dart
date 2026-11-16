import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/report_sharer.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('sharer_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('pdfName swaps the extension', () {
    expect(
      ReportSharer.pdfName('medremind-report_a_b.csv'),
      'medremind-report_a_b.pdf',
    );
    expect(ReportSharer.pdfName('x'), 'x.pdf');
  });

  test('safeName strips unsafe characters', () {
    expect(ReportSharer.safeName('a/b\\c d.pdf'), 'a_b_c_d.pdf');
  });

  test('writes the file, shares it and deletes it', () async {
    String? seenPath;
    List<int>? seenBytes;
    String? seenMime;
    final s = ReportSharer(
      tempDir: () async => dir,
      share: (p, m, subj) async {
        seenPath = p;
        seenMime = m;
        seenBytes = File(p).readAsBytesSync();
      },
    );
    await s.sharePdf(
      Uint8List.fromList([1, 2, 3]),
      fileName: 'r.pdf',
      subject: 's',
    );
    expect(seenBytes, [1, 2, 3]);
    expect(seenMime, 'application/pdf');
    expect(File(seenPath!).existsSync(), isFalse);
  });

  test('csv uses the csv mime type', () async {
    String? mime;
    final s = ReportSharer(
      tempDir: () async => dir,
      share: (p, m, subj) async => mime = m,
    );
    await s.shareCsv(Uint8List(1), fileName: 'r.csv', subject: 's');
    expect(mime, 'text/csv');
  });

  test('the file is deleted even when sharing fails', () async {
    String? path;
    final s = ReportSharer(
      tempDir: () async => dir,
      share: (p, m, subj) async {
        path = p;
        throw Exception('no app');
      },
    );
    await expectLater(
      s.sharePdf(Uint8List(1), fileName: 'r.pdf', subject: 's'),
      throwsException,
    );
    expect(File(path!).existsSync(), isFalse);
  });
}
