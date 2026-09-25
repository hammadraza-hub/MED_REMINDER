import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

/// Field design variants:
/// - [FieldVariant.filled]   → Login style: borderless, soft fill
/// - [FieldVariant.bordered] → Signup style: label + border
enum FieldVariant { filled, bordered }

/// App-wide text field — dono designs EK hi class se.
/// Password eye-toggle andar encapsulated hai.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.label,
    this.variant = FieldVariant.filled,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? label;
  final FieldVariant variant;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  /// Keyboard ka "done/action" button dabane par chale
  final ValueChanged<String>? onSubmitted;

  /// Screen/sheet khulte hi field par cursor aa jaye
  final bool autofocus;

  /// Text formatting rules — sirf digits, max length, etc.
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true; // sirf ISI class ko pata — encapsulation!

  @override
  Widget build(BuildContext context) {
    final isBordered = widget.variant == FieldVariant.bordered;

    OutlineInputBorder makeBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(isBordered ? 12 : 18),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ===== LABEL (sirf diya gaya ho) =====
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
        ],

        SizedBox(
          height: isBordered ? 53 : null,
          child: TextField(
            controller: widget.controller,
            autofocus: widget.autofocus,
            obscureText: widget.isPassword && _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: TextStyle(
              fontSize: isBordered ? 14 : 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: isBordered ? 14 : 15,
                color: isBordered
                    ? AppColors.fieldHint
                    : (widget.hasError
                          ? AppColors.error
                          : AppColors.textSecondary),
              ),
              prefixIcon: Icon(
                widget.icon,
                size: isBordered ? 21 : 24,
                color: isBordered
                    ? AppColors.formIcon
                    : (widget.hasError ? AppColors.error : AppColors.primary),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: isBordered ? 21 : 24,
                        color: isBordered
                            ? AppColors.formIcon
                            : AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              filled: true,
              fillColor: isBordered
                  ? AppColors.fieldFill
                  : (widget.hasError
                        ? AppColors.error.withValues(alpha: 0.05)
                        : AppColors.inputFill),
              contentPadding: isBordered
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 15)
                  : const EdgeInsets.symmetric(vertical: 18),
              enabledBorder: isBordered
                  ? makeBorder(
                      widget.hasError ? AppColors.error : AppColors.fieldBorder,
                      widget.hasError ? 1.5 : 1,
                    )
                  : makeBorder(
                      widget.hasError ? AppColors.error : Colors.transparent,
                      widget.hasError ? 1.5 : 1,
                    ),
              focusedBorder: isBordered
                  ? makeBorder(
                      widget.hasError ? AppColors.error : AppColors.fieldBorder,
                      1.5,
                    )
                  : makeBorder(AppColors.primary, 1.5),
              errorBorder: isBordered ? makeBorder(AppColors.error, 1.5) : null,
              focusedErrorBorder: isBordered
                  ? makeBorder(AppColors.error, 1.5)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
