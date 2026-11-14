import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/vitals/vital_models.dart';
import '../core/vitals/vital_summary.dart';
import '../core/vitals/vital_types.dart';
import '../core/vitals/vital_validator.dart';

/// Result of [FirebaseVitalsRepository.importSynced].
class SyncResult {
  const SyncResult({
    required this.written,
    required this.skippedExisting,
    required this.duplicatesInBatch,
    required this.rejected,
  });

  final int written;
  final int skippedExisting;
  final int duplicatesInBatch;
  final int rejected;
}

/// ============================================================
/// FIREBASE VITALS REPOSITORY — M15 step 3
///
/// Firestore paths (memberId == profile id):
///   profiles/{memberId}/vitals/{id}                  one reading
///   profiles/{memberId}/vitalsDaily/{type}_{day}     avg / min / max per day
///
/// Spark plan: no Cloud Function maintains `vitalsDaily`, so this repository
/// recomputes the affected day after every write.
///
/// Rules never allow a recorded reading to be changed (only its note), so
/// health-sync imports skip ids that already exist (see [VitalSyncPlanner]).
///
/// Needs the composite index vitals(type ASC, measuredAt DESC) from
/// firestore.indexes.json for [list] / [latest].
///
/// All methods throw [AppException].
/// ============================================================
class FirebaseVitalsRepository {
  static final FirebaseVitalsRepository instance = FirebaseVitalsRepository._();
  FirebaseVitalsRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const int _whereInLimit = 30;
  static const int _batchLimit = 400;

  CollectionReference<Map<String, dynamic>> _vitals(String memberId) =>
      _db.collection('profiles').doc(memberId).collection('vitals');

  CollectionReference<Map<String, dynamic>> _daily(String memberId) =>
      _db.collection('profiles').doc(memberId).collection('vitalsDaily');

