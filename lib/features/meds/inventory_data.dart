import 'meds_data.dart';

/// ============================================================
/// INVENTORY DATA
///
/// Real-time remaining medication supply ke liye calculation/data
/// layer.
///
/// Abhi deterministic dummy inventory use ho rahi hai.
///
/// TODO Backend:
/// Current signed-in user / selected family member ke active
/// medication inventory documents Firestore se fetch karne hain.
///
/// Suggested fields:
/// • medicationId
/// • remainingQuantity
/// • packageQuantity
/// • unitsPerDay
/// • unitLabel
/// • lowStockThresholdDays
/// • lastAdjustedAt
/// • adjustmentSource
///
/// UI LOW / OK status ko hardcode nahi karti.
/// Status remaining supply se calculate hota hai.
/// ============================================================

enum InventoryStatus { low, ok }

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.medicationId,
    required this.medicineName,
    required this.strength,
    required this.medicineType,
    required this.remainingQuantity,
    required this.packageQuantity,
    required this.unitsPerDay,
    required this.unitLabel,
    this.lowStockThresholdDays = 7,
  });

  final String id;
  final String medicationId;

  final String medicineName;
  final String strength;

  final MedicineType medicineType;

  int remainingQuantity;

  final int packageQuantity;

  final double unitsPerDay;

  final String unitLabel;

  final int lowStockThresholdDays;

  // ============================================================
  // COMPUTED VALUES
  // ============================================================

  String get displayName {
    if (strength.trim().isEmpty) {
      return medicineName;
    }

    return '$medicineName $strength';
  }

  int get estimatedDaysRemaining {
    if (unitsPerDay <= 0) {
      return 0;
    }

    return (remainingQuantity / unitsPerDay).floor();
  }

  InventoryStatus get status {
    if (estimatedDaysRemaining <= lowStockThresholdDays) {
      return InventoryStatus.low;
    }

    return InventoryStatus.ok;
  }

  bool get isLowStock {
    return status == InventoryStatus.low;
  }

  double get supplyProgress {
    if (packageQuantity <= 0) {
      return 0;
    }

    return (remainingQuantity / packageQuantity).clamp(0.0, 1.0);
  }

  String get supplyLabel {
    final unit = _pluralizedUnit(remainingQuantity, unitLabel);

    return '$remainingQuantity $unit · '
        '~$estimatedDaysRemaining days';
  }

  String? get medicineImageAsset {
    switch (medicineType) {
      case MedicineType.tablet:
        return 'assets/images/tablet.jpg';

      case MedicineType.capsule:
        return 'assets/images/capsule.jpg';

      case MedicineType.liquid:
        return 'assets/images/liquid.jpg';

      case MedicineType.drops:
        return null;

      case MedicineType.injection:
        return 'assets/images/injection.jpg';
    }
  }

  String _pluralizedUnit(int quantity, String source) {
    if (quantity == 1) {
      return source;
    }

    switch (source.toLowerCase()) {
      case 'tablet':
        return 'tablets';

      case 'capsule':
        return 'capsules';

      case 'bottle':
        return 'bottles';

      case 'dose':
        return 'doses';

      default:
        return '${source}s';
    }
  }
}

class InventoryData {
  InventoryData._();

  // ============================================================
  // DUMMY INVENTORY
  //
  // TODO Backend:
  // Is list ko Firestore repository query se replace karna hai.
  // medicationId ke through inventory active medicine se linked
  // rahegi.
  // ============================================================

  static List<InventoryItem> inventory() {
    return [
      InventoryItem(
        id: 'inventory_metformin',
        medicationId: 'med_metformin',
        medicineName: 'Metformin',
        strength: '500mg',
        medicineType: MedicineType.tablet,
        remainingQuantity: 18,
        packageQuantity: 100,
        unitsPerDay: 3,
        unitLabel: 'tablet',
        lowStockThresholdDays: 7,
      ),
      InventoryItem(
        id: 'inventory_amlodipine',
        medicationId: 'med_amlodipine',
        medicineName: 'Amlodipine',
        strength: '5mg',
        medicineType: MedicineType.tablet,
        remainingQuantity: 42,
        packageQuantity: 60,
        unitsPerDay: 2,
        unitLabel: 'tablet',
        lowStockThresholdDays: 7,
      ),
      InventoryItem(
        id: 'inventory_vitamin_d3',
        medicationId: 'med_vitamin_d3',
        medicineName: 'Vitamin D3',
        strength: 'Drops',
        medicineType: MedicineType.drops,
        remainingQuantity: 1,
        packageQuantity: 1,
        unitsPerDay: 0.033,
        unitLabel: 'bottle',
        lowStockThresholdDays: 7,
      ),
    ];
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  static int lowStockCount(List<InventoryItem> items) {
    return items.where((item) {
      return item.isLowStock;
    }).length;
  }

  static int okCount(List<InventoryItem> items) {
    return items.where((item) {
      return !item.isLowStock;
    }).length;
  }
}
