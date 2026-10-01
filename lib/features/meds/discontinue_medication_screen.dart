import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'meds_data.dart';

/// ============================================================
/// DISCONTINUE MEDICATION — MODAL CONTENT
///
/// Full-screen route NAHI.
/// Meds screen ke upar centered confirmation card.
///
/// Outside card tap:
/// showGeneralDialog barrier is modal ko close karega.
///
/// Backend:
/// Actual archive/persistence MedsScreen / repository layer
/// se handle hogi.
/// ============================================================
class DiscontinueMedicationScreen extends StatefulWidget {
  const DiscontinueMedicationScreen({super.key, required this.medicine});

  final Medicine medicine;

  @override
  State<DiscontinueMedicationScreen> createState() =>
      _DiscontinueMedicationScreenState();
}

class _DiscontinueMedicationScreenState
    extends State<DiscontinueMedicationScreen> {
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _quickReasons = const [
    'Treatment complete',
    'Side effects',
    'Doctor advised',
    'Switched med',
  ];

  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ================= QUICK REASON =================

  void _selectReason(String reason) {
    setState(() {
      if (_selectedReason == reason) {
        _selectedReason = null;
        _reasonController.clear();
      } else {
        _selectedReason = reason;
        _reasonController.text = reason;
      }
    });
  }

  // ================= ARCHIVE =================

  void _archiveMedication() {
    final reason = _reasonController.text.trim();

    // TODO Backend:
    // Firestore / repository mein medicine archive karni hai:
    //
    // isArchived = true
    // discontinueReason = reason
    // discontinuedAt = serverTimestamp
    //
    // Medicine/dose history DELETE nahi hogi.
    // Existing history Reports ke liye preserve rahegi.

    Navigator.of(context).pop<String>(reason);
  }

  // ================= KEEP ACTIVE =================

  void _keepActive() {
    Navigator.of(context).pop();
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    // Reference design mein modal full screen nahi leta.
    final maxModalHeight = screenSize.height * 0.82;

    // IMPORTANT:
    // Yahan full-screen Material / GestureDetector nahi hai.
    // Is wajah se card ke bahar showGeneralDialog ka barrier
    // touch receive karega aur modal close kar dega.
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360, maxHeight: maxModalHeight),

          // Sirf actual white modal Material hai.
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= MEDICINE IMAGE =================
                  _buildMedicineIcon(),

                  const SizedBox(height: 12),

                  // ================= TITLE =================
                  const Text(
                    'Discontinue Medication?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 9),

                  // ================= MEDICINE CHIP =================
                  Center(child: _buildMedicineChip()),

                  const SizedBox(height: 12),

                  // ================= DESCRIPTION =================
                  const Text(
                    'This will stop tracking this medication\n'
                    'going forward.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 13),

                  // ================= HISTORY =================
                  _buildHistoryCard(),

                  const SizedBox(height: 13),

                  // ================= REASON =================
                  const Text(
                    'Reason (optional)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  _buildReasonField(),

                  const SizedBox(height: 8),

                  // ================= QUICK REASONS =================
                  _buildReasonChips(),

                  const SizedBox(height: 12),

                  const Divider(color: AppColors.hairline, height: 1),

                  const SizedBox(height: 12),

                  // ================= ARCHIVE =================
                  _buildArchiveButton(),

                  const SizedBox(height: 8),

                  // ================= KEEP ACTIVE =================
                  _buildKeepActiveButton(),

                  const SizedBox(height: 12),

                  // ================= HISTORY FOOTER =================
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.formAccent,
                        size: 11,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'History is never deleted',
                        style: TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICINE IMAGE
  // ============================================================

  Widget _buildMedicineIcon() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.hintBackground,
              border: Border.all(color: AppColors.accentOrange),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cardFill,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: widget.medicine.typeImageAsset != null
                    ? Image.asset(
                        widget.medicine.typeImageAsset!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              widget.medicine.typeIcon,
                              color: AppColors.formSubtitle,
                              size: 23,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          widget.medicine.typeIcon,
                          color: AppColors.formSubtitle,
                          size: 23,
                        ),
                      ),
              ),
            ),
          ),

          // Red discontinue badge
          Positioned(
            right: -2,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: AppColors.surface,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICINE CHIP
  // ============================================================

  Widget _buildMedicineChip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.formAccent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.cardFill,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: widget.medicine.typeImageAsset != null
                  ? Image.asset(
                      widget.medicine.typeImageAsset!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            widget.medicine.typeIcon,
                            color: AppColors.formAccent,
                            size: 13,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        widget.medicine.typeIcon,
                        color: AppColors.formAccent,
                        size: 13,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 6),

          Flexible(
            child: Text(
              '${widget.medicine.name} '
              '${widget.medicine.dose}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.formAccent),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: AppColors.formAccent,
            size: 16,
          ),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              'Your complete history is preserved and\n'
              'stays accessible in Reports.',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 9,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REASON FIELD
  // ============================================================

  Widget _buildReasonField() {
    return TextField(
      controller: _reasonController,
      minLines: 2,
      maxLines: 3,
      onChanged: (_) {
        if (_selectedReason != null &&
            _reasonController.text != _selectedReason) {
          setState(() {
            _selectedReason = null;
          });
        }
      },
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
      decoration: InputDecoration(
        hintText:
            'e.g. Treatment completed, switched\n'
            'medication, side effects...',
        hintStyle: const TextStyle(
          color: AppColors.fieldHint,
          fontSize: 9.5,
          height: 1.35,
        ),
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.all(11),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.formAccent),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK REASONS
  // ============================================================

  Widget _buildReasonChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _quickReasons.map((reason) {
        final selected = _selectedReason == reason;

        return GestureDetector(
          onTap: () => _selectReason(reason),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.successBackground
                  : AppColors.fieldEditFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.formAccent : AppColors.outline,
              ),
            ),
            child: Text(
              reason,
              style: const TextStyle(
                color: AppColors.formAccent,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ARCHIVE BUTTON
  // ============================================================

  Widget _buildArchiveButton() {
    return SizedBox(
      height: 43,
      child: ElevatedButton.icon(
        onPressed: _archiveMedication,
        icon: const Icon(Icons.archive_rounded, size: 14),
        label: const Text(
          'Archive Medication',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KEEP ACTIVE
  // ============================================================

  Widget _buildKeepActiveButton() {
    return SizedBox(
      height: 41,
      child: OutlinedButton(
        onPressed: _keepActive,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.formAccent,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.formAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Keep Active',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
