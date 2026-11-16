import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Shows the finished report PDF (the bytes already made on the phone).
/// M17 step 6. Sharing is done from the Report Builder, not here.
class ReportPdfViewerScreen extends StatelessWidget {
  const ReportPdfViewerScreen({super.key, required this.pdf, this.onShare});

  final Uint8List pdf;

  /// Optional share action shown in the app bar.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.permissionsHeader,
        foregroundColor: AppColors.surface,
        title: Text(
          l10n.rptViewerTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (onShare != null)
            IconButton(
              tooltip: l10n.rptSharePdf,
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => pdf,
        useActions: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        pdfFileName: 'report.pdf',
        scrollViewDecoration: const BoxDecoration(color: AppColors.background),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.rptViewerError, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
