import 'dart:async';
import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../profile/profile_controller.dart';
import '../../models/dose.dart';
import '../../repositories/dose_repository.dart';
import 'reminder_action_queue.dart';

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
/// Refreshes on app start/resume, after any dose or medication change, and
/// when the selected profile changes. Overdue doses are marked missed first.
class ReminderScheduler with WidgetsBindingObserver {
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

  /// Escalation repeats (PDF M8: default 10 min, from settings).
  /// shortcut: fixed values until M8 step 5 reads users/{uid}.settings.
  static const int _escalationCount = 3;
  static const int _escalationMinutes = 10;

  static const List<AndroidNotificationAction> _actions = [
    AndroidNotificationAction('taken', 'Taken'),
    AndroidNotificationAction('skipped', 'Skip'),
    AndroidNotificationAction('snooze', 'Snooze'),
  ];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _rescheduling;
  String? _lastProfileId;

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
      actions: _actions,
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
    WidgetsBinding.instance.addObserver(this);
    _lastProfileId = ProfileController.instance.memberId;
    ProfileController.instance.addListener(_onProfileChanged);
    debugPrint('ReminderScheduler: ready (tz: ${tz.local.name})');
  }

  /// Reminders must follow the selected member (caregiver switching profiles).
  void _onProfileChanged() {
    final profileId = ProfileController.instance.memberId;
    if (profileId == _lastProfileId) return;
    _lastProfileId = profileId;
    unawaited(rescheduleAll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Actions tapped while the app was away take effect now.
    unawaited(_applyQueuedActions());
  }

  Future<void> _applyQueuedActions() async {
    await ReminderActionQueue.instance.replay();
    await rescheduleAll();
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

    // Close out overdue doses first (Spark has no scheduled functions).
    try {
      final missed = await DoseRepository.instance.markOverdueDosesMissed(
        profileId,
      );
      if (missed > 0) {
        debugPrint('ReminderScheduler: $missed overdue dose(s) marked missed');
      }
    } catch (e) {
      debugPrint('ReminderScheduler: overdue sweep failed: $e');
    }

    final now = DateTime.now();
    // Query is day-granular, so this returns today 00:00 → day after tomorrow.
    final doses = await DoseRepository.instance.getDosesForDateRange(
      profileId,
      now,
      now.add(const Duration(days: 1)),
    );

    final upcoming = doses
        .where((dose) {
          if (dose.status != DoseStatus.pending) return false;
          final alertAt = dose.snoozedUntil ?? dose.scheduledAt;
          return alertAt.isAfter(now) && alertAt.isBefore(now.add(_window));
        })
        .take(_maxScheduled)
        .toList();

    // Simple + idempotent; also clears notifications left from a previous run.
    await _plugin.cancelAll();

    final mode = await _scheduleMode();
    var alarms = 0;
    for (final dose in upcoming) {
      alarms += await _scheduleDose(dose, mode);
    }

    debugPrint(
      'ReminderScheduler: ${upcoming.length} dose(s), $alarms alarm(s) '
      'for $profileId (${mode.name})',
    );
  }

  /// Schedules the reminder plus escalation repeats for one dose.
  /// Returns how many alarms were set.
  Future<int> _scheduleDose(Dose dose, AndroidScheduleMode mode) async {
    final first = dose.snoozedUntil ?? dose.scheduledAt;
    final payload = jsonEncode({
      'doseId': dose.id,
      'profileId': dose.profileId,
    });

    var count = await _schedule(
      id: _idFor(dose.id),
      at: first,
      dose: dose,
      payload: payload,
      mode: mode,
    );

    for (var i = 1; i <= _escalationCount; i++) {
      final at = first.add(Duration(minutes: _escalationMinutes * i));
      if (!at.isBefore(dose.missDeadline)) break; // never nag past the deadline
      count += await _schedule(
        id: _idFor('${dose.id}#$i'),
        at: at,
        dose: dose,
        payload: payload,
        mode: mode,
      );
    }
    return count;
  }

  Future<int> _schedule({
    required int id,
    required DateTime at,
    required Dose dose,
    required String payload,
    required AndroidScheduleMode mode,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: dose.medName,
      body: dose.doseLabel ?? 'Time to take your medication',
      scheduledDate: tz.TZDateTime.from(at.toLocal(), tz.local),
      notificationDetails: _details,
      androidScheduleMode: mode,
      payload: payload,
    );
    return 1;
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

  /// Cancels every alert for one dose (the reminder + its escalations).
  Future<void> cancelForDose(String doseId) async {
    await _plugin.cancel(id: _idFor(doseId));
    for (var i = 1; i <= _escalationCount; i++) {
      await _plugin.cancel(id: _idFor('$doseId#$i'));
    }
  }

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
    final action = response.actionId;
    if (action != null) {
      // Actions normally land in the background isolate; this covers the
      // case where the app is already in the foreground.
      unawaited(_handleAction(action, response.payload));
      return;
    }
    // Body tap just opens the app; queued actions replay on resume.
    debugPrint('ReminderScheduler: notification opened (${response.payload})');
  }

  Future<void> _handleAction(String action, String? payload) async {
    final target = _parsePayload(payload);
    if (target == null) return;

    await ReminderActionQueue.instance.enqueue(
      doseId: target.doseId,
      profileId: target.profileId,
      action: action,
      snoozeMinutes: action == 'snooze'
          ? ReminderActionQueue.snoozeMinutes
          : null,
    );
    await cancelForDose(target.doseId);
    await _applyQueuedActions();
  }

  /// Notification payload: {doseId, profileId}. The background isolate has
  /// no ProfileController, so the profile travels with the notification.
  static ({String doseId, String profileId})? _parsePayload(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        doseId: map['doseId'] as String,
        profileId: map['profileId'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────
  // DEBUG HELPERS
  // ────────────────────────────────────────────────────────────

  /// Proof that notifications + action buttons work. Run with:
  ///   flutter run --dart-define=NOTIF_TEST=true
  Future<void> scheduleTestNotification({int seconds = 10}) async {
    if (!_initialized) await init();
    final now = DateTime.now();
    final fake = Dose(
      id: '__test__',
      profileId: 'test',
      medicationId: 'test',
      medName: 'MedRemind test reminder',
      doseLabel: '1 tablet',
      scheduledAt: now.add(Duration(seconds: seconds)),
      missDeadline: now.add(const Duration(minutes: 30)),
      createdAt: now,
    );
    final mode = await _scheduleMode();
    final alarms = await _scheduleDose(fake, mode);
    debugPrint(
      'ReminderScheduler: $alarms test alarm(s) from +${seconds}s '
      '(${mode.name})',
    );
  }

  Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;
}

/// Runs in a background isolate when a notification action is tapped.
/// Top-level + vm:entry-point is required by flutter_local_notifications.
///
/// No Firestore here: auth/profile state is unreliable in this isolate, so
/// the tap is queued and replayed when the app next opens or resumes.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();

  final action = response.actionId;
  final target = ReminderScheduler._parsePayload(response.payload);
  if (action == null || target == null) return;

  await ReminderActionQueue.instance.enqueue(
    doseId: target.doseId,
    profileId: target.profileId,
    action: action,
    snoozeMinutes: action == 'snooze'
        ? ReminderActionQueue.snoozeMinutes
        : null,
  );

  try {
    await ReminderScheduler.instance.cancelForDose(target.doseId);
  } catch (e) {
    // Cancelling is a nicety; the queued action is what matters.
    debugPrint('ReminderScheduler: background cancel failed: $e');
  }
}
