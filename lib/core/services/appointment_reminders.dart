import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../../repositories/firebase_appointment_repository.dart';
import '../../repositories/firebase_prescriber_repository.dart';
import '../doctors/appointment_models.dart';
import '../doctors/appointment_reminder_service.dart';
import '../doctors/appointment_validator.dart';
import '../locale/locale_controller.dart';
import 'reminder_scheduler.dart';

/// Localised labels for appointment types and the notification texts.
class AppointmentTexts {
  AppointmentTexts._();

  static String typeLabel(AppLocalizations l10n, AppointmentType type) =>
      switch (type) {
        AppointmentType.followUp => l10n.apptTypeFollowUp,
        AppointmentType.checkup => l10n.apptTypeCheckup,
        AppointmentType.labReview => l10n.apptTypeLabReview,
        AppointmentType.other => l10n.apptTypeOther,
      };

  /// "Fri, Nov 20, 10:30 AM" in the app language.
  static String when(AppLocalizations l10n, DateTime at) =>
      DateFormat.MMMEd(l10n.localeName).add_jm().format(at);

  static AppointmentReminderPlan plan(
    AppLocalizations l10n,
    Appointment appointment,
    String? doctorName,
  ) {
    final hasDoctor = doctorName != null && doctorName.trim().isNotEmpty;
    final place = (appointment.location ?? '').trim();
    final body = StringBuffer(
      l10n.apptNotifBody(
        typeLabel(l10n, appointment.type),
        when(l10n, appointment.startsAt),
      ),
    );
    if (place.isNotEmpty) body.write(' · $place');

    return AppointmentReminderPlan(
      appointment: appointment,
      title: hasDoctor
          ? l10n.apptNotifTitle(doctorName.trim())
          : l10n.apptNotifTitleNoDoctor,
      body: body.toString(),
    );
  }
}

/// The real notification system (flutter_local_notifications).
class PluginAppointmentBackend implements AppointmentNotificationBackend {
  PluginAppointmentBackend({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'appointment_reminders';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Creates the channel (safe to call again).
  Future<void> ensureChannel(AppLocalizations l10n) async {
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        l10n.apptChannelName,
        description: l10n.apptChannelDesc,
        importance: Importance.high,
      ),
    );
  }

  NotificationDetails _details(AppLocalizations l10n) => NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      l10n.apptChannelName,
      channelDescription: l10n.apptChannelDesc,
      icon: 'ic_stat_medication',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));
  set l10n(AppLocalizations value) => _l10n = value;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  }) async {
    // Same rule as the dose reminders: exact when Android allows it (so a
    // "30 minutes before" reminder is not late), otherwise inexact.
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at.toLocal(), tz.local),
      notificationDetails: _details(_l10n),
      androidScheduleMode: await _scheduleMode(),
      payload: payload,
    );
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      return exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<List<PendingReminder>> pending() async => [
    for (final p in await _plugin.pendingNotificationRequests())
      PendingReminder(id: p.id, payload: p.payload),
  ];
}

/// ============================================================
/// APPOINTMENT REMINDERS (phone side) — M16 step 5
///
/// The screens call [schedule] / [cancel] after saving or deleting an
/// appointment. [syncProfile] runs with the dose scheduler (app start,
/// resume, profile change) so a new phone, a reinstall, or a change made on
/// another device ends up with the right reminders.
/// ============================================================
class AppointmentReminders {
  AppointmentReminders._() {
    _service = AppointmentReminderService(_backend);
  }

  static final AppointmentReminders instance = AppointmentReminders._();

  final PluginAppointmentBackend _backend = PluginAppointmentBackend();
  late final AppointmentReminderService _service;

  Future<AppLocalizations> _prepare() async {
    await ReminderScheduler.instance.init(); // time zone + plugin setup
    final l10n = lookupAppLocalizations(LocaleController.instance.locale);
    _backend.l10n = l10n;
    await _backend.ensureChannel(l10n);
    return l10n;
  }

  /// Replaces the reminders of one saved appointment. Never throws: a failed
  /// reminder must not undo a saved appointment.
  Future<void> schedule(
    String profileId,
    Appointment appointment, {
    String? doctorName,
  }) async {
    try {
      final l10n = await _prepare();
      final plan = AppointmentTexts.plan(l10n, appointment, doctorName);
      await _service.schedule(
        appointment,
        profileId: profileId,
        title: plan.title,
        body: plan.body,
      );
    } catch (e) {
      debugPrint('AppointmentReminders: schedule failed: $e');
    }
  }

  Future<void> cancel(Appointment appointment) async {
    try {
      await _prepare();
      await _service.cancel(appointment, includeDelivered: true);
    } catch (e) {
      debugPrint('AppointmentReminders: cancel failed: $e');
    }
  }

  /// Makes the phone match Firestore for this profile.
  Future<void> syncProfile(String profileId) async {
    try {
      final l10n = await _prepare();
      final appointments = await FirebaseAppointmentRepository.instance.list(
        profileId,
        from: DateTime.now(),
        limit: 50,
      );

      final names = <String, String>{};
      if (appointments.any((a) => a.prescriberId != null)) {
        for (final d in await FirebasePrescriberRepository.instance.list(
          profileId,
        )) {
          names[d.id] = d.name;
        }
      }

      final result = await _service.sync(
        profileId: profileId,
        plans: [
          for (final a in appointments)
            AppointmentTexts.plan(l10n, a, names[a.prescriberId]),
        ],
      );
      debugPrint(
        'AppointmentReminders: ${appointments.length} appointment(s), '
        '${result.scheduled} reminder(s) set, ${result.cancelled} removed',
      );
    } catch (e) {
      debugPrint('AppointmentReminders: sync failed: $e');
    }
  }
}
