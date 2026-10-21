import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../core/doses/dose_repository.dart';

/// ============================================================
/// FIREBASE DOSE REPOSITORY
/// ============================================================
///
/// Implements [DoseRepository] using Firestore.
///
/// Firestore Path (M0 schema):
///   profiles/{memberId}/doses/{doseId}
///
/// Dose ID Format: medId_yyyyMMddHHmm
///
/// Notes:
///   - Date queries use start-of-day and end-of-day timestamps
///     to handle timezone correctly.
///   - dailySummaries subcollection is NOT updated here — it's
///     maintained by Cloud Functions (M2+).
///
/// All methods throw [AppException] on failure.
/// ============================================================
class FirebaseDoseRepository implements DoseRepository {
  // Singleton
  static final FirebaseDoseRepository instance = FirebaseDoseRepository._();
  FirebaseDoseRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────
  // Path helper
  // ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _dosesRef(String memberId) {
    return _firestore.collection('profiles').doc(memberId).collection('doses');
  }

  // ───────────────────────────────────────────────────────────
  // Date helpers
  // ───────────────────────────────────────────────────────────

  /// Returns start of day (00:00:00) in local timezone.
  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns end of day (23:59:59.999) in local timezone.
  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // ───────────────────────────────────────────────────────────
  // Serialization helpers
  // ───────────────────────────────────────────────────────────

  Dose _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String memberId,
  }) {
    final data = doc.data() ?? {};
    return Dose(
      id: doc.id,
      memberId: memberId,
      medId: data['medId'] as String? ?? '',
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      missDeadline:
          (data['missDeadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DoseStatusX.fromString(data['status'] as String?),
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate(),
      reasonCode: data['reasonCode'] as String?,
    );
  }

  Map<String, dynamic> _toMap(Dose dose, {bool isNew = false}) {
    return {
      'id': dose.id,
      'medId': dose.medId,
      'scheduledAt': Timestamp.fromDate(dose.scheduledAt),
      'missDeadline': Timestamp.fromDate(dose.missDeadline),
      'status': dose.status.name,
      'loggedAt': dose.loggedAt != null
          ? Timestamp.fromDate(dose.loggedAt!)
          : null,
      'reasonCode': dose.reasonCode,
      'createdAt': isNew ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================
  // WATCH (realtime streams)
  // ============================================================

  @override
  Stream<List<Dose>> watchDosesForDate({
    required String memberId,
    required DateTime date,
  }) {
    try {
      final start = _startOfDay(date);
      final end = _endOfDay(date);

      return _dosesRef(memberId)
          .where(
            'scheduledAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((d) => _fromDoc(d, memberId: memberId))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Stream<List<Dose>> watchDosesForDateRange({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    try {
      final start = _startOfDay(startDate);
      final end = _endOfDay(endDate);

      return _dosesRef(memberId)
          .where(
            'scheduledAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((d) => _fromDoc(d, memberId: memberId))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ============================================================
  // GET (one-time fetches)
  // ============================================================

  @override
  Future<List<Dose>> getDosesForDate({
    required String memberId,
    required DateTime date,
  }) async {
    try {
      final start = _startOfDay(date);
      final end = _endOfDay(date);

      final snapshot = await _dosesRef(memberId)
          .where(
            'scheduledAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      return snapshot.docs.map((d) => _fromDoc(d, memberId: memberId)).toList();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<Dose?> getDoseById({
    required String memberId,
    required String doseId,
  }) async {
    try {
      final doc = await _dosesRef(memberId).doc(doseId).get();
      if (!doc.exists) return null;
      return _fromDoc(doc, memberId: memberId);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ============================================================
  // SAVE (create or update)
  // ============================================================

  @override
  Future<void> saveDose(Dose dose) async {
    try {
      // Dose ID is required — caller should use generateDoseId() first.
      if (dose.id.isEmpty) {
        throw AppException.validation(
          'Dose ID cannot be empty. Use generateDoseId() to create one.',
        );
      }

      await _dosesRef(dose.memberId)
          .doc(dose.id)
          .set(_toMap(dose, isNew: true), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown('Failed to save dose: $e', originalError: e);
    }
  }

  // ============================================================
  // LOG DOSE (mark as taken/skipped/missed)
  // ============================================================

  @override
  Future<void> logDose({
    required String memberId,
    required String doseId,
    required DoseStatus status,
    String? reasonCode,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'loggedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reasonCode != null) {
        updateData['reasonCode'] = reasonCode;
      }

      await _dosesRef(memberId).doc(doseId).update(updateData);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown('Failed to log dose: $e', originalError: e);
    }
  }

  // ============================================================
  // GENERATE DOSE ID
  // ============================================================

  @override
  String generateDoseId({
    required String medId,
    required DateTime scheduledAt,
  }) {
    // Format: medId_yyyyMMddHHmm
    final year = scheduledAt.year.toString().padLeft(4, '0');
    final month = scheduledAt.month.toString().padLeft(2, '0');
    final day = scheduledAt.day.toString().padLeft(2, '0');
    final hour = scheduledAt.hour.toString().padLeft(2, '0');
    final minute = scheduledAt.minute.toString().padLeft(2, '0');

    return '${medId}_${year}${month}${day}${hour}${minute}';
  }
}
