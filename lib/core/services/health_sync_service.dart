import 'package:flutter/foundation.dart';

import '../../repositories/firebase_vitals_repository.dart';
import '../vitals/health_sync_mapper.dart';
import '../vitals/vital_models.dart';
import '../vitals/vital_types.dart';

/// ============================================================
/// HEALTH SYNC SERVICE — M15 step 7
///
/// Imports blood pressure, glucose, weight and heart rate from Apple Health /
/// Health Connect into `profiles/{memberId}/vitals`, without duplicates.
///
/// Orchestration only: everything platform- or Firebase-specific is injected
/// ([HealthDataSource], [HealthSyncStateStore], the importer and the Pro check),
/// so the flow is unit-tested with fakes. The real wiring is
/// [HealthSyncService.standard] (see health_plugin_source.dart).
///
/// Health sync is a Pro feature: the Pro check runs FIRST, before the
/// platform is touched, and fails closed.
/// ============================================================
enum HealthAccess { granted, denied, unavailable }

abstract class HealthDataSource {
  VitalSource get source;

  /// Checks that the health app exists on this device and asks for read
  /// permission (the platform shows its own dialog).
  Future<HealthAccess> ensureAccess();

  /// Samples between [from] and [to], in canonical units.
  Future<List<RawHealthSample>> read(DateTime from, DateTime to);
}

abstract class HealthSyncStateStore {
  Future<DateTime?> lastSync(String memberId);
  Future<void> saveLastSync(String memberId, DateTime at);
}

enum HealthSyncOutcome {
  success,
  notPro,
  permissionDenied,
  unavailable,
  failed,
}

class HealthSyncReport {
  const HealthSyncReport(
    this.outcome, {
    this.imported = 0,
    this.skippedExisting = 0,
    this.rejected = 0,
    this.truncated = false,
  });

  final HealthSyncOutcome outcome;

  /// New readings written to Firestore.
  final int imported;

  /// Readings that were already imported earlier.
  final int skippedExisting;

  /// Readings that failed validation.
  final int rejected;

  /// More data was available than the per-sync limit.
  final bool truncated;
}

class HealthSyncService {
  HealthSyncService({
    required this.source,
    required this.store,
    required this.isPro,
    required this.importer,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final HealthDataSource source;
  final HealthSyncStateStore store;

  /// Whether the signed-in user has the Pro plan. Must fail closed.
  final Future<bool> Function() isPro;

  final Future<SyncResult> Function(String memberId, List<VitalReading> r)
  importer;
  final DateTime Function() _clock;

  /// Health Connect only lets an app read the last 30 days by default.
  static const int firstSyncDays = 30;

  /// A new sync starts a little before the last one so late-arriving data is
  /// still picked up; already imported readings are skipped by id.
  static const Duration overlap = Duration(days: 1);

  bool _running = false;

  Future<HealthSyncReport> syncNow(String memberId) async {
    if (_running) return const HealthSyncReport(HealthSyncOutcome.failed);
    _running = true;
    try {
      if (!await isPro()) {
        return const HealthSyncReport(HealthSyncOutcome.notPro);
      }

      switch (await source.ensureAccess()) {
        case HealthAccess.unavailable:
          return const HealthSyncReport(HealthSyncOutcome.unavailable);
        case HealthAccess.denied:
          return const HealthSyncReport(HealthSyncOutcome.permissionDenied);
        case HealthAccess.granted:
          break;
      }

      final now = _clock();
      final last = await store.lastSync(memberId);
      final from = last == null
          ? now.subtract(const Duration(days: firstSyncDays))
          : last.subtract(overlap);

      final samples = await source.read(from, now);
      final mapped = HealthSyncMapper.map(samples, source.source);

      var imported = 0;
      var skipped = 0;
      var rejected = 0;
      if (mapped.readings.isNotEmpty) {
        final result = await importer(memberId, mapped.readings);
        imported = result.written;
        skipped = result.skippedExisting + result.duplicatesInBatch;
        rejected = result.rejected;
      }

      // Only after a successful import, so a failure is retried from the same
      // starting point next time.
      await store.saveLastSync(memberId, now);

      return HealthSyncReport(
        HealthSyncOutcome.success,
        imported: imported,
        skippedExisting: skipped,
        rejected: rejected,
        truncated: mapped.truncated,
      );
    } catch (e) {
      debugPrint('HealthSyncService: sync failed — $e');
      return const HealthSyncReport(HealthSyncOutcome.failed);
    } finally {
      _running = false;
    }
  }
}
