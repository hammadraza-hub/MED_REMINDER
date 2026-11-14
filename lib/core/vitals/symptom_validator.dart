/// ============================================================
/// SYMPTOM VALIDATOR — M15 step 1
///
/// Pure checks for `profiles/{pid}/symptoms/{id}`: symptom name, severity 1-5,
/// optional notes. Limits are repeated in firestore.rules (step 2).
/// ============================================================
enum SymptomError {
  nameEmpty,
  nameTooLong,
  severityOutOfRange,
  notesTooLong,
  timeInFuture,
}

class SymptomValidation {
  const SymptomValidation.ok() : error = null;
  const SymptomValidation.error(this.error);

  final SymptomError? error;

  bool get isValid => error == null;
}

class SymptomValidator {
  SymptomValidator._();

  static const int maxNameLength = 100;
  static const int maxNotesLength = 500;
  static const int minSeverity = 1;
  static const int maxSeverity = 5;
  static const Duration futureTolerance = Duration(minutes: 10);

  static SymptomValidation validate({
    required String name,
    required int severity,
    String? notes,
    DateTime? occurredAt,
    DateTime? now,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const SymptomValidation.error(SymptomError.nameEmpty);
    }
    if (trimmed.length > maxNameLength) {
      return const SymptomValidation.error(SymptomError.nameTooLong);
    }
    if (severity < minSeverity || severity > maxSeverity) {
      return const SymptomValidation.error(SymptomError.severityOutOfRange);
    }
    if (notes != null && notes.trim().length > maxNotesLength) {
      return const SymptomValidation.error(SymptomError.notesTooLong);
    }
    if (occurredAt != null) {
      final limit = (now ?? DateTime.now()).add(futureTolerance);
      if (occurredAt.isAfter(limit)) {
        return const SymptomValidation.error(SymptomError.timeInFuture);
      }
    }
    return const SymptomValidation.ok();
  }
}
