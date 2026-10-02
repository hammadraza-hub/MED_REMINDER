import 'meds_data.dart';

/// ============================================================
/// INVENTORY DATA
///
/// Real-time remaining medication supply ke liye calculation/data
/// layer.
///
/// IMPORTANT:
/// Medication identity (name, dose, type) MedsData se aati hai.
/// Inventory sirf stock-specific information maintain karti hai.
///
/// Iska faida:
/// • Meds aur Inventory medicine list synchronized rehti hai.
/// • Name / strength / type duplicate hardcode nahi hote.
/// • Active medicine Inventory mein automatically include hoti hai.
///
/// TODO Backend:
/// Current signed-in user / selected family member ke active
/// medications aur unke inventory documents Firestore se fetch
/// karne hain.
///
/// Suggested inventory fields:
/// • medicationId
/// • remainingQuantity
/// • packageQuantity
/// • unitsPerDay
/// • unitLabel
/// • lowStockThresholdDays
/// • lastAdjustedAt
/// • adjustmentSource
///
/// UI LOW / OK status hardcode nahi karti.
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

  /// Manual adjustment ke baad locally update hoti hai.
  int remainingQuantity;

  final int packageQuantity;

  /// Roz kitni units consume hoti hain.
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

  /// Same medicine image mapping jo Meds feature use karta hai.
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

/// ============================================================
/// TEMPORARY STOCK DATA
///
/// Medication ki identity yahan duplicate nahi rakhi ja rahi.
/// Sirf Inventory-specific values hain.
///
/// TODO Backend:
/// Ye poora stock config Firestore inventory documents se replace
/// hoga aur medicationId active medication document ko reference
/// karega.
/// ============================================================

class _InventoryStock {
  const _InventoryStock({
    required this.remainingQuantity,
    required this.packageQuantity,
    required this.unitsPerDay,
    required this.unitLabel,
    this.lowStockThresholdDays = 7,
  });

  final int remainingQuantity;
  final int packageQuantity;
  final double unitsPerDay;
  final String unitLabel;
  final int lowStockThresholdDays;
}

class InventoryData {
  InventoryData._();

  // ============================================================
  // DUMMY STOCK CONFIG
  //
  // Key medicine name hai sirf current dummy phase ke liye.
  //
  // TODO Backend:
  // Production/Firebase mein medicine name ko relation key mat
  // banana. Stable medication document ID use karna hai.
  // ============================================================

  static const Map<String, _InventoryStock> _stockByMedicine = {
    'Metformin': _InventoryStock(
      remainingQuantity: 18,
      packageQuantity: 100,

      // Meds: 2x daily
      unitsPerDay: 2,

      unitLabel: 'tablet',
      lowStockThresholdDays: 7,
    ),

    'Amlodipine': _InventoryStock(
      remainingQuantity: 42,
      packageQuantity: 60,

      // Meds: 1x daily
      unitsPerDay: 1,

      unitLabel: 'tablet',
      lowStockThresholdDays: 7,
    ),

    'Vitamin D3 Drops': _InventoryStock(
      remainingQuantity: 1,
      packageQuantity: 1,

      // Bottle-based supply.
      // Approx 30 days per bottle in current dummy data.
      unitsPerDay: 0.033,

      unitLabel: 'bottle',
      lowStockThresholdDays: 7,
    ),

    'Amoxicillin': _InventoryStock(
      // Current Meds data says course has roughly 4 days
      // supply remaining and medicine is taken 3x daily.
      remainingQuantity: 12,
      packageQuantity: 30,
      unitsPerDay: 3,
      unitLabel: 'capsule',
      lowStockThresholdDays: 5,
    ),
  };

  // ============================================================
  // INVENTORY
  //
  // Active medication list ka single source MedsData hai.
  // ============================================================

  static List<InventoryItem> inventory() {
    final activeMedicines = MedsData.medicines();

    final items = <InventoryItem>[];

    for (var index = 0; index < activeMedicines.length; index++) {
      final medicine = activeMedicines[index];

      final stock = _stockByMedicine[medicine.name];

      // Agar medicine ke liye stock configuration abhi available
      // nahi hai to fallback us medicine ko Inventory se gayab
      // nahi hone deta.
      final resolvedStock = stock ?? _fallbackStockFor(medicine);

      items.add(
        InventoryItem(
          id: 'inventory_$index',

          // TODO Backend:
          // Firebase mein yahan actual medication document ID
          // use hoga. Index/name based ID use nahi karni.
          medicationId: 'med_$index',

          // Medicine identity MedsData se directly aa rahi hai.
          medicineName: medicine.name,
          strength: medicine.dose,
          medicineType: medicine.type,

          remainingQuantity: resolvedStock.remainingQuantity,
          packageQuantity: resolvedStock.packageQuantity,
          unitsPerDay: resolvedStock.unitsPerDay,
          unitLabel: resolvedStock.unitLabel,
          lowStockThresholdDays: resolvedStock.lowStockThresholdDays,
        ),
      );
    }

    return items;
  }

  // ============================================================
  // FALLBACK STOCK
  //
  // Agar future dummy medicine MedsData mein add ho aur temporary
  // stock config add karna reh jaye, tab bhi Inventory mein
  // medicine visible rahegi.
  //
  // TODO Backend:
  // Firebase phase mein missing inventory document ke liye proper
  // initialization strategy use karni hai.
  // ============================================================

  static _InventoryStock _fallbackStockFor(Medicine medicine) {
    final unitsPerDay = _unitsPerDayFromFrequency(medicine.frequency);

    final unitLabel = _unitLabelForType(medicine.type);

    final estimatedQuantity = (medicine.supplyDaysLeft * unitsPerDay)
        .round()
        .clamp(0, 999999);

    return _InventoryStock(
      remainingQuantity: estimatedQuantity,
      packageQuantity: estimatedQuantity > 0 ? estimatedQuantity : 1,
      unitsPerDay: unitsPerDay,
      unitLabel: unitLabel,
      lowStockThresholdDays: 7,
    );
  }

  // ============================================================
  // FREQUENCY → UNITS PER DAY
  // ============================================================

  static double _unitsPerDayFromFrequency(String frequency) {
    final normalized = frequency.toLowerCase();

    final match = RegExp(r'(\d+)\s*x\s*daily').firstMatch(normalized);

    if (match != null) {
      final value = int.tryParse(match.group(1) ?? '');

      if (value != null && value > 0) {
        return value.toDouble();
      }
    }

    // Safe dummy fallback.
    return 1;
  }

  // ============================================================
  // MEDICINE TYPE → INVENTORY UNIT
  // ============================================================

  static String _unitLabelForType(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return 'tablet';

      case MedicineType.capsule:
        return 'capsule';

      case MedicineType.liquid:
        return 'dose';

      case MedicineType.drops:
        return 'bottle';

      case MedicineType.injection:
        return 'dose';
    }
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
