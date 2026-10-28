import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import 'login_screen.dart';
import '../../core/profile/profile_controller.dart';
import '../profile/health_profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _agreeToTerms = false;

  bool _nameError = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _termsError = false;
  bool _precacheDone = false;

  bool _isLoading = false;
  bool _googleLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_precacheDone) return;
    _precacheDone = true;

    for (final asset in [
      'assets/images/signup_pill1.jpg',
      'assets/images/pill.png',
      'assets/images/signup_pill3.jpg',
    ]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // PASSWORD STRENGTH
  // ============================================================
  int get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;

    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]]').hasMatch(p)) score++;

    if (score <= 1) return 1;
    if (score <= 3) return 2;
    return 3;
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Good';
      case 3:
        return 'Strong';
    }
    return '';
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.accentOrange;
      case 3:
        return AppColors.formAccent;
    }
    return AppColors.barEmpty;
  }

  // ============================================================
  // CREATE ACCOUNT (M2 - Firebase Auth + Firestore)
  // ============================================================
  Future<void> _createAccount() async {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty;
      _emailError = _emailController.text.trim().isEmpty;
      final password = _passwordController.text;
      _passwordError = password.length < 8 || password.length > 16;
      _termsError = !_agreeToTerms;
    });

    if (_nameError || _emailError || _passwordError || _termsError) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final user = await AuthRepository.instance.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      await AuthRepository.instance.updateDisplayName(displayName: name);

      await _createUserDocument(uid: user.uid, email: email, displayName: name);

      final profileId = await _createSelfProfile(
        uid: user.uid,
        displayName: name,
      );

      await FirebaseProfileRepository.instance.saveSelectedProfile(
        StoredProfile(memberId: profileId, displayName: name),
      );

      await ProfileController.instance.initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Welcome to MedRemind.'),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HealthProfileScreen()),
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
            .showSnackBar(SnackBar(content: Text('Signup failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // HELPER: Create users/{uid} document in Firestore
  // ============================================================
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final timezone = DateTime.now().timeZoneName ?? 'UTC';

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'timezone': timezone,
      'settings': {},
      'legalVersions': {'terms': '1.0', 'privacy': '1.0'},
      'aiConsentAt': null,
      'legal': {
        'termsVersion': '1.0',
        'privacyVersion': '1.0',
        'acceptedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  // ============================================================
  // HELPER: Create "self" profile in profiles/{profileId}
  // ============================================================
  Future<String> _createSelfProfile({
    required String uid,
    required String displayName,
  }) async {
    final timezone = DateTime.now().timeZoneName ?? 'UTC';

    final profileRef = await FirebaseFirestore.instance
        .collection('profiles')
        .add({
          'ownerUid': uid,
          'kind': 'self',
          'name': displayName,
          'timezone': timezone,
          'roles': {uid: 'owner'},
          'memberUids': [uid],
          'healthUids': [uid],
          'permissions': {},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'selectedMemberId': profileRef.id,
      'selectedDisplayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return profileRef.id;
  }

  // ============================================================
  // GOOGLE SIGN-UP (NEW - Google provider)
  // Loads ACTUAL profileId from Firestore users/{uid}.selectedMemberId
  // instead of using user.uid (which was a bug)
  // ============================================================
  Future<void> _handleGoogleSignUp() async {
    setState(() => _googleLoading = true);
    try {
      debugPrint(
        'ðŸ” GOOGLE SIGN-UP: Calling AuthRepository.instance.signInWithGoogle()',
      );
      final result = await AuthRepository.instance.signInWithGoogle();
      debugPrint(
        'ðŸ” GOOGLE SIGN-UP: signInWithGoogle returned. uid=${result.user.uid}, isNewUser=${result.isNewUser}',
      );
      if (!mounted) {
        debugPrint(
          'ðŸ” GOOGLE SIGN-UP: Widget not mounted after signInWithGoogle â€” ABORTING',
        );
        return;
      }

      debugPrint(
        'ðŸ” GOOGLE SIGN-UP: Querying Firestore for users/{uid} doc...',
      );
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user.uid)
          .get();

      String? memberId;
      String? memberDisplayName;

      if (userDoc.exists) {
        final data = userDoc.data()!;
        memberId = data['selectedMemberId'] as String?;
        memberDisplayName = data['selectedDisplayName'] as String?;
        debugPrint(
          'ðŸ” GOOGLE SIGN-UP: Firestore user doc found. memberId=$memberId, displayName=$memberDisplayName',
        );
      } else {
        debugPrint(
          'ðŸ” GOOGLE SIGN-UP: âŒ Firestore user doc NOT FOUND â€” using fallback',
        );
      }

      memberId ??= result.user.uid;
      memberDisplayName ??= result.user.displayName ?? 'Me';

      await FirebaseProfileRepository.instance.saveSelectedProfile(
        StoredProfile(memberId: memberId, displayName: memberDisplayName),
      );

      debugPrint(
        'ðŸ” GOOGLE SIGN-UP: Calling ProfileController.instance.initialize()...',
      );
      await ProfileController.instance.initialize();

      if (!mounted) {
        debugPrint(
          'ðŸ” GOOGLE SIGN-UP: Widget not mounted before navigation â€” ABORTING',
        );
        return;
      }

      if (result.isNewUser) {
        debugPrint(
          'ðŸ” GOOGLE SIGN-UP: Navigating to HealthProfileScreen (new user)',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google account connected! Welcome to MedRemind.'),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HealthProfileScreen()),
        );
      } else {
        debugPrint(
          'ðŸ” GOOGLE SIGN-UP: Navigating to MedRemindShell (existing user)',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account already exists. Logging you in...'),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MedRemindShell()),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Google sign-up failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  // ================= BACK =================
                  InkWell(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(30),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ================= LOGO + MEDREMIND =================
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/med_reminder_logo.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.formAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'MedRemind',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ================= TITLE =================
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Start your health journey today',
                    style: TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ================= PILLS =================
                  Row(
                    children: [
                      _pillCircle('assets/images/signup_pill1.jpg'),
                      Transform.translate(
                        offset: const Offset(-7, 0),
                        child: _pillCircle('assets/images/signup_pill2.jpg'),
                      ),
                      Transform.translate(
                        offset: const Offset(-14, 0),
                        child: _pillCircle('assets/images/signup_pill3.jpg'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ================= FULL NAME =================
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Sarah Johnson',
                    icon: Icons.person_outline_rounded,
                    variant: FieldVariant.bordered,
                    textInputAction: TextInputAction.next,
                    hasError: _nameError,
                    onChanged: (_) {
                      if (_nameError) setState(() => _nameError = false);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ================= EMAIL =================
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'sarah@email.com',
                    icon: Icons.mail_outline_rounded,
                    variant: FieldVariant.bordered,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    hasError: _emailError,
                    onChanged: (_) {
                      if (_emailError) setState(() => _emailError = false);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ================= PASSWORD =================
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '8-16 characters',
                    icon: Icons.lock_outline_rounded,
                    variant: FieldVariant.bordered,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    hasError: _passwordError,
                    inputFormatters: [LengthLimitingTextInputFormatter(16)],
                    onChanged: (_) {
                      setState(() {
                        _passwordError = false;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // ================= PASSWORD STRENGTH (live) =================
                  Row(
                    children: [
                      Expanded(
                        child: _StrengthBar(
                          color: _passwordStrength >= 1
                              ? _strengthColor
                              : AppColors.barEmpty,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _StrengthBar(
                          color: _passwordStrength >= 2
                              ? _strengthColor
                              : AppColors.barEmpty,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _StrengthBar(
                          color: _passwordStrength >= 3
                              ? _strengthColor
                              : AppColors.barEmpty,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 44,
                        child: Text(
                          _strengthLabel,
                          style: TextStyle(
                            color: _strengthColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // ================= DIVIDER =================
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppColors.hairline, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 13),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppColors.hairline, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),

                  // ================= SOCIAL (Apple + Google) =================
                  Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          label: 'Apple',
                          icon: const AppleLogo(size: 20),
                          variant: SocialVariant.outlined,
                          height: 50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SocialButton(
                          label: 'Google',
                          icon: _googleLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const GoogleLogo(size: 20),
                          variant: SocialVariant.outlined,
                          height: 50,
                          onPressed: _googleLoading
                              ? null
                              : _handleGoogleSignUp,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ================= TERMS =================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _agreeToTerms,
                          activeColor: AppColors.formAccent,
                          checkColor: Colors.white,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: _termsError
                                ? AppColors.error
                                : AppColors.formIcon,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                    _termsError = false;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'I agree to ',
                              style: TextStyle(
                                fontSize: 12,
                                color: _termsError
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                            ),
                            _linkText('Terms of Service'),
                            Text(
                              ' and ',
                              style: TextStyle(
                                fontSize: 12,
                                color: _termsError
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                            ),
                            _linkText('Privacy Policy'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),

                  // ================= CREATE BUTTON =================
                  CustomButton.classic(
                    label: _isLoading
                        ? 'Creating Account...'
                        : 'Create Account',
                    onPressed: (_agreeToTerms && !_isLoading)
                        ? _createAccount
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // ================= LOGIN LINK =================
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.formSubtitle,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: AppColors.formAccent,
                              fontSize: 14,
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

  // ================= HELPERS =================

  Widget _linkText(String text) {
    return GestureDetector(
      onTap: () {
        // TODO: Terms / Privacy screen
      },
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.formAccent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.formAccent,
        ),
      ),
    );
  }

  Widget _pillCircle(String asset) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.pillPlaceholder,
            child: const Icon(
              Icons.medication_rounded,
              size: 23,
              color: AppColors.formAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Strength bar segment with smooth color transition
class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
