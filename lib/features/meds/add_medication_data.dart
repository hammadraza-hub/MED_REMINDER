import 'package:flutter/material.dart';

/// ============================================================
/// ADD MEDICATION DATA — backend-ready
///
/// Abhi: local medicine "database" (dummy)
/// Backend: FDA/openFDA API ya Firebase medicines collection
///
/// Flow: User search kare → results → Select → details form
/// ============================================================

/// Search result — database ki medicine
class MedSearchResult {
  const MedSearchResult({
    required this.name,
    required this.strength,
    required this.form,
    required this.route,
    required this.commonFor,
    this.isDailyDose = false,
  });

  final String name; // "Metformin"
  final String strength; // "500mg"
  final String form; // "Tablet" / "Extended Release"
  final String route; // "Oral"
  final String commonFor; // "Common for: Diabetes"
  final bool isDailyDose;

  /// Backend: MedSearchResult.fromFdaJson(json)
}

class AddMedicationData {
  /// ============================================================
  /// DUMMY DATABASE — common medicines
  /// Backend: FDA database API se search
  ///
  /// Abhi humari list chhoti hai — search "smart" hai:
  /// naam se match + related variants bhi dikhata hai
  /// ============================================================
  static const List<MedSearchResult> _database = [
    MedSearchResult(
      name: 'Metformin',
      strength: '500mg',
      form: 'Tablet',
      route: 'Oral',
      commonFor: 'Diabetes',
    ),
    MedSearchResult(
      name: 'Metformin HCl',
      strength: '1000mg',
      form: 'Extended Release',
      route: 'Oral',
      commonFor: 'Type 2 Diabetes',
    ),
    MedSearchResult(
      name: 'Metformin ER',
      strength: '750mg',
      form: 'Tablet',
      route: 'Oral',
      commonFor: 'Daily Dose',
      isDailyDose: true,
    ),
    MedSearchResult(
      name: 'Amlodipine',
      strength: '5mg',
      form: 'Tablet',
      route: 'Oral',
      commonFor: 'High Blood Pressure',
    ),
    MedSearchResult(
      name: 'Lisinopril',
      strength: '10mg',
      form: 'Tablet',
      route: 'Oral',
      commonFor: 'Hypertension',
    ),
    MedSearchResult(
      name: 'Aspirin',
      strength: '81mg',
      form: 'Tablet',
      route: 'Oral',
      commonFor: 'Heart Health',
    ),
    MedSearchResult(
      name: 'Atorvastatin',
      strength: '20mg',
      form: 'Tablet',
      route: 'Oral',
      commonFor: 'High Cholesterol',
    ),
    MedSearchResult(
      name: 'Amoxicillin',
      strength: '250mg',
      form: 'Capsule',
      route: 'Oral',
      commonFor: 'Bacterial Infection',
    ),
    MedSearchResult(
      name: 'Ibuprofen',
      strength: '200mg',
      form: 'Tablet',
      route: 'Oral',
      commonFor: 'Pain & Inflammation',
    ),
    MedSearchResult(
      name: 'Vitamin D3',
      strength: '1000 IU',
      form: 'Drops',
      route: 'Oral',
      commonFor: 'Bone Health',
    ),
    MedSearchResult(
      name: 'Insulin Glargine',
      strength: '100 units/mL',
      form: 'Injection',
      route: 'Subcutaneous',
      commonFor: 'Diabetes',
    ),
    MedSearchResult(
      name: 'Omeprazole',
      strength: '20mg',
      form: 'Capsule',
      route: 'Oral',
      commonFor: 'Acid Reflux',
    ),
  ];

  /// ============================================================
  /// SEARCH — query se matching medicines
  /// Backend: FDA API call (openFDA)
  ///
  /// Smart matching: naam se start ho YA naam mein kahin ho
  /// ============================================================
  static List<MedSearchResult> search(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) return [];

    return _database
        .where((med) => med.name.toLowerCase().contains(q))
        .toList();
  }

  /// Badge text — "Common for: X" ya "Daily Dose"
  static String badgeFor(MedSearchResult med) {
    return med.isDailyDose ? 'Daily Dose' : 'Common for: ${med.commonFor}';
  }
}
