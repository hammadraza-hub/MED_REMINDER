import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';

/// ============================================================
/// EDIT MEDICATION — existing medicine editing!
///
/// Meds list → card tap → YE SCREEN
///
/// Genius helpers (ye version se):
/// - _parseStrength — "500mg" → ("500", "mg") auto-split!
/// - _normalizeForm — koi bhi text → standard form!
/// - Smart inventory units — capsules/ml/doses!
///
/// System: AppColors + suite bar + tablet cap
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

    // "500mg" → ("500", "mg") — GENIUS split!
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
  // GENIUS HELPERS (ye version se!)
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
        if (unit.toLowerCase() == 'iu') return (number, 'IU');
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

    if (lower.contains('capsule')) return 'Capsule';
    if (lower.contains('liquid') ||
        lower.contains('syrup') ||
        lower.contains('solution') ||
        lower.contains('suspension')) {
      return 'Liquid';
    }
    if (lower.contains('inject')) return 'Injection';
    return 'Tablet';
  }

  /// Form ka image asset (fallback icon ke sath!)
  String _formAsset(String form) {
    final value = form.toLowerCase();

    if (value.contains('capsule')) return 'assets/images/capsule.jpg';
    if (value.contains('liquid') ||
        value.contains('syrup') ||
        value.contains('solution') ||
        value.contains('suspension')) {
      return 'assets/images/liquid.jpg';
    }
    if (value.contains('inject')) return 'assets/images/injection.jpg';
    return 'assets/images/tablet.jpg';
  }

  /// Inventory unit — form ke hisaab se (smart!)
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
      // TODO Backend: changes save (Phase 2)
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

      Navigator.pop(context); // wapas Meds!
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _changeSchedule() {
    // TODO: ScheduleScreen open — reuse hoga!
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule editor — Schedule screen se hoga!'),
      ),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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

      // Suite bar — app jaisi!
      bottomNavigationBar: const _SuiteBottomBar(currentIndex: 1),
    );
  }

  // ================= CONTENT =================
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- Photo ----
        _buildPhoto(),
        const SizedBox(height: 20),

        // ---- Details ----
        _sectionTitle('MEDICATION DETAILS'),
        const SizedBox(height: 14),

        _fieldLabel('Medication Name', required: true),
        const SizedBox(height: 6),
        _buildNameField(),
        const SizedBox(height: 14),

        _fieldLabel('Strength'),
        const SizedBox(height: 6),
        _buildStrengthRow(),
        const SizedBox(height: 16),

        _fieldLabel('Medication Form'),
        const SizedBox(height: 8),
        _buildFormGrid(),
        const SizedBox(height: 16),

        _fieldLabel('Special Instructions'),
        const SizedBox(height: 6),
        _buildInstructions(),
        const SizedBox(height: 24),

        // ---- Schedule ----
        _sectionTitle('SCHEDULE'),
        const SizedBox(height: 10),
        _buildScheduleCard(),
        const SizedBox(height: 24),

        // ---- Inventory ----
        _sectionTitle('INVENTORY'),
        const SizedBox(height: 10),
        _buildInventoryCard(),
        const SizedBox(height: 16),

        // ---- Notes ----
        _fieldLabel('Notes (optional)'),
        const SizedBox(height: 6),
        _buildNotes(),
        const SizedBox(height: 24),

        // ---- Save ----
        _buildSaveButton(),
        const SizedBox(height: 14),

        // ---- Discontinue (dangerous) ----
        TextButton(
          onPressed: _showDiscontinueDialog,
          child: const Text(
            'Discontinue this medication',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 14),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text(
                      'Edit Medication',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Cancel
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 3),

                  // Save (header se bhi!)
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMedication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.formAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Editing info
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 2),
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
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Changes saved automatically',
                        style: TextStyle(
                          color: AppColors.headerSubtext,
                          fontSize: 9.5,
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
          width: 86,
          height: 86,
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
                width: 58,
                height: 58,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.formAccent,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () {
            // TODO: image_picker se photo change (Phase 3 extension!)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo picker coming soon.')),
            );
          },
          child: const Text(
            'Change Photo',
            style: TextStyle(
              color: AppColors.formAccent,
              fontSize: 11,
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
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.formIcon),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(13, 14, 44, 13),
          suffixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.formAccent,
            size: 21,
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
            height: 50,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Unit dropdown (parse se auto-set!)
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.formAccent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUnit,
              dropdownColor: AppColors.formAccent,
              iconEnabledColor: Colors.white,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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
                setState(() => _selectedUnit = value);
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
            const SizedBox(width: 8),
            Expanded(child: _formButton('Capsule')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _formButton('Liquid')),
            const SizedBox(width: 8),
            Expanded(child: _formButton('Injection')),
          ],
        ),
      ],
    );
  }

  Widget _formButton(String form) {
    final selected = _selectedForm == form;

    return GestureDetector(
      onTap: () => setState(() => _selectedForm = form),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 9),
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
            // Form image (asset ya fallback!)
            Container(
              width: 44,
              height: 44,
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
                  width: 34,
                  height: 34,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.formAccent,
                    size: 22,
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
                  color: selected ? Colors.white : AppColors.formAccent,
                  fontSize: 12,
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
      constraints: const BoxConstraints(minHeight: 82),
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
          fontSize: 11.5,
          height: 1.45,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(13),
          hintText: 'Enter special instructions...',
          hintStyle: TextStyle(color: AppColors.fieldHintLight, fontSize: 11.5),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'After meals · Mon–Sun',
                  style: TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 10.5,
                  ),
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
                  'Change Schedule',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded, size: 11),
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
      padding: const EdgeInsets.all(14),
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
          // Form image (selected ka!)
          Container(
            width: 52,
            height: 52,
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
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.formAccent,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Count info — LIVE low-stock!
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Count',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLow
                      ? '$_currentCount ${_inventoryUnit()} remaining ⚠️'
                      : '$_currentCount ${_inventoryUnit()} remaining',
                  style: TextStyle(
                    color: isLow
                        ? AppColors.hintAccent
                        : AppColors.formSubtitle,
                    fontSize: 10,
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
                ? () => setState(() => _currentCount--)
                : null,
          ),

          // Count
          SizedBox(
            width: 36,
            child: Text(
              '$_currentCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Plus
          _counterButton(
            icon: Icons.add,
            filled: true,
            onTap: () => setState(() => _currentCount++),
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
        width: 34,
        height: 34,
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
          size: 18,
          color: disabled
              ? AppColors.fieldHint
              : filled
              ? Colors.white
              : AppColors.formAccent,
        ),
      ),
    );
  }

  // ================= NOTES =================
  Widget _buildNotes() {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outline),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(13),
          hintText: 'Add any personal notes about this medication...',
          hintStyle: TextStyle(color: AppColors.fieldHintLight, fontSize: 10.5),
        ),
      ),
    );
  }

  // ================= SAVE =================
  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveMedication,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          disabledBackgroundColor: AppColors.formAccent.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
        fontSize: 11,
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
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Discontinue medication?'),
          content: Text(
            '${_nameController.text.trim()} will be moved '
            'out of your active medications.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // TODO Backend: discontinue/archive (Phase 2)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medication discontinued.')),
                );

                Navigator.pop(context);
              },
              child: const Text(
                'Discontinue',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// SUITE BOTTOM BAR — app jaisi!
// ============================================================
class _SuiteBottomBar extends StatelessWidget {
  const _SuiteBottomBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.formAccent,
      unselectedItemColor: AppColors.fieldHint,
      backgroundColor: AppColors.surface,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_rounded),
          label: 'Meds',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Family',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MedRemindShell()),
          (route) => false,
        );
      },
    );
  }
}
