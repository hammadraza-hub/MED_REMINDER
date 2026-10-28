import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/app_exception.dart';
import '../../core/profile/profile_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/firebase_profile_repository.dart';
import '../../main_shell.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_icons.dart';
import 'reset_password_screen.dart';
import '../../core/profile/profile_controller.dart';

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

  // M2: Loading state during async login
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN (M2 — Firebase Auth)
  // ============================================================
  /// M2 Plan: "Real email + password" auth via Firebase AuthRepository.
  /// After login, loads user's selected profile from Firestore
  /// (users/{uid}.selectedMemberId) so dashboard can show correct data.
  Future<void> _login() async {
    // ─────────────────────────────────────────────────────────
    // 1. Validate form fields
    // ─────────────────────────────────────────────────────────
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.isEmpty;
    });

    if (_emailError || _passwordError) return;

    // ─────────────────────────────────────────────────────────
    // 2. Start loading + capture form values
    // ─────────────────────────────────────────────────────────
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // ───────────────────────────────────────────────────────
      // 3. Firebase Auth sign in
      // ───────────────────────────────────────────────────────
      final user = await AuthRepository.instance.signInWithEmailPassword(
        email: email,
        password: password,
      );

      // ───────────────────────────────────────────────────────
      // 4. Load user's selected profile from Firestore
      //    (so dashboard shows correct member/profile data)
      // ───────────────────────────────────────────────────────
      await _loadSelectedProfileFromFirestore(user.uid);

      // ───────────────────────────────────────────────────────
      // 5. Success! Navigate to dashboard
      // ───────────────────────────────────────────────────────
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Welcome back!')));

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MedRemindShell()),
        );
      }
    } on AppException catch (e) {
      // Check if it's "email not verified" error
      final isNotVerifiedError = e.message.toLowerCase().contains(
        'not verified',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            duration: const Duration(seconds: 5),
            action: isNotVerifiedError
                ? SnackBarAction(
                    label: 'Resend Email',
                    textColor: Colors.white,
                    onPressed: () => _showResendVerificationDialog(email),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      // Unknown errors
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // HELPER: Load selected profile from Firestore users/{uid}
  // ============================================================
  /// After successful login, fetches the user's document from
  /// Firestore to get their selectedMemberId and displayName.
  /// Saves to SharedPreferences for fast app launch next time.
  Future<void> _loadSelectedProfileFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final selectedMemberId = data['selectedMemberId'] as String?;
      final selectedDisplayName = data['selectedDisplayName'] as String?;

      if (selectedMemberId != null && selectedDisplayName != null) {
        // Save to SharedPreferences via FirebaseProfileRepository
        await FirebaseProfileRepository.instance.saveSelectedProfile(
          StoredProfile(
            memberId: selectedMemberId,
            displayName: selectedDisplayName,
          ),
        );

        // M2 Fix: Refresh ProfileController with new data from SharedPreferences
        await ProfileController.instance.initialize();
      }
    } catch (e) {
      // Non-fatal — log and continue
      debugPrint('⚠️ Failed to load selected profile: $e');
    }
  }

  // ============================================================
  // RESEND VERIFICATION EMAIL DIALOG
  // ============================================================
  Future<void> _showResendVerificationDialog(String email) async {
    final passwordController = TextEditingController();

    final shouldResend = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resend Verification Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('We will resend the verification link to:'),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('Enter your password to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resend'),
          ),
        ],
      ),
    );

    if (shouldResend != true) return;

    try {
      await AuthRepository.instance.resendEmailVerification(
        email: email,
        password: passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to resend: $e')));
      }
    }
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
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
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

                  // ===== EMAIL FIELD =====
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

                  // ===== PASSWORD FIELD =====
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

                  // ===== FORGOT PASSWORD =====
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ResetPasswordScreen(),
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

                  // ===== LOGIN BUTTON =====
                  // M2: Show loading state when _isLoading
                  CustomButton(
                    label: _isLoading ? 'Logging in...' : 'Log In',
                    onPressed: _isLoading ? null : _login,
                  ),
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

                  // ===== SOCIAL =====
                  // TODO M2-Phase 2: Implement Google sign-in
                  // (requires Google provider in Firebase Console + SHA keys)
                  // TODO M2-Phase 4: Implement Apple sign-in
                  // (requires Apple Developer account $99/year)
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
                          onTap: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
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
