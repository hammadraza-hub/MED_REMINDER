import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Primary buttons — do styles:
/// - [CustomButton]         → Login: pill, primary green
/// - [CustomButton.classic] → Signup/Reset: rounded, formAccent
enum _ButtonKind { pill, classic }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.height = 56,
    this.isEnabled = true,
  }) : _kind = _ButtonKind.pill,
       radius = null,
       elevation = null,
       fontSize = null;

  /// Signup-style button.
  /// Optional params se exact UI tune karo — defaults signup style:
  const CustomButton.classic({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.height = 54,
    this.isEnabled = true,
    this.radius = 13,
    this.elevation = 4,
    this.fontSize = 16,
  }) : _kind = _ButtonKind.classic;

  // ================= FIELDS =================
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final double height;
  final bool isEnabled;
  final _ButtonKind _kind; // ← YE LINE TUMHARI FILE MEIN THI HI NAHI!

  // Sirf classic variant inhe use karta hai:
  final double? radius;
  final double? elevation;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isPill = _kind == _ButtonKind.pill;
    final color = isPill ? AppColors.primary : AppColors.formAccent;

    final effectiveRadius = isPill ? height / 2 : (radius ?? 13);
    final effectiveFontSize = isPill ? 17.0 : (fontSize ?? 16);
    final effectiveElevation = !isEnabled
        ? 0.0
        : (isPill ? 5.0 : (elevation ?? 4));

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: effectiveElevation,
          shadowColor: (isPill ? AppColors.primaryDark : AppColors.formAccent)
              .withValues(alpha: isPill ? 0.25 : 0.20),
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: effectiveFontSize,
                fontWeight: isPill ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Social login buttons — do styles:
/// - [SocialVariant.pill]     → Login: white outlined pill (full width)
/// - [SocialVariant.outlined] → Signup: light border, 12px (Apple + Google)
enum SocialVariant { pill, outlined }

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.height = 56,
    this.variant = SocialVariant.pill,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final double height;
  final SocialVariant variant;

  @override
  Widget build(BuildContext context) {
    final isPill = variant == SocialVariant.pill;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: TextStyle(
            fontSize: isPill ? 16 : 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(
            color: isPill ? AppColors.divider : AppColors.outline,
            width: 1,
          ),
          padding: isPill ? null : EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPill ? height / 2 : 12),
          ),
        ),
      ),
    );
  }
}
