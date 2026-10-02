import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';

/// ============================================================
/// EDIT MEDICATION — existing medicine editing!
///
/// Meds list → card tap → YE SCREEN
///
/// Genius helpers:
/// - _parseStrength — "500mg" → ("500", "mg") auto-split!
/// - _normalizeForm — koi bhi text → standard form!
/// - Smart inventory units — capsules/ml/doses!
///
/// System: AppColors + shared bottom bar + tablet cap
///
/// TODO Backend:
/// - Current user/family member medication Firestore document load
/// - Medication changes update
/// - Inventory document update by medicationId
/// - Schedule persistence
/// - Medication photo upload/storage
/// - Discontinue/archive persistence
/// ============================================================
class EditMedicationScreen extends StatefulWidget {
  const EditMedicationScreen({
    super.key,
    required this.medicineName,
    required this.medicineStrength,
    required this.medicineForm,
    required this.dosesPerDay,
    required this.pillsRemaining,
    required this.isLowStock,
  });

  final String medicineName;
  final String medicineStrength;
  final String medicineForm;
  final int dosesPerDay;
  final int pillsRemaining;
  final bool isLowStock;

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  // ================= CONTROLLERS =================
  late final TextEditingController _nameController;
  late final TextEditingController _strengthController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _notesController;

  // ================= STATE =================
  late String _selectedForm;
  String _selectedUnit = 'mg';
  late int _currentCount;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // "500mg" → ("500", "mg")
    final parsedStrength = _parseStrength(widget.medicineStrength);

    // Existing data → PRE-FILL
    _nameController = TextEditingController(text: widget.medicineName);
    _strengthController = TextEditingController(text: parsedStrength.$1);
    _selectedUnit = parsedStrength.$2;

    _instructionsController = TextEditingController(
      text: 'Take with food after breakfast, avoid grapefruit',
    );

    _notesController = TextEditingController();
    _selectedForm = _normalizeForm(widget.medicineForm);
    _currentCount = widget.pillsRemaining;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  /// "500mg" / "500 mg" / "500" → ("500", "mg")
  (String, String) _parseStrength(String value) {
    final text = value.trim();

    final match = RegExp(
      r'^([\d.]+)\s*(mg|mcg|ml|iu|%)?$',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      final number = match.group(1) ?? text;
      final unit = match.group(2);

      if (unit != null) {
        if (unit.toLowerCase() == 'iu') {
          return (number, 'IU');
        }

        return (number, unit.toLowerCase());
      }

      return (number, 'mg');
    }

    final numberOnly = text.replaceAll(RegExp(r'[^\d.]'), '');

    return (numberOnly.isEmpty ? text : numberOnly, 'mg');
  }

  /// Koi bhi text → standard form ("TABLETS BP" → "Tablet")
  String _normalizeForm(String value) {
    final lower = value.toLowerCase();

    if (lower.contains('capsule')) {
      return 'Capsule';
    }

    if (lower.contains('liquid') ||
        lower.contains('syrup') ||
        lower.contains('solution') ||
        lower.contains('suspension')) {
      return 'Liquid';
    }

    if (lower.contains('inject')) {
      return 'Injection';
    }

    return 'Tablet';
  }

  /// Form ka image asset (fallback icon ke sath!)
  String _formAsset(String form) {
    final value = form.toLowerCase();

    if (value.contains('capsule')) {
      return 'assets/images/capsule.jpg';
    }

    if (value.contains('liquid') ||
        value.contains('syrup') ||
        value.contains('solution') ||
        value.contains('suspension')) {
      return 'assets/images/liquid.jpg';
    }

    if (value.contains('inject')) {
      return 'assets/images/injection.jpg';
    }

    return 'assets/images/tablet.jpg';
  }

