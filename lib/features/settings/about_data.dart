/// ============================================================
/// ABOUT DATA — backend-ready
///
/// PURPOSE:
/// Settings → About screen ka static config (legal documents list,
/// credits).
///
/// IMPORTANT:
/// Display text yahan nahi rakhte — woh AppLocalizations (ARB) se
/// stable id ke through aata hai, taake language change effect ho.
///
/// Backend: legal document content backend/CMS phase mein wire hoga;
/// abhi in-app sheet mein generic summary dikhti hai.
/// ============================================================
library;

class AboutData {
  AboutData._();

  /// Legal document rows — stable localization ids (order = screen order).
  static const List<String> legalDocIds = ['terms', 'privacy', 'licenses'];

  /// Credits rows — stable localization ids (order = screen order).
  static const List<String> creditIds = ['design', 'drugData', 'icons'];
}
