/// ============================================================
/// APPOINTMENT VALIDATOR — M16 step 1
///
/// Pure checks for an appointment. Limits are mirrored in the Firestore rules
/// (step 2). Returns error CODES so the UI can localise.
/// ============================================================
enum AppointmentType {
  followUp('follow_up'),
  checkup('checkup'),
  labReview('lab_review'),
  other('other');

  const AppointmentType(this.code);

  /// Value stored in Firestore.
  final String code;

  static AppointmentType? fromCode(String? code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

enum AppointmentError {
  startsAtMissing,
  startsAtInPast,
  locationTooLong,
  notesTooLong,
  offsetsTooMany,
  offsetInvalid,
  offsetDuplicate,
}

class AppointmentLimits {
  AppointmentLimits._();

  /// Keep in sync with firestore.rules.
  static const int locationMax = 200;
  static const int notesMax = 500;
  static const int maxOffsets = 5;

  /// 30 days, in minutes.
  static const int maxOffsetMinutes = 30 * 24 * 60;

  /// Reminder 1 day and 2 hours before.
  static const List<int> defaultOffsets = [1440, 120];
}

class AppointmentValidator {
  AppointmentValidator._();

  /// [requireFuture] is true when creating; editing an old appointment may
  /// keep its past time.
  static Set<AppointmentError> validate({
    required DateTime? startsAt,
    String? location,
    String? notes,
    List<int> reminderOffsets = AppointmentLimits.defaultOffsets,
    bool requireFuture = false,
    DateTime? now,
  }) {
    final errors = <AppointmentError>{};

    if (startsAt == null) {
      errors.add(AppointmentError.startsAtMissing);
    } else if (requireFuture && !startsAt.isAfter(now ?? DateTime.now())) {
      errors.add(AppointmentError.startsAtInPast);
    }

    if ((location ?? '').trim().length > AppointmentLimits.locationMax) {
      errors.add(AppointmentError.locationTooLong);
    }
    if ((notes ?? '').trim().length > AppointmentLimits.notesMax) {
      errors.add(AppointmentError.notesTooLong);
    }

    errors.addAll(validateOffsets(reminderOffsets));
    return errors;
  }

  static Set<AppointmentError> validateOffsets(List<int> offsets) {
    final errors = <AppointmentError>{};
    if (offsets.length > AppointmentLimits.maxOffsets) {
      errors.add(AppointmentError.offsetsTooMany);
    }
    if (offsets.toSet().length != offsets.length) {
      errors.add(AppointmentError.offsetDuplicate);
    }
    for (final o in offsets) {
      if (o <= 0 || o > AppointmentLimits.maxOffsetMinutes) {
        errors.add(AppointmentError.offsetInvalid);
      }
    }
    return errors;
  }
}
