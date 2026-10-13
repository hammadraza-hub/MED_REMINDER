import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// ============================================================
/// APP TOGGLE SWITCH — shared iOS-style pill toggle
///
/// PURPOSE:
/// Settings-type screens (Notifications, Privacy & Security) ke
/// on/off toggles ka ek hi consistent look.
///
/// COLORS:
/// Active → formAccent (app action green), inactive → reportChipHigh.
///
/// NOTE:
/// Material Switch ke bajaye custom pill use hoti hai taake design ke
/// exact 44×24 dimensions match hon.
/// ============================================================
class AppToggleSwitch extends StatelessWidget {
  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        toggled: value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? AppColors.formAccent : AppColors.reportChipHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.toggleKnobShadow,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
