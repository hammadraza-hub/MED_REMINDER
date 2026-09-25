import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();

  bool _emailError = false;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND RESET LINK
  // ============================================================

  void _sendResetLink() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    final isValid = email.isNotEmpty && emailRegex.hasMatch(email);

    setState(() {
      _emailError = !isValid;
      _linkSent = isValid;
    });

    if (!isValid) return;

    // TODO: Backend reset email integration.
    debugPrint('Reset link sent to: $email');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        titleSpacing: 20,

        title: Row(
          children: [
            Image.asset(
              'assets/images/med_reminder_logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.formAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                );
              },
            ),

            const SizedBox(width: 10),

            const Text(
              'MedRemind',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,

        onTap: () {
          FocusScope.of(context).unfocus();
        },

        child: SafeArea(
          top: false,

          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double height = constraints.maxHeight;

              final double shortestSide = math.min(width, height);

              final bool tablet = shortestSide >= 600;

              final bool largeTablet = shortestSide >= 800;

              final bool compactPhone = !tablet && height < 650;

              // ================================================
              // CONTENT WIDTH
              //
              // This is the important Login-like tablet fix.
              // ================================================

              final double contentWidth;

              if (largeTablet) {
                contentWidth = 520;
              } else if (tablet) {
                contentWidth = 500;
              } else {
                contentWidth = width;
              }

              // ================================================
              // RESPONSIVE SIZES
              // ================================================

              final double imageSize = largeTablet
                  ? 120
                  : tablet
                  ? 110
                  : compactPhone
                  ? 105
                  : 130;

              final double titleSize = largeTablet
                  ? 29
                  : tablet
                  ? 27
                  : compactPhone
                  ? 25
                  : 29;

              final double subtitleSize = tablet
                  ? 14
                  : compactPhone
                  ? 13
                  : 14;

              final double horizontalPadding = tablet ? 24 : 20;

              final double topGap = tablet
                  ? 18
                  : compactPhone
                  ? 8
                  : 25;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,

                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: 30,
                ),

                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        // ======================================
                        // BACK ARROW
                        // ======================================

                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                              size: 27,
                            ),
                          ),
                        ),

                        SizedBox(height: topGap),

                        // ======================================
                        // FORGET IMAGE
                        // ======================================
                        Center(
                          child: Container(
                            width: imageSize,
                            height: imageSize,

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              border: Border.all(
                                color: AppColors.formAccent,
                                width: 2,
                              ),
                            ),

                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),

                              child: Image.asset(
                                'assets/images/forget.png',

                                width: imageSize,
                                height: imageSize,

                                fit: BoxFit.cover,

                                cacheWidth: (imageSize * 2).round(),

                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.pillPlaceholder,

                                    alignment: Alignment.center,

                                    child: Icon(
                                      Icons.lock_reset_rounded,

                                      color: AppColors.formAccent,

                                      size: tablet ? 46 : 48,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: tablet ? 20 : 22),

                        // ======================================
                        // TITLE
                        // ======================================
                        Text(
                          'Reset Password',
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: AppColors.textPrimary,

                            fontSize: titleSize,

                            fontWeight: FontWeight.w700,

                            letterSpacing: -0.8,
                          ),
                        ),

                        SizedBox(height: tablet ? 9 : 10),

                        // ======================================
                        // SUBTITLE
                        // ======================================
                        Text(
                          "Enter your email address and we'll send\n"
                          "you a secure reset link.",

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: AppColors.formSubtitle,

                            fontSize: subtitleSize,

                            height: 1.55,

                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(
                          height: tablet
                              ? 28
                              : compactPhone
                              ? 22
                              : 30,
                        ),

                        // ======================================
                        // EMAIL FIELD
                        // ======================================
                        CustomTextField(
                          controller: _emailController,

                          label: 'Email Address',

                          hint: 'your@email.com',

                          icon: Icons.mail_outline_rounded,

                          variant: FieldVariant.bordered,

                          keyboardType: TextInputType.emailAddress,

                          textInputAction: TextInputAction.done,

                          hasError: _emailError,

                          onChanged: (_) {
                            if (_emailError || _linkSent) {
                              setState(() {
                                _emailError = false;
                                _linkSent = false;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 18),

                        // ======================================
                        // SEND RESET BUTTON
                        // ======================================
                        CustomButton.classic(
                          label: 'Send Reset Link',

                          onPressed: _sendResetLink,

                          radius: 12,

                          elevation: 2,

                          fontSize: 15,
                        ),

                        // ======================================
                        // SUCCESS BANNER
                        // ======================================
                        if (_linkSent) ...[
                          const SizedBox(height: 15),

                          Container(
                            width: double.infinity,
                            height: 64,

                            decoration: BoxDecoration(
                              color: AppColors.successBackground,

                              borderRadius: BorderRadius.circular(10),
                            ),

                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 64,

                                  decoration: const BoxDecoration(
                                    color: AppColors.formAccent,

                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),

                                      bottomLeft: Radius.circular(10),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 15),

                                Container(
                                  width: 32,
                                  height: 32,

                                  decoration: const BoxDecoration(
                                    color: AppColors.formAccent,

                                    shape: BoxShape.circle,
                                  ),

                                  child: const Icon(
                                    Icons.check_rounded,

                                    color: Colors.white,

                                    size: 18,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                const Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        'Reset link sent!',

                                        style: TextStyle(
                                          color: AppColors.formAccent,

                                          fontSize: 13,

                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),

                                      SizedBox(height: 2),

                                      Text(
                                        'Check your inbox.',

                                        style: TextStyle(
                                          color: AppColors.textPrimary,

                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ======================================
                        // BACK TO LOGIN
                        // ======================================
                        SizedBox(height: tablet ? 15 : 22),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },

                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.formAccent,

                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),

                            child: const Text(
                              'Back to Log In',

                              style: TextStyle(
                                color: AppColors.formAccent,

                                fontSize: 13.5,

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
