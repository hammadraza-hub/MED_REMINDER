import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../core/dose_engine.dart';
import '../core/services/reminder_scheduler.dart';
import '../models/dose.dart';
import '../models/medication.dart';
import '../repositories/firebase_inventory_repository.dart';

/// Dose Repository — dose logging, snooze, undo, PRN, and adherence.
///
/// M7 — Dose Logging, Adherence & Calendar
///
/// Per M7 plan:
///   • Logging: {status: taken|skipped, loggedAt, loggedBy, reasonCode?, reasonText?}
///   • PRN: create dose with status taken (id {medId}_prn_{timestamp})
///   • Snooze: updates snoozedUntil + missDeadline (capped at 2h after scheduledAt)
///   • Undo: taken/skipped → pending within 24h
///   • Adherence: taken ÷ (taken + skipped + missed), PRN never counts
///   • Calendar: dayStatus = taken/missed/partial
///
/// Client-side daily summaries + adherence (Phase A — Spark plan).
/// When Blaze is enabled, onDoseWritten trigger auto-maintains these.
class DoseRepository {
  final FirebaseFirestore _db;

  static DoseRepository? _instance;
  static DoseRepository get instance =>
      _instance ??= DoseRepository._(FirebaseFirestore.instance);

  DoseRepository._(this._db);

  CollectionReference<Map<String, dynamic>> _dosesRef(String profileId) {
    return _db.collection('profiles').doc(profileId).collection('doses');
  }

  // ──────────────────────────────────────────────────────────────
  // WATCH (Streams for real-time UI)
  // ──────────────────────────────────────────────────────────────

