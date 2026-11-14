import 'dart:convert';

import 'appointment_models.dart';
import 'reminder_planner.dart';

/// Reminder options offered on the Add / Edit Appointment screen
/// (minutes before the appointment). M16 step 5.
class ReminderOffsetOptions {
  ReminderOffsetOptions._();

  /// 1 week, 1 day, 2 hours, 1 hour, 30 minutes.
  static const List<int> standard = [10080, 1440, 120, 60, 30];

  /// The standard options plus any other offsets an existing appointment
  /// already has, largest first, so nothing it had is silently lost.
  static List<int> withExtras(Iterable<int> current) =>
      {...standard, ...current}.toList()..sort((a, b) => b.compareTo(a));
}

/// One notification waiting on the phone.
class PendingReminder {
  const PendingReminder({required this.id, this.payload});

  final int id;
  final String? payload;
}

/// What the service needs from the phone's notification system.
abstract class AppointmentNotificationBackend {
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  });

  Future<void> cancel(int id);

  Future<List<PendingReminder>> pending();
}

/// An appointment together with the texts of its notification.
class AppointmentReminderPlan {
  const AppointmentReminderPlan({
    required this.appointment,
    required this.title,
    required this.body,
  });

  final Appointment appointment;
  final String title;
  final String body;
}

class AppointmentSyncResult {
  const AppointmentSyncResult({
    required this.scheduled,
    required this.cancelled,
  });

  final int scheduled;
  final int cancelled;
}

/// ============================================================
/// APPOINTMENT REMINDER SERVICE — M16 step 5
///
/// Spark has no Cloud Tasks, so the phone schedules the reminders itself.
/// Ids come from [ReminderPlanner] (appointment id + offset), so an edit
/// cancels the old reminders and schedules the new ones. No Flutter imports:
/// the notification system is injected, so this is unit-testable.
/// ============================================================
class AppointmentReminderService {
  AppointmentReminderService(this._backend);

  final AppointmentNotificationBackend _backend;

  /// Marks a pending notification as an appointment reminder, so the dose
  /// scheduler (which clears and rebuilds dose alerts) leaves it alone.
  static const String payloadKind = 'appointment';

  static String payloadFor(String profileId, String appointmentId) =>
      jsonEncode({
        'kind': payloadKind,
        'profileId': profileId,
        'appointmentId': appointmentId,
      });

  static bool isAppointmentPayload(String? payload) {
    if (payload == null || payload.isEmpty) return false;
    try {
      final data = jsonDecode(payload);
      return data is Map && data['kind'] == payloadKind;
    } catch (_) {
      return false;
    }
  }

  /// Replaces the reminders of one appointment (edit-safe). Returns how many
  /// were scheduled; reminders already in the past are skipped.
  Future<int> schedule(
    Appointment appointment, {
    required String profileId,
    required String title,
    required String body,
    DateTime? now,
  }) async {
    await cancel(appointment);

    final payload = payloadFor(profileId, appointment.id);
    var count = 0;
    for (final r in ReminderPlanner.upcoming(appointment, now: now)) {
      await _backend.schedule(
        id: r.notificationId,
        title: title,
        body: body,
        at: r.fireAt,
        payload: payload,
      );
      count++;
    }
    return count;
  }

  /// Cancels the reminders of the appointment that are still waiting to fire:
  /// the ones its current offsets give, and any left from earlier offsets (an
  /// edit that removed an offset must not leave that reminder behind).
  ///
  /// A reminder that has already been delivered is left alone, so syncing
  /// does not wipe it from the notification shade. Pass [includeDelivered]
  /// when the appointment itself is deleted.
  Future<void> cancel(
    Appointment appointment, {
    bool includeDelivered = false,
  }) async {
    if (includeDelivered) {
      for (final r in ReminderPlanner.all(appointment)) {
        await _backend.cancel(r.notificationId);
      }
    }
    final planned = {
      for (final r in ReminderPlanner.all(appointment)) r.notificationId,
    };
    for (final p in await _backend.pending()) {
      if (planned.contains(p.id) ||
          _appointmentIdOf(p.payload) == appointment.id) {
        await _backend.cancel(p.id);
      }
    }
  }

  static String? _appointmentIdOf(String? payload) {
    if (!isAppointmentPayload(payload)) return null;
    final data = jsonDecode(payload!) as Map;
    final id = data['appointmentId'];
    return id is String ? id : null;
  }

  /// Makes the phone match [plans] exactly: stale appointment reminders
  /// (deleted or edited elsewhere) are removed, the rest are (re)scheduled.
  /// Dose reminders are never touched.
  Future<AppointmentSyncResult> sync({
    required String profileId,
    required List<AppointmentReminderPlan> plans,
    DateTime? now,
  }) async {
    final wanted = <int>{
      for (final p in plans)
        for (final r in ReminderPlanner.upcoming(p.appointment, now: now))
          r.notificationId,
    };

    var cancelled = 0;
    for (final p in await _backend.pending()) {
      if (isAppointmentPayload(p.payload) && !wanted.contains(p.id)) {
        await _backend.cancel(p.id);
        cancelled++;
      }
    }

    var scheduled = 0;
    for (final p in plans) {
      scheduled += await schedule(
        p.appointment,
        profileId: profileId,
        title: p.title,
        body: p.body,
        now: now,
      );
    }
    return AppointmentSyncResult(scheduled: scheduled, cancelled: cancelled);
  }
}
