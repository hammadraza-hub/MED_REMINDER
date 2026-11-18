import '../../models/dose.dart';

/// One local alarm the scheduler must set.
class PlannedAlarm {
  const PlannedAlarm({
    required this.dose,
    required this.index,
    required this.at,
  });

  final Dose dose;

  /// 0 = the reminder itself, 1..n = escalation repeats.
  final int index;
  final DateTime at;

  /// Stable key; the scheduler turns it into a notification id.
  String get key => index == 0 ? dose.id : '${dose.id}#$index';
}

/// Decides WHICH alarms to set (M8 step 2/3, M22 step 3). Pure: no plugin, no
/// Firestore, no clock of its own, so every rule is unit-tested.
///
/// Rules (PDF M8):
///  * only pending doses, alert at `snoozedUntil ?? scheduledAt`;
///  * rolling 48 h window, never the whole course;
///  * main alarm + up to [escalationCount] repeats every N minutes, cancelled
///    once the dose is logged and never later than the miss deadline;
///  * the OS limits pending alarms (iOS 64): nearest doses first, whole doses
///    only, so the next reminders are never the ones that get dropped;
///  * the "dose reminders" switch off = no dose alarms at all;
///  * quiet hours NEVER delay the person's own dose reminders.
class DoseAlarmPlanner {
  DoseAlarmPlanner._();

  static const Duration window = Duration(hours: 48);
  static const int escalationCount = 3;

  /// Pending local notifications the OS keeps per app.
  static const int iosAlarmCap = 64;
  static const int androidAlarmCap = 200;

  static List<PlannedAlarm> plan({
    required Iterable<Dose> doses,
    required DateTime now,
    required int escalationMinutes,
    required bool doseEnabled,
    required int maxAlarms,
  }) {
    if (!doseEnabled || maxAlarms <= 0) return const [];
    final until = now.add(window);

    final upcoming = <(DateTime, Dose)>[];
    for (final dose in doses) {
      if (dose.status != DoseStatus.pending) continue;
      final alertAt = dose.snoozedUntil ?? dose.scheduledAt;
      if (alertAt.isAfter(now) && alertAt.isBefore(until)) {
        upcoming.add((alertAt, dose));
      }
    }
    upcoming.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.id.compareTo(b.$2.id);
    });

    final result = <PlannedAlarm>[];
    for (final (first, dose) in upcoming) {
      final alarms = <PlannedAlarm>[
        PlannedAlarm(dose: dose, index: 0, at: first),
      ];
      if (escalationMinutes > 0) {
        for (var i = 1; i <= escalationCount; i++) {
          final at = first.add(Duration(minutes: escalationMinutes * i));
          if (!at.isBefore(dose.missDeadline)) break;
          alarms.add(PlannedAlarm(dose: dose, index: i, at: at));
        }
      }
      if (result.length + alarms.length > maxAlarms) break;
      result.addAll(alarms);
    }
    return result;
  }
}
