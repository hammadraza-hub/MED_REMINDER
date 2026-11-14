/// ============================================================
/// DOCTOR NOTE VALIDATOR — M16 step 1
/// ============================================================
enum DoctorNoteError { bodyMissing, bodyTooLong }

class DoctorNoteLimits {
  DoctorNoteLimits._();

  /// Keep in sync with firestore.rules.
  static const int bodyMax = 500;
}

class DoctorNoteValidator {
  DoctorNoteValidator._();

  static Set<DoctorNoteError> validate(String body) {
    final b = body.trim();
    if (b.isEmpty) return {DoctorNoteError.bodyMissing};
    if (b.length > DoctorNoteLimits.bodyMax) {
      return {DoctorNoteError.bodyTooLong};
    }
    return {};
  }
}
