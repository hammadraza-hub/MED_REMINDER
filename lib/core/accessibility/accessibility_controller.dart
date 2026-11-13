import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// ACCESSIBILITY CONTROLLER
///
/// App-wide text-size (font scale) state.
///
/// Accessibility screen slider yahan value set karta hai aur
/// main.dart isko MediaQuery.textScaler par apply karta hai — is
/// tarah text poore app mein scale hota hai.
///
/// IMPORTANT:
/// Scale ko safe bounds (min/max) ke andar rakha jata hai taake
/// fixed-height rows/headers overflow na hon.
///
/// TODO Backend:
/// Firebase phase mein per-account preference Firestore mein
/// persist ho sakegi.
/// ============================================================
class AccessibilityController extends ChangeNotifier {
  AccessibilityController._();

  static final AccessibilityController instance = AccessibilityController._();

  static const String _textSizeKey = 'accessibility_text_size_index';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _simplifiedKey = 'accessibility_simplified_mode';
  static const String _voiceInputKey = 'accessibility_voice_input';

  // Defaults match the Accessibility screen (AccessibilityData).
  static const bool defaultHighContrast = false;
  static const bool defaultSimplifiedMode = true;
  static const bool defaultVoiceInput = true;

  /// Small → Extra Large. Index 2 (Large) = current app default (1.0).
  static const List<double> textScaleSteps = [0.85, 0.95, 1.0, 1.3];

  /// Safe bounds — iske bahar layouts overflow kar sakte hain.
  static const double minScaleFactor = 0.85;
  static const double maxScaleFactor = 1.3;

  /// Design default: "Large".
  static const int defaultIndex = 2;

  int _textSizeIndex = defaultIndex;

  // M13 step 3: these three are only STORED (and synced across devices)
  // for now; they do not change the app's look yet.
  bool _highContrast = defaultHighContrast;
  bool _simplifiedMode = defaultSimplifiedMode;
  bool _voiceInput = defaultVoiceInput;

  bool _isInitialized = false;

  int get textSizeIndex => _textSizeIndex;

  double get textScaleFactor => textScaleSteps[_textSizeIndex];

  bool get isInitialized => _isInitialized;

  bool get highContrast => _highContrast;
  bool get simplifiedMode => _simplifiedMode;
  bool get voiceInput => _voiceInput;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_textSizeKey);

      if (stored != null && stored >= 0 && stored < textScaleSteps.length) {
        _textSizeIndex = stored;
      }
      _highContrast = prefs.getBool(_highContrastKey) ?? _highContrast;
      _simplifiedMode = prefs.getBool(_simplifiedKey) ?? _simplifiedMode;
      _voiceInput = prefs.getBool(_voiceInputKey) ?? _voiceInput;
    } catch (error, stackTrace) {
      debugPrint('Accessibility initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ============================================================
  // SET TEXT SIZE
  // ============================================================

  Future<void> setTextSizeIndex(int index) async {
    if (index < 0 || index >= textScaleSteps.length) {
      return;
    }

    if (index == _textSizeIndex) {
      return;
    }

    _textSizeIndex = index;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_textSizeKey, index);
    } catch (error) {
      debugPrint('Accessibility persist failed: $error');
    }
  }

  Future<void> setHighContrast(bool value) =>
      _setBool(value, _highContrast, _highContrastKey, (v) => _highContrast = v);

  Future<void> setSimplifiedMode(bool value) => _setBool(
      value, _simplifiedMode, _simplifiedKey, (v) => _simplifiedMode = v);

  Future<void> setVoiceInput(bool value) =>
      _setBool(value, _voiceInput, _voiceInputKey, (v) => _voiceInput = v);

  Future<void> _setBool(
    bool value,
    bool current,
    String key,
    void Function(bool) assign,
  ) async {
    if (value == current) return;
    assign(value);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (error) {
      debugPrint('Accessibility persist failed: $error');
    }
  }
}
