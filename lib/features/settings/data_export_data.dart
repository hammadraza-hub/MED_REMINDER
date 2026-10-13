/// ============================================================
/// DATA EXPORT DATA — backend-ready
///
/// PURPOSE:
/// Settings → Data Export screen ka static config (kaun se modules
/// export hote hain, retention reference).
///
/// IMPORTANT:
/// Display text yahan nahi rakhte — woh AppLocalizations (ARB) se
/// stable id ke through aata hai, taake language change effect ho.
///
/// Backend: actual export request (ZIP generate + email) backend
/// phase mein wire hoga; UI structure waisa hi rahega.
/// ============================================================
library;

class DataExportData {
  DataExportData._();

  /// Included modules — stable localization ids (order = screen order).
  static const List<String> includedModules = [
    'profiles',
    'doses',
    'vitals',
    'prescribers',
  ];

  /// Account records retention reference (design).
  static const String retentionId = '#EXP-8849-MED';
}
