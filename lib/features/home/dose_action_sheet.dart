import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'home_data.dart';

/// ============================================================
/// DOSE ACTION SHEET — dose card tap par khulti hai
///
/// Status-aware:
/// - Pending dose → Mark as Taken + Skip (reason) + Snooze
/// - Taken dose → Mark as Untaken (undo galat tap!)
///
/// Backend: callbacks parent (Home) ko jaate hain —
/// DB updates wahan TODO mark hain. Ye sheet sirf UI hai!
/// ============================================================
void showDoseActionSheet(
  BuildContext context, {
  required Dose dose,
  required VoidCallback onTaken,
  required VoidCallback onUntaken,
  required void Function(String? reason) onSkip,
  required void Function(int minutes) onSnooze,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // keyboard support
    backgroundColor: Colors.transparent, // apna rounded container
    builder: (_) => _DoseActionSheet(
      dose: dose,
      onTaken: onTaken,
      onUntaken: onUntaken,
      onSkip: onSkip,
      onSnooze: onSnooze,
    ),
  );
}

class _DoseActionSheet extends StatefulWidget {
  const _DoseActionSheet({
    required this.dose,
    required this.onTaken,
    required this.onUntaken,
    required this.onSkip,
    required this.onSnooze,
  });

  final Dose dose;
  final VoidCallback onTaken;
  final VoidCallback onUntaken;
  final void Function(String? reason) onSkip;
  final void Function(int minutes) onSnooze;

  @override
  State<_DoseActionSheet> createState() => _DoseActionSheetState();
}

class _DoseActionSheetState extends State<_DoseActionSheet> {
  bool _showSnooze = false;
  bool _showSkip = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ================= ACTIONS — pehle sheet band, phir callback =================
  void _taken() {
    Navigator.of(context).pop();
    widget.onTaken();
  }

  void _untaken() {
    Navigator.of(context).pop();
    widget.onUntaken();
  }

  void _skip() {
    final reason = _reasonController.text.trim();
    Navigator.of(context).pop();
    widget.onSkip(reason.isEmpty ? null : reason);
  }

  void _snooze(int minutes) {
    Navigator.of(context).pop();
    widget.onSnooze(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final dose = widget.dose;
    final isTaken = dose.status == DoseStatus.taken;

    return Padding(
      // Keyboard khule to sheet upar chale jaye
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== Handle =====
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.barEmpty,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ===== Medicine Info (status-aware colors!) =====
              Row(
                children: [
                  // Pill icon — taken? green check : orange pill
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isTaken
                          ? AppColors.successBackground
                          : AppColors.pendingBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTaken ? Icons.check_rounded : Icons.medication_outlined,
                      size: 26,
                      color: isTaken
                          ? AppColors.success
                          : AppColors.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dose.name} ${dose.doseAmount}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dose.details,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.formSubtitle,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: isTaken
                                  ? AppColors.success
                                  : AppColors.statusPendingText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTaken ? dose.time : '${dose.time} · Due soon',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isTaken
                                    ? AppColors.success
                                    : AppColors.statusPendingText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge — taken? TAKEN : PENDING
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isTaken
                          ? AppColors.successBackground
                          : AppColors.pendingBackground,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      isTaken ? 'TAKEN' : 'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isTaken
                            ? AppColors.success
                            : AppColors.statusPendingText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ===== MAIN BUTTON — taken? Untaken(undo) : Taken =====
              isTaken
                  ? CustomButton.classic(
                      label: 'Mark as Untaken',
                      trailingIcon: Icons.undo_rounded,
                      radius: 14,
                      elevation: 0,
                      onPressed: _untaken,
                    )
                  : CustomButton.classic(
                      label: 'Mark as Taken',
                      trailingIcon: Icons.check_rounded,
                      radius: 14,
                      elevation: 0,
                      onPressed: _taken,
                    ),
              const SizedBox(height: 12),

              // ===== Skip + Snooze (sirf PENDING dose ke liye!) =====
              if (!isTaken) ...[
                Row(
                  children: [
                    Expanded(
                      child: _secondaryButton(
                        label: _showSkip ? 'Hide Reason' : 'Skip Dose',
                        icon: Icons.close_rounded,
                        color: AppColors.error,
                        onTap: () => setState(() {
                          _showSkip = !_showSkip;
                          if (_showSkip) _showSnooze = false;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _secondaryButton(
                        label: 'Snooze',
                        icon: Icons.snooze_rounded,
                        color: AppColors.formAccent,
                        onTap: () => setState(() {
                          _showSnooze = !_showSnooze;
                          if (_showSnooze) _showSkip = false;
                        }),
                      ),
                    ),
                  ],
                ),

                // ===== Snooze options (expand) =====
                if (_showSnooze) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'SNOOZE FOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.fieldHint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _snoozeOption('10 min', 10),
                      const SizedBox(width: 8),
                      _snoozeOption('30 min', 30),
                      const SizedBox(width: 8),
                      _snoozeOption('1 hr', 60),
                    ],
                  ),
                ],

                // ===== Skip reason (expand) =====
                if (_showSkip) ...[
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _reasonController,
                    label: 'Reason (optional)',
                    hint: 'e.g., Feeling nauseous',
                    icon: Icons.notes_rounded,
                    variant: FieldVariant.bordered,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _skip,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Confirm Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _snoozeOption(String label, int minutes) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _snooze(minutes),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.formAccent, width: 1.2),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.formAccent,
            ),
          ),
        ),
      ),
    );
  }
}
