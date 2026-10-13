/// ============================================================
/// COMPARE PLANS DATA — backend-ready
///
/// PURPOSE:
/// Free vs Solo Pro vs Family Pro ke side-by-side feature matrix
/// aur pricing ka static config.
///
/// IMPORTANT:
/// Display text yahan nahi rakhte — woh AppLocalizations (ARB) se
/// stable id ke through aata hai, taake language change effect ho.
///
/// Column order = availability list order: [free, solo, family].
///
/// TODO Backend:
/// Pricing aur feature catalog RevenueCat / App Store / Play
/// Billing se aayega. Abhi hardcoded USD demo values hain.
/// ============================================================
library;

class CompareGroup {
  const CompareGroup({required this.id, required this.featureIds});

  final String id;
  final List<String> featureIds;
}

class ComparePlansData {
  ComparePlansData._();

  /// Demo subscriber name (proper noun — localized nahi hota).
  static const String demoName = 'Sarah M.';

  /// Plan column ids in display order (Free / Solo / Family).
  static const List<String> columnIds = ['free', 'solo', 'family'];

  /// Feature groups (display order).
  static const List<CompareGroup> groups = [
    CompareGroup(
      id: 'daily',
      featureIds: ['unlimitedMeds', 'adherence'],
    ),
    CompareGroup(
      id: 'clinical',
      featureIds: [
        'interactions',
        'inventory',
        'doctorTools',
        'reports',
        'healthSync',
      ],
    ),
    CompareGroup(
      id: 'family',
      featureIds: ['familyLinking', 'missedDose', 'familyDashboard'],
    ),
  ];

  /// Feature availability per column: [free, solo, family].
  static const Map<String, List<bool>> availability = {
    'unlimitedMeds': [true, true, true],
    'adherence': [true, true, true],
    'interactions': [false, true, true],
    'inventory': [false, true, true],
    'doctorTools': [false, true, true],
    'reports': [false, true, true],
    'healthSync': [false, true, true],
    'familyLinking': [false, false, true],
    'missedDose': [false, false, true],
    'familyDashboard': [false, false, true],
  };

  /// Yearly price per plan (USD). TODO: StoreKit / Play Billing.
  static const Map<String, String> priceYearly = {
    'free': r'$0',
    'solo': r'$39.99',
    'family': r'$79.99',
  };

  /// Kya [featureId] plan column [columnIndex] mein available hai.
  static bool isAvailable(String featureId, int columnIndex) {
    return availability[featureId]?[columnIndex] ?? false;
  }
}