  /// Inventory unit — form ke hisaab se
  String _inventoryUnit() {
    switch (_selectedForm) {
      case 'Capsule':
        return 'capsules';
      case 'Liquid':
        return 'ml';
      case 'Injection':
        return 'doses';
      default:
        return 'tablets';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  // ================= ACTIONS =================
  Future<void> _saveMedication() async {
    if (_nameController.text.trim().isEmpty ||
        _strengthController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication name and strength are required.'),
        ),
      );

      return;
    }

    setState(() => _isSaving = true);

    try {
      // TODO Backend:
      // Update existing medication document for current user/family member.
      //
      // Inventory must update the EXISTING inventory document using
      // medicationId instead of creating a duplicate inventory document.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${_nameController.text.trim()} updated!\n'
              'Count: $_currentCount ${_inventoryUnit()}',
            ),
          ),
        );

      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _changeSchedule() {
    // TODO Backend:
    // Reuse ScheduleScreen and persist schedule against medicationId.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule editor — Schedule screen se hoga!'),
      ),
    );
  }

  // ================= SHARED BOTTOM NAVIGATION =================
  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ],
      ),

      // Edit Medication belongs to Meds.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ================= CONTENT =================
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- Photo ----
        _buildPhoto(),
        const SizedBox(height: 22),

        // ---- Details ----
        _sectionTitle('MEDICATION DETAILS'),
        const SizedBox(height: 15),

        _fieldLabel('Medication Name', required: true),
        const SizedBox(height: 7),
        _buildNameField(),
        const SizedBox(height: 16),

        _fieldLabel('Strength'),
        const SizedBox(height: 7),
        _buildStrengthRow(),
        const SizedBox(height: 18),

        _fieldLabel('Medication Form'),
        const SizedBox(height: 9),
        _buildFormGrid(),
        const SizedBox(height: 18),

        _fieldLabel('Special Instructions'),
        const SizedBox(height: 7),
        _buildInstructions(),
        const SizedBox(height: 26),

        // ---- Schedule ----
        _sectionTitle('SCHEDULE'),
        const SizedBox(height: 11),
        _buildScheduleCard(),
        const SizedBox(height: 26),

        // ---- Inventory ----
        _sectionTitle('INVENTORY'),
        const SizedBox(height: 11),
        _buildInventoryCard(),
        const SizedBox(height: 18),

        // ---- Notes ----
        _fieldLabel('Notes (optional)'),
        const SizedBox(height: 7),
        _buildNotes(),
        const SizedBox(height: 26),

        // ---- Save ----
        _buildSaveButton(),
        const SizedBox(height: 16),

        // ---- Discontinue ----
        TextButton(
          onPressed: _showDiscontinueDialog,
          child: const Text(
            'Discontinue this medication',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 15),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.surface,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 3),

                  const Expanded(
                    child: Text(
                      'Edit Medication',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Cancel
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 3),

                  // Save (header se bhi!)
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMedication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.formAccent,
                        foregroundColor: AppColors.surface,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Editing info
              Padding(
                padding: const EdgeInsets.only(left: 45, top: 3),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editing: ${widget.medicineName} '
                        '${widget.medicineStrength}',
                        style: const TextStyle(
                          color: AppColors.headerSubtext,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Changes are saved when you tap Save',
                        style: TextStyle(
                          color: AppColors.headerSubtext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PHOTO =================
  Widget _buildPhoto() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.formAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                _formAsset(_selectedForm),
                fit: BoxFit.contain,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.formAccent,
                  size: 34,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),

        GestureDetector(
          onTap: () {
            // TODO Backend:
            // Use image_picker + Firebase Storage and save image URL
            // against this medication document.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo picker coming soon.')),
            );
          },
          child: const Text(
            'Change Photo',
            style: TextStyle(
              color: AppColors.formAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.formAccent,
            ),
          ),
        ),
      ],
    );
  }

  // ================= NAME =================
  Widget _buildNameField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.formIcon),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(13, 15, 44, 13),
          suffixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.formAccent,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ================= STRENGTH + UNIT =================
  Widget _buildStrengthRow() {
    return Row(
      children: [
        // Number input
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.formIcon),
              borderRadius: BorderRadius.circular(9),
            ),
            child: TextField(
              controller: _strengthController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 9),

        // Unit dropdown
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppColors.formAccent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUnit,
              dropdownColor: AppColors.formAccent,
              iconEnabledColor: AppColors.surface,
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(value: 'mg', child: Text('mg')),
                DropdownMenuItem(value: 'mcg', child: Text('mcg')),
                DropdownMenuItem(value: 'ml', child: Text('ml')),
                DropdownMenuItem(value: 'IU', child: Text('IU')),
                DropdownMenuItem(value: '%', child: Text('%')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedUnit = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ================= FORM GRID =================
  Widget _buildFormGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _formButton('Tablet')),
            const SizedBox(width: 9),
            Expanded(child: _formButton('Capsule')),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(child: _formButton('Liquid')),
            const SizedBox(width: 9),
            Expanded(child: _formButton('Injection')),
          ],
        ),
      ],
    );
  }

  Widget _formButton(String form) {
    final selected = _selectedForm == form;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedForm = form;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.formAccent,
            width: selected ? 1.6 : 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Form image
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.surface
                      : AppColors.formAccent.withValues(alpha: 0.20),
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  _formAsset(form),
                  fit: BoxFit.contain,
                  width: 36,
                  height: 36,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.formAccent,
                    size: 23,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 9),

            Flexible(
              child: Text(
                form,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.surface : AppColors.formAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INSTRUCTIONS =================
  Widget _buildInstructions() {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.formIcon),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TextField(
        controller: _instructionsController,
        maxLines: 3,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.45,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(13),
          hintText: 'Enter special instructions...',
          hintStyle: TextStyle(color: AppColors.fieldHintLight, fontSize: 13),
        ),
      ),
    );
  }

  // ================= SCHEDULE =================
  Widget _buildScheduleCard() {
    final frequency = widget.dosesPerDay <= 1
        ? 'Once Daily'
        : '${widget.dosesPerDay}x Daily';

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 16, 13, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  '$frequency · 8:30 AM + 8:00 PM',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'After meals · Mon–Sun',
                  style: TextStyle(color: AppColors.formSubtitle, fontSize: 13),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: _changeSchedule,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.formAccent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= INVENTORY =================
  Widget _buildInventoryCard() {
    final isLow = _currentCount <= 10;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Form image
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.formAccent.withValues(alpha: 0.15),
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                _formAsset(_selectedForm),
                fit: BoxFit.contain,
                width: 42,
                height: 42,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.formAccent,
                  size: 25,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Count info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Count',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isLow
                      ? '$_currentCount ${_inventoryUnit()} remaining ⚠️'
                      : '$_currentCount ${_inventoryUnit()} remaining',
                  style: TextStyle(
                    color: isLow
                        ? AppColors.hintAccent
                        : AppColors.formSubtitle,
                    fontSize: 12,
                    fontWeight: isLow ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Minus
          _counterButton(
            icon: Icons.remove,
            onTap: _currentCount > 0
                ? () {
                    setState(() {
                      _currentCount--;
                    });
                  }
                : null,
          ),

          // Count
          SizedBox(
            width: 40,
            child: Text(
              '$_currentCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Plus
          _counterButton(
            icon: Icons.add,
            filled: true,
            onTap: () {
              setState(() {
                _currentCount++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _counterButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? AppColors.formAccent : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: disabled
                ? AppColors.outline
                : filled
                ? AppColors.formAccent
                : AppColors.outline,
          ),
        ),
        child: Icon(
          icon,
          size: 19,
          color: disabled
              ? AppColors.fieldHint
              : filled
              ? AppColors.surface
              : AppColors.formAccent,
        ),
      ),
    );
  }

  // ================= NOTES =================
  Widget _buildNotes() {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outline),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(13),
          hintText: 'Add any personal notes about this medication...',
          hintStyle: TextStyle(color: AppColors.fieldHintLight, fontSize: 13),
        ),
      ),
    );
  }

  // ================= SAVE =================
  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveMedication,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          disabledBackgroundColor: AppColors.formAccent.withValues(alpha: 0.6),
          foregroundColor: AppColors.surface,
          elevation: 3,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ================= COMMON =================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.headerDark,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.formAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  // ================= DISCONTINUE =================
  void _showDiscontinueDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Discontinue medication?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '${_nameController.text.trim()} will be moved '
            'out of your active medications.',
            style: const TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // TODO Backend:
                // Set this medication to archived/discontinued for the
                // current user/family member. Do not delete history.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medication discontinued.')),
                );

                Navigator.pop(context);
              },
              child: const Text(
                'Discontinue',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
