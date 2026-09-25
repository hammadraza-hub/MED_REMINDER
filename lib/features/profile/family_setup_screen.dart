import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/onboarding_header.dart';
import '../home/home_screen.dart';

/// Family Setup — Step 3 of 3
/// Invite a Caregiver / Add Family Member + send invite
class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _inviteController = TextEditingController();

  // Kaunsa option select hai — caregiver ya family member
  bool _inviteCaregiver = true; // default: caregiver

  bool _inviteError = false;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  // ================= ACTIONS =================
  void _sendInvite() {
    FocusScope.of(context).unfocus();

    final value = _inviteController.text.trim();

    // Email YA phone — dono valid
    final emailValid = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value);
    final phoneValid = RegExp(r'^\+?[\d\s-]{10,15}$').hasMatch(value);
    final isValid = value.isNotEmpty && (emailValid || phoneValid);

    setState(() => _inviteError = !isValid);

    if (!isValid) return;

    // TODO: Asli invite backend — agle phase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invite sent to $value! '
          '${_inviteCaregiver ? '(Caregiver)' : '(Family Member)'}',
        ),
      ),
    );
    _inviteController.clear();
  }

  void _skipForNow() {
    // Setup complete — ab HOME! Poora stack saaf.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= SHARED HEADER =================
                  OnboardingHeader(
                    step: 3,
                    totalSteps: 3,
                    onBack: () => Navigator.of(context).maybePop(),
                    onSkip: _skipForNow,
                  ),

                  // ================= SCROLLABLE CONTENT =================
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ============ SQUARE IMAGE (responsive) ============
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/family_main.png',
                                width: screenHeight * 0.26,
                                height: screenHeight * 0.26, // square!
                                fit: BoxFit.cover,
                                cacheWidth: 600,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: screenHeight * 0.26,
                                      height: screenHeight * 0.26,
                                      color: AppColors.primaryLight,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.family_restroom_rounded,
                                        size: 64,
                                        color: AppColors.formAccent,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ============ TITLE ============
                          const Text(
                            'Connect Your Family',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add loved ones to share reminders and stay connected in their care.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.formSubtitle,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ============ 2 OPTION CARDS ============
                          _optionCard(
                            asset: 'assets/images/caregiver.png',
                            fallbackIcon: Icons.volunteer_activism_rounded,
                            title: 'Invite a Caregiver',
                            subtitle: 'They can view & manage reminders',
                            isSelected: _inviteCaregiver,
                            onTap: () =>
                                setState(() => _inviteCaregiver = true),
                          ),
                          const SizedBox(height: 12),
                          _optionCard(
                            asset: 'assets/images/family_member.png',
                            fallbackIcon: Icons.person_add_rounded,
                            title: 'Add Family Member',
                            subtitle: 'Get their dose reminders too',
                            isSelected: !_inviteCaregiver,
                            onTap: () =>
                                setState(() => _inviteCaregiver = false),
                          ),
                          const SizedBox(height: 24),

                          // ============ INVITE INPUT ============
                          CustomTextField(
                            controller: _inviteController,
                            label: 'Invite via',
                            hint: 'Enter email or phone number...',
                            icon: Icons.alternate_email_rounded,
                            variant: FieldVariant.bordered,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            hasError: _inviteError,
                            onSubmitted: (_) => _sendInvite(),
                            onChanged: (_) {
                              if (_inviteError) {
                                setState(() => _inviteError = false);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ============ SEND INVITE ============
                  CustomButton.classic(
                    label: 'Send Invite',
                    trailingIcon: Icons.send_rounded,
                    radius: 16,
                    elevation: 0,
                    onPressed: _sendInvite,
                  ),

                  // ============ SKIP FOR NOW ============
                  TextButton(
                    onPressed: _skipForNow,
                    child: const Text(
                      'Skip for Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.formAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= OPTION CARD =================
  Widget _optionCard({
    required String asset,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.successBackground : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.formAccent : AppColors.outline,
            width: isSelected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            // Round image
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.outline),
              ),
              child: ClipOval(
                child: Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(fallbackIcon, size: 26, color: AppColors.formAccent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.formSubtitle,
                    ),
                  ),
                ],
              ),
            ),

            // Selection circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.formAccent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.formAccent : AppColors.outline,
                  width: 1.6,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
