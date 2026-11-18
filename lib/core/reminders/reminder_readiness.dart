/// What the phone must allow so a dose reminder rings on time (Android 12-16,
/// iOS). Pure model: the platform part is `ReminderPermissionService`.
enum ReminderStep {
  /// Show notifications at all (Android 13+ runtime permission, iOS prompt).
  notifications,

  /// "Alarms & reminders" (Android 12+; off by default from Android 14):
  /// without it alarms are inexact and can be minutes late.
  exactAlarms,

  /// Not restricted by battery saving / Doze.
  battery,

  /// The vendor's own "autostart / background" page (Xiaomi, Oppo, Vivo,
  /// Huawei, Samsung...). It cannot be read back, so it is shown once as a tip.
  autostart,
}

class ReminderReadiness {
  const ReminderReadiness({
    required this.notifications,
    required this.exactAlarms,
    required this.batteryUnrestricted,
    this.manufacturer = '',
    this.autostartShown = false,
  });

  final bool notifications;
  final bool exactAlarms;
  final bool batteryUnrestricted;

  /// Lower case, e.g. "xiaomi", "samsung", "google".
  final String manufacturer;

  /// The autostart tip was already shown on this phone.
  final bool autostartShown;

  /// Makers whose battery managers kill background alarms.
  static const Set<String> aggressiveMakers = {
    'xiaomi',
    'redmi',
    'poco',
    'oppo',
    'realme',
    'oneplus',
    'vivo',
    'iqoo',
    'huawei',
    'honor',
    'samsung',
    'asus',
    'tecno',
    'infinix',
    'itel',
    'transsion',
  };

  bool get needsAutostartTip =>
      !autostartShown && aggressiveMakers.contains(manufacturer);

  /// Steps still to do, most important first.
  List<ReminderStep> get missing => [
    if (!notifications) ReminderStep.notifications,
    if (!exactAlarms) ReminderStep.exactAlarms,
    if (!batteryUnrestricted) ReminderStep.battery,
    if (needsAutostartTip) ReminderStep.autostart,
  ];

  /// Everything that CAN be checked is fine (the autostart tip does not count:
  /// it is advice, not a state).
  bool get allGood => notifications && exactAlarms && batteryUnrestricted;

  /// Reminders will not ring at all.
  bool get blocked => !notifications;

  /// Reminders may ring late or not at all.
  bool get atRisk => !allGood;

  ReminderStep? get next => missing.isEmpty ? null : missing.first;
}
