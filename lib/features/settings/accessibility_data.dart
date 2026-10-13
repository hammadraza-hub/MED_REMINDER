/// ============================================================
/// ACCESSIBILITY SETTINGS DATA — backend-ready
///
/// PURPOSE:
/// Settings → Accessibility screen ka text-size scale, display
/// toggle defaults aur copy.
///
/// Backend: Future mein text scale + display modes ko app-wide
/// preferences (per account) ke saath persist kiya jayega.
/// ============================================================
library;

import 'package:flutter/material.dart';

/// Ek text-size step (slider + preview).
class TextSizeOption {
  const TextSizeOption({
    required this.label,
    required this.fraction,
    required this.previewFontSize,
  });

  final String label;

  /// Slider fill fraction (0.0 – 1.0).
  final double fraction;

  /// Live-preview text ka font size.
  final double previewFontSize;
}

/// Display options card ka ek toggle row.
class DisplayOption {
  const DisplayOption({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.defaultEnabled,
  });

  final String id;

  final IconData icon;

  final String title;

  final String subtitle;

  final bool defaultEnabled;
}

class AccessibilityData {
  AccessibilityData._();

  /// Text-size scale — screen order (Small → Extra Large).
  static const List<TextSizeOption> textSizes = [
    TextSizeOption(label: 'Small', fraction: 0.0, previewFontSize: 13),
    TextSizeOption(label: 'Medium', fraction: 0.33, previewFontSize: 14),
    TextSizeOption(label: 'Large', fraction: 0.75, previewFontSize: 18),
    TextSizeOption(label: 'Extra Large', fraction: 1.0, previewFontSize: 20),
  ];

  /// Scale labels (A A A A) ke fixed font sizes.
  static const List<double> scaleFontSizes = [13, 14, 18, 24];

  static const String previewText = 'Take with dinner to minimize upset.';

  /// Display Options section.
  static const List<DisplayOption> displayOptions = [
    DisplayOption(
      id: 'highContrast',
      icon: Icons.contrast_rounded,
      title: 'High Contrast',
      subtitle: 'Maximize color contrast and text outlines',
      defaultEnabled: false,
    ),
    DisplayOption(
      id: 'simplified',
      icon: Icons.accessibility_new_rounded,
      title: 'Simplified Mode (Senior)',
      subtitle: 'Larger text, fewer taps, high-touch buttons',
      defaultEnabled: true,
    ),
  ];

  /// Voice Logging section.
  static const bool defaultVoiceInput = true;

  static const String voiceTitle = 'Voice Input for Dose Logging';

  static const String voiceSubtitle =
      "Say 'taken' to confirm a dose without typing";

  static const String noteText =
      'Changes apply live across the whole app. High-contrast and simplified '
      'modes adjust dosage cards and alerts immediately.';
}
