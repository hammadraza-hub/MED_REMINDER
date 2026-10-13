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

  /// Small → Extra Large. Index 2 (Large) = current app default (1.0).
  static const List<double> textScaleSteps = [0.85, 0.95, 1.0, 1.3];

  /// Safe bounds — iske bahar layouts overflow kar sakte hain.
  static const double minScaleFactor = 0.85;
  static const double maxScaleFactor = 1.3;

  /// Design default: "Large".
  static const int defaultIndex = 2;

  int _textSizeIndex = defaultIndex;

  bool _isInitialized = false;

  int get textSizeIndex => _textSizeIndex;

  double get textScaleFactor => textScaleSteps[_textSizeIndex];

  bool get isInitialized => _isInitialized;

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
}
