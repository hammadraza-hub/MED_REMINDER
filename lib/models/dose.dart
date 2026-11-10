import 'package:cloud_firestore/cloud_firestore.dart';

/// Dose model — represents a single scheduled dose of a medication.
///
/// M6 (dose generation) + M7 (dose logging)
///
/// Per M7 plan:
///   • Dose fields: medicationId, medName, doseLabel, scheduledAt,
///     missDeadline, status: pending
///   • Logging: {status: taken|skipped, loggedAt, loggedBy, reasonCode?, reasonText?}
///   • Snooze: updates snoozedUntil + missDeadline (capped at 2h after scheduledAt)
///   • PRN doses: created with status taken (id {medId}_prn_{timestamp})
///   • Undo: taken/skipped → pending within 24h
///
/// Deterministic ID: {medId}_{yyyyMMddHHmm} — prevents duplicates on regenerate.
/// PRN ID: {medId}_prn_{timestamp} — unique per PRN log.
class Dose {
  /// Firestore document ID.
  /// Format: {medId}_{yyyyMMddHHmm} for scheduled doses
  ///         {medId}_prn_{timestamp} for PRN doses
  final String id;

  /// Parent profile ID (profiles/{profileId}/doses/{doseId})
  final String profileId;

  /// Reference to the medication this dose belongs to.
  final String medicationId;

  /// Medication name copied onto the dose (Firestore has no joins).
  /// Dashboard reads only doses — no need to fetch medication.
  final String medName;

  /// Display label for the dose (e.g., "1 tablet at 08:00").
  final String? doseLabel;

  /// When the dose should be taken (UTC Timestamp).
  final DateTime scheduledAt;

  /// Deadline before the dose is marked as missed.
  /// = scheduledAt + missedAfterMin (from profile).
  final DateTime missDeadline;

  /// Current status of the dose.
  final DoseStatus status;

  /// When the dose was logged (taken/skipped). Null if pending.
  final DateTime? loggedAt;

  /// Who logged the dose (user UID). Null if pending.
  final String? loggedBy;

  /// Reason code for missed/skipped doses.
  final MissedDoseReason? reasonCode;

  /// Free-text reason for missing/skipping.
  final String? reasonText;

  /// Snooze: dose is delayed until this time. Null if not snoozed.
  /// missDeadline is pushed back accordingly (max 2h after scheduledAt).
  final DateTime? snoozedUntil;

  /// Audit: when this dose document was created.
  final DateTime createdAt;

  const Dose({
    required this.id,
    required this.profileId,
    required this.medicationId,
    required this.medName,
    this.doseLabel,
    required this.scheduledAt,
    required this.missDeadline,
    this.status = DoseStatus.pending,
    this.loggedAt,
    this.loggedBy,
    this.reasonCode,
    this.reasonText,
    this.snoozedUntil,
    required this.createdAt,
  });

  // ──────────────────────────────────────────────────────────────
  // SERIALIZATION
  // ──────────────────────────────────────────────────────────────

