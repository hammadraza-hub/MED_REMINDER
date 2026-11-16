import 'dart:typed_data';

import 'report_builder_controller.dart';
import 'report_csv_builder.dart';
import 'report_csv_labels.dart';
import 'report_models.dart';
import 'report_pdf_builder.dart';
import 'report_pdf_fonts.dart';
import 'report_pdf_labels.dart';

/// Everything needed to make the PDF and CSV, as plain data, so it can be
/// handed to a background isolate. M17 step 5.
class ReportFilesJob {
  const ReportFilesJob({
    required this.data,
    required this.regular,
    required this.bold,
    required this.devanagari,
    required this.arabic,
    required this.csvLabels,
    required this.pdfLabels,
    required this.rtl,
  });

  final ReportData data;
  final Uint8List regular;
  final Uint8List bold;
  final Uint8List devanagari;
  final Uint8List arabic;
  final ReportCsvLabels csvLabels;
  final ReportPdfLabels pdfLabels;
  final bool rtl;
}

/// Top-level on purpose: `compute()` needs a top-level (or static) function.
Future<ReportFiles> buildReportFiles(ReportFilesJob job) async {
  ByteData bd(Uint8List b) => ByteData.sublistView(b);

  final fonts = ReportPdfFonts(
    regular: bd(job.regular),
    bold: bd(job.bold),
    devanagari: bd(job.devanagari),
    arabic: bd(job.arabic),
  );

  final pdf = await ReportPdfBuilder.build(
    job.data,
    fonts: fonts,
    labels: job.csvLabels,
    pdfLabels: job.pdfLabels,
    rtl: job.rtl,
  );
  final csv = ReportCsvBuilder.build(job.data, labels: job.csvLabels);
  return ReportFiles(pdf: pdf, csv: csv);
}
