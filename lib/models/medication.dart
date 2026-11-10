import 'package:cloud_firestore/cloud_firestore.dart';

import 'schedule.dart';

/// Medication model — represents a saved medication for a profile.
///
/// M5 — Medications & Schedules
///
/// Per the PRD data model:
///   • One medication = one embedded schedule (not separate collection)
///   • All 5 schedule types supported (daily, weekdays, cyclical, PRN, taper)
///   • Archive, never delete (status field: active | archived)
///
/// Server-maintained fields (NOT writable by client per M5 rules):
///   • quantityOnHand (M9 — inventory tracking)
///   • daysOfSupply (M6 — calculated from schedule)
///   • flags { lowStock, interaction } (M9, M10 — auto-maintained)
///
/// In Phase A (Spark plan, no Cloud Functions), these fields will be:
///   • null / 0 when medication is created
///   • Remain null / 0 (no function to update them)
///   • Populated automatically when Blaze plan + M6/M9/M10 functions are added
class Medication {
  /// Firestore document ID (medications/{medId})
  final String id;

  /// Parent profile ID (profiles/{profileId}/medications/{medId})
  final String profileId;

  // ────────────────────────────────────────────────────────────
  // DRUG IDENTIFICATION
  // ────────────────────────────────────────────────────────────

  /// Display name (e.g., "Metformin 500 MG")
  final String name;

  /// Drug strength (e.g., "500 MG", "5 MCG/ML")
  final String? strength;

  /// Dose form (e.g., "Tablet", "Capsule", "Syrup", "Injection")
  final String? form;

  /// Numeric dose amount per intake (e.g., 1.0 for "1 tablet", 500.0 for "500 mg")
  final double? doseAmount;

  /// Unit of doseAmount (e.g., "tablet", "mg", "ml", "units")
  final String? doseUnit;

  /// Free-text directions / instructions
  /// (e.g., "Take with food, avoid grapefruit")
  final String? instructions;

  /// RxNorm ID from M4 drug catalog (nullable for manual entries)
  final String? rxcui;

  // ────────────────────────────────────────────────────────────
  // RELATIONSHIPS (optional — populated in later modules)
  // ────────────────────────────────────────────────────────────

  /// Prescriber reference (prescribers/{prescriberId} subcollection)
  final String? prescriberId;

  /// Pharmacy reference (pharmacies/{pharmacyId})
  final String? pharmacyId;

  // ────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ────────────────────────────────────────────────────────────

  /// active | archived
  final MedicationStatus status;

  /// Reason for archiving (e.g., "Switched to alternative", "Course completed")
  final String? archivedReason;

  // ────────────────────────────────────────────────────────────
  // INVENTORY (server-maintained — see class docs)
  // ────────────────────────────────────────────────────────────

  /// Current quantity on hand (server-maintained by M9)
  final int? quantityOnHand;

  /// Low stock threshold in days (default: 7). Client-writable on create.
  final int lowStockDays;

  /// Days of supply remaining (server-maintained by M6)
  final int? daysOfSupply;

  // ────────────────────────────────────────────────────────────
  // SOURCE TRACKING
  // ────────────────────────────────────────────────────────────

  /// How this medication was added (search | scan | manual)
  /// Set at creation, immutable afterwards.
  final MedicationSource source;

  // ────────────────────────────────────────────────────────────
  // AUTO-MAINTAINED FLAGS (server-side, M9 + M10)
  // ────────────────────────────────────────────────────────────

  final MedicationFlags flags;

  // ────────────────────────────────────────────────────────────
  // EMBEDDED SCHEDULE (per PRD — not a separate collection)
  // ────────────────────────────────────────────────────────────

  final Schedule schedule;

