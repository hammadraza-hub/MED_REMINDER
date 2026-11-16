import 'dart:io';
import 'dart:typed_data';

/// Shares a finished report file. M17 step 6.
///
/// The bytes are written to a temporary file, handed to the share sheet and
/// the file is deleted afterwards (also when sharing fails): a medical report
/// must not stay in the phone's cache. Folder and share sheet are injected so
/// the logic is unit-testable.
class ReportSharer {
  ReportSharer({required this.tempDir, required this.share});

  /// Folder for the temporary file.
  final Future<Directory> Function() tempDir;

  /// Opens the share sheet for a file path.
  final Future<void> Function(String path, String mimeType, String subject)
  share;

  static const String pdfMime = 'application/pdf';
  static const String csvMime = 'text/csv';

  /// `medremind-report_2026-11-10_2026-11-16.csv` → `....pdf`.
  static String pdfName(String csvName) =>
      csvName.toLowerCase().endsWith('.csv')
      ? '${csvName.substring(0, csvName.length - 4)}.pdf'
      : '$csvName.pdf';

  /// Only characters that are safe in a file name.
  static String safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  Future<void> sharePdf(
    Uint8List bytes, {
    required String fileName,
    required String subject,
  }) => _write(bytes, fileName, pdfMime, subject);

  Future<void> shareCsv(
    Uint8List bytes, {
    required String fileName,
    required String subject,
  }) => _write(bytes, fileName, csvMime, subject);

  Future<void> _write(
    Uint8List bytes,
    String fileName,
    String mime,
    String subject,
  ) async {
    final dir = await tempDir();
    final file = File('${dir.path}/${safeName(fileName)}');
    await file.writeAsBytes(bytes, flush: true);
    try {
      await share(file.path, mime, subject);
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
        // best effort
      }
    }
  }
}
