import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import 'inventory_data.dart';
import 'meds_data.dart';
import 'pharmacy_info_data.dart';
import 'add_edit_pharmacy_screen.dart';
import 'add_edit_pharmacy_data.dart';

/// ============================================================
/// PHARMACY DETAILS
///
/// PURPOSE:
/// Medication ke saath stored/linked pharmacy details dekhna.
///
/// KEY ELEMENTS:
/// • Pharmacy name
/// • Phone
/// • Optional address
/// • Linked medications
/// • Opening hours
///
/// USER ACTIONS:
/// • Call
/// • Directions
/// • Edit
///
/// NAVIGATION:
/// Edit Pharmacy Details → Add/Edit Pharmacy
///
/// TODO Backend:
/// Pharmacy repository, phone integration, maps/directions aur
/// edit persistence Firebase/current user data se connect karna hai.
/// ============================================================
class PharmacyInfoScreen extends StatefulWidget {
  const PharmacyInfoScreen({super.key, this.pharmacyId});

  final String? pharmacyId;

  @override
  State<PharmacyInfoScreen> createState() => _PharmacyInfoScreenState();
}

class _PharmacyInfoScreenState extends State<PharmacyInfoScreen> {
  late final PharmacyInfoData _pharmacy = PharmacyInfoData.current();

  late final List<InventoryItem> _inventory = InventoryData.inventory();

  DateTime get _now => DateTime.now();

