import 'dart:typed_data';

/// The font files the PDF needs, as bytes. M17 step 4.
///
/// A PDF has to carry its own fonts. Latin (English, Spanish, French) uses Noto
/// Sans; Devanagari (Hindi) and Arabic use their own Noto fonts and are tried
/// automatically for any character Noto Sans does not have, so a note written
/// in any of those scripts prints correctly inside any report.
///
/// The builder never reads assets itself (that keeps it testable); the caller
/// loads the bytes: `rootBundle.load('assets/fonts/...')` in the app,
/// `File(...).readAsBytes()` in tests.
class ReportPdfFonts {
  const ReportPdfFonts({
    required this.regular,
    required this.bold,
    required this.devanagari,
    required this.arabic,
  });

  final ByteData regular;
  final ByteData bold;
  final ByteData devanagari;
  final ByteData arabic;

  /// Where the files live in the app bundle.
  static const String regularAsset = 'assets/fonts/NotoSans-Regular.ttf';
  static const String boldAsset = 'assets/fonts/NotoSans-Bold.ttf';
  static const String devanagariAsset =
      'assets/fonts/NotoSansDevanagari-Regular.ttf';
  static const String arabicAsset = 'assets/fonts/NotoNaskhArabic-Regular.ttf';

  static const List<String> allAssets = [
    regularAsset,
    boldAsset,
    devanagariAsset,
    arabicAsset,
  ];
}