  /// Stream of doses for a specific day (Dashboard).
  /// Per M7: doses where scheduledAt between startOfDay and endOfDay.
  Stream<List<Dose>> watchDosesForDay(String profileId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _dosesRef(profileId)
        .where('scheduledAt', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledAt', isLessThan: endOfDay)
        .orderBy('scheduledAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Dose.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Stream of today's doses (Dashboard — live updates).
  Stream<List<Dose>> watchTodaysDoses(String profileId) {
    return watchDosesForDay(profileId, DateTime.now());
  }

  // ──────────────────────────────────────────────────────────────
  // READ (Future)
  // ──────────────────────────────────────────────────────────────
  /// Stream of doses for a date range (Calendar view — real-time).
  /// Per M7: Calendar ek hi query mein saari month/week ki doses
  /// fetch karta hai, phir har cell ke liye local compute karta hai.
  Stream<List<Dose>> watchDosesForDateRange(
    String profileId,
    DateTime from,
    DateTime to,
  ) {
    final fromUtc = DateTime(from.year, from.month, from.day).toUtc();
    final toUtc = DateTime(
      to.year,
      to.month,
      to.day,
    ).add(const Duration(days: 1)).toUtc();

    return _dosesRef(profileId)
        .where('scheduledAt', isGreaterThanOrEqualTo: fromUtc)
        .where('scheduledAt', isLessThan: toUtc)
        .orderBy('scheduledAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Dose.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Get doses for a date range (Calendar view).
  Future<List<Dose>> getDosesForDateRange(
    String profileId,
    DateTime from,
    DateTime to,
  ) async {
    final fromUtc = DateTime(from.year, from.month, from.day).toUtc();
    final toUtc = DateTime(
      to.year,
      to.month,
      to.day,
    ).add(const Duration(days: 1)).toUtc();

    final snapshot = await _dosesRef(profileId)
        .where('scheduledAt', isGreaterThanOrEqualTo: fromUtc)
        .where('scheduledAt', isLessThan: toUtc)
        .orderBy('scheduledAt')
        .get();

    return snapshot.docs
        .map((doc) => Dose.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  /// Get doses for a specific medication (Medication Detail / Adherence).
  Future<List<Dose>> getDosesForMedication(
    String profileId,
    String medicationId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _dosesRef(profileId)
        .where('medicationId', isEqualTo: medicationId);

    if (from != null) {
      query = query.where('scheduledAt', isGreaterThanOrEqualTo: from.toUtc());
    }
    if (to != null) {
      query = query.where('scheduledAt', isLessThanOrEqualTo: to.toUtc());
    }

    final snapshot = await query.orderBy('scheduledAt').get();
    return snapshot.docs
        .map((doc) => Dose.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  /// Get a single dose by ID.
  Future<Dose?> getDose(String profileId, String doseId) async {
    final doc = await _dosesRef(profileId).doc(doseId).get();
    if (!doc.exists) return null;
    return Dose.fromJson(doc.data()!, id: doc.id);
  }

  // ──────────────────────────────────────────────────────────────
  // LOG DOSE (Taken / Skipped)
  // ──────────────────────────────────────────────────────────────

  /// Log a dose as taken or skipped.
  /// Per M7: {status: taken|skipped, loggedAt, loggedBy, reasonCode?, reasonText?}
  Future<void> logDose({
    required String profileId,
    required String doseId,
    required DoseStatus status,
    required String loggedBy,
    MissedDoseReason? reasonCode,
    String? reasonText,
  }) async {
    // Validate status (must be taken or skipped for logging)
    if (status != DoseStatus.taken && status != DoseStatus.skipped) {
      throw AppException.validation('Can only log as taken or skipped');
    }

    final updateData = <String, dynamic>{
      'status': status.value,
      'loggedAt': DateTime.now().toUtc(),
      'loggedBy': loggedBy,
    };

    if (reasonCode != null) updateData['reasonCode'] = reasonCode.value;
    if (reasonText != null) updateData['reasonText'] = reasonText;

    try {
      await _dosesRef(profileId).doc(doseId).update(updateData);
      unawaited(ReminderScheduler.instance.rescheduleAll());

      // M9: Deduct stock when dose is logged as taken
      if (status == DoseStatus.taken) {
        // Fetch the dose to get its medicationId
        final doseDoc = await _dosesRef(profileId).doc(doseId).get();
        final doseData = doseDoc.data();
        final medicationId = doseData?['medicationId'] as String?;
        if (medicationId != null) {
          // Fetch the medication to get doseAmount
          final medDoc = await _db
              .collection('profiles')
              .doc(profileId)
              .collection('medications')
              .doc(medicationId)
              .get();
          final medData = medDoc.data();
          final doseAmount = (medData?['doseAmount'] as num?)?.toDouble();
          if (doseAmount != null && doseAmount > 0) {
            final FirebaseInventoryRepository inventory =
                FirebaseInventoryRepository.instance;
            await inventory.adjustQuantity(
              memberId: profileId,
              medicationId: medicationId,
              delta: (-doseAmount).toInt(), // negative = decrement stock
              reason: 'dose_taken',
              doseId: doseId,
            );
          }
        }
      }
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to log dose: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // PRN LOGGING (create + log on-demand)
  // ──────────────────────────────────────────────────────────────

  /// Create + log a PRN dose on-demand.
  /// Per M7: create dose with status taken (id {medId}_prn_{timestamp})
  Future<String> logPrnDose({
    required String profileId,
    required Medication medication,
    required String loggedBy,
    String? reasonText,
  }) async {
    final doseId = DoseEngine.generatePrnDoseId(medication.id);
    final now = DateTime.now().toUtc();

    String doseLabel;
    if (medication.doseAmount != null && medication.doseUnit != null) {
      doseLabel = 'PRN — ${medication.doseAmount} ${medication.doseUnit}';
    } else {
      doseLabel = 'PRN — ${medication.name}';
    }

    final dose = Dose(
      id: doseId,
      profileId: profileId,
      medicationId: medication.id,
      medName: medication.name,
      doseLabel: doseLabel,
      scheduledAt: now,
      missDeadline: now, // PRN has no deadline (already taken)
      status: DoseStatus.taken,
      loggedAt: now,
      loggedBy: loggedBy,
      reasonText: reasonText,
      createdAt: now,
    );

    try {
      await _dosesRef(profileId).doc(doseId).set(dose.toJson());
      return doseId;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to log PRN dose: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // SNOOZE
  // ──────────────────────────────────────────────────────────────

  /// Snooze a dose — updates snoozedUntil + pushes missDeadline back.
  /// Per M7: capped at 2h after scheduledAt.
  Future<void> snoozeDose({
    required String profileId,
    required String doseId,
    required Duration snoozeDuration,
  }) async {
    final dose = await getDose(profileId, doseId);
    if (dose == null) {
      throw AppException.notFound('Dose not found');
    }

    final snoozedUntil = DateTime.now().toUtc().add(snoozeDuration);

    // Cap missDeadline at 2h after scheduledAt
    final maxDeadline = dose.scheduledAt.add(const Duration(hours: 2));
    final newMissDeadline = snoozedUntil.isAfter(maxDeadline)
        ? maxDeadline
        : snoozedUntil;

    try {
      await _dosesRef(profileId).doc(doseId).update({
        'snoozedUntil': snoozedUntil,
        'missDeadline': newMissDeadline,
      });
      unawaited(ReminderScheduler.instance.rescheduleAll());
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to snooze dose: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // UNDO (revert to pending within 24h)
  // ──────────────────────────────────────────────────────────────

  /// Undo a logged dose — reverts status to pending.
  /// Per M7: taken/skipped → pending within 24h of loggedAt.
  Future<void> undoDose({
    required String profileId,
    required String doseId,
  }) async {
    final dose = await getDose(profileId, doseId);
    if (dose == null) {
      throw AppException.notFound('Dose not found');
    }

    if (!dose.canUndo()) {
      throw AppException.validation(
        'Cannot undo — dose must be taken/skipped within the last 24 hours',
      );
    }

    try {
      await _dosesRef(profileId).doc(doseId).update({
        'status': DoseStatus.pending.value,
        'loggedAt': null,
        'loggedBy': null,
        'reasonCode': null,
        'reasonText': null,
        'snoozedUntil': null,
      });
      unawaited(ReminderScheduler.instance.rescheduleAll());
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to undo dose: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // MISSED REASON
  // ──────────────────────────────────────────────────────────────

  // OVERDUE SWEEP (client-side — Spark has no scheduled functions)

  /// Marks pending doses whose `missDeadline` has passed as missed.
  ///
  /// Called on app start/resume. Bounded to 200 docs per run; a second run
  /// picks up the rest. `reasonCode` is left null so the UI can ask why.
  Future<int> markOverdueDosesMissed(String profileId, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).toUtc();

    try {
      final snapshot = await _dosesRef(profileId)
          .where('missDeadline', isLessThan: cutoff)
          .limit(200)
          .get();

      final overdue = snapshot.docs
          .where((doc) => doc.data()['status'] == DoseStatus.pending.value)
          .toList();
      if (overdue.isEmpty) return 0;

      final batch = _db.batch();
      for (final doc in overdue) {
        batch.update(doc.reference, {'status': DoseStatus.missed.value});
      }
      await batch.commit();
      return overdue.length;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to mark missed doses: $e');
    }
  }

  /// Update the reason for a missed/skipped dose.
  /// Per M7: reasonCode (forgot / side_effect / ran_out / other) + reasonText.
  Future<void> updateMissedReason({
    required String profileId,
    required String doseId,
    required MissedDoseReason reasonCode,
    String? reasonText,
  }) async {
    final updateData = <String, dynamic>{'reasonCode': reasonCode.value};
    if (reasonText != null) updateData['reasonText'] = reasonText;

    try {
      await _dosesRef(profileId).doc(doseId).update(updateData);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } catch (e) {
      throw AppException.unknown('Failed to update reason: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // DAILY SUMMARY (client-side — Phase A)
  // ──────────────────────────────────────────────────────────────

  /// Compute daily summary for a date (client-side).
  /// Returns counts of due, taken, skipped, missed for the day.
  /// PRN doses never count.
  Future<DailySummary> getDailySummary(String profileId, DateTime date) async {
    final doses = await getDosesForDateRange(profileId, date, date);

    int due = 0, taken = 0, skipped = 0, missed = 0;

    for (final dose in doses) {
      if (dose.isPrn) continue; // PRN never counts

      switch (dose.status) {
        case DoseStatus.pending:
          if (dose.isOverdue) {
            missed++;
          } else {
            due++;
          }
          break;
        case DoseStatus.taken:
          taken++;
          break;
        case DoseStatus.skipped:
          skipped++;
          break;
        case DoseStatus.missed:
          missed++;
          break;
        case DoseStatus.snoozed:
          due++;
          break;
      }
    }

    return DailySummary(
      date: date,
      due: due,
      taken: taken,
      skipped: skipped,
      missed: missed,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // ADHERENCE (client-side — Phase A)
  // ──────────────────────────────────────────────────────────────

  /// Get adherence percentage for a date range.
  /// Per M7: taken ÷ (taken + skipped + missed), PRN never counts.
  /// Returns percentage as a double (0.0 - 100.0).
  Future<double> getAdherencePercentage(
    String profileId,
    DateTime from,
    DateTime to,
  ) async {
    final doses = await getDosesForDateRange(profileId, from, to);

    int taken = 0, skipped = 0, missed = 0;

    for (final dose in doses) {
      if (dose.isPrn) continue; // PRN never counts

      switch (dose.status) {
        case DoseStatus.taken:
          taken++;
          break;
        case DoseStatus.skipped:
          skipped++;
          break;
        case DoseStatus.missed:
          missed++;
          break;
        default:
          break;
      }
    }

    final total = taken + skipped + missed;
    if (total == 0) return 0.0;

    return (taken / total) * 100;
  }

  /// Get adherence for last 7 days.
  Future<double> getAdherence7Days(String profileId) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 7));
    return getAdherencePercentage(profileId, from, now);
  }

  /// Get adherence for last 30 days.
  Future<double> getAdherence30Days(String profileId) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    return getAdherencePercentage(profileId, from, now);
  }

  /// Get adherence for last 90 days.
  Future<double> getAdherence90Days(String profileId) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 90));
    return getAdherencePercentage(profileId, from, now);
  }
}

/// Daily summary for a single day.
/// Per M7 calendar coloring:
///   • taken = all doses taken (green)
///   • missed = nothing taken with something missed (red)
///   • partial = anything else (yellow)
class DailySummary {
  final DateTime date;
  final int due;
  final int taken;
  final int skipped;
  final int missed;

  const DailySummary({
    required this.date,
    required this.due,
    required this.taken,
    required this.skipped,
    required this.missed,
  });

  int get total => due + taken + skipped + missed;

  /// Day status for calendar coloring.
  /// Per M7: taken = all taken, missed = nothing taken with something missed, partial = anything else.
  String get dayStatus {
    if (total == 0) return 'empty';
    if (taken > 0 && due == 0 && missed == 0) return 'taken';
    if (taken == 0 && missed > 0) return 'missed';
    return 'partial';
  }
}
