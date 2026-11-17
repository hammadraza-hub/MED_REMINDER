import '../l10n/app_localizations.dart';

/// What a reminder may show on a locked phone. M21 step 4.
///
/// A notification is readable by anyone who holds the phone. By default the
/// app therefore says "Medication reminder" and does not name the medicine or
/// the doctor; the user can turn this off in Settings > Notifications. The
/// default is also what applies when the setting cannot be read (offline, first
/// start): the safe choice wins.
class NotificationPrivacy {
  NotificationPrivacy._();

  static final NotificationPrivacy instance = NotificationPrivacy._();

  /// True: no medicine or doctor names in notifications.
  bool hideNames = true;
}

/// The words of a dose reminder, with or without the medicine.
class ReminderText {
  const ReminderText._();

  static String title(
    AppLocalizations l10n, {
    required bool hide,
    required String medName,
  }) {
    final name = medName.trim();
    return hide || name.isEmpty ? l10n.reminderGenericTitle : name;
  }

  static String body(
    AppLocalizations l10n, {
    required bool hide,
    String? doseLabel,
  }) {
    final label = (doseLabel ?? '').trim();
    return hide || label.isEmpty ? l10n.reminderGenericBody : label;
  }
}
