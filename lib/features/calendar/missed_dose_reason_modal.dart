import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../meds/meds_data.dart';
import 'calendar_data.dart';

// ============================================================
// MISSED DOSE REASON
//
// Reusable modal for Calendar / Dashboard.
//
// PURPOSE:
// User se missed dose ka reason capture karna for:
// • personal history
// • adherence context
// • future caregiver context
//
// IMPORTANT:
// Ye full-screen page nahi hai.
// Existing screen ke upar modal open hota hai.
//
// TODO Backend:
// Save par existing dose-history document update karna hai.
// Duplicate dose-history record create NAHI karna.
//
// Suggested fields:
// • missedReasonType
// • missedReasonText
// • missedReasonNote
// • reasonRecordedAt
// • recordedByUserId
// ============================================================

// ============================================================
// REASON TYPE
// ============================================================

enum MissedDoseReasonType { forgot, sideEffect, ranOut, other }

// ============================================================
// RESULT
//
// Modal save hone ke baad caller ko ye object milega.
// null result = user ne close / outside tap / Skip for Now kiya.
// ============================================================

class MissedDoseReasonResult {
  const MissedDoseReasonResult({
    required this.type,
    required this.reasonText,
    this.note,
  });

  final MissedDoseReasonType type;

  /// Human-readable reason.
  ///
  /// Examples:
  /// Forgot
  /// Side Effect
  /// Ran Out
  /// "Travelling" (Other)
  final String reasonText;

  /// Optional additional context.
  final String? note;
}

// ============================================================
// SHOW MODAL
// ============================================================

Future<MissedDoseReasonResult?> showMissedDoseReasonModal(
  BuildContext context, {
  required DoseHistoryItem dose,
  DateTime? doseDate,
}) {
  return showGeneralDialog<MissedDoseReasonResult>(
    context: context,

    barrierDismissible: true,

    barrierLabel: 'Close missed dose reason',

    barrierColor: AppColors.headerDark.withValues(alpha: 0.55),

    transitionDuration: const Duration(milliseconds: 220),

    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460, maxHeight: 650),
              child: _MissedDoseReasonCard(
                dose: dose,
                doseDate: doseDate ?? DateTime.now(),
              ),
            ),
          ),
        ),
      );
    },

    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ============================================================
// MODAL CARD
// ============================================================

class _MissedDoseReasonCard extends StatefulWidget {
  const _MissedDoseReasonCard({required this.dose, required this.doseDate});

  final DoseHistoryItem dose;
  final DateTime doseDate;

  @override
  State<_MissedDoseReasonCard> createState() => _MissedDoseReasonCardState();
}

class _MissedDoseReasonCardState extends State<_MissedDoseReasonCard> {
  MissedDoseReasonType? _selectedReason;

  final TextEditingController _otherController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  String? _validationMessage;

  bool get _isOther {
    return _selectedReason == MissedDoseReasonType.other;
  }

