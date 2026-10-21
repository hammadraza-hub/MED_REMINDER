/// ============================================================
/// DOSE DOMAIN MODEL
///
/// Represents a single scheduled dose of a medication.
///
/// Firestore Path (M0 schema):
///   profiles/{memberId}/doses/{doseId}
///
/// Dose ID Format: medId_yyyyMMddHHmm
///   e.g. med123_202610211430 (medication 123, scheduled 2026-10-21 14:30)
/// ============================================================

/// Status of a scheduled dose.
enum DoseStatus {
  /// Scheduled but not yet logged.
  pending,

  /// User confirmed they took the dose.
  taken,

  /// User intentionally skipped the dose.
  skipped,

  /// User missed the dose (deadline passed without action).
  missed,
}

/// String ↔ DoseStatus conversion helpers.
extension DoseStatusX on DoseStatus {
  String get name {
    switch (this) {
      case DoseStatus.pending:
        return 'pending';
      case DoseStatus.taken:
        return 'taken';
      case DoseStatus.skipped:
        return 'skipped';
      case DoseStatus.missed:
        return 'missed';
    }
  }

  static DoseStatus fromString(String? value) {
    switch (value) {
      case 'taken':
        return DoseStatus.taken;
      case 'skipped':
        return DoseStatus.skipped;
      case 'missed':
        return DoseStatus.missed;
      case 'pending':
      default:
        return DoseStatus.pending;
    }
  }
}

/// Single dose of a medication.
class Dose {
  const Dose({
    required this.id,
    required this.memberId,
    required this.medId,
    required this.scheduledAt,
    required this.missDeadline,
    this.status = DoseStatus.pending,
    this.loggedAt,
    this.reasonCode,
  });

  /// Dose ID. Format: medId_yyyyMMddHHmm
  final String id;

  /// Parent member (profile) ID.
  final String memberId;

  /// Medication ID this dose belongs to.
  final String medId;

  /// When the dose is scheduled to be taken.
  final DateTime scheduledAt;

  /// Deadline before which the dose must be logged (else marked missed).
  final DateTime missDeadline;

  /// Current status of the dose.
  final DoseStatus status;

  /// When the dose was actually logged (taken/skipped/missed).
  /// Null if still pending.
  final DateTime? loggedAt;

  /// Optional reason code (e.g., 'side_effect', 'forgot', 'doctor_advised').
  final String? reasonCode;

  Dose copyWith({
    String? id,
    String? memberId,
    String? medId,
    DateTime? scheduledAt,
    DateTime? missDeadline,
    DoseStatus? status,
    DateTime? loggedAt,
    bool clearLoggedAt = false,
    String? reasonCode,
    bool clearReasonCode = false,
  }) {
    return Dose(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      medId: medId ?? this.medId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      missDeadline: missDeadline ?? this.missDeadline,
      status: status ?? this.status,
      loggedAt: clearLoggedAt ? null : loggedAt ?? this.loggedAt,
      reasonCode: clearReasonCode ? null : reasonCode ?? this.reasonCode,
    );
  }
}

/// ============================================================
/// DOSE REPOSITORY CONTRACT
/// ============================================================
///
/// UI/controller → Member + date-based interface.
///
/// CURRENT:
/// Local dose repository → Drift / SQLite
///
/// FUTURE:
/// FirebaseDoseRepository → Firestore
/// ============================================================
abstract class DoseRepository {
  /// Watch all doses for a specific date (realtime).
  ///
  /// Date is in user's local timezone. Implementation should
  /// normalize to start/end of day.
  Stream<List<Dose>> watchDosesForDate({
    required String memberId,
    required DateTime date,
  });

  /// Watch doses for a date range (realtime).
  /// Used by calendar view to show doses across multiple days.
  Stream<List<Dose>> watchDosesForDateRange({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// One-time fetch of doses for a specific date.
  Future<List<Dose>> getDosesForDate({
    required String memberId,
    required DateTime date,
  });

  /// Get a single dose by ID.
  Future<Dose?> getDoseById({required String memberId, required String doseId});

  /// Create or update a dose.
  /// Used by dose scheduler to generate upcoming doses.
  Future<void> saveDose(Dose dose);

  /// Log a dose — mark as taken/skipped/missed.
  ///
  /// Updates: status, loggedAt, reasonCode.
  /// Should also trigger dailySummary recalculation (M2+ via Cloud Function).
  Future<void> logDose({
    required String memberId,
    required String doseId,
    required DoseStatus status,
    String? reasonCode,
  });

  /// Generate the standard dose ID for a medication + scheduled time.
  /// Format: medId_yyyyMMddHHmm
  String generateDoseId({required String medId, required DateTime scheduledAt});
}