  List<InventoryItem> get _linkedMedicines {
    return _pharmacy.linkedInventoryItems(_inventory);
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _callPharmacy() {
    // TODO Integration:
    // url_launcher package ke tel: URI se _pharmacy.phone
    // phone dialer mein open karna hai.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Calling ${_pharmacy.name} — integration pending'),
        ),
      );
  }

  void _openDirections() {
    // TODO Integration:
    // Pharmacy latitude/longitude ya address ko Google Maps /
    // Apple Maps directions mein open karna hai.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Directions to ${_pharmacy.name} — integration pending',
          ),
        ),
      );
  }

  Future<void> _editPharmacy() async {
    final result = await Navigator.of(context).push<AddEditPharmacyResult>(
      MaterialPageRoute(
        builder: (_) => AddEditPharmacyScreen(pharmacyId: _pharmacy.id),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    // TODO Backend:
    // Real repository/Firestore phase mein AddEditPharmacyScreen
    // existing pharmacy document update karegi aur Pharmacy Info
    // stream automatically updated data rebuild karegi.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Pharmacy details saved')));
  }

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
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                  child: Column(
                    children: [
                      _buildPharmacyHero(),
                      const SizedBox(height: 16),
                      _buildContactCard(),
                      const SizedBox(height: 16),
                      _buildLinkedMedications(),
                      const SizedBox(height: 16),
                      _buildOpeningHours(),
                      const SizedBox(height: 18),
                      _buildEditButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _PharmacyBottomBar(),
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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pharmacy Details',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // TODO Backend/Auth:
              // Same current-user image source Home/Meds mein
              // use hone wali profile se load karni hai.
              const AppAvatar(
                size: 34,
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
  // PHARMACY HERO
  // ============================================================

  Widget _buildPharmacyHero() {
    final isOpen = _pharmacy.isOpenAt(_now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.inventoryOkBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_pharmacy_outlined,
              color: AppColors.inventoryOk,
              size: 27,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _pharmacy.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _pharmacy.openStatus(_now),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isOpen ? AppColors.inventoryOk : AppColors.inventoryLow,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOpen
                  ? AppColors.inventoryOkBackground
                  : AppColors.inventoryLowBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? AppColors.inventoryOk
                        : AppColors.inventoryLow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOpen ? 'OPEN NOW' : 'CLOSED',
                  style: TextStyle(
                    color: isOpen
                        ? AppColors.inventoryOk
                        : AppColors.inventoryLow,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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
  // CONTACT
  // ============================================================

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
              const Expanded(
                child: Text(
                  'CONTACT',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_pharmacy.isPrimary)
                const Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: AppColors.inventoryOk,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Primary Provider',
                      style: TextStyle(
                        color: AppColors.inventoryOk,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _contactRow(
            icon: Icons.phone_outlined,
            title: _pharmacy.phone,
            subtitle: 'Direct Pharmacy Line',
            onTap: _callPharmacy,
          ),
          if (_pharmacy.address != null) ...[
            const SizedBox(height: 14),
            _contactRow(
              icon: Icons.location_on_outlined,
              title: _pharmacy.address!,
              subtitle: _addressSubtitle,
              onTap: _openDirections,
            ),
          ],
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _callPharmacy,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.inventoryOk,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 19),
                    label: const Text(
                      'Call',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _openDirections,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.inventoryAdjustBackground,
                      foregroundColor: AppColors.inventoryOk,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.near_me_outlined, size: 19),
                    label: const Text(
                      'Directions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _addressSubtitle {
    final parts = <String>[];

    if (_pharmacy.distanceLabel != null) {
      parts.add(_pharmacy.distanceLabel!);
    }

    if (_pharmacy.landmark != null) {
      parts.add(_pharmacy.landmark!);
    }

    return parts.join(' · ');
  }

  Widget _contactRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.inventoryOkBackground,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.inventoryOk, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.fieldHint,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LINKED MEDICATIONS
  // ============================================================

  Widget _buildLinkedMedications() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
              const Expanded(
                child: Text(
                  'LINKED MEDICATIONS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.inventoryFilterBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_linkedMedicines.length} Prescriptions',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_linkedMedicines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No medications linked',
                style: TextStyle(color: AppColors.formSubtitle, fontSize: 13),
              ),
            )
          else
            for (var i = 0; i < _linkedMedicines.length; i++) ...[
              _linkedMedicationRow(_linkedMedicines[i]),
              if (i != _linkedMedicines.length - 1) const SizedBox(height: 12),
            ],
          if (_linkedMedicines.any((item) => item.isLowStock)) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.inventoryLow,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _lowStockMessage,
                    style: const TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _linkedMedicationRow(InventoryItem item) {
    final statusColor = item.isLowStock
        ? AppColors.inventoryLow
        : AppColors.inventoryOk;

    return Row(
      children: [
        _medicineImage(item, statusColor),
        const SizedBox(width: 11),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.supplyLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: item.isLowStock
                ? AppColors.inventoryLowBackground
                : AppColors.inventoryOkBackground,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            item.isLowStock ? 'LOW' : 'OK',
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String get _lowStockMessage {
    final lowItems = _linkedMedicines.where((item) => item.isLowStock).toList();

    if (lowItems.isEmpty) {
      return '';
    }

    final first = lowItems.first;
    final days = first.estimatedDaysRemaining;

    return '${first.medicineName} needs a refill in '
        '$days ${days == 1 ? 'day' : 'days'}.';
  }

  // ============================================================
  // MEDICINE IMAGE
  // ============================================================

  Widget _medicineImage(InventoryItem item, Color fallbackColor) {
    return Container(
      width: 44,
      height: 44,
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
                  size: 21,
                );
              },
            )
          : Icon(
              _medicineTypeIcon(item.medicineType),
              color: fallbackColor,
              size: 21,
            ),
    );
  }

  IconData _medicineTypeIcon(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
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
  // OPENING HOURS
  // ============================================================

  Widget _buildOpeningHours() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
          const Row(
            children: [
              Expanded(
                child: Text(
                  'OPENING HOURS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.schedule_rounded,
                color: AppColors.inventoryOk,
                size: 16,
              ),
              SizedBox(width: 5),
              Text(
                'Standard Hours',
                style: TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          for (var i = 0; i < _pharmacy.openingHours.length; i++) ...[
            _openingHourRow(_pharmacy.openingHours[i]),
            if (i != _pharmacy.openingHours.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _openingHourRow(PharmacyOpeningHours hours) {
    final closed = hours.isClosed;

    return Row(
      children: [
        Expanded(
          child: Text(
            hours.label,
            style: const TextStyle(
              color: AppColors.formAccent,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (closed)
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.inventoryLow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                hours.hoursLabel,
                style: const TextStyle(
                  color: AppColors.inventoryLow,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
          Text(
            hours.hoursLabel,
            style: const TextStyle(
              color: AppColors.inventoryOk,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // EDIT
  // ============================================================

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _editPharmacy,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.inventoryAdjustBackground,
          foregroundColor: AppColors.inventoryOk,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.edit_outlined, size: 19),
        label: const Text(
          'Edit Pharmacy Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class _PharmacyBottomBar extends StatelessWidget {
  const _PharmacyBottomBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.formAccent,
      unselectedItemColor: AppColors.fieldHint,
      backgroundColor: AppColors.surface,
      elevation: 5,
      iconSize: 22,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_rounded),
          label: 'Meds',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        // TODO Navigation:
        // MedRemindShell mein initialIndex support ke baad
        // exact clicked tab open karna hai.

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MedRemindShell()),
          (route) => false,
        );
      },
    );
  }
}