  @override
  void dispose() {
    _otherController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _selectReason(MissedDoseReasonType reason) {
    setState(() {
      _selectedReason = reason;
      _validationMessage = null;

      if (reason != MissedDoseReasonType.other) {
        _otherController.clear();
      }
    });
  }

  void _saveReason() {
    final selected = _selectedReason;

    if (selected == null) {
      setState(() {
        _validationMessage = 'Please select a reason or choose Other.';
      });

      return;
    }

    String reasonText;

    switch (selected) {
      case MissedDoseReasonType.forgot:
        reasonText = 'Forgot';
        break;

      case MissedDoseReasonType.sideEffect:
        reasonText = 'Side Effect';
        break;

      case MissedDoseReasonType.ranOut:
        reasonText = 'Ran Out';
        break;

      case MissedDoseReasonType.other:
        reasonText = _otherController.text.trim();

        if (reasonText.isEmpty) {
          setState(() {
            _validationMessage = 'Please type the reason.';
          });

          return;
        }
        break;
    }

    final note = _notesController.text.trim();

    final result = MissedDoseReasonResult(
      type: selected,
      reasonText: reasonText,
      note: note.isEmpty ? null : note,
    );

    // TODO Backend:
    // Caller/repository ko existing dose history document id:
    // widget.dose.id
    //
    // ke against ye values persist karni hain:
    // missedReasonType = selected.name
    // missedReasonText = reasonText
    // missedReasonNote = note
    // reasonRecordedAt = serverTimestamp
    // recordedByUserId = currentUser.uid
    //
    // Duplicate history entry create NAHI karni.

    Navigator.of(context).pop(result);
  }

  void _skipForNow() {
    // null = koi reason save nahi hua.
    Navigator.of(context).pop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: AppColors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 6 : 0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMedicineHeader(),

                  const SizedBox(height: 14),

                  const Divider(height: 1, color: AppColors.missedReasonBorder),

                  const SizedBox(height: 14),

                  _buildReasonSection(),

                  const SizedBox(height: 13),

                  _buildNotesField(),

                  const SizedBox(height: 10),

                  _buildRefillHint(),

                  if (_validationMessage != null) ...[
                    const SizedBox(height: 8),

                    Text(
                      _validationMessage!,
                      style: const TextStyle(
                        color: AppColors.missedReasonDanger,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  _buildSaveButton(),

                  const SizedBox(height: 7),

                  _buildSkipButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICINE HEADER
  // ============================================================

  Widget _buildMedicineHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMedicineImage(),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Missed Dose',
                style: TextStyle(
                  color: AppColors.missedReasonDanger,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                widget.dose.medicineName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _doseMetaLabel,
                style: const TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.missedReasonCloseBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.formSubtitle,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineImage() {
    final asset = _medicineImageAsset(widget.dose.medicineType);

    return Container(
      width: 45,
      height: 45,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.missedReasonDangerBackground),
      ),
      child: asset != null
          ? Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return _medicineFallback();
              },
            )
          : _medicineFallback(),
    );
  }

  Widget _medicineFallback() {
    return Icon(
      _medicineTypeIcon(widget.dose.medicineType),
      color: AppColors.missedReasonDanger,
      size: 23,
    );
  }

  String get _doseMetaLabel {
    return '${widget.dose.time} · ${_formatDate(widget.doseDate)}';
  }

  // ============================================================
  // REASONS
  // ============================================================

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why was this dose missed?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'This helps track patterns and improve your routine.',
          style: TextStyle(color: AppColors.formSubtitle, fontSize: 8.5),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _reasonChip(
              type: MissedDoseReasonType.forgot,
              label: 'Forgot',
              icon: Icons.check_rounded,
            ),

            _reasonChip(
              type: MissedDoseReasonType.sideEffect,
              label: 'Side Effect',
              icon: Icons.health_and_safety_outlined,
            ),

            _reasonChip(
              type: MissedDoseReasonType.ranOut,
              label: 'Ran Out',
              icon: Icons.inventory_2_outlined,
            ),

            _reasonChip(
              type: MissedDoseReasonType.other,
              label: 'Other',
              icon: Icons.more_horiz_rounded,
            ),
          ],
        ),

        if (_isOther) ...[
          const SizedBox(height: 9),

          TextField(
            controller: _otherController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_validationMessage != null) {
                setState(() {
                  _validationMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Type why this dose was missed...',
              hintStyle: const TextStyle(
                color: AppColors.fieldHint,
                fontSize: 10,
              ),
              filled: true,
              fillColor: AppColors.missedReasonFieldBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: AppColors.missedReasonBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.formAccent),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reasonChip({
    required MissedDoseReasonType type,
    required String label,
    required IconData icon,
  }) {
    final selected = _selectedReason == type;

    return InkWell(
      onTap: () => _selectReason(type),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.missedReasonSelectedBackground
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.missedReasonSelected
                : AppColors.missedReasonBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected
                  ? AppColors.missedReasonSelected
                  : AppColors.formSubtitle,
            ),

            const SizedBox(width: 5),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.missedReasonSelected
                    : AppColors.textPrimary,
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional notes (optional)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: _notesController,
          minLines: 2,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Add more details about why this dose was missed...',
            hintStyle: const TextStyle(color: AppColors.fieldHint, fontSize: 9),
            filled: true,
            fillColor: AppColors.missedReasonFieldBackground,
            contentPadding: const EdgeInsets.all(11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.missedReasonBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.formAccent),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REFILL HINT
  // ============================================================

  Widget _buildRefillHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.missedReasonWarningBackground,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.missedReasonWarning, width: 3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.missedReasonWarning,
              size: 15,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Running low on ${widget.dose.medicineName}?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.missedReasonWarning,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                const Text(
                  'Tap to set up a refill reminder →',
                  style: TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 7.5,
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
  // BUTTONS
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton(
        onPressed: _saveReason,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.missedReasonSelected,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: const Text(
          'Save Reason',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: _skipForNow,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.missedReasonSelected,
          side: const BorderSide(color: AppColors.missedReasonSelected),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: const Text(
          'Skip for Now',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICINE HELPERS
  // ============================================================

  String? _medicineImageAsset(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return 'assets/images/tablet.jpg';

      case MedicineType.capsule:
        return 'assets/images/capsule.jpg';

      case MedicineType.liquid:
        return 'assets/images/liquid.jpg';

      case MedicineType.drops:
        return null;

      case MedicineType.injection:
        return 'assets/images/injection.jpg';
    }
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}
