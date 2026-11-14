import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_info_service.dart';
import 'export_builder.dart';
import 'export_collector.dart';
import 'export_data_source.dart';
import 'export_zip.dart';

/// Thrown when there is no signed-in user.
class ExportNotSignedInException implements Exception {
  @override
  String toString() => 'ExportNotSignedInException';
}

/// Runs the whole export on the device (Spark plan: no server): read data ->
/// build files -> ZIP -> temp file -> share sheet. The temp file is deleted
/// afterwards because it holds health data.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Builds the ZIP and writes it to a temp file. Returns the file.
  Future<File> createExportFile({
    void Function(String step)? onProgress,
    ExportDataSource? source,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw ExportNotSignedInException();

    final info = AppInfoService.instance;
    await info.initialize();
    final bundle = await ExportCollector(source ?? FirestoreExportSource())
        .collect(
          uid: uid,
          appVersion: '${info.version}+${info.buildNumber}',
          onProgress: onProgress,
        );
    final files = ExportBuilder.build(bundle);
    final bytes = ExportZip.encode(files);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${ExportZip.fileName(bundle.generatedAt)}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Opens the share sheet for [file], then deletes it.
  Future<void> shareAndCleanUp(File file, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: subject),
      );
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('ExportService: temp file cleanup failed — $e');
      }
    }
  }
}
