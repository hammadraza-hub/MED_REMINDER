import 'inventory_data.dart';
import '../../l10n/app_localizations.dart';

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
  static InventoryCountQuickOption refillOption(
    AppLocalizations l10n,
    InventoryItem item,
  ) {
    return InventoryCountQuickOption(
      label: l10n.inventoryAfterRefill(item.packageQuantity),
      quantity: item.packageQuantity,
    );
  }

  /// Second useful quick option.
  ///
  /// Tablet/capsule/dose medicines ke liye half package.
  /// Bottle inventory ke liye full package.
  static InventoryCountQuickOption secondaryOption(
    AppLocalizations l10n,
    InventoryItem item,
  ) {
    final normalizedUnit = item.unitLabel.toLowerCase();

    if (normalizedUnit == 'bottle') {
      return InventoryCountQuickOption(
        label: l10n.inventoryFullBottle(item.packageQuantity),
        quantity: item.packageQuantity,
      );
    }

    final halfPackage = (item.packageQuantity / 2).round();

    return InventoryCountQuickOption(
      label: l10n.inventoryHalfPack(halfPackage),
      quantity: halfPackage,
    );
  }
}
