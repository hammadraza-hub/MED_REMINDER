import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
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
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    // Add/Edit Pharmacy Meds feature ka child screen hai.
    // Shared bottom bar se exact selected main tab open hoga.
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTopInfo(),

                        const SizedBox(height: 16),

                        _buildPharmacyForm(),

                        const SizedBox(height: 18),

                        _buildAssignmentHeader(),

                        const SizedBox(height: 12),

                        _buildMedicationAssignments(),

                        const SizedBox(height: 16),

                        _buildCaregiverSync(),

                        const SizedBox(height: 18),

                        _buildSaveButton(),

                        const SizedBox(height: 8),

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

      // Shared app-wide bottom navigation.
      // Pharmacy management Meds flow ka part hai.
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
                onTap: _cancel,
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  _isEdit ? 'Edit Pharmacy' : 'Add Pharmacy',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // TODO Backend/Auth:
              // Current user's same profile image jo Home/Meds
              // mein use hoti hai.
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
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Manage prescription contact & fulfillment',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.inventoryOkBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: AppColors.inventoryOk, size: 7),

              SizedBox(width: 6),

              Text(
                'Fulfillment\nActive',
                style: TextStyle(
                  color: AppColors.inventoryOk,
                  fontSize: 11,
                  height: 1.15,
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
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 17),
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
          _buildFieldLabel(
            title: 'Pharmacy Name',
            trailing: _isEdit ? 'Verified' : null,
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            validator: AddEditPharmacyData.validateName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: _fieldDecoration(hintText: 'Enter pharmacy name'),
          ),

          const SizedBox(height: 16),

          _buildFieldLabel(title: 'Phone Number'),

          const SizedBox(height: 8),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: AddEditPharmacyData.validatePhone,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: _fieldDecoration(
              hintText: 'Enter phone number',
              suffixIcon: Icons.phone_outlined,
            ),
          ),

          const SizedBox(height: 16),

          _buildFieldLabel(title: 'Address (optional)'),

          const SizedBox(height: 8),

          TextFormField(
            controller: _addressController,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: AppColors.inventoryOk,
              fontSize: 11,
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
      hintStyle: const TextStyle(color: AppColors.fieldHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.inventoryFilterBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      suffixIcon: suffixIcon == null
          ? null
          : Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.inventoryOkBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(suffixIcon, color: AppColors.inventoryOk, size: 19),
            ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.formAccent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inventoryLow),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inventoryLow),
      ),
      errorStyle: const TextStyle(
        color: AppColors.inventoryLow,
        fontSize: 11,
        height: 1.2,
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
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'This pharmacy will handle automatic refill requests for:',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Text(
          '$_connectedCount Connected',
          style: const TextStyle(
            color: AppColors.inventoryOk,
            fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      child: _medications.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'No active medications available',
                  style: TextStyle(color: AppColors.formSubtitle, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _medicineImage(item),

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
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  AddEditPharmacyData.unitScheduleLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

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
                  color: AppColors.formAccent,
                  size: 22,
                );
              },
            )
          : Icon(
              _medicineTypeIcon(item.medicineType),
              color: AppColors.formAccent,
              size: 22,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inventorySyncBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.sync_rounded,
              color: AppColors.formAccent,
              size: 22,
            ),
          ),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caregiver Real-time Sync',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Changes will immediately reflect for the linked care profile.',
                  style: TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 12,
                    height: 1.3,
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
  // SAVE / CANCEL
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.inventoryOk,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.inventoryOkBackground,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: _saving
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(
          _saving ? 'Saving...' : 'Save Pharmacy',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _saving ? null : _cancel,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.formAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: const Text(
        'Cancel',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
