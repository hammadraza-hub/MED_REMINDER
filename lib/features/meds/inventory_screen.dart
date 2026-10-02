import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import 'inventory_data.dart';
import 'meds_data.dart';
import 'refill_alert_detail_screen.dart';
import 'adjust_inventory_count_sheet.dart';

/// ============================================================
/// INVENTORY
///
/// PURPOSE:
/// Real-time remaining medication supply.
///
/// Features:
/// • Remaining quantity
/// • Estimated days-of-supply
/// • LOW / OK calculated status
/// • All / Low Stock / OK filters
/// • Manual count adjustment
/// • Refill Detail navigation hook
///
/// Backend:
/// InventoryData abhi dummy provider hai.
/// Future mein Firebase inventory repository same UI ko real
/// stock data provide karegi.
/// ============================================================
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

enum _InventoryFilter { all, lowStock, ok }

class _InventoryScreenState extends State<InventoryScreen> {
  _InventoryFilter _selectedFilter = _InventoryFilter.all;

  late final List<InventoryItem> _items = InventoryData.inventory();

  // ================= COMPUTED DATA =================

  int get _lowStockCount => InventoryData.lowStockCount(_items);

  List<InventoryItem> get _visibleItems {
    switch (_selectedFilter) {
      case _InventoryFilter.all:
        return _items;

      case _InventoryFilter.lowStock:
        return _items.where((item) => item.isLowStock).toList();

      case _InventoryFilter.ok:
        return _items.where((item) => !item.isLowStock).toList();
    }
  }

  // ============================================================
  // ADJUST COUNT
  // ============================================================

