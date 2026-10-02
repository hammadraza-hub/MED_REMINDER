import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'inventory_data.dart';
import 'meds_data.dart';
import 'refill_alert_detail_data.dart';
import 'pharmacy_info_screen.dart';

/// ============================================================
/// REFILL ALERT DETAIL
///
/// PURPOSE:
/// Low-stock medication ki refill information aur actions.
///
/// Dynamic values:
/// • Medication name / strength
/// • Remaining quantity
/// • Supply progress
/// • Estimated run-out date
/// • Pharmacy information
///
/// USER ACTIONS:
/// • Mark as Refilled
/// • Call Pharmacy
/// • Snooze alert for 3 days
///
/// TODO Backend:
/// Firebase inventory/refill/pharmacy repositories se real data
/// load/persist karna hai.
/// ============================================================
class RefillAlertDetailScreen extends StatefulWidget {
  const RefillAlertDetailScreen({super.key, required this.inventoryItem});

  final InventoryItem inventoryItem;

  @override
  State<RefillAlertDetailScreen> createState() =>
      _RefillAlertDetailScreenState();
}

class _RefillAlertDetailScreenState extends State<RefillAlertDetailScreen> {
  late final RefillAlertDetailData _data;

  @override
  void initState() {
    super.initState();

    _data = RefillAlertDetailData.fromInventoryItem(widget.inventoryItem);
  }

  // ============================================================
  // MARK AS REFILLED
  // ============================================================

  Future<void> _markAsRefilled() async {
    // Frontend dummy behavior:
    // Refill par inventory ko full package quantity tak reset.
    setState(() {
      widget.inventoryItem.remainingQuantity =
          widget.inventoryItem.packageQuantity;
    });

    // TODO Backend:
    // Existing inventory document ko medicationId se update:
    //
    // remainingQuantity = packageQuantity / actual refill quantity
    // lastAdjustedAt = serverTimestamp
    // adjustmentSource = 'refill'
    // adjustedByUserId = currentUser.uid
    //
    // Refill history/event bhi persist karna hai.
    // Duplicate inventory document create NAHI karna.

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${widget.inventoryItem.medicineName} marked as refilled',
          ),
        ),
      );

    Navigator.of(context).pop(true);
  }

  // ============================================================
  // CALL PHARMACY
  // ============================================================

  void _callPharmacy() {
    // TODO Backend / Integration:
    // Linked pharmacy phone number repository se load karke
    // url_launcher ke tel: URI ke through phone dialer open karna hai.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Calling ${_data.pharmacy.name} — integration pending'),
        ),
      );
  }

  // ============================================================
  // PHARMACY INFO
  // ============================================================

  void _openPharmacyInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PharmacyInfoScreen(pharmacyId: _data.pharmacy.id),
      ),
    );
  }

  // ============================================================
  // SNOOZE
  // ============================================================

  void _snoozeAlert() {
    // TODO Backend / Notifications:
    // Existing refill alert document update:
    //
    // snoozedUntil = serverTimestamp + 3 days
    // snoozedByUserId = currentUser.uid
    //
    // Local/push refill notification bhi reschedule karni hai.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Refill alert snoozed for 3 days')),
      );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    // Refill Alert Detail Meds feature ka child screen hai.
    // Shared bottom bar se clicked main tab directly open hoga.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
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
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  child: Column(
                    children: [
                      _buildMedicationCard(),

                      const SizedBox(height: 14),

                      _buildRunOutCard(),

                      const SizedBox(height: 14),

                      _buildPharmacyCard(),

                      const SizedBox(height: 16),

                      _buildMarkRefilledButton(),

                      const SizedBox(height: 10),

                      _buildCallPharmacyButton(),

                      const SizedBox(height: 16),

                      _buildSnoozeButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Shared app-wide bottom navigation.
      // Refill flow Meds feature ka part hai.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavigationTap,
      ),
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
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(22),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Refill Alert Detail',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // TODO Backend/Auth:
              // Current signed-in user's actual profile image
              // Home ke same profile source se load karni hai.
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.headerDark,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICATION SUMMARY
  // ============================================================

  Widget _buildMedicationCard() {
    final item = widget.inventoryItem;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 17, 15, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
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
            children: [
              _medicineImage(item),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _data.medicineDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _data.supplyStatusLabel,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _data.remainingCount,
            style: const TextStyle(
              color: AppColors.formAccent,
              fontSize: 29,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            '${_data.remainingUnit} remaining',
            style: const TextStyle(
              color: AppColors.formAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _data.supplyProgress,
              minHeight: 6,
              backgroundColor: AppColors.inventoryProgressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(
                _data.isLowStock
                    ? AppColors.inventoryLow
                    : AppColors.inventoryOk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RUN OUT DATE
  // ============================================================

  Widget _buildRunOutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.inventoryCardShadow,
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.formAccent,
            size: 21,
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Text(
              'Runs out on',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              _data.estimatedRunOutDateLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHARMACY
  // ============================================================

  Widget _buildPharmacyCard() {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: _openPharmacyInfo,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 17),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: AppColors.inventoryCardShadow,
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR PHARMACY',
                style: TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.inventoryOkBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_outlined,
                      color: AppColors.inventoryOk,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _data.pharmacy.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _data.pharmacy.openStatus,
                          style: const TextStyle(
                            color: AppColors.inventoryOk,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.formSubtitle,
                    size: 20,
                  ),

                  const SizedBox(width: 6),

                  InkWell(
                    onTap: _callPharmacy,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.inventoryOkBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.inventoryOk,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildMarkRefilledButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _markAsRefilled,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.inventoryOk,
          foregroundColor: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
        label: const Text(
          'Mark as Refilled',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCallPharmacyButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _callPharmacy,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.inventoryAdjustBackground,
          foregroundColor: AppColors.inventoryOk,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.phone_in_talk_outlined, size: 19),
        label: const Text(
          'Call Pharmacy',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSnoozeButton() {
    return TextButton(
      onPressed: _snoozeAlert,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.formAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: const Text(
        'Snooze this alert for 3 days',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // ============================================================
  // MEDICINE IMAGE
  // ============================================================

  Widget _medicineImage(InventoryItem item) {
    return Container(
      width: 48,
      height: 48,
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
                  color: AppColors.formAccent,
                  size: 24,
                );
              },
            )
          : Icon(
              _medicineTypeIcon(item.medicineType),
              color: AppColors.formAccent,
              size: 24,
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
}
