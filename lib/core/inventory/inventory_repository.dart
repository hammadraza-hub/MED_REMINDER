/// ============================================================
/// INVENTORY DOMAIN MODEL
///
/// Represents current stock + audit log for a medication.
///
/// Firestore Path (M0 schema):
///   profiles/{memberId}/medications/{medId}  ← Inventory fields here
///   profiles/{memberId}/medications/{medId}/inventoryEvents/{eventId}  ← Audit log
///
/// Architecture:
///   - Inventory state stored ON medication document
///     (quantityOnHand, packageQuantity, unitsPerDay, etc.)
///   - Inventory events (deltas) stored in subcollection
///     (immutable audit log)
///   - Atomic updates via Firestore batch writes
/// ============================================================

/// Inventory item representing current stock of a medication.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.medicationId,
    required this.memberId,
    required this.medicineName,
    required this.strength,
    required this.medicineType,
    required this.remainingQuantity,
    this.packageQuantity,
    this.unitsPerDay,
    this.unitLabel,
    this.lowStockThresholdDays = 7,
    this.lastAdjustedAt,
    this.adjustmentSource,
  });

  /// Same as medicationId (inventory is part of med doc).
  final String id;

  /// Reference to parent medication.
  final String medicationId;

  /// Reference to parent member/profile.
  final String memberId;

  /// Denormalized from medication for display.
  final String medicineName;
  final String strength;
  final String medicineType;

  /// Current quantity on hand (synced with medication.quantityOnHand).
  final int remainingQuantity;

  /// Original package size (e.g., 30 tablets).
  final int? packageQuantity;

  /// Units consumed per day (for low stock calculation).
  final int? unitsPerDay;

  /// Display label for unit (e.g., 'tablet', 'capsule').
  final String? unitLabel;

  /// Days of supply below which to alert user.
  final int lowStockThresholdDays;

  /// When quantity was last adjusted.
  final DateTime? lastAdjustedAt;

  /// Why quantity was last adjusted (e.g., 'dose_taken', 'refill').
  final String? adjustmentSource;

  /// Calculate days of supply remaining.
  /// Returns null if unitsPerDay is not set or is zero.
  int? get daysOfSupply {
    if (unitsPerDay == null || unitsPerDay! <= 0) return null;
    return remainingQuantity ~/ unitsPerDay!;
  }

  /// Whether this medication is in low stock.
  bool get isLowStock {
    final days = daysOfSupply;
    if (days == null) return false;
    return days <= lowStockThresholdDays;
  }

  InventoryItem copyWith({
    String? id,
    String? medicationId,
    String? memberId,
    String? medicineName,
    String? strength,
    String? medicineType,
    int? remainingQuantity,
    int? packageQuantity,
    int? unitsPerDay,
    String? unitLabel,
    int? lowStockThresholdDays,
    DateTime? lastAdjustedAt,
    bool clearLastAdjustedAt = false,
    String? adjustmentSource,
    bool clearAdjustmentSource = false,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      memberId: memberId ?? this.memberId,
      medicineName: medicineName ?? this.medicineName,
      strength: strength ?? this.strength,
      medicineType: medicineType ?? this.medicineType,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      packageQuantity: packageQuantity ?? this.packageQuantity,
      unitsPerDay: unitsPerDay ?? this.unitsPerDay,
      unitLabel: unitLabel ?? this.unitLabel,
      lowStockThresholdDays:
          lowStockThresholdDays ?? this.lowStockThresholdDays,
      lastAdjustedAt: clearLastAdjustedAt
          ? null
          : lastAdjustedAt ?? this.lastAdjustedAt,
      adjustmentSource: clearAdjustmentSource
          ? null
          : adjustmentSource ?? this.adjustmentSource,
    );
  }
}

/// Inventory adjustment event (audit log entry).
class InventoryEvent {
  const InventoryEvent({
    required this.id,
    required this.medicationId,
    required this.memberId,
    required this.delta,
    required this.reason,
    this.doseId,
    required this.createdAt,
  });

  final String id;
  final String medicationId;
  final String memberId;

  /// Change in quantity. Positive for additions, negative for subtractions.
  /// e.g., -1 for taking a dose, +30 for refill.
  final int delta;

  /// Reason for the adjustment.
  /// Common values: 'dose_taken', 'refill', 'manual_adjustment', 'initial_setup'
  final String reason;

  /// Optional reference to the dose that triggered this adjustment.
  final String? doseId;

  final DateTime createdAt;
}

/// ============================================================
/// INVENTORY REPOSITORY CONTRACT
/// ============================================================
abstract class InventoryRepository {
  /// Watch all inventory items for a member (realtime).
  /// Returns inventory for all active medications.
  Stream<List<InventoryItem>> watchInventory(String memberId);

  /// One-time fetch of all inventory items for a member.
  Future<List<InventoryItem>> getInventory(String memberId);

  /// Get inventory for a single medication.
  Future<InventoryItem?> getInventoryForMedication({
    required String memberId,
    required String medicationId,
  });

  /// Adjust quantity — atomically:
  ///   1. Adds an event to inventoryEvents subcollection
  ///   2. Updates quantityOnHand on the medication document
  ///
  /// [delta] can be positive (refill) or negative (dose taken).
  /// [reason] should be one of: 'dose_taken', 'refill',
  /// 'manual_adjustment', 'initial_setup', etc.
  /// [doseId] optional, for dose-triggered adjustments.
  Future<void> adjustQuantity({
    required String memberId,
    required String medicationId,
    required int delta,
    required String reason,
    String? doseId,
  });

  /// Watch inventory events (audit log) for a medication (realtime).
  /// Returns most recent 50 events.
  Stream<List<InventoryEvent>> watchInventoryEvents({
    required String memberId,
    required String medicationId,
  });

  /// Set initial inventory configuration for a medication.
  /// Used when user first adds a medication.
  Future<void> setInventoryConfig({
    required String memberId,
    required String medicationId,
    int? packageQuantity,
    int? unitsPerDay,
    String? unitLabel,
    int? lowStockThresholdDays,
    int? initialQuantity,
  });
}
