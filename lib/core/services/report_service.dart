
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/report_data_wiring.dart';
import '../reports/report_builder_controller.dart';
import '../reports/report_files_builder.dart';
import '../reports/report_l10n.dart';
import '../reports/report_models.dart';
import '../reports/report_options.dart';
import '../reports/report_pdf_fonts.dart';
import '../reports/report_range.dart';

/// The real wiring of the Report Builder (M17 step 5): reads the data from
/// Firestore through the app's repositories and makes the PDF + CSV on the
/// phone, in a background isolate so a long report does not freeze the screen.
class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  List<Uint8List>? _fonts;

  Future<List<Uint8List>> _loadFonts() async {
    final cached = _fonts;
    if (cached != null) return cached;
    final loaded = <Uint8List>[];
    for (final asset in [
      ReportPdfFonts.regularAsset,
      ReportPdfFonts.boldAsset,
      ReportPdfFonts.devanagariAsset,
      ReportPdfFonts.arabicAsset,
    ]) {
      final bytes = await rootBundle.load(asset);
      loaded.add(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }
    return _fonts = loaded;
  }

  Future<ReportData> load({
    required String memberId,
    required String? profileName,
    required ReportRange range,
    required ReportOptions options,
  }) =>
      buildReportDataSource(memberId)
          .load(range: range, options: options, profileName: profileName);

  Future<ReportFiles> buildFiles({
    required ReportData data,
    required AppLocalizations l10n,
    required bool rtl,
  }) async {
    final f = await _loadFonts();
    final job = ReportFilesJob(
      data: data,
      regular: f[0],
      bold: f[1],
      devanagari: f[2],
      arabic: f[3],
      csvLabels: ReportL10n.csv(l10n),
      pdfLabels: ReportL10n.pdf(l10n),
      rtl: rtl,
    );
    return compute(buildReportFiles, job);
  }
}
