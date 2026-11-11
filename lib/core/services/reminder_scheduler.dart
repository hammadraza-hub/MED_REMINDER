import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../profile/profile_controller.dart';
import '../../models/dose.dart';
import '../../repositories/dose_repository.dart';

/// ============================================================
/// REMINDER SCHEDULER — M8, Spark-plan half
/// ============================================================
///
/// Schedules a local notification for every pending dose in the
/// next 48 hours. Runs entirely on the phone (no Cloud Functions),
/// so it works on the Firebase Spark plan.
///
/// Server push (caregiver / refill / appointment alerts) is a
/// separate concern and plugs in later via PushService; nothing in
/// this class changes when Blaze is enabled.
///
/// shortcut: only future pending doses are (re)scheduled here.
/// Overdue-but-not-yet-missed doses need the reschedule hooks from
/// M8 step 4.
class ReminderScheduler {
  ReminderScheduler._();

  static final ReminderScheduler instance = ReminderScheduler._();

  static const String _channelId = 'dose_reminders';
  static const String _channelName = 'Dose reminders';
  static const String _channelDescription = 'Scheduled medication reminders';
  static const String _icon = 'ic_stat_medication';

  /// Rolling window (PDF M8 step 2: never schedule the whole course).
  static const Duration _window = Duration(hours: 48);

  /// Hard cap so a large family profile does not flood the OS.
  static const int _maxScheduled = 100;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _rescheduling;

  static final NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      icon: _icon,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      enableVibration: true,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  // ────────────────────────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────────────────────────

  /// Call once at startup, after Firebase and ProfileController.
  Future<void> init() async {
    if (_initialized) return;

    await _setupTimeZone();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        iOS: DarwinInitializationSettings(
          // Asked explicitly from the onboarding screen (M8 step 5).
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
    debugPrint('ReminderScheduler: ready (tz: ${tz.local.name})');
  }

  Future<void> _setupTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Keeps UTC; reminders still fire, just at the wrong wall-clock time.
      debugPrint('ReminderScheduler: timezone fallback to ${tz.local.name} ($e)');
    }
  }

  // ────────────────────────────────────────────────────────────
  // PERMISSIONS (UI calls this from onboarding — M8 step 5)
  // ────────────────────────────────────────────────────────────

  /// Returns false only when notifications were explicitly denied.
  Future<bool> requestPermissions() async {
    final android = _android;
    if (android == null) return true;

    final allowed = await android.requestNotificationsPermission() ?? true;
    if (allowed) {
      await android.requestExactAlarmsPermission();
    }
    return allowed;
  }

  // ────────────────────────────────────────────────────────────
  // SCHEDULING
  // ────────────────────────────────────────────────────────────

  /// Cancels every pending reminder and schedules the next 48 h again.
  /// Idempotent: concurrent calls share the same run.
  Future<void> rescheduleAll() {
    final running = _rescheduling;
    if (running != null) return running;

    final future = _runReschedule();
    _rescheduling = future;
    return future;
  }

  Future<void> _runReschedule() async {
    try {
      await _reschedule();
    } catch (e) {
      debugPrint('ReminderScheduler: reschedule failed: $e');
    } finally {
      _rescheduling = null;
    }
  }

  Future<void> _reschedule() async {
    if (!_initialized) await init();

    final profileId = ProfileController.instance.memberId;
    if (profileId == null || profileId.isEmpty) {
      debugPrint('ReminderScheduler: no profile selected — skipping');
      return;
    }

    final now = DateTime.now();
    // Query is day-granular, so this returns today 00:00 → day after tomorrow.
    final doses = await DoseRepository.instance.getDosesForDateRange(
      profileId,
      now,
      now.add(const Duration(days: 1)),
    );

    final upcoming = doses
        .where(
          (dose) =>
              dose.status == DoseStatus.pending &&
              dose.scheduledAt.isAfter(now) &&
              dose.scheduledAt.isBefore(now.add(_window)),
        )
        .take(_maxScheduled)
        .toList();

    // Simple + idempotent; also clears notifications left from a previous run.
    await _plugin.cancelAll();

    final mode = await _scheduleMode();
    for (final dose in upcoming) {
      await _plugin.zonedSchedule(
        id: _idFor(dose.id),
        title: dose.medName,
        body: dose.doseLabel ?? 'Time to take your medication',
        scheduledDate: tz.TZDateTime.from(dose.scheduledAt.toLocal(), tz.local),
        notificationDetails: _details,
        androidScheduleMode: mode,
        payload: dose.id,
      );
    }

    debugPrint(
      'ReminderScheduler: scheduled ${upcoming.length} reminder(s) '
      'for $profileId (${mode.name})',
    );
  }

  /// Exact alarms need a user grant on Android 14+; fall back to inexact.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _android;
    if (android == null) return AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      final exact = await android.canScheduleExactNotifications() ?? false;
      return exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Cancels the reminder for one dose (used by M8 step 3 after logging).
  Future<void> cancelForDose(String doseId) => _plugin.cancel(id: _idFor(doseId));

  /// Stable across app restarts (unlike String.hashCode).
  static int _idFor(String doseId) {
    var hash = 7;
    for (final unit in doseId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }

  // ────────────────────────────────────────────────────────────
  // HANDLERS
  // ────────────────────────────────────────────────────────────

  void _onNotificationResponse(NotificationResponse response) {
    // M8 step 3: open the right dose / handle action buttons.
    debugPrint(
      'ReminderScheduler: notification tapped '
      '(action: ${response.actionId}, payload: ${response.payload})',
    );
  }

  // ────────────────────────────────────────────────────────────
  // DEBUG HELPERS
  // ────────────────────────────────────────────────────────────

  /// Proof that local notifications work. Run with:
  ///   flutter run --dart-define=NOTIF_TEST=true
  Future<void> scheduleTestNotification({int seconds = 10}) async {
    if (!_initialized) await init();
    final mode = await _scheduleMode();
    await _plugin.zonedSchedule(
      id: _idFor('__test__'),
      title: 'MedRemind test reminder',
      body: 'Local notifications are working',
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      notificationDetails: _details,
      androidScheduleMode: mode,
      payload: 'test',
    );
    debugPrint(
      'ReminderScheduler: test notification scheduled in ${seconds}s '
      '(${mode.name})',
    );
  }

  Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;
}

/// Runs in a background isolate when a notification action is tapped.
/// Top-level + vm:entry-point is required by flutter_local_notifications.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // M8 step 3: Taken / Skip / Snooze handling.
  debugPrint(
    'ReminderScheduler: background action ${response.actionId} '
    '(payload: ${response.payload})',
  );
}
