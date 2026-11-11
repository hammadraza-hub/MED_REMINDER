/// Notification / reminder preferences stored on `users/{uid}.settings`.
///
/// M8 (step 5): kept here so the client works on Spark today; the same
/// document is read by the server-side `sendPush` helper when Blaze is added
/// later — no client change needed then.
///
/// Fields mirror `NotificationsData` defaults so the settings screen can load
/// and save without a round-trip to the backend.
class NotificationSettings {
  /// Dose reminders (Taken / Skip / Snooze) fire at each dose time.
  final bool doseEnabled;

  /// Refill alerts when supply runs low.
  final bool refillEnabled;

  /// Caregiver alerts when a dose is missed (server push, Blaze only).
  final bool caregiverEnabled;

  /// Re-remind interval in minutes (one of [5, 10, 15, 30]).
  final int escalationMinutes;

  /// Quiet hours delay refill/appointment pushes; never blocks dose reminders.
  final bool quietHoursEnabled;

    /// Quiet-hours start (local hour, 0-23).
  final int quietStartHour;

    /// Quiet-hours start minute.
  final int quietStartMinute;

    /// Quiet-hours end (local hour, 0-23).
  final int quietEndHour;

    /// Quiet-hours end minute.
  final int quietEndMinute;

    /// Hide medicine names on the lock screen / notification preview.
  final bool hideMedicineNamesOnLockScreen;

  const NotificationSettings({
    required this.doseEnabled,
    required this.refillEnabled,
    required this.caregiverEnabled,
    required this.escalationMinutes,
    required this.quietHoursEnabled,
    required this.quietStartHour,
    required this.quietStartMinute,
    required this.quietEndHour,
    required this.quietEndMinute,
    required this.hideMedicineNamesOnLockScreen,
  });

  /// Sensible defaults matching `NotificationsData` (used until user saves).
  static const NotificationSettings defaults = NotificationSettings(
    doseEnabled: true,
    refillEnabled: true,
    caregiverEnabled: true,
    escalationMinutes: 10,
    quietHoursEnabled: false,
    quietStartHour: 22,
    quietStartMinute: 0,
    quietEndHour: 7,
    quietEndMinute: 0,
    hideMedicineNamesOnLockScreen: false,
  );

  /// Read from `users/{uid}.settings` map (Firestore `map` field).
  factory NotificationSettings.fromMap(Map<String, dynamic> m) {
    return NotificationSettings(
      doseEnabled: _bool(m['doseEnabled'], true),
      refillEnabled: _bool(m['refillEnabled'], true),
      caregiverEnabled: _bool(m['caregiverEnabled'], true),
      escalationMinutes: _int(m['escalationMinutes'], 10),
      quietHoursEnabled: _bool(m['quietHoursEnabled'], false),
      quietStartHour: _int(m['quietStartHour'], 22),
      quietStartMinute: _int(m['quietStartMinute'], 0),
      quietEndHour: _int(m['quietEndHour'], 7),
      quietEndMinute: _int(m['quietEndMinute'], 0),
      hideMedicineNamesOnLockScreen: _bool(m['hideMedicineNamesOnLockScreen'], false),
    );
  }

  /// Write to `users/{uid}.settings` map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'doseEnabled': doseEnabled,
      'refillEnabled': refillEnabled,
      'caregiverEnabled': caregiverEnabled,
      'escalationMinutes': escalationMinutes,
      'quietHoursEnabled': quietHoursEnabled,
      'quietStartHour': quietStartHour,
      'quietStartMinute': quietStartMinute,
      'quietEndHour': quietEndHour,
      'quietEndMinute': quietEndMinute,
      'hideMedicineNamesOnLockScreen': hideMedicineNamesOnLockScreen,
    };
  }

  NotificationSettings copyWith({
    bool? doseEnabled,
    bool? refillEnabled,
    bool? caregiverEnabled,
    int? escalationMinutes,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietStartMinute,
    int? quietEndHour,
    int? quietEndMinute,
    bool? hideMedicineNamesOnLockScreen,
  }) {
    return NotificationSettings(
      doseEnabled: doseEnabled ?? this.doseEnabled,
      refillEnabled: refillEnabled ?? this.refillEnabled,
      caregiverEnabled: caregiverEnabled ?? this.caregiverEnabled,
      escalationMinutes: escalationMinutes ?? this.escalationMinutes,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietStartMinute: quietStartMinute ?? this.quietStartMinute,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      quietEndMinute: quietEndMinute ?? this.quietEndMinute,
      hideMedicineNamesOnLockScreen:
          hideMedicineNamesOnLockScreen ?? this.hideMedicineNamesOnLockScreen,
    );
  }

  @override
  String toString() => 'NotificationSettings(${toMap()})';

  static bool _bool(dynamic v, bool d) => v is bool ? v : d;
  static int _int(dynamic v, int d) => v is int ? v : (v is num ? v.toInt() : d);
}
