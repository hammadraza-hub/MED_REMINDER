import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import 'add_edit_pharmacy_data.dart';
import 'inventory_data.dart';
import 'meds_data.dart';

/// ============================================================
/// ADD / EDIT PHARMACY
///
/// PURPOSE:
/// Pharmacy contact info store/update karna aur medications
/// assign karna.
///
/// KEY ELEMENTS:
/// • Pharmacy name
/// • Phone
/// • Optional address
/// • Medication assignments
///
/// ACTIONS:
/// • Save Pharmacy
/// • Assign/unassign one or more medications
/// • Cancel
///
/// NAVIGATION:
/// Save / Cancel → Pharmacy Info
///
/// TODO Backend:
/// Add mode mein pharmacy document create karna hai.
/// Edit mode mein existing pharmacy document UPDATE karna hai.
/// Edit par duplicate document create NAHI karna.
/// ============================================================
class AddEditPharmacyScreen extends StatefulWidget {
  const AddEditPharmacyScreen({super.key, this.pharmacyId});

  /// null → Add mode
  /// non-null → Edit mode
  final String? pharmacyId;

  @override
  State<AddEditPharmacyScreen> createState() => _AddEditPharmacyScreenState();
}

class _AddEditPharmacyScreenState extends State<AddEditPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  late final List<InventoryItem> _medications;

  late Set<String> _selectedMedicationIds;

  bool _saving = false;

  bool get _isEdit => widget.pharmacyId != null;

  int get _connectedCount {
    return _selectedMedicationIds.length;
  }

  @override
  void initState() {
    super.initState();

    final existing = AddEditPharmacyData.pharmacyForEdit(widget.pharmacyId);

    _nameController = TextEditingController(text: existing?.name ?? '');

    _phoneController = TextEditingController(text: existing?.phone ?? '');

    _addressController = TextEditingController(text: existing?.address ?? '');

    _selectedMedicationIds = AddEditPharmacyData.initialSelectedMedicationIds(
      existing,
    );

    _medications = AddEditPharmacyData.medications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  // ============================================================
  // MEDICATION ASSIGNMENT
  // ============================================================

  void _toggleMedication(InventoryItem item, bool selected) {
    setState(() {
      if (selected) {
        _selectedMedicationIds.add(item.medicationId);
      } else {
        _selectedMedicationIds.remove(item.medicationId);
      }
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final address = AddEditPharmacyData.normalizeOptionalText(
      _addressController.text,
    );

    final result = AddEditPharmacyResult(
      pharmacyId: widget.pharmacyId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: address.isEmpty ? null : address,
      linkedMedicationIds: _selectedMedicationIds.toList(),
    );

    // TODO Backend:
    //
    // ADD MODE:
    // Current user / selected member ke under new pharmacy
    // document create karna hai.
    //
    // EDIT MODE:
    // result.pharmacyId ke existing pharmacy document ko update
    // karna hai. Duplicate document create NAHI karna.
    //
    // Persist:
    // name
    // phone
    // address
    // linkedMedicationIds
    // updatedAt = serverTimestamp
    // updatedByUserId = currentUser.uid
    //
    // Medication documents mein linkedPharmacyId relation bhi
    // repository transaction/batch ke through synchronize karna hai.

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    Navigator.of(context).pop(result);
  }

  void _cancel() {
    Navigator.of(context).pop();
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 13, 18, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTopInfo(),

                        const SizedBox(height: 12),

                        _buildPharmacyForm(),

                        const SizedBox(height: 14),

                        _buildAssignmentHeader(),

                        const SizedBox(height: 9),

                        _buildMedicationAssignments(),

                        const SizedBox(height: 12),

                        _buildCaregiverSync(),

                        const SizedBox(height: 14),

                        _buildSaveButton(),

                        const SizedBox(height: 6),

                        _buildCancelButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const _AddEditPharmacyBottomBar(),
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
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 12),
          child: Row(
            children: [
              InkWell(
                onTap: _cancel,
                borderRadius: BorderRadius.circular(22),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 23,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  _isEdit ? 'Edit Pharmacy' : 'Add Pharmacy',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // TODO Backend/Auth:
              // Current user's same profile image jo Home/Meds
              // mein use hoti hai.
              const AppAvatar(
                size: 30,
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
  // TOP INFO
  // ============================================================

  Widget _buildTopInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PHARMACY DETAILS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 3),

              Text(
                'Manage prescription contact & fulfillment',
                style: TextStyle(color: AppColors.formAccent, fontSize: 9),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.inventoryOkBackground,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: AppColors.inventoryOk, size: 6),
              SizedBox(width: 5),
              Text(
                'Fulfillment\nActive',
                style: TextStyle(
                  color: AppColors.inventoryOk,
                  fontSize: 8,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildPharmacyForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          _buildFieldLabel(
            title: 'Pharmacy Name',
            trailing: _isEdit ? 'Verified' : null,
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            validator: AddEditPharmacyData.validateName,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            decoration: _fieldDecoration(hintText: 'Enter pharmacy name'),
          ),

          const SizedBox(height: 12),

          _buildFieldLabel(title: 'Phone Number'),

          const SizedBox(height: 6),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: AddEditPharmacyData.validatePhone,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            decoration: _fieldDecoration(
              hintText: 'Enter phone number',
              suffixIcon: Icons.phone_outlined,
            ),
          ),

          const SizedBox(height: 12),

          _buildFieldLabel(title: 'Address (optional)'),

          const SizedBox(height: 6),

          TextFormField(
            controller: _addressController,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
            decoration: _fieldDecoration(hintText: 'Enter pharmacy address'),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel({required String title, String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: AppColors.inventoryOk,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.fieldHint, fontSize: 10),
      filled: true,
      fillColor: AppColors.inventoryFilterBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: suffixIcon == null
          ? null
          : Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.inventoryOkBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(suffixIcon, color: AppColors.inventoryOk, size: 16),
            ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.formAccent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.inventoryLow),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.inventoryLow),
      ),
    );
  }

  // ============================================================
  // ASSIGNMENTS HEADER
  // ============================================================

  Widget _buildAssignmentHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASSIGN TO MEDICATIONS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 3),

              Text(
                'This pharmacy will handle automatic refill requests for:',
                style: TextStyle(color: AppColors.formAccent, fontSize: 8),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Text(
          '$_connectedCount Connected',
          style: const TextStyle(
            color: AppColors.inventoryOk,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MEDICATION ASSIGNMENTS
  // ============================================================

  Widget _buildMedicationAssignments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.inventoryCardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _medications.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No active medications available',
                  style: TextStyle(color: AppColors.formSubtitle, fontSize: 10),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < _medications.length; i++) ...[
                  _medicationAssignmentRow(_medications[i]),

                  if (i != _medications.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.inventoryProgressTrack,
                    ),
                ],
              ],
            ),
    );
  }

  Widget _medicationAssignmentRow(InventoryItem item) {
    final selected = _selectedMedicationIds.contains(item.medicationId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _medicineImage(item),

          const SizedBox(width: 9),

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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  AddEditPharmacyData.unitScheduleLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          Switch(
            value: selected,
            onChanged: (value) {
              _toggleMedication(item, value);
            },
            activeTrackColor: AppColors.inventoryOk,
            activeThumbColor: AppColors.surface,
            inactiveTrackColor: AppColors.inventoryProgressTrack,
            inactiveThumbColor: AppColors.surface,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICINE IMAGE
  // ============================================================

  Widget _medicineImage(InventoryItem item) {
    return Container(
      width: 38,
      height: 38,
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
                  size: 19,
                );
              },
            )
          : Icon(
              _medicineTypeIcon(item.medicineType),
              color: AppColors.formAccent,
              size: 19,
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
  // CAREGIVER SYNC
  // ============================================================

  Widget _buildCaregiverSync() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.inventorySyncBackground,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.sync_rounded,
              color: AppColors.formAccent,
              size: 19,
            ),
          ),

          SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caregiver Real-time Sync',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Changes will immediately reflect for the linked care profile.',
                  style: TextStyle(color: AppColors.formSubtitle, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE / CANCEL
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.inventoryOk,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.inventoryOkBackground,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: _saving
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 17),
        label: Text(
          _saving ? 'Saving...' : 'Save Pharmacy',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _saving ? null : _cancel,
      style: TextButton.styleFrom(foregroundColor: AppColors.formAccent),
      child: const Text(
        'Cancel',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class _AddEditPharmacyBottomBar extends StatelessWidget {
  const _AddEditPharmacyBottomBar();

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
        // MedRemindShell initialIndex support ke baad
        // clicked tab ko exact index par open karna hai.

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MedRemindShell()),
          (route) => false,
        );
      },
    );
  }
}
