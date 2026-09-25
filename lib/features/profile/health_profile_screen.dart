import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/onboarding_header.dart';
import 'notification_setup_screen.dart';

/// Profile Setup — Step 1 of 3
/// Conditions (multi-select cards) + Known Allergies (add/remove chips)
class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  // ================= STATE =================
  final Set<String> _selectedConditions = {'Asthma'};
  final List<String> _allergies = ['Penicillin'];
  final _allergyController = TextEditingController();

  // Mutable — runtime par custom conditions add hote hain
  List<_Condition> _conditions = [
    const _Condition(
      name: 'Diabetes',
      emoji: '🩸',
      badgeColor: Color(0xFFE8F0FB),
    ),
    const _Condition(
      name: 'Hypertension',
      emoji: '🩺',
      badgeColor: Color(0xFFE0F2EE),
    ),
    const _Condition(
      name: 'Heart Disease',
      emoji: '❤️',
      badgeColor: Color(0xFFFCE4EA),
    ),
    const _Condition(
      name: 'Thyroid',
      emoji: '📋',
      badgeColor: Color(0xFFFDF3DC),
    ),
    const _Condition(
      name: 'Asthma',
      emoji: '🫁',
      badgeColor: Color(0xFFE8F0FB),
    ),
    const _Condition(
      name: 'Depression',
      emoji: '💊',
      badgeColor: Color(0xFFF3E8FB),
    ),
  ];

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  // ================= ACTIONS =================
  void _toggleCondition(String name) {
    setState(() {
      if (_selectedConditions.contains(name)) {
        _selectedConditions.remove(name);
      } else {
        _selectedConditions.add(name);
      }
    });
  }

  // Field se allergy add — green + button aur keyboard done, dono yahan
  void _addAllergyFromField() {
    final value = _allergyController.text.trim();
    if (value.isEmpty) return;
    _addAllergy(value);
  }

  void _addAllergy(String value) {
    final allergy = value.trim();
    if (allergy.isEmpty || _allergies.contains(allergy)) return;

    FocusScope.of(context).unfocus(); // keyboard close
    setState(() => _allergies.add(allergy));
    _allergyController.clear();
  }

  void _removeAllergy(String allergy) {
    setState(() => _allergies.remove(allergy));
  }

  // ===== ADD OTHER CONDITION — bottom sheet =====
  void _showAddConditionSheet() {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // keyboard support
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.barEmpty,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Condition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: nameController,
                label: 'Condition Name',
                hint: 'e.g., Arthritis',
                icon: Icons.healing_rounded,
                variant: FieldVariant.bordered,
                textInputAction: TextInputAction.done,
                autofocus: true,
                onSubmitted: (_) {
                  _addCustomCondition(nameController.text);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 18),

              CustomButton.classic(
                label: 'Add Condition',
                onPressed: () {
                  _addCustomCondition(nameController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addCustomCondition(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    setState(() {
      _conditions = [
        ..._conditions,
        _Condition(
          name: cleanName,
          emoji: '🏥',
          badgeColor: AppColors.primaryLight,
        ),
      ];
      _selectedConditions.add(cleanName); // auto-select!
    });
  }

  void _continue() {
    // Step 2 (Current Medications) abhi nahi bana — seedha Notification (Step 3)
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationSetupScreen()));
  }

  void _skip() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 8),

                  // ================= SHARED HEADER (system widget) =================
                  OnboardingHeader(
                    step: 1,
                    totalSteps: 3,
                    onBack: () => Navigator.of(context).maybePop(),
                    onSkip: _skip,
                  ),

                  // ================= SCROLLABLE CONTENT =================
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Your Health Profile',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Helps us run medication safety checks (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.formSubtitle,
                            ),
                          ),
                          const SizedBox(height: 26),

                          // ================= CONDITIONS =================
                          const _SectionLabel('COMMON CONDITIONS'),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.35,
                            children: [
                              for (final condition in _conditions)
                                _ConditionCard(
                                  condition: condition,
                                  isSelected: _selectedConditions.contains(
                                    condition.name,
                                  ),
                                  onTap: () => _toggleCondition(condition.name),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _AddConditionButton(onTap: _showAddConditionSheet),
                          const SizedBox(height: 26),

                          // ================= ALLERGIES =================
                          const _SectionLabel('KNOWN ALLERGIES'),
                          const SizedBox(height: 12),

                          // Field + green add button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _allergyController,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _addAllergyFromField(),
                                  decoration: InputDecoration(
                                    hintText: 'Type allergy (e.g., Penicillin)',
                                    hintStyle: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.fieldHint,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 22,
                                      color: AppColors.fieldHint,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: AppColors.outline,
                                        width: 1.3,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: AppColors.formAccent,
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _addAllergyFromField,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: AppColors.formAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_allergies.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _AllergyChips(
                              allergies: _allergies,
                              onRemove: _removeAllergy,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ================= CONTINUE =================
                  CustomButton.classic(
                    label: 'Continue',
                    trailingIcon: Icons.arrow_forward,
                    radius: 16,
                    elevation: 0,
                    onPressed: _continue,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION LABEL
// ============================================================
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.fieldHint,
      ),
    );
  }
}

// ============================================================
// DATA CLASS — condition
// ============================================================
class _Condition {
  final String name;
  final String emoji;
  final Color badgeColor;

  const _Condition({
    required this.name,
    required this.emoji,
    required this.badgeColor,
  });
}

// ============================================================
// CONDITION CARD
// ============================================================
class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.condition,
    required this.isSelected,
    required this.onTap,
  });

  final _Condition condition;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.successBackground : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.formAccent : AppColors.outline,
            width: isSelected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: condition.badgeColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                condition.emoji,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                condition.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.formAccent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD OTHER CONDITION
// ============================================================
class _AddConditionButton extends StatelessWidget {
  const _AddConditionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Row(
        children: [
          Icon(Icons.add, size: 18, color: AppColors.formAccent),
          SizedBox(width: 4),
          Text(
            'Add other condition',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.formAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ALLERGY CHIPS
// ============================================================
class _AllergyChips extends StatelessWidget {
  const _AllergyChips({required this.allergies, required this.onRemove});

  final List<String> allergies;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final allergy in allergies)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  allergy,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => onRemove(allergy),
                  child: const Icon(
                    Icons.close,
                    size: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
