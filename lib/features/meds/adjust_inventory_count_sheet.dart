import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'adjust_inventory_count_data.dart';
import 'inventory_data.dart';
import 'meds_data.dart';

/// ============================================================
/// ADJUST INVENTORY COUNT SHEET
///
/// Reference-style bottom modal:
/// • Background visible/dim
/// • Rounded top corners
/// • Medicine summary
/// • +/- quantity controls
/// • Dynamic quick options
/// • Optional reason
/// • Save / Cancel
///
/// Returns:
/// AdjustInventoryCountResult → Save
/// null                       → Cancel/outside/back
///
/// TODO Backend:
/// Inventory persistence InventoryScreen/repository layer karegi.
/// ============================================================

Future<AdjustInventoryCountResult?> showAdjustInventoryCountSheet(
  BuildContext context, {
  required InventoryItem item,
}) {
  return showModalBottomSheet<AdjustInventoryCountResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.headerDark.withValues(alpha: 0.38),
    builder: (_) {
      return _AdjustInventoryCountSheet(item: item);
    },
  );
}

class _AdjustInventoryCountSheet extends StatefulWidget {
  const _AdjustInventoryCountSheet({required this.item});

  final InventoryItem item;

  @override
  State<_AdjustInventoryCountSheet> createState() =>
      _AdjustInventoryCountSheetState();
}

class _AdjustInventoryCountSheetState
    extends State<_AdjustInventoryCountSheet> {
  late int _count;

  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _count = widget.item.remainingQuantity;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _decrease() {
    if (_count <= 0) {
      return;
    }

    setState(() {
      _count--;
    });
  }

  void _increase() {
    setState(() {
      _count++;
    });
  }

  void _selectQuickOption(InventoryCountQuickOption option) {
    setState(() {
      _count = option.quantity;
    });
  }

  void _save() {
    final reason = _reasonController.text.trim();

    Navigator.of(context).pop(
      AdjustInventoryCountResult(
        medicationId: widget.item.medicationId,
        remainingQuantity: _count,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final refillOption = AdjustInventoryCountData.refillOption(widget.item);

    final secondaryOption = AdjustInventoryCountData.secondaryOption(
      widget.item,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ================= HANDLE =================
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inventoryProgressTrack,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 13),

              // ================= TITLE =================
              const Text(
                'Adjust Count',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              // ================= MEDICINE =================
              _MedicineSummary(item: widget.item),

              const SizedBox(height: 17),

              // ================= COUNTER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CounterButton(
                    icon: Icons.remove_rounded,
                    filled: false,
                    onTap: _decrease,
                  ),

                  const SizedBox(width: 25),

                  Column(
                    children: [
                      Text(
                        '$_count',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        AdjustInventoryCountData.unitForCount(
                          _count,
                          widget.item.unitLabel,
                        ).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 25),

                  _CounterButton(
                    icon: Icons.add_rounded,
                    filled: true,
                    onTap: _increase,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ================= QUICK OPTIONS =================
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 7,
                runSpacing: 7,
                children: [
                  _QuickOptionChip(
                    option: refillOption,
                    onTap: () {
                      _selectQuickOption(refillOption);
                    },
                  ),

                  _QuickOptionChip(
                    option: secondaryOption,
                    onTap: () {
                      _selectQuickOption(secondaryOption);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ================= REASON =================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adjustment Reason (Optional)',
                  style: TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              TextField(
                controller: _reasonController,
                minLines: 2,
                maxLines: 3,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
                decoration: InputDecoration(
                  hintText: 'Reason for adjustment (optional)...',
                  hintStyle: const TextStyle(
                    color: AppColors.fieldHint,
                    fontSize: 10,
                  ),
                  filled: true,
                  fillColor: AppColors.inventoryFilterBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.inventoryBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.formAccent),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ================= SAVE =================
              SizedBox(
                width: double.infinity,
                height: 47,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inventoryOk,
                    foregroundColor: AppColors.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save Count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(width: 7),

                      Icon(Icons.check_rounded, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ================= CANCEL =================
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.formAccent,
                  minimumSize: const Size(80, 34),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MEDICINE SUMMARY
// ============================================================

class _MedicineSummary extends StatelessWidget {
  const _MedicineSummary({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inventoryProgressTrack),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MedicineImage(item: item),

          const SizedBox(width: 9),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Current on hand: '
                  '${item.remainingQuantity} '
                  '${AdjustInventoryCountData.unitForCount(item.remainingQuantity, item.unitLabel)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICINE IMAGE
// ============================================================

class _MedicineImage extends StatelessWidget {
  const _MedicineImage({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.cardFill,
        shape: BoxShape.circle,
      ),
      child: item.medicineImageAsset != null
          ? Image.asset(
              item.medicineImageAsset!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return _fallbackIcon();
              },
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      _medicineTypeIcon(item.medicineType),
      color: AppColors.formAccent,
      size: 19,
    );
  }

  IconData _medicineTypeIcon(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return Icons.medication_outlined;

      case MedicineType.capsule:
        return Icons.medication_outlined;

      case MedicineType.liquid:
        return Icons.medication_liquid_outlined;

      case MedicineType.drops:
        return Icons.opacity_outlined;

      case MedicineType.injection:
        return Icons.vaccines_outlined;
    }
  }
}

// ============================================================
// COUNTER BUTTON
// ============================================================

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: filled ? AppColors.inventoryOk : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.inventoryOk),
        ),
        child: Icon(
          icon,
          color: filled ? AppColors.surface : AppColors.inventoryOk,
          size: 20,
        ),
      ),
    );
  }
}

// ============================================================
// QUICK OPTION
// ============================================================

class _QuickOptionChip extends StatelessWidget {
  const _QuickOptionChip({required this.option, required this.onTap});

  final InventoryCountQuickOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.inventoryOkBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              color: AppColors.inventoryOk,
              size: 12,
            ),

            const SizedBox(width: 3),

            Text(
              option.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
