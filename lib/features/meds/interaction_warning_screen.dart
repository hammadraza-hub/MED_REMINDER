import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import 'interaction_warning_data.dart';

/// ============================================================
/// INTERACTION WARNING
///
/// PURPOSE:
/// Add Medication flow ke dauraan drug interaction / duplicate
/// therapy risk surface karna — us waqt jab user nayi dawa
/// add kar raha ho.
///
/// KEY ELEMENTS:
/// - Severity indicator
/// - Plain-language explanation
/// - Affected medications named
/// - "Consult your doctor/pharmacist" disclaimer
///
/// USER ACTIONS:
/// - Acknowledge and proceed
/// - Go back and edit
///
/// NAVIGATION:
/// Add Medication mid-flow par appears hoti hai; dismiss par
/// wapas usi flow par laut jati hai.
/// Result [InteractionWarningAction] ke through caller ko milta hai.
///
/// TODO Backend:
/// Warning [InteractionWarningData] interaction engine se aayega,
/// aur "proceed" par medication setup continue karna hai.
/// ============================================================
class InteractionWarningScreen extends StatelessWidget {
  const InteractionWarningScreen({super.key, required this.data});

  /// Interaction details (medications, severity, copy).
  final InteractionWarningData data;

  // ================= ACTIONS =================

  void _close(BuildContext context, InteractionWarningAction action) {
    Navigator.of(context).pop(action);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: Stack(
                children: [
                  // ---- Simulated dimmed background (Add Medication) ----
                  Positioned.fill(child: _buildBackdrop()),

                  // ---- Backdrop overlay ----
                  const Positioned.fill(
                    child: ColoredBox(color: AppColors.interactionWarningScrim),
                  ),

                  // ---- Modal card ----
                  Positioned.fill(
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: _buildCard(context),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ---- iOS-style home indicator ----
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Center(child: _buildHomeIndicator()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.interactionWarningHeaderShadow,
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.close,
                      color: AppColors.reportPrimary,
                      size: 24,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    InteractionWarningData.screenTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.reportPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                // TODO Backend / Firebase Storage:
                // Selected member ki persistent profile image yahan aayegi.
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.reportPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.surface,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BACKDROP =================

  Widget _buildBackdrop() {
    return Opacity(
      opacity: 0.85,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: const _AddMedicationBackdropMock(),
      ),
    );
  }

  // ================= CARD =================

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.interactionWarningCardShadow,
            blurRadius: 60,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeroIcon(),
          const SizedBox(height: 16),

          _buildSeverityBadge(),
          const SizedBox(height: 12),

          const Text(
            InteractionWarningData.cardTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.permissionsHeader,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),

          _buildAffectedMedications(),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              data.explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.permissionsHeader,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildDisclaimer(),
          const SizedBox(height: 20),

          _buildActions(context),
          const SizedBox(height: 14),

          _buildTrustNote(),
        ],
      ),
    );
  }

  // ---- Top hero icon ----

  Widget _buildHeroIcon() {
    final imageAsset = data.medications.isNotEmpty
        ? data.medications.first.imageAsset
        : null;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.shareTileFill,
              border: Border.all(
                color: AppColors.interactionWarningAmber,
                width: 3,
              ),
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              child: ClipOval(child: _buildMedImage(imageAsset, 22)),
            ),
          ),

          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.interactionWarningRed,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Text(
                '\u26A0',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Severity badge ----

  Widget _buildSeverityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.interactionWarningAmber,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        data.severityLabel.toUpperCase(),
        style: const TextStyle(
          color: AppColors.surface,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ---- Affected medications ----

  Widget _buildAffectedMedications() {
    final children = <Widget>[];

    for (var i = 0; i < data.medications.length; i++) {
      if (i > 0) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '\u00D7',
              style: TextStyle(
                color: AppColors.shareSecondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }

      children.add(_buildMedChip(data.medications[i]));
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _buildMedChip(InteractionMedication med) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.shareTileFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.shareBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: ClipOval(child: _buildMedImage(med.imageAsset, 12)),
          ),
          const SizedBox(width: 6),
          Text(
            med.chipLabel,
            style: const TextStyle(
              color: AppColors.shareSecondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Disclaimer ----

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.shareTileFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.shareBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_rounded,
            color: AppColors.interactionWarningAmber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.disclaimer,
              style: const TextStyle(
                color: AppColors.shareSecondaryText,
                fontSize: 12,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Action buttons ----

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _close(context, InteractionWarningAction.proceed),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.interactionWarningRed,
              foregroundColor: AppColors.surface,
              elevation: 4,
              shadowColor: AppColors.interactionWarningRedShadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              InteractionWarningData.proceedLabel,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 50,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _close(context, InteractionWarningAction.goBack),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.shareTileFill,
              foregroundColor: AppColors.interactionWarningGreen,
              side: const BorderSide(
                color: AppColors.interactionWarningGreen,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              InteractionWarningData.goBackLabel,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Trust note ----

  Widget _buildTrustNote() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_rounded,
          color: AppColors.shareSecondaryText,
          size: 14,
        ),
        SizedBox(width: 6),
        Text(
          InteractionWarningData.footerNote,
          style: TextStyle(
            color: AppColors.shareSecondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---- Home indicator ----

  Widget _buildHomeIndicator() {
    return Container(
      width: 128,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.interactionWarningHomeIndicator,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  // ---- Shared pill image ----

  Widget _buildMedImage(String? asset, double iconSize) {
    if (asset == null) {
      return Icon(
        Icons.medication_rounded,
        color: AppColors.shareSecondaryText,
        size: iconSize,
      );
    }

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.medication_rounded,
          color: AppColors.shareSecondaryText,
          size: iconSize,
        );
      },
    );
  }
}

/// ============================================================
/// ADD MEDICATION BACKDROP MOCK
///
/// Design mein ye "SIMULATED BACKGROUND" hai — warning modal ke
/// peeche blurred Add Medication form. Production mein ye layer
/// real Add Medication flow se aa sakti hai (modal presentation).
/// ============================================================
class _AddMedicationBackdropMock extends StatelessWidget {
  const _AddMedicationBackdropMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.shareTileFill,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Mock top nav ----
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppColors.permissionsHeader,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Add Medication',
                    style: TextStyle(
                      color: AppColors.permissionsHeader,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.interactionWarningGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ---- Mock search ----
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.shareSecondaryText,
                ),
                SizedBox(width: 8),
                Text(
                  'Search prescription or OTC...',
                  style: TextStyle(
                    color: AppColors.shareSecondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Mock medication cards ----
          _MockMedCard(
            name: 'Metformin HCl',
            detail: '500mg \u2022 Oral Tablet',
          ),
          const SizedBox(height: 12),
          _MockMedCard(
            name: 'Amlodipine Besylate',
            detail: '5mg \u2022 Oral Tablet',
          ),
          const SizedBox(height: 16),

          // ---- Mock schedule selector ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FREQUENCY & DOSAGE',
                  style: TextStyle(
                    color: AppColors.shareSecondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Expanded(child: _MockScheduleChip('Every Morning')),
                    SizedBox(width: 8),
                    Expanded(child: _MockScheduleChip('With Meals')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockMedCard extends StatelessWidget {
  const _MockMedCard({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.shareTileFill,
              shape: BoxShape.circle,
            ),
            child: const ClipOval(
              child: Icon(
                Icons.medication_rounded,
                color: AppColors.shareSecondaryText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.shareSecondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.interactionWarningGreen,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _MockScheduleChip extends StatelessWidget {
  const _MockScheduleChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.shareTileFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.permissionsHeader,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