  factory Dose.fromJson(Map<String, dynamic> json, {String? id}) {
    return Dose(
      id: id ?? json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      medicationId: json['medicationId'] as String? ?? '',
      medName: json['medName'] as String? ?? '',
      doseLabel: json['doseLabel'] as String?,
      scheduledAt: _parseDateTime(json['scheduledAt']) ?? DateTime.now(),
      missDeadline: _parseDateTime(json['missDeadline']) ?? DateTime.now(),
      status: DoseStatus.fromString(json['status'] as String? ?? 'pending'),
      loggedAt: _parseDateTime(json['loggedAt']),
      loggedBy: json['loggedBy'] as String?,
      reasonCode: json['reasonCode'] != null
          ? MissedDoseReason.fromString(json['reasonCode'] as String)
          : null,
      reasonText: json['reasonText'] as String?,
      snoozedUntil: _parseDateTime(json['snoozedUntil']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  /// Full JSON — used for reads and dose generation (create).
  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'medicationId': medicationId,
      'medName': medName,
      'doseLabel': doseLabel,
      'scheduledAt': scheduledAt,
      'missDeadline': missDeadline,
      'status': status.value,
      'loggedAt': loggedAt,
      'loggedBy': loggedBy,
      'reasonCode': reasonCode?.value,
      'reasonText': reasonText,
      'snoozedUntil': snoozedUntil,
      'createdAt': createdAt,
    };
  }

  /// JSON for logging a dose (Taken/Skip).
  /// Per M7 rules: only these fields can be updated by client.
  ///   {status, loggedAt, loggedBy, reasonCode?, reasonText?}
  Map<String, dynamic> toJsonForLog() {
    final json = <String, dynamic>{
      'status': status.value,
      'loggedAt': loggedAt,
      'loggedBy': loggedBy,
    };
    if (reasonCode != null) json['reasonCode'] = reasonCode!.value;
    if (reasonText != null) json['reasonText'] = reasonText;
    return json;
  }

  /// JSON for snooze — updates snoozedUntil + missDeadline.
  Map<String, dynamic> toJsonForSnooze() {
    return {'snoozedUntil': snoozedUntil, 'missDeadline': missDeadline};
  }

  /// JSON for undo — reverts status to pending.
  /// Per M7 rules: taken/skipped → pending within 24h.
  Map<String, dynamic> toJsonForUndo() {
    return {
      'status': DoseStatus.pending.value,
      'loggedAt': null,
      'loggedBy': null,
      'reasonCode': null,
      'reasonText': null,
      'snoozedUntil': null,
    };
  }

  // ──────────────────────────────────────────────────────────────
  // COPY WITH
  // ──────────────────────────────────────────────────────────────

  Dose copyWith({
    String? id,
    String? profileId,
    String? medicationId,
    String? medName,
    String? doseLabel,
    DateTime? scheduledAt,
    DateTime? missDeadline,
    DoseStatus? status,
    DateTime? loggedAt,
    String? loggedBy,
    MissedDoseReason? reasonCode,
    String? reasonText,
    DateTime? snoozedUntil,
    DateTime? createdAt,
  }) {
    return Dose(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      medicationId: medicationId ?? this.medicationId,
      medName: medName ?? this.medName,
      doseLabel: doseLabel ?? this.doseLabel,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      missDeadline: missDeadline ?? this.missDeadline,
      status: status ?? this.status,
      loggedAt: loggedAt ?? this.loggedAt,
      loggedBy: loggedBy ?? this.loggedBy,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonText: reasonText ?? this.reasonText,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────

  bool get isPending => status == DoseStatus.pending;
  bool get isTaken => status == DoseStatus.taken;
  bool get isSkipped => status == DoseStatus.skipped;
  bool get isMissed => status == DoseStatus.missed;
  bool get isSnoozed => status == DoseStatus.snoozed || snoozedUntil != null;
  bool get isPrn => id.contains('_prn_');

  /// Can this dose be logged (taken/skipped)?
  /// Per M7 rules: pending/missed → taken/skipped.
  bool get canLog => isPending || isMissed;

  /// Can this dose be undone?
  /// Per M7 rules: taken/skipped → pending within 24h of loggedAt.
  bool canUndo() {
    if (!isTaken && !isSkipped) return false;
    if (loggedAt == null) return false;
    final elapsed = DateTime.now().difference(loggedAt!);
    return elapsed.inHours < 24;
  }

  /// Is this dose overdue (past missDeadline but still pending)?
  bool get isOverdue {
    if (!isPending) return false;
    return DateTime.now().isAfter(missDeadline);
  }

  @override
  String toString() =>
      'Dose(id: $id, med: $medName, at: $scheduledAt, status: $status.value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dose && other.id == id && other.profileId == profileId);

  @override
  int get hashCode => Object.hash(id, profileId);

  // ──────────────────────────────────────────────────────────────
  // DATE PARSING (handles Firestore Timestamp + DateTime + String)
  // ──────────────────────────────────────────────────────────────

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

// ════════════════════════════════════════════════════════════════
// ENUMS
// ════════════════════════════════════════════════════════════════

/// Dose lifecycle status.
/// Per M7 plan: pending → taken/skipped, pending → missed, taken/skipped → pending (undo).
enum DoseStatus {
  pending, // Scheduled, not yet logged
  taken, // User took the dose
  skipped, // User skipped the dose
  missed, // Time passed without logging
  snoozed; // Temporarily snoozed

  String get value => name;

  static DoseStatus fromString(String value) {
    return DoseStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => DoseStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case DoseStatus.pending:
        return 'Pending';
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.skipped:
        return 'Skipped';
      case DoseStatus.missed:
        return 'Missed';
      case DoseStatus.snoozed:
        return 'Snoozed';
    }
  }

  /// Color for UI badges
  int get colorValue {
    switch (this) {
      case DoseStatus.pending:
        return 0xFF6B7280; // Grey
      case DoseStatus.taken:
        return 0xFF22C55E; // Green
      case DoseStatus.skipped:
        return 0xFF3B82F6; // Blue
      case DoseStatus.missed:
        return 0xFFEF4444; // Red
      case DoseStatus.snoozed:
        return 0xFFF59E0B; // Amber
    }
  }
}

/// Reason for missing/skipping a dose.
/// Per M7 plan: forgot / side_effect / ran_out / other
enum MissedDoseReason {
  forgot,
  sideEffect,
  ranOut,
  other;

  String get value {
    switch (this) {
      case MissedDoseReason.forgot:
        return 'forgot';
      case MissedDoseReason.sideEffect:
        return 'side_effect';
      case MissedDoseReason.ranOut:
        return 'ran_out';
      case MissedDoseReason.other:
        return 'other';
    }
  }

  static MissedDoseReason fromString(String value) {
    switch (value.toLowerCase()) {
      case 'forgot':
        return MissedDoseReason.forgot;
      case 'side_effect':
        return MissedDoseReason.sideEffect;
      case 'ran_out':
        return MissedDoseReason.ranOut;
      default:
        return MissedDoseReason.other;
    }
  }

  String get label {
    switch (this) {
      case MissedDoseReason.forgot:
        return 'Forgot';
      case MissedDoseReason.sideEffect:
        return 'Side Effect';
      case MissedDoseReason.ranOut:
        return 'Ran Out';
      case MissedDoseReason.other:
        return 'Other';
    }
  }
}
