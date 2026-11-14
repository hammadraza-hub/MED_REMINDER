import 'appointment_models.dart';

/// One reminder to schedule on the device.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.notificationId,
    required this.offsetMinutes,
    required this.fireAt,
  });

  /// `appointmentId_offset` — stable, so an edit can cancel and recreate.
  final String id;

  /// 31-bit int derived from [id] for the local notification plugin.
  final int notificationId;
  final int offsetMinutes;
  final DateTime fireAt;
}

/// ============================================================
/// REMINDER PLANNER — M16 step 1
///
/// Works out when reminders fire. Spark has no Cloud Tasks, so the phone
/// schedules them locally; ids are stable so an edit can cancel the old ones.
/// ============================================================
class ReminderPlanner {
  ReminderPlanner._();

  static String reminderId(String appointmentId, int offsetMinutes) =>
      '${appointmentId}_$offsetMinutes';

  /// Stable positive 31-bit id (FNV-1a) for local notifications.
  static int notificationIdFor(String reminderId) {
    var h = 0x811c9dc5;
    for (final c in reminderId.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }

  /// Every reminder of the appointment, including ones already in the past,
  /// earliest first. Use this to cancel before re-scheduling.
  static List<PlannedReminder> all(Appointment a) {
    final list = [
      for (final o in Appointment.normalizeOffsets(a.reminderOffsets))
        PlannedReminder(
          id: reminderId(a.id, o),
          notificationId: notificationIdFor(reminderId(a.id, o)),
          offsetMinutes: o,
          fireAt: a.startsAt.subtract(Duration(minutes: o)),
        ),
    ];
    list.sort((x, y) => x.fireAt.compareTo(y.fireAt));
    return list;
  }

  /// Only reminders that still lie in the future.
  static List<PlannedReminder> upcoming(Appointment a, {DateTime? now}) {
    final t = now ?? DateTime.now();
    return all(a).where((r) => r.fireAt.isAfter(t)).toList();
  }
}
