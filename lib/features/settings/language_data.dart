/// ============================================================
/// LANGUAGE SETTINGS DATA — backend-ready
///
/// PURPOSE:
/// Settings → Language screen ki supported languages list aur copy.
///
/// Backend: selected language ko app-wide (per account) persist
/// kiya jayega aur localization resources load honge.
/// ============================================================
library;

import '../../l10n/app_localizations.dart';

/// Ek supported display language.
class LanguageOption {
  const LanguageOption({required this.code, required this.label});

  /// ISO language code (persist / i18n + flag lookup ke liye).
  final String code;

  /// Display label (native script ke saath).
  final String label;
}

class LanguageData {
  LanguageData._();

  /// Endonyms (native names) — keyed by ISO language code.
  ///
  /// Nayi language add karte waqt yahan uska native naam add karo;
  /// baaki list AppLocalizations se khud derive hoti hai.
  static const Map<String, String> _endonyms = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'ar': 'العربية (Arabic)',
    'hi': 'हिन्दी (Hindi)',
  };

  /// Supported languages — AppLocalizations se derive (single source).
  ///
  /// Flag icons `LanguageFlag(code: ...)` widget se draw hote hain.
  static List<LanguageOption> get languages => [
    for (final locale in AppLocalizations.supportedLocales)
      LanguageOption(
        code: locale.languageCode,
        label: _endonyms[locale.languageCode] ?? locale.languageCode,
      ),
  ];

  /// Default selected language (design: English).
  static const String defaultCode = 'en';
}