  Future<void> _adjustCount(InventoryItem item) async {
    final result = await showAdjustInventoryCountSheet(context, item: item);

    // Cancel / outside tap / back → kuch save nahi hoga.
    if (!mounted || result == null) {
      return;
    }

    // Safety: result isi medication ka hona chahiye.
    if (result.medicationId != item.medicationId) {
      return;
    }

    setState(() {
      item.remainingQuantity = result.remainingQuantity;
    });

    // LOW / OK, estimatedDaysRemaining aur supplyProgress
    // InventoryItem ke computed getters hain, isliye count update
    // hote hi automatically recalculate ho jayenge.

    // TODO Backend:
    // Existing inventory document ko medicationId se UPDATE karna hai:
    //
    // medicationId = result.medicationId
    // remainingQuantity = result.remainingQuantity
    // adjustmentReason = result.reason
    // adjustmentSource = 'manual'
    // lastAdjustedAt = serverTimestamp
    // adjustedByUserId = currentUser.uid
    //
    // IMPORTANT:
    // Duplicate inventory document create NAHI karna.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${item.medicineName} count updated to '
            '${result.remainingQuantity}',
          ),
        ),
      );
  }

  // ============================================================
  // REFILL DETAIL
  // ============================================================

  Future<void> _openRefillDetail(InventoryItem item) async {
    final refilled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RefillAlertDetailScreen(inventoryItem: item),
      ),
    );

    if (!mounted) {
      return;
    }

    if (refilled == true) {
      setState(() {});

      // TODO Backend:
      // Firebase phase mein Refill Detail screen existing inventory
      // document update karegi aur inventory stream automatically
      // refreshed values provide karegi.
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      _buildSummary(),
                      const SizedBox(height: 12),
                      _buildFilters(),
                      const SizedBox(height: 10),
                      _buildInventoryList(),
                      const SizedBox(height: 2),
                      _buildAutoSyncCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _InventoryBottomBar(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 7, 20, 10),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Inventory',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // TODO Backend/Auth:
              // Current signed-in user's profile image yahan provide karni hai.
              const AppAvatar(
                size: 28,
                ringColor: AppColors.surface,
                ringWidth: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: AppColors.inventoryCardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_items.length} Medications',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tracked supply',
                  style: TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_lowStockCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.inventoryLowBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.inventoryLow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_lowStockCount LOW STOCK',
                    style: const TextStyle(
                      color: AppColors.inventoryLow,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Row(
      children: [
        _filterButton(title: 'All', filter: _InventoryFilter.all),
        const SizedBox(width: 7),
        _filterButton(title: 'Low Stock', filter: _InventoryFilter.lowStock),
        const SizedBox(width: 7),
        _filterButton(title: 'OK', filter: _InventoryFilter.ok),
      ],
    );
  }

  Widget _filterButton({
    required String title,
    required _InventoryFilter filter,
  }) {
    final selected = _selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.formAccent
              : AppColors.inventoryFilterBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected
                ? AppColors.surface
                : filter == _InventoryFilter.lowStock
                ? AppColors.inventoryLow
                : AppColors.formAccent,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INVENTORY LIST
  // ============================================================

  Widget _buildInventoryList() {
    final items = _visibleItems;

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: const Text(
          'No medications in this filter',
          style: TextStyle(color: AppColors.formSubtitle, fontSize: 10),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _inventoryCard(item),
        );
      }).toList(),
    );
  }

  Widget _inventoryCard(InventoryItem item) {
    final low = item.isLowStock;

    final statusColor = low ? AppColors.inventoryLow : AppColors.inventoryOk;

    return InkWell(
      onTap: () {
        _adjustCount(item);
      },
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(
              color: AppColors.inventoryCardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _medicineImage(item, statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.supplyLabel,
                        style: const TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 8.5,
                          height: 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: low
                        ? AppColors.inventoryLowBackground
                        : AppColors.inventoryOkBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    low ? 'LOW' : 'OK',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 7,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: item.supplyProgress,
                minHeight: 5,
                backgroundColor: AppColors.inventoryProgressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 7),
            if (low) _lowStockActions(item) else _okStockActions(item),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOW STOCK ACTIONS
  // ============================================================

  Widget _lowStockActions(InventoryItem item) {
    return Column(
      children: [
        const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.inventoryLow,
              size: 12,
            ),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Running low — order refill',
                style: TextStyle(
                  color: AppColors.inventoryLow,
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 33,
                child: FilledButton(
                  onPressed: () {
                    _openRefillDetail(item);
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.inventoryLow,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Refill →',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: SizedBox(
                height: 33,
                child: FilledButton(
                  onPressed: () {
                    _adjustCount(item);
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.inventoryAdjustBackground,
                    foregroundColor: AppColors.formAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Adjust Count',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // OK STOCK ACTIONS
  // ============================================================

  Widget _okStockActions(InventoryItem item) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.inventoryOk,
            size: 11,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              item.estimatedDaysRemaining >= 25
                  ? 'Sufficient supply'
                  : 'Sufficient through next refill',
              style: const TextStyle(
                color: AppColors.inventoryOk,
                fontSize: 8,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _adjustCount(item);
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(30, 24),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICINE IMAGE
  // ============================================================

  Widget _medicineImage(InventoryItem item, Color fallbackColor) {
    return Container(
      width: 40,
      height: 40,
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
                return Icon(
                  _medicineTypeIcon(item.medicineType),
                  color: fallbackColor,
                  size: 20,
                );
              },
            )
          : Icon(
              _medicineTypeIcon(item.medicineType),
              color: fallbackColor,
              size: 20,
            ),
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

  // ============================================================
  // AUTO-SYNC PHARMACY
  // ============================================================

  Widget _buildAutoSyncCard() {
    return InkWell(
      onTap: () {
        // TODO Backend / Integration:
        // Pharmacy account/provider connect flow open karna hai.
        // Linked pharmacy ID aur refill-sync permission current
        // authenticated user's account mein securely persist karni hai.

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Pharmacy auto-sync integration pending'),
            ),
          );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: AppColors.inventorySyncBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.local_pharmacy_outlined,
                color: AppColors.formAccent,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Sync Pharmacy',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Connect your pharmacy for automatic refill updates',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.sync_rounded,
              color: AppColors.formAccent,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM BAR
//
// Inventory Meds flow ka part hai,
// isliye Meds visually selected hai.
// ============================================================

class _InventoryBottomBar extends StatelessWidget {
  const _InventoryBottomBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.formAccent,
      unselectedItemColor: AppColors.fieldHint,
      backgroundColor: AppColors.surface,
      elevation: 5,
      iconSize: 19,
      selectedFontSize: 8,
      unselectedFontSize: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_outlined),
          activeIcon: Icon(Icons.medication_rounded),
          label: 'Meds',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        // TODO Navigation:
        // MedRemindShell mein initialIndex support ke baad clicked
        // bottom-navigation index ko exact selected tab ke saath
        // restore/open karna hai.

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MedRemindShell()),
          (route) => false,
        );
      },
    );
  }
}
