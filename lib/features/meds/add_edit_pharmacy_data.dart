import 'inventory_data.dart';
import 'pharmacy_info_data.dart';

/// ============================================================
/// ADD / EDIT PHARMACY DATA
///
/// Add/Edit Pharmacy screen ke form/result models.
///
/// UI pharmacy ya medication-specific values hardcode nahi karti.
/// Edit mode existing PharmacyInfoData ko use karta hai.
/// Medication assignments InventoryData se resolve hoti hain.
///
/// TODO Backend:
/// Pharmacy document current authenticated user / selected family
/// member ke account ke under persist/update karna hai.
/// ============================================================

class AddEditPharmacyResult {
  const AddEditPharmacyResult({
    this.pharmacyId,
    required this.name,
    required this.phone,
    this.address,
    required this.linkedMedicationIds,
  });

  /// null → new pharmacy
  /// non-null → existing pharmacy update
  final String? pharmacyId;

  final String name;
  final String phone;
  final String? address;
  final List<String> linkedMedicationIds;

  bool get isEdit => pharmacyId != null;
}

class AddEditPharmacyData {
  AddEditPharmacyData._();

  /// Edit mode ke liye existing pharmacy.
  ///
  /// Abhi dummy provider se aa rahi hai.
  ///
  /// TODO Backend:
  /// pharmacyId ke through Firestore/repository se existing
  /// pharmacy document fetch karna hai.
  static PharmacyInfoData? pharmacyForEdit(String? pharmacyId) {
    if (pharmacyId == null) {
      return null;
    }

    final pharmacy = PharmacyInfoData.current();

    if (pharmacy.id == pharmacyId) {
      return pharmacy;
    }

    return null;
  }

  /// Current user's active inventory medications.
  ///
  /// TODO Backend:
  /// Current user / selected family member ke active medication
  /// documents + inventory records repository se load karne hain.
  static List<InventoryItem> medications() {
    return InventoryData.inventory();
  }

  static Set<String> initialSelectedMedicationIds(PharmacyInfoData? pharmacy) {
    if (pharmacy == null) {
      return <String>{};
    }

    return pharmacy.linkedMedicationIds.toSet();
  }

  static String unitScheduleLabel(InventoryItem item) {
    final days = item.estimatedDaysRemaining;

    if (days <= 0) {
      return 'Supply needs review';
    }

    if (item.isLowStock) {
      return 'Low stock · ~$days days remaining';
    }

    return 'Active medication · ~$days days supply';
  }

  static String normalizeOptionalText(String source) {
    return source.trim();
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter pharmacy name';
    }

    if (value.trim().length < 2) {
      return 'Enter a valid pharmacy name';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Enter phone number';
    }

    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 7) {
      return 'Enter a valid phone number';
    }

    return null;
  }
}
