import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ocr_service.dart';
import '../../main_shell.dart';
import 'schedule_screen.dart';

/// ============================================================
/// REVIEW SCAN — Step 1 of 2 (wizard)
///
/// Scan → detect → YE SCREEN (review/correct) → Schedule (next)
///
/// OOP: DetectedMedicine class object — Map nahi!
/// System: AppColors + AppBottomBar (escape route!)
/// UX: Dynamic warning — strength mili to GAYAB!
/// ============================================================
class ReviewScanScreen extends StatefulWidget {
  const ReviewScanScreen({
    super.key,
    required this.medicine,
    required this.imagePath,
  });

  final DetectedMedicine medicine;
  final String imagePath;

  @override
  State<ReviewScanScreen> createState() => _ReviewScanScreenState();
}

class _ReviewScanScreenState extends State<ReviewScanScreen> {
  late final TextEditingController _medicineController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _strengthController;

  final FocusNode _medicineFocus = FocusNode();
  final FocusNode _instructionsFocus = FocusNode();
  final FocusNode _strengthFocus = FocusNode();

  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();

    // OCR data → PRE-FILL (user sirf correct kare!)
    _medicineController = TextEditingController(text: _buildMedicineName());
    _instructionsController = TextEditingController(
      text: widget.medicine.instructions ?? '',
    );
    _strengthController = TextEditingController(
      text: widget.medicine.strength ?? '',
    );
  }

  /// Display: "Metformin 500mg" (naam + strength ek saath)
  /// Strength separate controller mein bhi — structured data next step ke liye
  String _buildMedicineName() {
    final name = widget.medicine.name.trim();
    final strength = widget.medicine.strength?.trim();

    if (strength == null || strength.isEmpty) return name;
    return '$name $strength';
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _instructionsController.dispose();
    _strengthController.dispose();
    _medicineFocus.dispose();
    _instructionsFocus.dispose();
    _strengthFocus.dispose();
    super.dispose();
  }

  // ================= CONTINUE =================
  Future<void> _confirmAndContinue() async {
    if (_isContinuing) return;

    final medicineName = _medicineController.text.trim();
    final strength = _strengthController.text.trim();

    // Validation — focus jump ke sath!
    if (medicineName.isEmpty) {
      _medicineFocus.requestFocus();
      _showMessage('Please enter the medication name.');
      return;
    }
    if (strength.isEmpty) {
      _strengthFocus.requestFocus();
      _showMessage('Please enter the medication strength.');
      return;
    }

    setState(() => _isContinuing = true);

    try {
      // Schedule screen — Step 2! Data ke sath!
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScheduleScreen(
            medicineName: medicineName,
            medicineStrength: strength,
          ),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Scan confirmed — Schedule agla step hai!'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _retakePhoto() => Navigator.of(context).pop();

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
          _buildStepIndicator(),
          Expanded(
            child: Center(
              // Tablet cap
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),

      // Suite bar — jaise Home/Meds/Scan mein!
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
          height: 47,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Review Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= STEP INDICATOR (wizard!) =================
  Widget _buildStepIndicator() {
    return Container(
      height: 44,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ---- Step 1: ACTIVE ----
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.stepActive,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'Review Scan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),

          // ---- Progress line ----
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 1.3, color: AppColors.stepTrack),
                FractionallySizedBox(
                  widthFactor: 0.36,
                  child: Container(height: 1.6, color: AppColors.stepActive),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ---- Step 2: INACTIVE ----
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.stepInactiveBg,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '2',
              style: TextStyle(
                color: AppColors.stepInactiveText,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Schedule',
            style: TextStyle(
              color: AppColors.stepInactiveText,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTENT =================
  Widget _buildContent() {
    // DYNAMIC — strength mili to warning GAYAB!
    final strengthUnclear =
        widget.medicine.strength == null || widget.medicine.strength!.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageCard(),
          const SizedBox(height: 13),
          _buildReadSuccess(),
          const SizedBox(height: 13),
          _buildMainDetailsCard(),
          const SizedBox(height: 8),

          // DYNAMIC warning — sirf unclear par!
          if (strengthUnclear) _buildWarningCard(),

          const SizedBox(height: 8),
          _buildStrengthCard(strengthUnclear),
          const SizedBox(height: 12),
          _buildContinueButton(),
          const SizedBox(height: 12),
          _buildRetakeButton(),
        ],
      ),
    );
  }

  // ================= SCANNED IMAGE =================
  Widget _buildImageCard() {
    final file = File(widget.imagePath);

    return Container(
      width: double.infinity,
      height: 101,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (file.existsSync())
              Image.file(file, fit: BoxFit.cover, alignment: Alignment.center)
            else
              Container(
                color: AppColors.cardFill,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.medication_rounded,
                  size: 45,
                  color: AppColors.fieldHint,
                ),
              ),

            // SCANNED badge
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                height: 17,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SCANNED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.check_rounded, size: 8, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= READ SUCCESS =================
  Widget _buildReadSuccess() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.formAccent,
              size: 13,
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              "We've read these details from your label — "
              'check and correct if needed!',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 9,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DETAILS CARD =================
  Widget _buildMainDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Medication Name'),
          const SizedBox(height: 4),
          _EditableField(
            controller: _medicineController,
            focusNode: _medicineFocus,
          ),
          const SizedBox(height: 10),
          _fieldLabel('Instructions'),
          const SizedBox(height: 4),
          _EditableField(
            controller: _instructionsController,
            focusNode: _instructionsFocus,
            hintText: 'Enter medication instructions',
            minLines: 2,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.formSubtitle,
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ================= DYNAMIC WARNING! =================
  Widget _buildWarningCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 41),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.hintBackground),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            constraints: const BoxConstraints(minHeight: 41),
            decoration: const BoxDecoration(
              color: AppColors.hintAccent,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(7)),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.hintAccent,
            size: 13,
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Strength field was unclear in the photo — '
                'please verify manually.',
                style: TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 8,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ================= STRENGTH =================
  Widget _buildStrengthCard(bool showWarning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _fieldLabel('Strength'),
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.hintAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text(
                'REQUIRED',
                style: TextStyle(
                  color: AppColors.hintAccent,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _strengthController,
            focusNode: _strengthFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirmAndContinue(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Enter strength e.g. 500mg',
              hintStyle: const TextStyle(
                color: AppColors.fieldHintLight,
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 35),
              suffixIcon: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.hintAccent,
                size: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(
                  // Warning ho = orange border | warna normal
                  color: showWarning
                      ? AppColors.hintAccent
                      : AppColors.formIcon,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(
                  color: showWarning
                      ? AppColors.hintAccent
                      : AppColors.formIcon,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTINUE =================
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: ElevatedButton(
        onPressed: _isContinuing ? null : _confirmAndContinue,
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.30),
          backgroundColor: AppColors.formAccent,
          disabledBackgroundColor: AppColors.formAccent.withValues(alpha: 0.65),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isContinuing
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Confirm & Continue →',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ================= RETAKE =================
  Widget _buildRetakeButton() {
    return Center(
      child: GestureDetector(
        onTap: _retakePhoto,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 11,
              color: AppColors.formSubtitle,
            ),
            SizedBox(width: 3),
            Text(
              'Retake Photo',
              style: TextStyle(
                color: AppColors.formSubtitle,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EDITABLE FIELD — green border (OCR data feel!)
// Justified custom widget — review context ka apna look!
// ============================================================
class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller,
    required this.focusNode,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      style: const TextStyle(
        color: AppColors.fieldEditBorder,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.fieldHintLight,
          fontSize: 9,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.fieldEditFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 35,
          minHeight: 30,
        ),
        suffixIcon: GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: const Icon(
            Icons.edit_outlined,
            color: AppColors.fieldEditBorder,
            size: 14,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: AppColors.fieldEditBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: AppColors.fieldEditBorder,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
// ============================================================
// BOTTOM BAR
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
