/// ============================================================
/// PRESCRIBER VALIDATOR — M16 step 1
///
/// Pure shape checks for a doctor record. The same limits go into the
/// Firestore rules (step 2). Returns error CODES, never text, so the UI can
/// localise them.
/// ============================================================
enum PrescriberError {
  nameMissing,
  nameTooLong,
  specialtyTooLong,
  phoneInvalid,
  clinicTooLong,
  addressTooLong,
}

class PrescriberLimits {
  PrescriberLimits._();

  /// Keep in sync with firestore.rules.
  static const int nameMax = 80;
  static const int specialtyMax = 60;
  static const int clinicMax = 80;
  static const int addressMax = 200;
  static const int phoneMinDigits = 7;
  static const int phoneMaxDigits = 15;
}

class PrescriberValidator {
  PrescriberValidator._();

  static final RegExp _phoneChars = RegExp(r'^\+?[0-9 ()\-]+$');

  /// Empty set means valid. Optional fields may be null or blank.
  static Set<PrescriberError> validate({
    required String name,
    String? specialty,
    String? phone,
    String? clinic,
    String? address,
  }) {
    final errors = <PrescriberError>{};

    final n = name.trim();
    if (n.isEmpty) {
      errors.add(PrescriberError.nameMissing);
    } else if (n.length > PrescriberLimits.nameMax) {
      errors.add(PrescriberError.nameTooLong);
    }

    if ((specialty ?? '').trim().length > PrescriberLimits.specialtyMax) {
      errors.add(PrescriberError.specialtyTooLong);
    }
    if ((clinic ?? '').trim().length > PrescriberLimits.clinicMax) {
      errors.add(PrescriberError.clinicTooLong);
    }
    if ((address ?? '').trim().length > PrescriberLimits.addressMax) {
      errors.add(PrescriberError.addressTooLong);
    }
    if (!isPhoneValid(phone)) errors.add(PrescriberError.phoneInvalid);

    return errors;
  }

  /// Blank is fine (optional). Otherwise only digits, `+` (first), spaces,
  /// brackets and dashes, with 7-15 digits.
  static bool isPhoneValid(String? phone) {
    final p = (phone ?? '').trim();
    if (p.isEmpty) return true;
    if (!_phoneChars.hasMatch(p)) return false;
    final digits = p.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digits >= PrescriberLimits.phoneMinDigits &&
        digits <= PrescriberLimits.phoneMaxDigits;
  }
}