  // ────────────────────────────────────────────────────────────
  // AUDIT
  // ────────────────────────────────────────────────────────────

  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  const Medication({
    required this.id,
    required this.profileId,
    required this.name,
    this.strength,
    this.form,
    this.doseAmount,
    this.doseUnit,
    this.instructions,
    this.rxcui,
    this.prescriberId,
    this.pharmacyId,
    this.status = MedicationStatus.active,
    this.archivedReason,
    this.quantityOnHand,
    this.lowStockDays = 7,
    this.daysOfSupply,
    this.source = MedicationSource.manual,
    this.flags = const MedicationFlags(),
    required this.schedule,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  // ────────────────────────────────────────────────────────────
  // SERIALIZATION
  // ────────────────────────────────────────────────────────────

  factory Medication.fromJson(Map<String, dynamic> json, {String? id}) {
    return Medication(
      id: id ?? json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      strength: json['strength'] as String?,
      form: json['form'] as String?,
      doseAmount: (json['doseAmount'] as num?)?.toDouble(),
      doseUnit: json['doseUnit'] as String?,
      instructions: json['instructions'] as String?,
      rxcui: json['rxcui'] as String?,
      prescriberId: json['prescriberId'] as String?,
      pharmacyId: json['pharmacyId'] as String?,
      status: MedicationStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
      archivedReason: json['archivedReason'] as String?,
      quantityOnHand: (json['quantityOnHand'] as num?)?.toInt(),
      lowStockDays: (json['lowStockDays'] as num?)?.toInt() ?? 7,
      daysOfSupply: (json['daysOfSupply'] as num?)?.toInt(),
      source: MedicationSource.fromString(
        json['source'] as String? ?? 'manual',
      ),
      flags: MedicationFlags.fromJson(
        json['flags'] as Map<String, dynamic>? ?? const {},
      ),
      schedule: Schedule.fromJson(
        json['schedule'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  /// Full JSON — used for reads (includes server-maintained fields).
  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'name': name,
      'strength': strength,
      'form': form,
      'doseAmount': doseAmount,
      'doseUnit': doseUnit,
      'instructions': instructions,
      'rxcui': rxcui,
      'prescriberId': prescriberId,
      'pharmacyId': pharmacyId,
      'status': status.value,
      'archivedReason': archivedReason,
      'quantityOnHand': quantityOnHand,
      'lowStockDays': lowStockDays,
      'daysOfSupply': daysOfSupply,
      'source': source.value,
      'flags': flags.toJson(),
      'schedule': schedule.toJson(),
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  /// JSON for CREATE — excludes server-maintained fields per M5 rules.
  /// (quantityOnHand, daysOfSupply, flags — populated by Cloud Functions in Phase B)
  Map<String, dynamic> toJsonForCreate() {
    final json = toJson();
    json.remove('quantityOnHand');
    json.remove('daysOfSupply');
    json.remove('flags');
    return json;
  }

  /// JSON for UPDATE — only allows client-modifiable fields.
  /// Per M5 rules, client CANNOT modify:
  ///   • quantityOnHand, daysOfSupply, flags (server-maintained)
  ///   • status, archivedReason (use archive() method instead)
  ///   • profileId, createdBy, createdAt, source (immutable)
  Map<String, dynamic> toJsonForUpdate() {
    final json = toJson();
    json.remove('quantityOnHand');
    json.remove('daysOfSupply');
    json.remove('flags');
    json.remove('status');
    json.remove('archivedReason');
    json.remove('profileId');
    json.remove('createdBy');
    json.remove('createdAt');
    json.remove('source');
    return json;
  }

  // ────────────────────────────────────────────────────────────
  // COPY WITH
  // ────────────────────────────────────────────────────────────

  Medication copyWith({
    String? id,
    String? profileId,
    String? name,
    String? strength,
    String? form,
    double? doseAmount,
    String? doseUnit,
    String? instructions,
    String? rxcui,
    String? prescriberId,
    String? pharmacyId,
    MedicationStatus? status,
    String? archivedReason,
    int? quantityOnHand,
    int? lowStockDays,
    int? daysOfSupply,
    MedicationSource? source,
    MedicationFlags? flags,
    Schedule? schedule,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Medication(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      form: form ?? this.form,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      instructions: instructions ?? this.instructions,
      rxcui: rxcui ?? this.rxcui,
      prescriberId: prescriberId ?? this.prescriberId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      status: status ?? this.status,
      archivedReason: archivedReason ?? this.archivedReason,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      lowStockDays: lowStockDays ?? this.lowStockDays,
      daysOfSupply: daysOfSupply ?? this.daysOfSupply,
      source: source ?? this.source,
      flags: flags ?? this.flags,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // ────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────

  bool get isActive => status == MedicationStatus.active;
  bool get isArchived => status == MedicationStatus.archived;
  bool get hasRxcui => rxcui != null && rxcui!.isNotEmpty;
  bool get hasLowStockFlag => flags.lowStock;
  bool get hasInteractionFlag => flags.interaction;

  /// Returns an archived copy of this medication.
  Medication archived({required String reason, required String archivedBy}) {
    return copyWith(
      status: MedicationStatus.archived,
      archivedReason: reason,
      updatedAt: DateTime.now(),
      updatedBy: archivedBy,
    );
  }

  @override
  String toString() =>
      'Medication(id: $id, name: $name, status: $status.value, schedule: $schedule.type.value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication && other.id == id && other.profileId == profileId);

  @override
  int get hashCode => Object.hash(id, profileId);

  // ────────────────────────────────────────────────────────────
  // DATE PARSING (handles Firestore Timestamp + DateTime + String)
  // ────────────────────────────────────────────────────────────

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

/// Medication lifecycle status.
/// Per M5 plan: "Archive, never delete."
enum MedicationStatus {
  active,
  archived;

  String get value => name;

  static MedicationStatus fromString(String value) {
    return MedicationStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => MedicationStatus.active,
    );
  }

  String get label {
    switch (this) {
      case MedicationStatus.active:
        return 'Active';
      case MedicationStatus.archived:
        return 'Archived';
    }
  }
}

/// How the medication was added — used for analytics + audit trail.
enum MedicationSource {
  search, // Selected from M4 drug catalog
  scan, // Scanned via OCR (M4 Add Medication – Scan)
  manual; // Manually entered by user

  String get value => name;

  static MedicationSource fromString(String value) {
    return MedicationSource.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => MedicationSource.manual,
    );
  }

  String get label {
    switch (this) {
      case MedicationSource.search:
        return 'From drug catalog';
      case MedicationSource.scan:
        return 'Label scan';
      case MedicationSource.manual:
        return 'Manual entry';
    }
  }
}

// ════════════════════════════════════════════════════════════════
// FLAGS
// ════════════════════════════════════════════════════════════════

/// Auto-maintained flags on a medication document.
/// Per M5 plan: "Medication List badges come from flags on each document
/// (kept up to date by M9 and M10), so no extra query is needed per row."
///
/// In Phase A (Spark), these flags will always be false (no functions to set them).
/// In Phase B (Blaze), M9 sets lowStock and M10 sets interaction.
class MedicationFlags {
  /// True when quantityOnHand falls below lowStockDays supply.
  final bool lowStock;

  /// True when medication has a known interaction with another active med.
  final bool interaction;

  const MedicationFlags({this.lowStock = false, this.interaction = false});

  factory MedicationFlags.fromJson(Map<String, dynamic> json) {
    return MedicationFlags(
      lowStock: json['lowStock'] as bool? ?? false,
      interaction: json['interaction'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'lowStock': lowStock, 'interaction': interaction};
  }

  MedicationFlags copyWith({bool? lowStock, bool? interaction}) {
    return MedicationFlags(
      lowStock: lowStock ?? this.lowStock,
      interaction: interaction ?? this.interaction,
    );
  }

  @override
  String toString() =>
      'MedicationFlags(lowStock: $lowStock, interaction: $interaction)';
}
