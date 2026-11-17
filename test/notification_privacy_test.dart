import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:med_remind_app/core/doctors/appointment_models.dart';
import 'package:med_remind_app/core/doctors/appointment_validator.dart';
import 'package:med_remind_app/core/notification_privacy.dart';
import 'package:med_remind_app/core/services/appointment_reminders.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/notification_settings.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  setUpAll(() => initializeDateFormatting('en'));

  group('dose reminder text', () {
    test('hidden: a generic title and body, no medicine, no dose', () {
      expect(
        ReminderText.title(en, hide: true, medName: 'Metformin'),
        'Medication reminder',
      );
      expect(
        ReminderText.body(en, hide: true, doseLabel: '500 mg with food'),
        'Time to take your medication',
      );
    });

    test('shown: the medicine and the dose', () {
      expect(
        ReminderText.title(en, hide: false, medName: 'Metformin'),
        'Metformin',
      );
      expect(ReminderText.body(en, hide: false, doseLabel: '500 mg'), '500 mg');
    });

    test('shown but nothing to show: still a generic line', () {
      expect(
        ReminderText.title(en, hide: false, medName: '  '),
        'Medication reminder',
      );
      expect(
        ReminderText.body(en, hide: false, doseLabel: null),
        'Time to take your medication',
      );
      expect(
        ReminderText.body(en, hide: false, doseLabel: ''),
        'Time to take your medication',
      );
    });

    test('every language has its own generic text', () {
      for (final code in ['es', 'fr', 'ar', 'hi']) {
        final l = lookupAppLocalizations(Locale(code));
        expect(l.reminderGenericTitle, isNotEmpty, reason: code);
        expect(
          l.reminderGenericTitle,
          isNot(en.reminderGenericTitle),
          reason: code,
        );
        expect(
          l.reminderGenericBody,
          isNot(en.reminderGenericBody),
          reason: code,
        );
        expect(
          l.apptNotifBodyHidden,
          isNot(en.apptNotifBodyHidden),
          reason: code,
        );
        expect(l.notifPrivacyTitle, isNot(en.notifPrivacyTitle), reason: code);
      }
    });
  });

  group('appointment reminder text', () {
    final appointment = Appointment(
      id: 'a1',
      startsAt: DateTime(2027, 1, 12, 10, 30),
      prescriberId: 'p1',
      type: AppointmentType.followUp,
      location: 'City Heart Clinic',
    );

    test('hidden (the default): no doctor, no kind of visit, no place', () {
      final plan = AppointmentTexts.plan(en, appointment, 'Dr. Khan');
      final text = '${plan.title} ${plan.body}';
      expect(plan.title, 'Upcoming appointment');
      expect(plan.body, 'You have an upcoming appointment');
      expect(text, isNot(contains('Khan')));
      expect(text, isNot(contains('Heart')));
    });

    test('shown: doctor and place are there', () {
      final plan = AppointmentTexts.plan(
        en,
        appointment,
        'Dr. Khan',
        hide: false,
      );
      expect(plan.title, contains('Dr. Khan'));
      expect(plan.body, contains('City Heart Clinic'));
    });
  });

  group('the privacy switch', () {
    test('names are hidden until the user says otherwise', () {
      expect(NotificationPrivacy.instance.hideNames, isTrue);
    });

    test(
      'settings: hidden by default, when missing, and when stored as true',
      () {
        expect(
          NotificationSettings.defaults.hideMedicineNamesOnLockScreen,
          isTrue,
        );
        expect(
          NotificationSettings.fromMap(const {}).hideMedicineNamesOnLockScreen,
          isTrue,
        );
        expect(
          NotificationSettings.fromMap(const {
            'hideMedicineNamesOnLockScreen': true,
          }).hideMedicineNamesOnLockScreen,
          isTrue,
        );
      },
    );

    test('settings: the user can turn it off, and it round-trips', () {
      final off = NotificationSettings.fromMap(const {
        'hideMedicineNamesOnLockScreen': false,
      });
      expect(off.hideMedicineNamesOnLockScreen, isFalse);
      expect(
        NotificationSettings.fromMap(off.toMap()).hideMedicineNamesOnLockScreen,
        isFalse,
      );
    });
  });

  // Device-level protections live in native files no Dart test runs. These
  // checks fail if somebody removes them.
  group('platform files keep the privacy settings', () {
    String read(String path) => File(path).readAsStringSync();

    test('Android: no automatic backup of app data', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('@xml/data_extraction_rules'));
      expect(manifest, contains('@xml/backup_rules'));
      for (final f in ['data_extraction_rules.xml', 'backup_rules.xml']) {
        final xml = read('android/app/src/main/res/xml/$f');
        for (final domain in ['file', 'database', 'sharedpref']) {
          expect(xml, contains('domain="$domain"'), reason: '$f $domain');
        }
      }
    });

    test('Android: analytics and the advertising id are off', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('firebase_analytics_collection_deactivated'));
      expect(manifest, contains('google_analytics_adid_collection_enabled'));
    });

    test('Android: the recent-apps screen is blank', () {
      final kt = read(
        'android/app/src/main/kotlin/com/medreminder/app/MainActivity.kt',
      );
      expect(kt, contains('FLAG_SECURE'));
      expect(kt, contains('onPause'));
      expect(kt, contains('setRecentsScreenshotEnabled(false)'));
    });

    test('iOS: the app-switcher snapshot is covered', () {
      final swift = read('ios/Runner/SceneDelegate.swift');
      expect(swift, contains('sceneWillResignActive'));
      expect(swift, contains('sceneDidBecomeActive'));
    });

    test('iOS: analytics off', () {
      final plist = read('ios/Runner/Info.plist');
      expect(plist, contains('FIREBASE_ANALYTICS_COLLECTION_ENABLED'));
    });
  });
}
