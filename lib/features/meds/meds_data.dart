import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// ============================================================
/// MEDS DATA — backend-ready
/// Backend: Firebase se medicines collection — UI zero change!
/// ============================================================

/// Medicine type
enum MedicineType { tablet, capsule, liquid, drops, injection }

/// Medicine type ka localized form label.
String medicineTypeLabel(AppLocalizations l10n, MedicineType type) {
  return switch (type) {
    MedicineType.tablet => l10n.doseFormTablet,
    MedicineType.liquid => l10n.doseFormLiquid,
    MedicineType.capsule => l10n.medsFormCapsule,
    MedicineType.drops => l10n.medsFormDrops,
    MedicineType.injection => l10n.medsFormInjection,
  };
}

/// Frequency text ("2x daily") ko localized label banao.
/// Parse na ho to original text hi return (fallback).
String localizedFrequency(AppLocalizations l10n, String frequency) {
  final match = RegExp(r'(\d+)').firstMatch(frequency);
  final count = int.tryParse(match?.group(1) ?? '');
  if (count == null || count < 1) return frequency;
  return l10n.medsFrequencyDaily(count);
}

/// Dose form id ("Tablet", "Capsule", ...) ka localized label.
/// Unknown id → wahi id wapas (safe fallback).
String medFormLabel(AppLocalizations l10n, String formId) {
  switch (formId) {
    case 'Tablet':
      return l10n.doseFormTablet;
    case 'Capsule':
      return l10n.medsFormCapsule;
    case 'Drops':
      return l10n.medsFormDrops;
    case 'Liquid':
      return l10n.doseFormLiquid;
    case 'Injection':
      return l10n.medsFormInjection;
    case 'Extended Release':
      return l10n.medFormExtendedRelease;
    default:
      return formId;
  }
}

/// Ek medicine ki poori info
class Medicine {
  Medicine({
    required this.name,
    required this.dose,
    required this.type,
    required this.frequency,
    required this.nextDose,
    required this.supplyDaysLeft,
    this.isLowStock = false,
    this.courseDay,
    this.courseTotalDays,
    this.isArchived = false,
  });

  final String name;
  final String dose;
  final MedicineType type;
  final String frequency; // "2x daily"
  final String nextDose; // "8:30 AM"

  /// Kitne din ki supply bachi (regular medicines)
  final int supplyDaysLeft;
  final bool isLowStock;

  /// Course wali dawai (Amoxicillin jaisi) — din 4 of 10
  final int? courseDay;
  final int? courseTotalDays;
  final bool isArchived;

  /// Backend: Medicine.fromJson(json)

  // ================= COMPUTED — logic data mein, UI mein nahi! =================

  /// Course dawai hai? (Amoxicillin type — kisi din khatam hoti hai)
  bool get isCourse => courseDay != null && courseTotalDays != null;

  /// Course ka end date label — "Sep 22"
  /// Backend: courseTotalDays se calculate hoga
  String get endsOnLabel => 'Sep 22'; // TODO Backend: date math

  /// Display label — "Day 4 of 10" ya "5 days left" (localized).
  String supplyLabel(AppLocalizations l10n) {
    if (isCourse) return l10n.medsDayOf(courseDay!, courseTotalDays!);
    return l10n.medsDaysLeft(supplyDaysLeft);
  }

  /// Progress bar value — 0.0 to 1.0
  /// Low stock → kam | Course → kitna complete | Normal → supply ratio
  double get progressValue {
    if (isCourse) return courseDay! / courseTotalDays!;
    if (isLowStock) return 0.10;
    // Supply 0-60 din scale par
    return (supplyDaysLeft / 60).clamp(0.1, 1.0);
  }

  /// Low stock warning chip (Inventory badge ke liye)
  static int lowStockCount(List<Medicine> meds) => meds
      .where((m) => m.isLowStock || (m.isCourse && m.supplyDaysLeft <= 5))
      .length;

  // ================= LABELS =================

  String get typeLabel {
    switch (type) {
      case MedicineType.tablet:
        return 'Tablet';
      case MedicineType.capsule:
        return 'Capsule';
      case MedicineType.liquid:
        return 'Liquid';
      case MedicineType.drops:
        return 'Drops';
      case MedicineType.injection:
        return 'Injection';
    }
  }

  // ================= IMAGE ASSET =================

  /// Medicine form ki image.
  /// Image available na ho to UI typeIcon fallback use karegi.
  String? get typeImageAsset {
    switch (type) {
      case MedicineType.tablet:
        return 'assets/images/tablet.jpg';

      case MedicineType.capsule:
        return 'assets/images/capsule.jpg';

      case MedicineType.liquid:
        return 'assets/images/liquid.jpg';

      case MedicineType.injection:
        return 'assets/images/injection.jpg';

      case MedicineType.drops:
        return null;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case MedicineType.tablet:
        return Icons.medication_outlined;
      case MedicineType.capsule:
        return Icons.medication_outlined;
      case MedicineType.liquid:
        return Icons.medication_liquid_outlined;
      case MedicineType.drops:
        return Icons.opacity_outlined;
      case MedicineType.injection:
        return Icons.vaccines_outlined;
    }
  }
}

/// ============================================================
/// DATA PROVIDER — abhi dummy, backend Firebase
/// ============================================================
class MedsData {
  /// Backend: medicines collection from Firestore
  static List<Medicine> medicines() => [
    Medicine(
      name: 'Metformin',
      dose: '500mg',
      type: MedicineType.tablet,
      frequency: '2x daily',
      nextDose: '8:30 AM',
      supplyDaysLeft: 5,
      isLowStock: true,
    ),
    Medicine(
      name: 'Amlodipine',
      dose: '5mg',
      type: MedicineType.tablet,
      frequency: '1x daily',
      nextDose: '7:00 AM',
      supplyDaysLeft: 28,
    ),
    Medicine(
      name: 'Vitamin D3 Drops',
      dose: '1000 IU',
      type: MedicineType.drops,
      frequency: '1x daily',
      nextDose: '8:00 PM',
      supplyDaysLeft: 43,
    ),
    Medicine(
      name: 'Amoxicillin',
      dose: '250mg',
      type: MedicineType.capsule,
      frequency: '3x daily',
      nextDose: '2:00 PM',
      supplyDaysLeft: 4,
      courseDay: 4,
      courseTotalDays: 10,
    ),
  ];

  /// Backend: archived medicines
  static List<Medicine> archived() => [];

  /// Search filter — naam ya dose se
  static List<Medicine> search(List<Medicine> meds, String query) {
    if (query.isEmpty) return meds;
    return meds
        .where(
          (m) =>
              m.name.toLowerCase().contains(query.toLowerCase()) ||
              m.dose.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Backend: user ki allergies collection se count
  /// Abhi: Health Profile setup se aana chahiye — dummy 1 (Penicillin)
  static int allergiesCount() => 1;
}
