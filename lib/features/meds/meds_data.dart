import 'package:flutter/material.dart';

/// ============================================================
/// MEDS DATA — backend-ready
/// Backend: Firebase se medicines collection — UI zero change!
/// ============================================================

/// Medicine type
enum MedicineType { tablet, capsule, liquid, drops, injection }

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

  /// Display label — "Day 4 of 10" ya "5 days left"
  String get supplyLabel {
    if (isCourse) return 'Day $courseDay of $courseTotalDays';
    return '$supplyDaysLeft days left';
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
