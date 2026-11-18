import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reminders/reminder_readiness.dart';
import 'reminder_scheduler.dart';

/// Checks and asks for everything a reminder needs, from INSIDE the app.
///
/// An app cannot switch a permission on by itself (Android and iOS forbid it):
/// what it can do is show the system's own prompt or open the exact settings
/// page, one tap away, with an explanation first. This class does that for
/// notifications, exact alarms, battery saving and the vendor autostart page.
class ReminderPermissionService {
  ReminderPermissionService._();

  static final ReminderPermissionService instance =
      ReminderPermissionService._();

  static const MethodChannel _channel = MethodChannel(
    'medremind/reminder_permissions',
  );
  static const String _autostartKey = 'reminder_autostart_tip_shown_v1';

  Future<T?> _call<T>(String method) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException catch (e) {
      debugPrint('ReminderPermissionService: $method failed (${e.code})');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<ReminderReadiness> check() async {
    final scheduler = ReminderScheduler.instance;
    final notifications = await scheduler.notificationsAllowed();
    final exact = await scheduler.exactAlarmsAllowed();
    final battery =
        !Platform.isAndroid ||
        (await _call<bool>('isIgnoringBatteryOptimizations') ?? true);
    final maker = await _call<String>('manufacturer') ?? '';

    var shown = false;
    try {
      shown =
          (await SharedPreferences.getInstance()).getBool(_autostartKey) ??
          false;
    } catch (_) {}

    return ReminderReadiness(
      notifications: notifications,
      exactAlarms: exact,
      batteryUnrestricted: battery,
      manufacturer: maker,
      autostartShown: shown,
    );
  }

  /// Runs the system prompt / settings page of one step. The person comes back
  /// to the app afterwards, so call [check] again then.
  Future<void> run(ReminderStep step) async {
    switch (step) {
      case ReminderStep.notifications:
        final granted = await ReminderScheduler.instance
            .requestNotificationsOnly();
        // Denied twice (or "don't ask again"): the system shows no prompt any
        // more, so open the app's settings page instead.
        if (!granted) await _call<bool>('openAppSettings');
      case ReminderStep.exactAlarms:
        await ReminderScheduler.instance.requestExactAlarms();
      case ReminderStep.battery:
        await _call<bool>('requestIgnoreBatteryOptimizations');
      case ReminderStep.autostart:
        await markAutostartShown();
        final opened = await _call<bool>('openAutostartSettings') ?? false;
        if (!opened) await _call<bool>('openAppSettings');
    }
  }

  Future<void> markAutostartShown() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(
        _autostartKey,
        true,
      );
    } catch (_) {}
  }

  /// Reminders are only as good as the schedule: after a permission was given,
  /// set the alarms again straight away.
  Future<void> afterChange() => ReminderScheduler.instance.rescheduleAll();
}