  String _uid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw AppException.permission('Not signed in');
    return uid;
  }

  // ─────────────────────────────────────────────────────────
  // Manual entry
  // ─────────────────────────────────────────────────────────

  /// Saves a manual reading and refreshes that day's summary. Returns the
  /// saved reading (with its id).
  Future<VitalReading> addManual(String memberId, VitalReading reading) async {
    final uid = _uid();

    final check = VitalValidator.validate(
      reading.kind,
      reading.value,
      value2: reading.value2,
      pulse: reading.pulse,
      measuredAt: reading.measuredAt,
    );
    if (!check.isValid) {
      throw AppException.validation('Invalid reading: ${check.error}');
    }

    try {
      final ref = _vitals(memberId).doc();
      await ref.set({
        ...reading.toCreateMap(),
        'source': VitalSource.manual.wireName,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _recomputeDaySafely(
        memberId,
        reading.kind,
        VitalAnalysis.dayKey(reading.measuredAt.toLocal()),
      );
      return reading.copyWith(id: ref.id);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Health sync import
  // ─────────────────────────────────────────────────────────

  /// Imports readings from HealthKit / Health Connect without duplicates:
  /// ids that already exist are skipped, invalid readings are counted as
  /// rejected, and the daily summaries of the days that changed are rebuilt.
  Future<SyncResult> importSynced(
    String memberId,
    List<VitalReading> readings,
  ) async {
    final uid = _uid();
    if (readings.isEmpty) {
      return const SyncResult(
        written: 0,
        skippedExisting: 0,
        duplicatesInBatch: 0,
        rejected: 0,
      );
    }

    try {
      // First plan without knowing what exists, to learn the ids to check.
      final firstPass = VitalSyncPlanner.plan(readings, const {});
      final existing = await _existingIds(memberId, [
        for (final r in firstPass.toWrite) r.id!,
      ]);
      final plan = VitalSyncPlanner.plan(readings, existing);

      var written = 0;
      var racedExisting = 0;
      for (var i = 0; i < plan.toWrite.length; i += _batchLimit) {
        final chunk = plan.toWrite.skip(i).take(_batchLimit).toList();
        try {
          final batch = _db.batch();
          for (final r in chunk) {
            batch.set(_vitals(memberId).doc(r.id), _syncMap(r, uid));
          }
          await batch.commit();
          written += chunk.length;
        } on FirebaseException catch (e) {
          // Something in the batch already existed (another device synced at
          // the same time): fall back to one by one and skip the existing.
          debugPrint('Vitals sync batch failed (${e.code}); retrying singly');
          for (final r in chunk) {
            try {
              await _vitals(memberId).doc(r.id).set(_syncMap(r, uid));
              written++;
            } on FirebaseException catch (single) {
              if (single.code == 'permission-denied') {
                racedExisting++;
              } else {
                rethrow;
              }
            }
          }
        }
      }

      for (final key in plan.affectedDays) {
        final parts = key.split('|');
        final kind = VitalKind.fromWire(parts.first);
        if (kind != null) {
          await _recomputeDaySafely(memberId, kind, parts.last);
        }
      }

      return SyncResult(
        written: written,
        skippedExisting: plan.skippedExisting + racedExisting,
        duplicatesInBatch: plan.duplicatesInBatch,
        rejected: plan.rejected.length,
      );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  Map<String, Object?> _syncMap(VitalReading r, String uid) => {
    ...r.toCreateMap(),
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Future<Set<String>> _existingIds(String memberId, List<String> ids) async {
    final found = <String>{};
    for (var i = 0; i < ids.length; i += _whereInLimit) {
      final chunk = ids.skip(i).take(_whereInLimit).toList();
      final snap = await _vitals(memberId)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      found.addAll(snap.docs.map((d) => d.id));
    }
    return found;
  }

  // ─────────────────────────────────────────────────────────
  // Reading
  // ─────────────────────────────────────────────────────────

  /// Readings of one kind, newest first. [since] limits how far back.
  Future<List<VitalReading>> list(
    String memberId,
    VitalKind kind, {
    DateTime? since,
    int limit = 500,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _vitals(memberId)
          .where('type', isEqualTo: kind.wireName);
      if (since != null) {
        q = q.where('measuredAt', isGreaterThanOrEqualTo: since);
      }
      final snap = await q
          .orderBy('measuredAt', descending: true)
          .limit(limit)
          .get();
      return _parse(snap.docs);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Newest reading of [kind], or null.
  Future<VitalReading?> latest(String memberId, VitalKind kind) async {
    final items = await list(memberId, kind, limit: 1);
    return items.isEmpty ? null : items.first;
  }

  /// Daily summaries (oldest first) for [kind] between two local dates.
  /// Reads at most one small document per day.
  Future<List<VitalDaily>> dailySummaries(
    String memberId,
    VitalKind kind, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final start = '${kind.wireName}_${VitalAnalysis.dayKey(from.toLocal())}';
      final end = '${kind.wireName}_${VitalAnalysis.dayKey(to.toLocal())}';
      final snap = await _daily(memberId)
          .orderBy(FieldPath.documentId)
          .startAt([start])
          .endAt([end])
          .get();

      final out = <VitalDaily>[];
      for (final d in snap.docs) {
        final data = d.data();
        final day = data['day'];
        final count = data['count'];
        final avg = data['avg'];
        final min = data['min'];
        final max = data['max'];
        if (day is! String ||
            count is! num ||
            avg is! num ||
            min is! num ||
            max is! num) {
          continue;
        }
        final a2 = data['avg2'];
        final n2 = data['min2'];
        final x2 = data['max2'];
        out.add(
          VitalDaily(
            dayKey: day,
            count: count.toInt(),
            avg: avg.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            avg2: a2 is num ? a2.toDouble() : null,
            min2: n2 is num ? n2.toDouble() : null,
            max2: x2 is num ? x2.toDouble() : null,
          ),
        );
      }
      return out;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Change / delete
  // ─────────────────────────────────────────────────────────

  /// Only the note of a recorded reading can change.
  Future<void> updateNote(String memberId, String id, String? note) async {
    _uid();
    final n = note?.trim() ?? '';
    if (n.length > 500) {
      throw AppException.validation('Note is too long (max 500 characters)');
    }
    try {
      await _vitals(memberId)
          .doc(id)
          .update({'note': n.isEmpty ? FieldValue.delete() : n});
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Deletes a reading and refreshes that day's summary.
  Future<void> delete(String memberId, VitalReading reading) async {
    _uid();
    final id = reading.id;
    if (id == null) throw AppException.validation('Reading has no id');
    try {
      await _vitals(memberId).doc(id).delete();
      await _recomputeDaySafely(
        memberId,
        reading.kind,
        VitalAnalysis.dayKey(reading.measuredAt.toLocal()),
      );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Daily summary
  // ─────────────────────────────────────────────────────────

  /// Rebuilds `vitalsDaily/{kind}_{dayKey}` from that day's raw readings; the
  /// summary is removed when the day has no readings left.
  Future<void> recomputeDay(
    String memberId,
    VitalKind kind,
    String dayKey,
  ) async {
    final bounds = VitalAnalysis.dayBounds(dayKey);
    if (bounds == null) return;

    // Range on measuredAt only (no composite index needed); filter the kind
    // here — one day holds only a handful of readings.
    final snap = await _vitals(memberId)
        .where('measuredAt', isGreaterThanOrEqualTo: bounds.start)
        .where('measuredAt', isLessThan: bounds.end)
        .get();

    final points = [
      for (final r in _parse(snap.docs))
        if (r.kind == kind) r.toPoint(),
    ];
    final docRef = _daily(memberId).doc('${kind.wireName}_$dayKey');

    final summaries = VitalAnalysis.dailySummaries(points);
    if (summaries.isEmpty) {
      await docRef.delete();
      return;
    }
    await docRef.set({
      ...summaries.first.toMap(kind),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// A failed summary refresh must never turn a saved reading into an error:
  /// the reading is safe, and the summary is rebuilt on the next write.
  Future<void> _recomputeDaySafely(
    String memberId,
    VitalKind kind,
    String dayKey,
  ) async {
    try {
      await recomputeDay(memberId, kind, dayKey);
    } catch (e) {
      debugPrint('Vitals: daily summary refresh failed ($dayKey) — $e');
    }
  }

  // ─────────────────────────────────────────────────────────

  List<VitalReading> _parse(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final out = <VitalReading>[];
    for (final d in docs) {
      final data = Map<String, dynamic>.from(d.data());
      final at = data['measuredAt'];
      if (at is Timestamp) data['measuredAt'] = at.toDate();
      final r = VitalReading.fromMap(d.id, data);
      if (r != null) out.add(r);
    }
    return out;
  }
}
