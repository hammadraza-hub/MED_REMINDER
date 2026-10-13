import 'package:flutter/material.dart';

import '../../core/accessibility/accessibility_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_toggle_switch.dart';
import 'accessibility_data.dart';

/// ============================================================
/// ACCESSIBILITY SETTINGS SCREEN
///
/// PURPOSE:
/// Text size, high-contrast / simplified (senior) mode aur voice
/// dose-logging preferences.
///
/// NAVIGATION:
/// Settings → Accessibility row se khulti hai. Detail screen hone ki
/// wajah se shared AppBottomNavigation reuse hoti hai (Settings tab).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// Text scale + display modes ko app-wide preferences mein persist
/// karna (yeh demo live-preview deta hai).
/// ============================================================
class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  // ============================================================
  // STATE
  // ============================================================

  late int _textSizeIndex;

  late final Map<String, bool> _displayEnabled;

  late bool _voiceInput;

  @override
  void initState() {
    super.initState();

    _textSizeIndex = AccessibilityController.instance.textSizeIndex;

    _displayEnabled = {
      for (final option in AccessibilityData.displayOptions)
        option.id: option.defaultEnabled,
    };

    _voiceInput = AccessibilityData.defaultVoiceInput;
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _setTextSize(int index) {
    if (index == _textSizeIndex) return;

    setState(() {
      _textSizeIndex = index;
    });

    // Poore app ka text scale apply + persist karo.
    AccessibilityController.instance.setTextSizeIndex(index);
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextSizeCard(),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Display Options'),
                        const SizedBox(height: 8),
                        _buildDisplayOptionsCard(),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Voice Logging'),
                        const SizedBox(height: 8),
                        _buildVoiceCard(),
                        const SizedBox(height: 16),
                        _buildNoteStrip(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 4,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              const Expanded(
                child: Text(
                  'Accessibility Settings',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppAvatar(
                size: 32,
                ringColor: AppColors.surface,
                ringWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEXT SIZE CARD
  // ============================================================

  Widget _buildTextSizeCard() {
    final current = AccessibilityData.textSizes[_textSizeIndex];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Text Size',
                style: TextStyle(
                  color: AppColors.reportPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.permissionsChipFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  current.label,
                  style: const TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSizeSlider(),
          const SizedBox(height: 8),
          _buildScaleLabels(),
          const SizedBox(height: 16),
          _buildPreviewBox(),
        ],
      ),
    );
  }

  Widget _buildSizeSlider() {
    final fraction = AccessibilityData.textSizes[_textSizeIndex].fraction;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fillWidth = width * fraction;
        final knobLeft = (fillWidth - 10).clamp(0.0, width - 20);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _setSizeFromRatio(
            details.localPosition.dx / width,
          ),
          child: SizedBox(
            height: 24,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 8,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.permissionsChipFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: fillWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.reportPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: knobLeft,
                  top: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.toggleKnobShadow,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.reportPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setSizeFromRatio(double ratio) {
    final int index;
    if (ratio > 0.85) {
      index = 3;
    } else if (ratio > 0.55) {
      index = 2;
    } else if (ratio > 0.20) {
      index = 1;
    } else {
      index = 0;
    }

    _setTextSize(index);
  }

  Widget _buildScaleLabels() {
    final sizes = AccessibilityData.textSizes;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (var i = 0; i < sizes.length; i++)
          GestureDetector(
            onTap: () => _setTextSize(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: AccessibilityData.scaleFontSizes[i],
                  fontWeight: i == _textSizeIndex
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: i == _textSizeIndex
                      ? AppColors.reportPrimary
                      : AppColors.permissionsSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewBox() {
    final current = AccessibilityData.textSizes[_textSizeIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.formAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE PREVIEW',
                style: TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: AppColors.reportPrimary,
              fontSize: current.previewFontSize,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            child: const Text(AccessibilityData.previewText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPLAY OPTIONS CARD
  // ============================================================

  Widget _buildDisplayOptionsCard() {
    final options = AccessibilityData.displayOptions;

    return _card(
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.permissionsInactiveFill,
              ),
            _buildToggleRow(
              icon: options[i].icon,
              title: options[i].title,
              subtitle: options[i].subtitle,
              value: _displayEnabled[options[i].id] ?? false,
              accentIcon: false,
              onChanged: (value) {
                setState(() {
                  _displayEnabled[options[i].id] = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // VOICE CARD
  // ============================================================

  Widget _buildVoiceCard() {
    return _card(
      child: _buildToggleRow(
        icon: Icons.mic_rounded,
        title: AccessibilityData.voiceTitle,
        subtitle: AccessibilityData.voiceSubtitle,
        value: _voiceInput,
        accentIcon: true,
        onChanged: (value) {
          setState(() {
            _voiceInput = value;
          });
        },
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool accentIcon,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.permissionsChipFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 22,
            color: accentIcon
                ? AppColors.formAccent
                : AppColors.reportPrimary,
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
                  color: AppColors.reportPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AppToggleSwitch(value: value, onChanged: onChanged),
      ],
    );
  }

  // ============================================================
  // NOTE STRIP
  // ============================================================

  Widget _buildNoteStrip() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.formAccent,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              AccessibilityData.noteText,
              style: TextStyle(
                color: AppColors.permissionsSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED HELPERS
  // ============================================================

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.reportPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
