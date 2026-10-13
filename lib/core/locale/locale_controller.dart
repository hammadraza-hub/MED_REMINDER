import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// ============================================================
/// LOCALE CONTROLLER
///
/// App-wide display language (locale) state.
///
/// Language screen yahan selected locale set karta hai, aur
/// main.dart MaterialApp.locale ko iske saath bind karta hai —
/// is tarah poori app ke strings + RTL (Arabic) ek saath change
/// hote hain.
///
/// IMPORTANT:
/// Locale SharedPreferences se persist hota hai, is liye restart
/// ke baad bhi user ki language yaad rehti hai.
/// ============================================================
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const String _localeKey = 'app_locale';

  /// Supported locales — gen-l10n se derive (single source of truth).
  ///
  /// Nayi language add karni ho to sirf `lib/l10n/app_xx.arb` banao aur
  /// `flutter gen-l10n` chalao; yeh list khud update ho jayegi.
  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;

  /// Default locale (design: English).
  static const Locale defaultLocale = Locale('en');

  Locale _locale = defaultLocale;

  bool _isInitialized = false;

  Locale get locale => _locale;

  bool get isInitialized => _isInitialized;

  String get localeCode => _locale.languageCode;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_localeKey);

      if (stored != null && stored.isNotEmpty) {
        _locale = Locale(stored);
      }
    } catch (error, stackTrace) {
      debugPrint('Locale initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ============================================================
  // SET LOCALE
  // ============================================================

  Future<void> setLocaleCode(String code) async {
    if (!supportedLocales.any((locale) => locale.languageCode == code)) {
      return;
    }

    if (code == _locale.languageCode) {
      return;
    }

    _locale = Locale(code);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, code);
    } catch (error) {
      debugPrint('Locale persist failed: $error');
    }
  }
}