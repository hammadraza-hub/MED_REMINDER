import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import 'schedule_screen.dart';

/// ============================================================
/// ADD MEDICATION — MANUAL ENTRY
///
/// Teeno raste se aata hai:
/// 1. Add Medication → Manual Entry button
/// 2. Add Medication → "Can't find? Add Manually" link
/// 3. Scan → "Or enter manually" (fallback)
///
/// Features: naam + strength + unit (dropdown+chips)
/// + form cards (images/icons) + color selector + instructions
///
/// System: AppColors + suite bar — Home/Meds jaisi!
/// ============================================================
class AddManualScreen extends StatefulWidget {
  const AddManualScreen({
    super.key,
    // Scan fallback → pre-fill (optional!)
    this.prefillName,
    this.prefillStrength,
    this.prefillInstructions,
  });

  final String? prefillName;
  final String? prefillStrength;
  final String? prefillInstructions;

  @override
  State<AddManualScreen> createState() => _AddManualScreenState();
}

class _AddManualScreenState extends State<AddManualScreen> {
  // ================= CONTROLLERS =================
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _instructionsController = TextEditingController();

  // ================= STATE =================
  String _selectedUnit = 'mg';
  String _selectedForm = 'Tablet';
  int _selectedColor = 6; // green default (design!)

  bool _nameError = false;
  bool _strengthError = false;

  // ================= UNITS (5 — design!) =================
  static const List<String> _units = ['mg', 'mcg', 'ml', 'IU', '%'];

  // ================= FORM OPTIONS (images + fallback icons!) =================
  // Images assets mein hain? → dikheingi | Nahi? → icon fallback
  static const List<({String title, String asset, IconData fallbackIcon})>
  _formOptions = [
    (
      title: 'Tablet',
      asset: 'assets/images/tablet.jpg',
      fallbackIcon: Icons.medication_outlined,
    ),
    (
      title: 'Capsule',
      asset: 'assets/images/capsule.jpg',
      fallbackIcon: Icons.medication_liquid_outlined,
    ),
    (
      title: 'Liquid',
      asset: 'assets/images/liquid.jpg',
      fallbackIcon: Icons.water_drop_outlined,
    ),
    (
      title: 'Injection',
      asset: 'assets/images/injection.jpg',
      fallbackIcon: Icons.vaccines_outlined,
    ),
  ];

  // ================= COLORS (7 — design!) =================
  static const List<(Color, String)> _colorOptions = [
    (Colors.white, 'White'),
    (Color(0xFFFFE878), 'Yellow'),
    (Color(0xFFFFB7D2), 'Pink'),
    (Color(0xFFBEE7FA), 'Blue'),
    (Color(0xFFFFD3A7), 'Orange'),
    (Color(0xFFFFC0BD), 'Peach'),
    (Color(0xFF00745C), 'Green'), // ← default!
  ];

