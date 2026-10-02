import 'inventory_data.dart';

/// ============================================================
/// ADJUST INVENTORY COUNT DATA
///
/// Adjust Count bottom sheet ke liye data/result layer.
///
/// UI kisi specific medicine ka:
/// • name
/// • strength
/// • current count
/// • package quantity
/// • unit
///
/// hardcode nahi karti.
///
/// TODO Backend:
/// Save hone par existing inventory document ko medicationId se
/// update karna hai. Duplicate inventory document create NAHI karna.
/// ============================================================

class AdjustInventoryCountResult {
  const AdjustInventoryCountResult({
    required this.medicationId,
    required this.remainingQuantity,
    this.reason,
  });

  final String medicationId;
  final int remainingQuantity;
  final String? reason;
}

/// Bottom sheet ke quick-adjust options.
class InventoryCountQuickOption {
  const InventoryCountQuickOption({
    required this.label,
    required this.quantity,
  });

  final String label;
  final int quantity;
}

class AdjustInventoryCountData {
  AdjustInventoryCountData._();

  /// Refill ke baad normal package quantity.
  static InventoryCountQuickOption refillOption(InventoryItem item) {
    return InventoryCountQuickOption(
      label: 'After refill: ${item.packageQuantity}',
      quantity: item.packageQuantity,
    );
  }

  /// Second useful quick option.
  ///
  /// Tablet/capsule/dose medicines ke liye half package.
  /// Bottle inventory ke liye full package.
  static InventoryCountQuickOption secondaryOption(InventoryItem item) {
    final normalizedUnit = item.unitLabel.toLowerCase();

    if (normalizedUnit == 'bottle') {
      return InventoryCountQuickOption(
        label: 'Full bottle: ${item.packageQuantity}',
        quantity: item.packageQuantity,
      );
    }

    final halfPackage = (item.packageQuantity / 2).round();

    return InventoryCountQuickOption(
      label: 'Half pack: $halfPackage',
      quantity: halfPackage,
    );
  }

  static String unitForCount(int count, String source) {
    if (count == 1) {
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
