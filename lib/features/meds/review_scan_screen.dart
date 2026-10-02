import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ocr_service.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'schedule_screen.dart';

/// ============================================================
/// REVIEW SCAN — Step 1 of 2 (wizard)
///
/// Scan → detect → YE SCREEN (review/correct) → Schedule (next)
///
/// OOP: DetectedMedicine class object — Map nahi!
/// System: AppColors + shared AppBottomNavigation
/// UX: Dynamic warning — strength mili to GAYAB!
///
/// TODO Backend:
/// - OCR result ko current user/family medication draft se associate karna
/// - Confirmed scan data ko medication setup flow mein persist karna
/// - Final medication + schedule Firebase mein save karna
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

    if (strength == null || strength.isEmpty) {
      return name;
    }

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
      // TODO Backend:
      // Confirmed OCR values ko medication draft/model mein store karein.
      // Final Firestore save Schedule flow complete hone par hoga.

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

  void _retakePhoto() {
    Navigator.of(context).pop();
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

      // Review Scan belongs to Meds.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavigationTap,
      ),
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
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.surface,
                      size: 25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Review Scan',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
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
      height: 56,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // ---- Step 1: ACTIVE ----
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.stepActive,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Review Scan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 12),

          // ---- Progress line ----
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 2, color: AppColors.stepTrack),
                FractionallySizedBox(
                  widthFactor: 0.36,
                  child: Container(height: 2, color: AppColors.stepActive),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ---- Step 2: INACTIVE ----
          Container(
            width: 23,
            height: 23,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.stepInactiveBg,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '2',
              style: TextStyle(
                color: AppColors.stepInactiveText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 7),

          const Text(
            'Schedule',
            style: TextStyle(
              color: AppColors.stepInactiveText,
              fontSize: 12,
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
        widget.medicine.strength == null ||
        widget.medicine.strength!.trim().isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageCard(),
          const SizedBox(height: 16),

          _buildReadSuccess(),
          const SizedBox(height: 16),

          _buildMainDetailsCard(),
          const SizedBox(height: 10),

          // DYNAMIC warning — sirf unclear par!
          if (strengthUnclear) ...[
            _buildWarningCard(),
            const SizedBox(height: 10),
          ],

          _buildStrengthCard(strengthUnclear),
          const SizedBox(height: 18),

          _buildContinueButton(),
          const SizedBox(height: 16),

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
      height: 135,
      padding: const EdgeInsets.all(9),
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
                  size: 48,
                  color: AppColors.fieldHint,
                ),
              ),

            // SCANNED badge
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SCANNED',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.surface,
                    ),
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
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.formAccent,
              size: 18,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "We've read these details from your label — "
              'check and correct if needed!',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 13,
                height: 1.4,
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Medication Name'),
          const SizedBox(height: 7),

          _EditableField(
            controller: _medicineController,
            focusNode: _medicineFocus,
          ),

          const SizedBox(height: 15),

          _fieldLabel('Instructions'),
          const SizedBox(height: 7),

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
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ================= DYNAMIC WARNING =================
  Widget _buildWarningCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hintBackground),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 54),
            decoration: const BoxDecoration(
              color: AppColors.hintAccent,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
            ),
          ),

          const SizedBox(width: 10),

          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.hintAccent,
            size: 19,
          ),

          const SizedBox(width: 9),

          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: Text(
                'Strength field was unclear in the photo — '
                'please verify manually.',
                style: TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ================= STRENGTH =================
  Widget _buildStrengthCard(bool showWarning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _fieldLabel('Strength'),

              const SizedBox(width: 3),

              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.hintAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              const Text(
                'REQUIRED',
                style: TextStyle(
                  color: AppColors.hintAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          TextField(
            controller: _strengthController,
            focusNode: _strengthFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirmAndContinue(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Enter strength e.g. 500mg',
              hintStyle: const TextStyle(
                color: AppColors.fieldHintLight,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 42),
              suffixIcon: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.hintAccent,
                size: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: showWarning
                      ? AppColors.hintAccent
                      : AppColors.formIcon,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: showWarning
                      ? AppColors.hintAccent
                      : AppColors.formIcon,
                  width: 1.5,
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
      height: 54,
      child: ElevatedButton(
        onPressed: _isContinuing ? null : _confirmAndContinue,
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.30),
          backgroundColor: AppColors.formAccent,
          disabledBackgroundColor: AppColors.formAccent.withValues(alpha: 0.65),
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: _isContinuing
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: AppColors.surface,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Confirm & Continue →',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ================= RETAKE =================
  Widget _buildRetakeButton() {
    return Center(
      child: GestureDetector(
        onTap: _retakePhoto,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 17,
                color: AppColors.formSubtitle,
              ),
              SizedBox(width: 6),
              Text(
                'Retake Photo',
                style: TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
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
// EDITABLE FIELD — green border (OCR data feel!)
//
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.fieldHintLight,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.fieldEditFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 38,
        ),
        suffixIcon: GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: const Icon(
            Icons.edit_outlined,
            color: AppColors.fieldEditBorder,
            size: 19,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.fieldEditBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.fieldEditBorder,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