  @override
  void initState() {
    super.initState();

    // Scan fallback → pre-fill!
    _nameController.text = widget.prefillName ?? '';
    _strengthController.text = widget.prefillStrength ?? '';
    _instructionsController.text = widget.prefillInstructions ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // ================= ACTIONS =================
  void _continueToSchedule() {
    final name = _nameController.text.trim();
    final strength = _strengthController.text.trim();

    setState(() {
      _nameError = name.isEmpty;
      _strengthError = strength.isEmpty;
    });

    if (_nameError || _strengthError) return;

    // Schedule screen — Step 2!
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleScreen(
          medicineName: name,
          medicineStrength: '$strength $_selectedUnit',
        ),
      ),
    );
  }

  void _saveDraft() {
    // TODO Backend: draft save (local storage — Phase 1.5)
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Draft saved — baad mein complete!')),
      );
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ],
      ),

      // Suite bar — Home/Meds/Scan/Review jaisi!
      bottomNavigationBar: const _SuiteBottomBar(currentIndex: 1),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Add Medication',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // RX VERIFIED badge (design!)
                Container(
                  height: 23,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: AppColors.formAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 11),
                      SizedBox(width: 4),
                      Text(
                        'RX VERIFIED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),

                // Profile avatar
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.formIcon,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= FORM =================
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEDICATION DETAILS',
          style: TextStyle(
            color: AppColors.headerDark,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // ---- Naam ----
        _buildLabel('Medication Name', required: true),
        const SizedBox(height: 5),
        _nameField(),
        const SizedBox(height: 14),

        // ---- Strength + unit ----
        _buildLabel('Strength', required: true),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(child: _strengthField()),
            const SizedBox(width: 8),
            _buildUnitDropdown(),
          ],
        ),
        const SizedBox(height: 8),

        // ---- Unit chips (quick select!) ----
        Row(
          children: List.generate(_units.length, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == _units.length - 1 ? 0 : 7,
                ),
                child: _buildUnitChip(_units[index]),
              ),
            );
          }),
        ),
        const SizedBox(height: 15),

        // ---- Form selector ----
        Row(
          children: [
            const Expanded(
              child: Text(
                'Medication Form',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              '4 Formats',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 8.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        // Form cards — 2x2 grid (images ya icons!)
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col != 0) const SizedBox(width: 8),
                Expanded(child: _buildFormCard(_formOptions[row * 2 + col])),
              ],
            ],
          ),
          if (row != 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 15),

        // ---- Color selector ----
        Row(
          children: [
            const Expanded(
              child: Text(
                'Color (optional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _selectedColorName,
              style: const TextStyle(
                color: AppColors.headerDark,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            _colorOptions.length,
            (index) => _buildColorButton(index),
          ),
        ),
        const SizedBox(height: 16),

        // ---- Instructions ----
        const Row(
          children: [
            Expanded(
              child: Text(
                'Special Instructions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Optional',
              style: TextStyle(color: AppColors.headerDark, fontSize: 8.5),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _instructionsController,
          minLines: 2,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            hintText:
                'e.g. Take with food after breakfast, avoid grapefruit...',
          ).copyWith(contentPadding: const EdgeInsets.fromLTRB(11, 10, 11, 10)),
        ),
        const SizedBox(height: 14),

        // ---- Interaction check ----
        _buildInteractionCard(),
        const SizedBox(height: 12),

        // ---- Continue ----
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _continueToSchedule,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.formAccent,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: AppColors.formAccent.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continue to Schedule  →',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ---- Draft ----
        Center(
          child: TextButton(
            onPressed: _saveDraft,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.formAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Save as Draft',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ================= NAME FIELD (with live hint!) =================
  Widget _nameField() {
    final hasText = _nameController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration(
            hintText: 'Enter medication name',
            error: _nameError,
            suffixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.formAccent,
              size: 19,
            ),
          ),
        ),

        // "Matches clinical index" — live hint (design!)
        if (hasText) ...[
          const SizedBox(height: 5),
          const Row(
            children: [
              Icon(Icons.check_rounded, size: 12, color: AppColors.success),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Matches clinical index',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ================= STRENGTH FIELD =================
  Widget _strengthField() {
    return TextField(
      controller: _strengthController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(hintText: 'e.g. 500', error: _strengthError),
    );
  }

  // ================= LABEL =================
  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
    );
  }

  // ================= INPUT DECORATION =================
  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
    bool error = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.fieldHintLight, fontSize: 10),
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: error ? AppColors.error : AppColors.formIcon,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: error ? AppColors.error : AppColors.formIcon,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  // ================= UNIT DROPDOWN =================
  Widget _buildUnitDropdown() {
    return Container(
      height: 43,
      width: 67,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.formAccent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          dropdownColor: AppColors.formAccent,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 17,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          items: _units.map((unit) {
            return DropdownMenuItem<String>(value: unit, child: Text(unit));
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedUnit = value);
          },
        ),
      ),
    );
  }

  // ================= UNIT CHIP =================
  Widget _buildUnitChip(String unit) {
    final selected = _selectedUnit == unit;

    return InkWell(
      onTap: () => setState(() => _selectedUnit = unit),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.formAccent : AppColors.outline,
            width: 1,
          ),
        ),
        child: Text(
          unit,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.formAccent,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ================= FORM CARD (image ya icon — auto!) =================
  Widget _buildFormCard(
    ({String title, String asset, IconData fallbackIcon}) option,
  ) {
    final selected = _selectedForm == option.title;

    return InkWell(
      onTap: () => setState(() => _selectedForm = option.title),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.formAccent : AppColors.outline,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Selected check
            if (selected)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.formAccent,
                  size: 16,
                ),
              ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Round image frame — image ya fallback icon
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.successBackground
                          : AppColors.fieldFill,
                      border: Border.all(
                        color: selected
                            ? AppColors.formAccent.withValues(alpha: 0.22)
                            : AppColors.outline,
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        option.asset,
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        // Image na mile → fallback icon (crash-proof!)
                        errorBuilder: (context, error, stackTrace) => Icon(
                          option.fallbackIcon,
                          color: AppColors.formAccent,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    option.title,
                    style: TextStyle(
                      color: selected
                          ? AppColors.formAccent
                          : AppColors.headerDark,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COLOR BUTTON =================
  Widget _buildColorButton(int index) {
    final selected = _selectedColor == index;
    final color = _colorOptions[index].$1;

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = index),
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.formAccent : AppColors.outline,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 15,
                // SMART — light color par dark check!
                color: _contrastColor(color),
              )
            : null,
      ),
    );
  }

  /// Luminance ke hisaab se check ka rang — accessibility!
  Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.65
        ? AppColors.formAccent
        : Colors.white;
  }

  String get _selectedColorName => _colorOptions[_selectedColor].$2;

  // ================= INTERACTION CARD =================
  Widget _buildInteractionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.formAccent, width: 4),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_rounded,
            color: AppColors.formAccent,
            size: 17,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatic Interaction Checks',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "We'll cross-reference this dosage against your "
                  'existing logged medications in the next step.',
                  style: TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 9,
                    height: 1.35,
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
// SUITE BOTTOM BAR — Home/Meds/Scan/Review jaisi!
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
