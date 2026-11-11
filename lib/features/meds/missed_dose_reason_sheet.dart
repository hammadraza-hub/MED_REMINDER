import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// ============================================================
/// MISSED-DOSE REASON SHEET
///
/// PURPOSE:
/// Jab user koi dose skip karta hai, to reason capture karne ke
/// liye ye bottom sheet khulta hai. Reason Firestore mein
/// doses/{doseId}.reasonText field mein save hota hai.
///
/// USAGE:
///   final reason = await MissedDoseReasonSheet.show(
///     context,
///     medName: 'Paracetamol',
///     scheduledTimeLabel: '8:00 AM',
///   );
///   // reason == null  → skip without capturing
///   // reason == 'Forgot' / 'Side effect' / ... → predefined
///   // reason == `<custom text>` → "Other" text field
///
/// ARCHITECTURE:
/// • Self-contained widget — kisi data file pe depend nahi.
/// • Hardcoded strings (app_localizations.dart mein keys nahi
///   hain; baad mein migrate kar sakte ho).
/// • 6 predefined chips + "Other" radio + text field.
/// ============================================================
class MissedDoseReasonSheet extends StatefulWidget {
  const MissedDoseReasonSheet({
    super.key,
    required this.medName,
    required this.scheduledTimeLabel,
  });

  final String medName;
  final String scheduledTimeLabel;

  /// Shows the sheet and returns the chosen reason (or null if
  /// user tapped "Skip without reason").
  static Future<String?> show(
    BuildContext context, {
    required String medName,
    required String scheduledTimeLabel,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MissedDoseReasonSheet(
        medName: medName,
        scheduledTimeLabel: scheduledTimeLabel,
      ),
    );
  }

  @override
  State<MissedDoseReasonSheet> createState() => _MissedDoseReasonSheetState();
}

class _MissedDoseReasonSheetState extends State<MissedDoseReasonSheet> {
  static const List<String> _predefinedReasons = [
    'Forgot',
    'Side effect',
    'Felt better',
    'Felt worse',
    'Out of stock',
    'Away from home',
  ];

  String? _selectedReason;
  final TextEditingController _otherController = TextEditingController();
  final FocusNode _otherFocusNode = FocusNode();
  bool _isOtherSelected = false;

  @override
  void dispose() {
    _otherController.dispose();
    _otherFocusNode.dispose();
    super.dispose();
  }

  void _selectPredefined(String reason) {
    setState(() {
      _selectedReason = reason;
      _isOtherSelected = false;
      _otherController.clear();
      _otherFocusNode.unfocus();
    });
  }

  void _selectOther() {
    setState(() {
      _isOtherSelected = true;
      _selectedReason = null;
      // Auto-focus the text field so user can start typing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otherFocusNode.requestFocus();
      });
    });
  }

  void _save() {
    if (_isOtherSelected) {
      final text = _otherController.text.trim();
      if (text.isEmpty) {
        // If "Other" selected but empty, treat as no reason.
        Navigator.of(context).pop(null);
        return;
      }
      Navigator.of(context).pop(text);
    } else {
      Navigator.of(context).pop(_selectedReason);
    }
  }

  void _skipWithoutReason() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              const Text(
                'Why are you skipping this dose?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Med name + time subtitle
              Text(
                '${widget.medName} · ${widget.scheduledTimeLabel}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Predefined reason chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedReasons.map((reason) {
                  final isSelected =
                      _selectedReason == reason && !_isOtherSelected;
                  return _ReasonChip(
                    label: reason,
                    selected: isSelected,
                    onTap: () => _selectPredefined(reason),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Other option (radio + text field)
              InkWell(
                onTap: _selectOther,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _isOtherSelected
                        ? AppColors.formAccent.withValues(alpha: 0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isOtherSelected
                          ? AppColors.formAccent
                          : AppColors.outline,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOtherSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: _isOtherSelected
                            ? AppColors.formAccent
                            : AppColors.fieldHint,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Other',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isOtherSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isOtherSelected) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _otherController,
                  focusNode: _otherFocusNode,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tell us why (optional)',
                    hintStyle: const TextStyle(
                      color: AppColors.fieldHint,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.formAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.formAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Skip without reason link
              TextButton(
                onPressed: _skipWithoutReason,
                child: const Text(
                  'Skip without reason',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// REASON CHIP
///
/// Selectable pill for predefined reasons.
/// ============================================================
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.formAccent.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.formAccent : AppColors.outline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: selected
                  ? AppColors.formAccent
                  : AppColors.fieldHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.formAccent
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
