import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Shared setup-flow header — Brand + Back/Skip + Step progress.
///
/// Har setup screen mein SAME header:
/// ```dart
/// OnboardingHeader(
///   step: 1,
///   totalSteps: 3,
///   onBack: () => Navigator.of(context).maybePop(),
///   onSkip: () { ... },
/// )
/// ```
///
/// Ek widget, saari screens — component reuse ka asli jaadu! 🎯
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onSkip,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // ================= BRAND =================
        const _BrandRow(),
        const SizedBox(height: 16),

        // ================= NAV: Back + Skip =================
        _NavigationRow(onBack: onBack, onSkip: onSkip),
        const SizedBox(height: 20),

        // ================= PROGRESS =================
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: step / totalSteps, // Step 1 → 33% | 3 → 100% (auto math!)
            minHeight: 6,
            backgroundColor: AppColors.barEmpty,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.formAccent,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Step $step of $totalSteps',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.fieldHint,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ============================================================
// BRAND ROW — asli logo + asli naam
// ============================================================
class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/med_reminder_logo.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.formAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'MedRemind',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// NAVIGATION ROW — Back + Skip
// ============================================================
class _NavigationRow extends StatelessWidget {
  const _NavigationRow({required this.onBack, required this.onSkip});

  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Icon(
            Icons.arrow_back,
            size: 22,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Skip',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.formAccent,
            ),
          ),
        ),
      ],
    );
  }
}
