import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_icons.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ===== Error flags =====
  bool _emailError = false;
  bool _passwordError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.isEmpty;
    });

    if (_emailError || _passwordError) return;

    // TODO: Auth backend agle phase mein
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login successful! Home screen agle step mein banayenge'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // ===== TABLET SUPPORT: form max 480px, center mein =====
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // ===== BACK =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===== LOGO =====
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.12,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/images/med_reminder_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.medical_services_rounded,
                                size: 34,
                                color: AppColors.logoBadge,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== TITLE =====
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Log in to continue your health journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ===== FIELDS (reusable widgets se!) =====
                  CustomTextField(
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    hint: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    hasError: _emailError,
                    onChanged: (_) {
                      if (_emailError) setState(() => _emailError = false);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    hint: 'Password',
                    isPassword: true,
                    hasError: _passwordError,
                    onChanged: (_) {
                      if (_passwordError) {
                        setState(() => _passwordError = false);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // ===== FORGOT =====
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ResetPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTeal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== LOGIN BUTTON (CustomButton!) =====
                  CustomButton(label: 'Log In', onPressed: _login),
                  const SizedBox(height: 32),

                  // ===== DIVIDER =====
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ===== SOCIAL (SocialButton!) =====
                  SocialButton(label: 'Apple', icon: const AppleLogo(size: 22)),
                  const SizedBox(height: 14),
                  SocialButton(
                    label: 'Google',
                    icon: const GoogleLogo(size: 22),
                  ),
                  const SizedBox(height: 32),

                  // ===== SIGNUP LINK =====
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
