import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'export_builder.dart';

/// Packs [ExportFile]s into a ZIP (M14 step 3). Text is stored as UTF-8 with
/// a leading BOM on CSV files so Excel reads non-Latin text correctly.
class ExportZip {
  ExportZip._();

  static Uint8List encode(List<ExportFile> files) {
    final archive = Archive();
    for (final f in files) {
      List<int> bytes = utf8.encode(f.content);
      if (f.name.endsWith('.csv')) {
        bytes = [0xEF, 0xBB, 0xBF, ...bytes];
      }
      archive.addFile(ArchiveFile.bytes(f.name, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// `medremind-export-20261113-0905.zip` (UTC).
  static String fileName(DateTime now) {
    final u = now.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'medremind-export-${u.year}${two(u.month)}${two(u.day)}-'
        '${two(u.hour)}${two(u.minute)}.zip';
  }
}
