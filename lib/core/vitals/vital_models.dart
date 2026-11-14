import 'vital_summary.dart';
import 'vital_types.dart';
import 'vital_units.dart';
import 'vital_validator.dart';

/// ============================================================
/// VITAL MODELS & SYNC PLANNER — M15 step 3
///
/// Pure data classes and planning logic (no Firebase imports) used by the
/// Firestore repositories, so everything here is unit-testable.
/// ============================================================

/// One reading in canonical units (`profiles/{pid}/vitals/{id}`).
class VitalReading {
  const VitalReading({
    this.id,
    required this.kind,
    required this.value,
    this.value2,
    this.pulse,
    required this.measuredAt,
    this.source = VitalSource.manual,
    this.externalId,
    this.note,
    this.createdBy,
  });

  /// Document id; null until the reading is saved (manual) or planned (sync).
  final String? id;
  final VitalKind kind;

  /// Systolic for blood pressure.
  final double value;

  /// Diastolic (blood pressure only).
  final double? value2;

  /// Optional pulse that may accompany a BP reading.
  final double? pulse;
  final DateTime measuredAt;
  final VitalSource source;

  /// Id of the reading in HealthKit / Health Connect (sync only).
  final String? externalId;
  final String? note;
  final String? createdBy;

  String get unit => kind.canonicalUnit;

  VitalPoint toPoint() =>
      VitalPoint(at: measuredAt, value: value, value2: value2);

  VitalReading copyWith({String? id}) => VitalReading(
    id: id ?? this.id,
    kind: kind,
    value: value,
    value2: value2,
    pulse: pulse,
    measuredAt: measuredAt,
    source: source,
    externalId: externalId,
    note: note,
    createdBy: createdBy,
  );

  /// Fields to write on create. The repository adds `createdBy` and
  /// `createdAt` (server time); keys match the Firestore rules whitelist.
  Map<String, Object?> toCreateMap() {
    final n = note?.trim();
    return {
      'type': kind.wireName,
      'value': value,
      if (value2 != null) 'value2': value2,
      if (pulse != null) 'pulse': pulse,
      'unit': unit,
      'measuredAt': measuredAt,
      'source': source.wireName,
      if (source.isSync && externalId != null) 'externalId': externalId,
      if (n != null && n.isNotEmpty) 'note': n,
    };
  }

  /// Parses a stored document. [data] must already contain plain Dart values
  /// (`measuredAt` as DateTime). Returns null for a document that cannot be
  /// read, so one bad document never breaks a list.
  static VitalReading? fromMap(String id, Map<String, dynamic> data) {
    final kind = VitalKind.fromWire(data['type']);
    final value = data['value'];
    final at = data['measuredAt'];
    if (kind == null || value is! num || at is! DateTime) return null;

    final v2 = data['value2'];
    final pulse = data['pulse'];
    return VitalReading(
      id: id,
      kind: kind,
      value: value.toDouble(),
      value2: v2 is num ? v2.toDouble() : null,
      pulse: pulse is num ? pulse.toDouble() : null,
      measuredAt: at,
      source: VitalSource.fromWire(data['source']) ?? VitalSource.manual,
      externalId: data['externalId'] as String?,
      note: data['note'] as String?,
      createdBy: data['createdBy'] as String?,
    );
  }
}

/// A reading that failed validation, with the reason.
class RejectedReading {
  const RejectedReading(this.reading, this.reason);

  final VitalReading reading;
  final String reason;
}

/// Result of planning a health-sync import.
class SyncPlan {
  const SyncPlan({
    required this.toWrite,
    required this.skippedExisting,
    required this.duplicatesInBatch,
    required this.rejected,
    required this.affectedDays,
  });

  /// New readings, each with its deterministic document id.
  final List<VitalReading> toWrite;

  /// Ids that already exist in Firestore (already synced earlier).
  final int skippedExisting;

  /// The same id appeared more than once in this batch.
  final int duplicatesInBatch;

  /// Not importable (invalid value, not a sync reading, ...).
  final List<RejectedReading> rejected;

  /// `kind|yyyy-MM-dd` pairs whose daily summary must be recomputed.
  final Set<String> affectedDays;
}

class VitalSyncPlanner {
  VitalSyncPlanner._();

  /// Decides what to write for a batch of readings from HealthKit / Health
  /// Connect. Firestore rules forbid updating a recorded reading, so a reading
  /// whose id already exists must be skipped, never written again.
  static SyncPlan plan(
    Iterable<VitalReading> incoming,
    Set<String> existingIds, {
    DateTime? now,
  }) {
    final toWrite = <VitalReading>[];
    final rejected = <RejectedReading>[];
    final seen = <String>{};
    final affected = <String>{};
    var skipped = 0;
    var duplicates = 0;

    for (final r in incoming) {
      if (!r.source.isSync) {
        rejected.add(RejectedReading(r, 'not a sync reading'));
        continue;
      }
      final ext = r.externalId?.trim();
      if (ext == null || ext.isEmpty) {
        rejected.add(RejectedReading(r, 'externalId missing'));
        continue;
      }

      final check = VitalValidator.validate(
        r.kind,
        r.value,
        value2: r.value2,
        pulse: r.pulse,
        measuredAt: r.measuredAt,
        now: now,
      );
      if (!check.isValid) {
        rejected.add(RejectedReading(r, check.error.toString()));
        continue;
      }

      final id = VitalUnits.documentId(r.source, ext)!;
      if (!seen.add(id)) {
        duplicates++;
        continue;
      }
      if (existingIds.contains(id)) {
        skipped++;
        continue;
      }

      toWrite.add(r.copyWith(id: id));
      affected.add(
        '${r.kind.wireName}|${VitalAnalysis.dayKey(r.measuredAt.toLocal())}',
      );
    }

    return SyncPlan(
      toWrite: toWrite,
      skippedExisting: skipped,
      duplicatesInBatch: duplicates,
      rejected: rejected,
      affectedDays: affected,
    );
  }
}
