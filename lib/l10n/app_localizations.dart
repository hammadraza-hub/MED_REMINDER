import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
  ];

  /// Snackbar jab koi feature abhi available na ho.
  ///
  /// In en, this message translates to:
  /// **'{title} — coming soon'**
  String comingSoon(String title);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMeds.
  ///
  /// In en, this message translates to:
  /// **'Meds'**
  String get navMeds;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGroupPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsGroupPreferences;

  /// No description provided for @settingsGroupAccountPlan.
  ///
  /// In en, this message translates to:
  /// **'Account & Plan'**
  String get settingsGroupAccountPlan;

  /// No description provided for @settingsGroupSupportLegal.
  ///
  /// In en, this message translates to:
  /// **'Support & Legal'**
  String get settingsGroupSupportLegal;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsTrailing.
  ///
  /// In en, this message translates to:
  /// **'Chime & Vibrate'**
  String get settingsNotificationsTrailing;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageTrailing.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get settingsLanguageTrailing;

  /// No description provided for @settingsAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsAccessibility;

  /// No description provided for @settingsPrivacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsPrivacySecurity;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsDataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get settingsDataExport;

  /// No description provided for @settingsDataExportTrailing.
  ///
  /// In en, this message translates to:
  /// **'CSV & PDF'**
  String get settingsDataExportTrailing;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutTrailing.
  ///
  /// In en, this message translates to:
  /// **'v1.2.0'**
  String get settingsAboutTrailing;

  /// No description provided for @settingsPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get settingsPro;

  /// No description provided for @settingsCaregiverSync.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Sync Active'**
  String get settingsCaregiverSync;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your care plan.'**
  String get settingsLogoutMessage;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// No description provided for @settingsLogoutComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Log Out — coming soon'**
  String get settingsLogoutComingSoon;

  /// No description provided for @settingsFooterVersion.
  ///
  /// In en, this message translates to:
  /// **'MedRemind Care Health Suite • v1.2.0 (Build 412)'**
  String get settingsFooterVersion;

  /// No description provided for @settingsHipaa.
  ///
  /// In en, this message translates to:
  /// **'HIPAA Compliant & Encrypted'**
  String get settingsHipaa;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'The app updates instantly after selecting a language.'**
  String get languageNote;

  /// No description provided for @languageDeviceDefault.
  ///
  /// In en, this message translates to:
  /// **'Device default: System Language (English - US)'**
  String get languageDeviceDefault;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name} 👋'**
  String homeGreetingWithName(String greeting, String name);

  /// No description provided for @homeDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} Day Streak'**
  String homeDayStreak(int days);

  /// No description provided for @homeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeAdd;

  /// No description provided for @homeTodaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get homeTodaySchedule;

  /// No description provided for @homeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeFilterAll;

  /// No description provided for @homeFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get homeFilterPending;

  /// No description provided for @homeFilterTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get homeFilterTaken;

  /// No description provided for @homeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get homeDaily;

  /// No description provided for @homeStatTaken.
  ///
  /// In en, this message translates to:
  /// **'{count} Taken'**
  String homeStatTaken(int count);

  /// No description provided for @homeStatPending.
  ///
  /// In en, this message translates to:
  /// **'{count} Pending'**
  String homeStatPending(int count);

  /// No description provided for @homeStatMissed.
  ///
  /// In en, this message translates to:
  /// **'{count} Missed'**
  String homeStatMissed(int count);

  /// No description provided for @homeQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACCESS'**
  String get homeQuickAccess;

  /// No description provided for @homeShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get homeShortcuts;

  /// No description provided for @homeQuickVitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get homeQuickVitals;

  /// No description provided for @homeQuickDoctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get homeQuickDoctors;

  /// No description provided for @homeQuickAI.
  ///
  /// In en, this message translates to:
  /// **'AI Assist'**
  String get homeQuickAI;

  /// No description provided for @homeQuickFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get homeQuickFamily;

  /// No description provided for @homeScreenComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} screen coming next.'**
  String homeScreenComingSoon(String name);

  /// No description provided for @homeMarkedTaken.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as taken ✓'**
  String homeMarkedTaken(String name);

  /// No description provided for @homeMarkedUntaken.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as untaken 🔄'**
  String homeMarkedUntaken(String name);

  /// No description provided for @homeSkipped.
  ///
  /// In en, this message translates to:
  /// **'{name} skipped'**
  String homeSkipped(String name);

  /// No description provided for @homeSkippedReason.
  ///
  /// In en, this message translates to:
  /// **'{name} skipped — {reason}'**
  String homeSkippedReason(String name, String reason);

  /// No description provided for @homeSnoozed.
  ///
  /// In en, this message translates to:
  /// **'{name} snoozed — reminder again in {minutes} min'**
  String homeSnoozed(String name, int minutes);

  /// No description provided for @homeSwitchedMember.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}\'s medicines'**
  String homeSwitchedMember(String name);

  /// No description provided for @homeActionTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get homeActionTaken;

  /// No description provided for @homeActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get homeActionSkip;

  /// No description provided for @homeActionSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get homeActionSnooze;

  /// No description provided for @homeStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get homeStatusPending;

  /// No description provided for @homeStatusTaken.
  ///
  /// In en, this message translates to:
  /// **'TAKEN'**
  String get homeStatusTaken;

  /// No description provided for @homeStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get homeStatusUpcoming;

  /// No description provided for @homeStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED'**
  String get homeStatusSkipped;

  /// No description provided for @homeRunningLow.
  ///
  /// In en, this message translates to:
  /// **'{name} running low · {days} days left'**
  String homeRunningLow(String name, int days);

  /// No description provided for @homeRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill →'**
  String get homeRefill;

  /// No description provided for @homeSkippedNote.
  ///
  /// In en, this message translates to:
  /// **'Skipped — reminder will come again tomorrow'**
  String get homeSkippedNote;

  /// No description provided for @doseFormTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get doseFormTablet;

  /// No description provided for @doseFormLiquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get doseFormLiquid;

  /// No description provided for @doseScheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'1x daily'**
  String get doseScheduleDaily;

  /// No description provided for @doseScheduleBeforeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Before breakfast'**
  String get doseScheduleBeforeBreakfast;

  /// No description provided for @doseScheduleAfterBreakfast.
  ///
  /// In en, this message translates to:
  /// **'After breakfast'**
  String get doseScheduleAfterBreakfast;

  /// No description provided for @doseScheduleWithDinner.
  ///
  /// In en, this message translates to:
  /// **'With dinner'**
  String get doseScheduleWithDinner;

  /// No description provided for @doseDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{time} · Due soon'**
  String doseDueSoon(String time);

  /// No description provided for @doseMarkTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get doseMarkTaken;

  /// No description provided for @doseMarkUntaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as Untaken'**
  String get doseMarkUntaken;

  /// No description provided for @doseHideReason.
  ///
  /// In en, this message translates to:
  /// **'Hide Reason'**
  String get doseHideReason;

  /// No description provided for @doseSkipDose.
  ///
  /// In en, this message translates to:
  /// **'Skip Dose'**
  String get doseSkipDose;

  /// No description provided for @doseSnoozeFor.
  ///
  /// In en, this message translates to:
  /// **'SNOOZE FOR'**
  String get doseSnoozeFor;

  /// No description provided for @doseReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get doseReasonLabel;

  /// No description provided for @doseReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Feeling nauseous'**
  String get doseReasonHint;

  /// No description provided for @doseConfirmSkip.
  ///
  /// In en, this message translates to:
  /// **'Confirm Skip'**
  String get doseConfirmSkip;

  /// No description provided for @dataExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExportTitle;

  /// No description provided for @dataExportHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Export All My Data'**
  String get dataExportHeroTitle;

  /// No description provided for @dataExportHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a complete copy of everything stored in your account.'**
  String get dataExportHeroSubtitle;

  /// No description provided for @dataExportBadge.
  ///
  /// In en, this message translates to:
  /// **'Encrypted GDPR & HIPAA standard export'**
  String get dataExportBadge;

  /// No description provided for @dataExportIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get dataExportIncludedTitle;

  /// No description provided for @dataExportModules.
  ///
  /// In en, this message translates to:
  /// **'4 Modules'**
  String get dataExportModules;

  /// No description provided for @dataExportIncludedProfiles.
  ///
  /// In en, this message translates to:
  /// **'All profiles & medications'**
  String get dataExportIncludedProfiles;

  /// No description provided for @dataExportIncludedDoses.
  ///
  /// In en, this message translates to:
  /// **'Complete dose history & adherence'**
  String get dataExportIncludedDoses;

  /// No description provided for @dataExportIncludedVitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals, symptoms & notes'**
  String get dataExportIncludedVitals;

  /// No description provided for @dataExportIncludedPrescribers.
  ///
  /// In en, this message translates to:
  /// **'Prescribers, appointments & pharmacies'**
  String get dataExportIncludedPrescribers;

  /// No description provided for @dataExportFormatNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a ZIP archive ({formats}) via email within 24 hours.'**
  String dataExportFormatNote(String formats);

  /// No description provided for @dataExportFormats.
  ///
  /// In en, this message translates to:
  /// **'JSON + CSV'**
  String get dataExportFormats;

  /// No description provided for @dataExportSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent directly to {email}'**
  String dataExportSentTo(String email);

  /// No description provided for @dataExportRequest.
  ///
  /// In en, this message translates to:
  /// **'Request Export'**
  String get dataExportRequest;

  /// No description provided for @dataExportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating Package...'**
  String get dataExportGenerating;

  /// No description provided for @dataExportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get dataExportSubmitted;

  /// No description provided for @dataExportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Requested!'**
  String get dataExportSuccessTitle;

  /// No description provided for @dataExportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re preparing your raw data archive. You will receive a direct link once compilation completes.'**
  String get dataExportSuccessMessage;

  /// No description provided for @dataExportQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued in server batch'**
  String get dataExportQueued;

  /// No description provided for @dataExportLastExportNever.
  ///
  /// In en, this message translates to:
  /// **'Last export: Never'**
  String get dataExportLastExportNever;

  /// No description provided for @dataExportLastExportNow.
  ///
  /// In en, this message translates to:
  /// **'Last export: Just now ({timestamp})'**
  String dataExportLastExportNow(String timestamp);

  /// No description provided for @dataExportRetentionId.
  ///
  /// In en, this message translates to:
  /// **'Account records retention ID: {id}'**
  String dataExportRetentionId(String id);

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @helpSupportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search FAQ...'**
  String get helpSupportSearchHint;

  /// No description provided for @helpSupportNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching articles.'**
  String get helpSupportNoResults;

  /// No description provided for @helpSupportBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Caregiver & Patient Desk'**
  String get helpSupportBannerTitle;

  /// No description provided for @helpSupportBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to keep your routines on schedule.'**
  String get helpSupportBannerSubtitle;

  /// No description provided for @helpSupportFaqHeader.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked'**
  String get helpSupportFaqHeader;

  /// No description provided for @helpSupportFaqCount.
  ///
  /// In en, this message translates to:
  /// **'{count} articles'**
  String helpSupportFaqCount(int count);

  /// No description provided for @helpSupportStillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still Need Help?'**
  String get helpSupportStillNeedHelp;

  /// No description provided for @helpSupportLiveOnline.
  ///
  /// In en, this message translates to:
  /// **'Live Team Online'**
  String get helpSupportLiveOnline;

  /// No description provided for @helpSupportEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get helpSupportEmailSupport;

  /// No description provided for @helpSupportEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get helpSupportEmailAction;

  /// No description provided for @helpSupportSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit a Request'**
  String get helpSupportSubmitRequest;

  /// No description provided for @helpSupportResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Average response under 2 hours'**
  String get helpSupportResponseTime;

  /// No description provided for @helpSupportHelpful.
  ///
  /// In en, this message translates to:
  /// **'Was this page helpful?'**
  String get helpSupportHelpful;

  /// No description provided for @helpSupportYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get helpSupportYes;

  /// No description provided for @helpSupportNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get helpSupportNo;

  /// No description provided for @helpSupportFeedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get helpSupportFeedbackThanks;

  /// No description provided for @helpSupportVersion.
  ///
  /// In en, this message translates to:
  /// **'MedRemind v1.2.0 (build 245)'**
  String get helpSupportVersion;

  /// No description provided for @helpSupportCompliance.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Caregiver Network • HIPAA Compliant'**
  String get helpSupportCompliance;

  /// No description provided for @helpSupportEmailClipped.
  ///
  /// In en, this message translates to:
  /// **'Email us at {email}'**
  String helpSupportEmailClipped(String email);

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I change a dose time?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Open your Schedule or Medication tab, tap the specific medication card, select Edit Schedule, and adjust your dosage alerts. Changes sync instantly across caregiver devices.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'Why didn\'t I get a reminder?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'Ensure battery optimization is disabled for MedRemind in phone Settings. Also verify that Critical Alerts and notification permissions are granted in your operating system settings.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'How do caregiver alerts work?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'Caregivers receive silent affirmations when medicines are logged. If a crucial dose is missed for over 30 minutes, an escalated notification is automatically sent to the primary caregiver.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'How do I add a family member?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'Go to Profiles, tap Add, then send an invite by email or phone. They accept the link to connect.'**
  String get faqA4;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutAppName.
  ///
  /// In en, this message translates to:
  /// **'MedRemind'**
  String get aboutAppName;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.2.0 (build 245)'**
  String get aboutVersion;

  /// No description provided for @aboutUpToDate.
  ///
  /// In en, this message translates to:
  /// **'UP TO DATE ✓'**
  String get aboutUpToDate;

  /// No description provided for @aboutTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutTerms;

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacy;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get aboutLicenses;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get aboutCredits;

  /// No description provided for @aboutCreditsDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get aboutCreditsDesign;

  /// No description provided for @aboutCreditsDesignValue.
  ///
  /// In en, this message translates to:
  /// **'MedRemind Team'**
  String get aboutCreditsDesignValue;

  /// No description provided for @aboutCreditsDrugData.
  ///
  /// In en, this message translates to:
  /// **'Drug data'**
  String get aboutCreditsDrugData;

  /// No description provided for @aboutCreditsDrugDataValue.
  ///
  /// In en, this message translates to:
  /// **'RxNorm · OpenFDA'**
  String get aboutCreditsDrugDataValue;

  /// No description provided for @aboutCreditsIcons.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get aboutCreditsIcons;

  /// No description provided for @aboutCreditsIconsValue.
  ///
  /// In en, this message translates to:
  /// **'Open source sets'**
  String get aboutCreditsIconsValue;

  /// No description provided for @aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'Made with care for families managing health together.'**
  String get aboutFooter;

  /// No description provided for @aboutLegalBody1.
  ///
  /// In en, this message translates to:
  /// **'MedRemind is committed to high clinical accuracy and compassionate design. Our data sources conform strictly to standards published by the National Library of Medicine (RxNorm) and the FDA regulatory database.'**
  String get aboutLegalBody1;

  /// No description provided for @aboutLegalBody2.
  ///
  /// In en, this message translates to:
  /// **'All pill recognition heuristics, caregiver dispatch alerts, and dosage logs remain cryptographically bound to your designated family vault. Health parameters are not monetized or shared with third-party advertisers.'**
  String get aboutLegalBody2;

  /// No description provided for @aboutLegalComplianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Compliance & Audits'**
  String get aboutLegalComplianceTitle;

  /// No description provided for @aboutLegalComplianceValue.
  ///
  /// In en, this message translates to:
  /// **'SOC-2 Type II Certified · HIPAA Security Safeguards · Verified 2025'**
  String get aboutLegalComplianceValue;

  /// No description provided for @aboutDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get aboutDone;

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeTitle;

  /// No description provided for @upgradePlanStatus.
  ///
  /// In en, this message translates to:
  /// **'Free Plan • Ready to expand'**
  String get upgradePlanStatus;

  /// No description provided for @upgradeProGated.
  ///
  /// In en, this message translates to:
  /// **'Pro Gated'**
  String get upgradeProGated;

  /// No description provided for @upgradeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the full power of MedRemind'**
  String get upgradeHeroTitle;

  /// No description provided for @upgradeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interactions, refills, reports & family sharing'**
  String get upgradeHeroSubtitle;

  /// No description provided for @upgradeUnlockHeader.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll unlock'**
  String get upgradeUnlockHeader;

  /// No description provided for @upgradeUnlockInteractions.
  ///
  /// In en, this message translates to:
  /// **'Drug interaction & allergy checking'**
  String get upgradeUnlockInteractions;

  /// No description provided for @upgradeUnlockRefills.
  ///
  /// In en, this message translates to:
  /// **'Inventory tracking & refill alerts'**
  String get upgradeUnlockRefills;

  /// No description provided for @upgradeUnlockReports.
  ///
  /// In en, this message translates to:
  /// **'PDF/CSV reports for your doctor'**
  String get upgradeUnlockReports;

  /// No description provided for @upgradeUnlockFamily.
  ///
  /// In en, this message translates to:
  /// **'Family linking — up to 5 profiles'**
  String get upgradeUnlockFamily;

  /// No description provided for @upgradeSeeComparison.
  ///
  /// In en, this message translates to:
  /// **'See full comparison breakdown'**
  String get upgradeSeeComparison;

  /// No description provided for @upgradeChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get upgradeChoosePlan;

  /// No description provided for @upgradeFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'7-Day Free Trial'**
  String get upgradeFreeTrial;

  /// No description provided for @upgradeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get upgradeMonthly;

  /// No description provided for @upgradeAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get upgradeAnnual;

  /// No description provided for @upgradeSaveBadge.
  ///
  /// In en, this message translates to:
  /// **'Save 52%'**
  String get upgradeSaveBadge;

  /// No description provided for @upgradePlanSoloName.
  ///
  /// In en, this message translates to:
  /// **'Solo Pro'**
  String get upgradePlanSoloName;

  /// No description provided for @upgradePlanSoloSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything for one person'**
  String get upgradePlanSoloSubtitle;

  /// No description provided for @upgradePlanFamilyName.
  ///
  /// In en, this message translates to:
  /// **'Family Pro'**
  String get upgradePlanFamilyName;

  /// No description provided for @upgradePlanFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 linked profiles + caregiver alerts'**
  String get upgradePlanFamilySubtitle;

  /// No description provided for @upgradePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get upgradePopular;

  /// No description provided for @upgradeSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get upgradeSelected;

  /// No description provided for @upgradePriceAnnual.
  ///
  /// In en, this message translates to:
  /// **'{price}/yr'**
  String upgradePriceAnnual(String price);

  /// No description provided for @upgradePriceMonthly.
  ///
  /// In en, this message translates to:
  /// **'{price}/mo'**
  String upgradePriceMonthly(String price);

  /// No description provided for @upgradeWasPrice.
  ///
  /// In en, this message translates to:
  /// **'was {price}'**
  String upgradeWasPrice(String price);

  /// No description provided for @upgradeStartTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 7-Day Free Trial'**
  String get upgradeStartTrial;

  /// No description provided for @upgradeNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today. Reminder sent on Day 5.'**
  String get upgradeNothingDue;

  /// No description provided for @upgradeCompareAll.
  ///
  /// In en, this message translates to:
  /// **'Compare all features & plans'**
  String get upgradeCompareAll;

  /// No description provided for @upgradeRestorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get upgradeRestorePurchase;

  /// No description provided for @upgradeLegalNote.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime in App Store settings at least 24 hours before trial ends. Plan auto-renews until cancelled.'**
  String get upgradeLegalNote;

  /// No description provided for @upgradeComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Plan Comparison'**
  String get upgradeComparisonTitle;

  /// No description provided for @upgradeComparisonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with Selected Plan'**
  String get upgradeComparisonContinue;

  /// No description provided for @upgradeFeatureReminders.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get upgradeFeatureReminders;

  /// No description provided for @upgradeFeatureRemindersValue.
  ///
  /// In en, this message translates to:
  /// **'Free & Pro (Unlimited)'**
  String get upgradeFeatureRemindersValue;

  /// No description provided for @upgradeFeatureInteractions.
  ///
  /// In en, this message translates to:
  /// **'Drug Interactions Checker'**
  String get upgradeFeatureInteractions;

  /// No description provided for @upgradeFeatureRefills.
  ///
  /// In en, this message translates to:
  /// **'Refill Smart Alerts'**
  String get upgradeFeatureRefills;

  /// No description provided for @upgradeFeatureReports.
  ///
  /// In en, this message translates to:
  /// **'Doctor PDF Health Exports'**
  String get upgradeFeatureReports;

  /// No description provided for @upgradeFeatureFamily.
  ///
  /// In en, this message translates to:
  /// **'Family & Caregiver Sync'**
  String get upgradeFeatureFamily;

  /// No description provided for @upgradeValuePro.
  ///
  /// In en, this message translates to:
  /// **'Pro Exclusive'**
  String get upgradeValuePro;

  /// No description provided for @upgradeValueFamily.
  ///
  /// In en, this message translates to:
  /// **'Family Pro Only'**
  String get upgradeValueFamily;

  /// No description provided for @upgradeRestoreToast.
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases... No prior subscriptions found.'**
  String get upgradeRestoreToast;

  /// No description provided for @upgradeTrialToast.
  ///
  /// In en, this message translates to:
  /// **'Starting 7-day trial for {plan} ({cadence})'**
  String upgradeTrialToast(String plan, String cadence);

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare Plans'**
  String get compareTitle;

  /// No description provided for @compareGuarantee.
  ///
  /// In en, this message translates to:
  /// **'30-Day Money Back Guarantee'**
  String get compareGuarantee;

  /// No description provided for @compareAnnualSave.
  ///
  /// In en, this message translates to:
  /// **'Annual Save 40%'**
  String get compareAnnualSave;

  /// No description provided for @compareColFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get compareColFeatures;

  /// No description provided for @compareColFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get compareColFree;

  /// No description provided for @compareFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get compareFreeSubtitle;

  /// No description provided for @compareColSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get compareColSolo;

  /// No description provided for @compareSoloSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most Loved'**
  String get compareSoloSubtitle;

  /// No description provided for @compareColFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get compareColFamily;

  /// No description provided for @compareFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full Care'**
  String get compareFamilySubtitle;

  /// No description provided for @comparePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get comparePriceLabel;

  /// No description provided for @compareBilledYearly.
  ///
  /// In en, this message translates to:
  /// **'Billed yearly'**
  String get compareBilledYearly;

  /// No description provided for @compareForever.
  ///
  /// In en, this message translates to:
  /// **'forever'**
  String get compareForever;

  /// No description provided for @comparePerYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get comparePerYear;

  /// No description provided for @compareGroupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Medication Tools'**
  String get compareGroupDaily;

  /// No description provided for @compareGroupClinical.
  ///
  /// In en, this message translates to:
  /// **'Clinical Safety & Tracking'**
  String get compareGroupClinical;

  /// No description provided for @compareGroupFamily.
  ///
  /// In en, this message translates to:
  /// **'Family & Caregiver Circle'**
  String get compareGroupFamily;

  /// No description provided for @compareFeatUnlimitedMeds.
  ///
  /// In en, this message translates to:
  /// **'Unlimited meds & reminders'**
  String get compareFeatUnlimitedMeds;

  /// No description provided for @compareFeatAdherence.
  ///
  /// In en, this message translates to:
  /// **'Adherence calendar & streaks'**
  String get compareFeatAdherence;

  /// No description provided for @compareFeatInteractions.
  ///
  /// In en, this message translates to:
  /// **'Interaction & allergy checks'**
  String get compareFeatInteractions;

  /// No description provided for @compareFeatInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory & refill alerts'**
  String get compareFeatInventory;

  /// No description provided for @compareFeatDoctorTools.
  ///
  /// In en, this message translates to:
  /// **'Doctor & appointment tools'**
  String get compareFeatDoctorTools;

  /// No description provided for @compareFeatReports.
  ///
  /// In en, this message translates to:
  /// **'PDF/CSV health reports'**
  String get compareFeatReports;

  /// No description provided for @compareFeatHealthSync.
  ///
  /// In en, this message translates to:
  /// **'Apple Health & Fit sync'**
  String get compareFeatHealthSync;

  /// No description provided for @compareFeatFamilyLinking.
  ///
  /// In en, this message translates to:
  /// **'Family linking (up to 5)'**
  String get compareFeatFamilyLinking;

  /// No description provided for @compareFeatMissedDose.
  ///
  /// In en, this message translates to:
  /// **'Missed-dose caregiver alert'**
  String get compareFeatMissedDose;

  /// No description provided for @compareFeatFamilyDashboard.
  ///
  /// In en, this message translates to:
  /// **'Combined family dashboard'**
  String get compareFeatFamilyDashboard;

  /// No description provided for @compareQuote.
  ///
  /// In en, this message translates to:
  /// **'“Caregiver alerts gave me total peace of mind for mom.”'**
  String get compareQuote;

  /// No description provided for @compareQuoteAuthor.
  ///
  /// In en, this message translates to:
  /// **'— Sarah M., Family Pro Subscriber'**
  String get compareQuoteAuthor;

  /// No description provided for @compareChooseSolo.
  ///
  /// In en, this message translates to:
  /// **'Choose Solo Pro'**
  String get compareChooseSolo;

  /// No description provided for @compareChooseFamily.
  ///
  /// In en, this message translates to:
  /// **'Choose Family Pro'**
  String get compareChooseFamily;

  /// No description provided for @compareContinueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue with Free basic plan'**
  String get compareContinueFree;

  /// No description provided for @compareFreeSelected.
  ///
  /// In en, this message translates to:
  /// **'Free basic plan selected'**
  String get compareFreeSelected;

  /// No description provided for @compareFinePrint.
  ///
  /// In en, this message translates to:
  /// **'Prices shown for annual billing. Monthly plans also available at checkout. Cancel anytime with zero hassle.'**
  String get compareFinePrint;

  /// No description provided for @compareEncrypted.
  ///
  /// In en, this message translates to:
  /// **'256-bit Encrypted'**
  String get compareEncrypted;

  /// No description provided for @compareAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync'**
  String get compareAutoSync;

  /// No description provided for @compareHipaaReady.
  ///
  /// In en, this message translates to:
  /// **'HIPAA Ready'**
  String get compareHipaaReady;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentTitle;

  /// No description provided for @paymentProNowTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re Pro now!'**
  String get paymentProNowTitle;

  /// No description provided for @paymentWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {plan}, {name}. All Pro features are unlocked.'**
  String paymentWelcome(String plan, String name);

  /// No description provided for @paymentPlanActive.
  ///
  /// In en, this message translates to:
  /// **'Plan Active • Unlimited Care Sync'**
  String get paymentPlanActive;

  /// No description provided for @paymentOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get paymentOrderSummary;

  /// No description provided for @paymentTrialActive.
  ///
  /// In en, this message translates to:
  /// **'Trial Active'**
  String get paymentTrialActive;

  /// No description provided for @paymentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get paymentPlanLabel;

  /// No description provided for @paymentFreeTrialLabel.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get paymentFreeTrialLabel;

  /// No description provided for @paymentFreeTrialValue.
  ///
  /// In en, this message translates to:
  /// **'7 days — then {price}'**
  String paymentFreeTrialValue(String price);

  /// No description provided for @paymentNextBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next billing date'**
  String get paymentNextBillingLabel;

  /// No description provided for @paymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get paymentReceipt;

  /// No description provided for @paymentOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get paymentOrderIdLabel;

  /// No description provided for @paymentPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentPaymentMethodLabel;

  /// No description provided for @paymentReceiptSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to'**
  String get paymentReceiptSentLabel;

  /// No description provided for @paymentViewFullReceipt.
  ///
  /// In en, this message translates to:
  /// **'View full receipt'**
  String get paymentViewFullReceipt;

  /// No description provided for @paymentStartPro.
  ///
  /// In en, this message translates to:
  /// **'Start Using Pro'**
  String get paymentStartPro;

  /// No description provided for @paymentUnlockNote.
  ///
  /// In en, this message translates to:
  /// **'Interaction checks, refill alerts & reports are now active'**
  String get paymentUnlockNote;

  /// No description provided for @doctorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctorsTitle;

  /// No description provided for @doctorsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Doctor'**
  String get doctorsAdd;

  /// No description provided for @doctorsAdded.
  ///
  /// In en, this message translates to:
  /// **'Doctor added successfully'**
  String get doctorsAdded;

  /// No description provided for @doctorsCountOnFile.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 doctor on file} other{{count} doctors on file}}'**
  String doctorsCountOnFile(int count);

  /// No description provided for @doctorsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No doctors on file'**
  String get doctorsEmptyTitle;

  /// No description provided for @doctorsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a doctor to link prescriptions'**
  String get doctorsEmptySubtitle;

  /// No description provided for @doctorsUpcomingVisits.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Visits'**
  String get doctorsUpcomingVisits;

  /// No description provided for @doctorsAppointmentsScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 appointment scheduled} other{{count} appointments scheduled}}'**
  String doctorsAppointmentsScheduled(int count);

  /// No description provided for @doctorsView.
  ///
  /// In en, this message translates to:
  /// **'View →'**
  String get doctorsView;

  /// No description provided for @doctorsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a doctor to view details or edit'**
  String get doctorsHint;

  /// No description provided for @doctorsMedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 med} other{{count} meds}}'**
  String doctorsMedCount(int count);

  /// No description provided for @doctorsDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'DOCTOR DETAILS'**
  String get doctorsDetailsSection;

  /// No description provided for @doctorsFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get doctorsFieldFullName;

  /// No description provided for @doctorsHintFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get doctorsHintFullName;

  /// No description provided for @doctorsFieldSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get doctorsFieldSpecialty;

  /// No description provided for @doctorsHintSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Enter specialty'**
  String get doctorsHintSpecialty;

  /// No description provided for @doctorsFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get doctorsFieldPhone;

  /// No description provided for @doctorsHintPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get doctorsHintPhone;

  /// No description provided for @doctorsFieldClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic / Address (optional)'**
  String get doctorsFieldClinic;

  /// No description provided for @doctorsHintClinic.
  ///
  /// In en, this message translates to:
  /// **'Enter clinic or address'**
  String get doctorsHintClinic;

  /// No description provided for @doctorsLinkMedications.
  ///
  /// In en, this message translates to:
  /// **'LINK TO MEDICATIONS'**
  String get doctorsLinkMedications;

  /// No description provided for @doctorsLinkPrompt.
  ///
  /// In en, this message translates to:
  /// **'Which medications does this doctor prescribe?'**
  String get doctorsLinkPrompt;

  /// No description provided for @doctorsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Doctor'**
  String get doctorsSave;

  /// No description provided for @doctorsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the doctor\'s full name.'**
  String get doctorsNameRequired;

  /// No description provided for @medsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medsTitle;

  /// No description provided for @medsMemberMedications.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Medications'**
  String medsMemberMedications(String name);

  /// No description provided for @medsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active medication} other{{count} active medications}}'**
  String medsActiveCount(int count);

  /// No description provided for @medsManageHeader.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get medsManageHeader;

  /// No description provided for @medsQuickTools.
  ///
  /// In en, this message translates to:
  /// **'Quick Tools'**
  String get medsQuickTools;

  /// No description provided for @medsInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get medsInventory;

  /// No description provided for @medsLowBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} LOW'**
  String medsLowBadge(int count);

  /// No description provided for @medsAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get medsAllergies;

  /// No description provided for @medsSideEffects.
  ///
  /// In en, this message translates to:
  /// **'Side Effects'**
  String get medsSideEffects;

  /// No description provided for @medsPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get medsPharmacy;

  /// No description provided for @medsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search medications...'**
  String get medsSearchHint;

  /// No description provided for @medsTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String medsTabActive(int count);

  /// No description provided for @medsTabArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived ({count})'**
  String medsTabArchived(int count);

  /// No description provided for @medsEmptyArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived medicines'**
  String get medsEmptyArchived;

  /// No description provided for @medsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No medicines found'**
  String get medsEmpty;

  /// No description provided for @medsMovedToArchived.
  ///
  /// In en, this message translates to:
  /// **'{name} moved to Archived'**
  String medsMovedToArchived(String name);

  /// No description provided for @medsDiscontinueError.
  ///
  /// In en, this message translates to:
  /// **'Could not discontinue medication. Please try again.'**
  String get medsDiscontinueError;

  /// No description provided for @medsDiscontinueBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Close discontinue medication'**
  String get medsDiscontinueBarrierLabel;

  /// No description provided for @medsDiscontinue.
  ///
  /// In en, this message translates to:
  /// **'Discontinue'**
  String get medsDiscontinue;

  /// No description provided for @medsLowStock.
  ///
  /// In en, this message translates to:
  /// **'LOW STOCK'**
  String get medsLowStock;

  /// No description provided for @medsBadgeActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get medsBadgeActive;

  /// No description provided for @medsScheduleNotSet.
  ///
  /// In en, this message translates to:
  /// **'Schedule not set'**
  String get medsScheduleNotSet;

  /// No description provided for @medsFrequencyAsNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get medsFrequencyAsNeeded;

  /// No description provided for @medsFrequencySelectedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1x on selected days} other{{count}x on selected days}}'**
  String medsFrequencySelectedDays(int count);

  /// No description provided for @medsFrequencyCyclical.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1x cyclical} other{{count}x cyclical}}'**
  String medsFrequencyCyclical(int count);

  /// No description provided for @medsFrequencyTapering.
  ///
  /// In en, this message translates to:
  /// **'Tapering schedule'**
  String get medsFrequencyTapering;

  /// No description provided for @medsFrequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1x daily} other{{count}x daily}}'**
  String medsFrequencyDaily(int count);

  /// No description provided for @medsNextDoseTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow {time}'**
  String medsNextDoseTomorrow(String time);

  /// No description provided for @medsNextDoseWeekday.
  ///
  /// In en, this message translates to:
  /// **'{day} {time}'**
  String medsNextDoseWeekday(String day, String time);

  /// No description provided for @medsEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String medsEnds(String date);

  /// No description provided for @medsNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {time}'**
  String medsNext(String time);

  /// No description provided for @medsWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get medsWeekdayMon;

  /// No description provided for @medsWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get medsWeekdayTue;

  /// No description provided for @medsWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get medsWeekdayWed;

  /// No description provided for @medsWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get medsWeekdayThu;

  /// No description provided for @medsWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get medsWeekdayFri;

  /// No description provided for @medsWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get medsWeekdaySat;

  /// No description provided for @medsWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get medsWeekdaySun;

  /// No description provided for @medsFormCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get medsFormCapsule;

  /// No description provided for @medsFormDrops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get medsFormDrops;

  /// No description provided for @medsFormInjection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get medsFormInjection;

  /// No description provided for @medsDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String medsDayOf(int day, int total);

  /// No description provided for @medsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String medsDaysLeft(int count);

  /// No description provided for @medsUnitTablet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{tablet} other{tablets}}'**
  String medsUnitTablet(int count);

  /// No description provided for @medsUnitCapsule.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{capsule} other{capsules}}'**
  String medsUnitCapsule(int count);

  /// No description provided for @medsUnitBottle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{bottle} other{bottles}}'**
  String medsUnitBottle(int count);

  /// No description provided for @medsUnitDose.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{dose} other{doses}}'**
  String medsUnitDose(int count);

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventoryMedicationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Medication} other{{count} Medications}}'**
  String inventoryMedicationsCount(int count);

  /// No description provided for @inventoryTrackedSupply.
  ///
  /// In en, this message translates to:
  /// **'Tracked supply'**
  String get inventoryTrackedSupply;

  /// No description provided for @inventoryLowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} LOW STOCK'**
  String inventoryLowStockCount(int count);

  /// No description provided for @inventoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryFilterAll;

  /// No description provided for @inventoryFilterLow.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get inventoryFilterLow;

  /// No description provided for @inventoryFilterOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get inventoryFilterOk;

  /// No description provided for @inventoryEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No medications in this filter'**
  String get inventoryEmptyFilter;

  /// No description provided for @inventoryStatusLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get inventoryStatusLow;

  /// No description provided for @inventoryStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get inventoryStatusOk;

  /// No description provided for @inventoryRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Running low — order refill'**
  String get inventoryRunningLow;

  /// No description provided for @inventoryRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill →'**
  String get inventoryRefill;

  /// No description provided for @inventoryAdjustCount.
  ///
  /// In en, this message translates to:
  /// **'Adjust Count'**
  String get inventoryAdjustCount;

  /// No description provided for @inventorySufficient.
  ///
  /// In en, this message translates to:
  /// **'Sufficient supply'**
  String get inventorySufficient;

  /// No description provided for @inventorySufficientNext.
  ///
  /// In en, this message translates to:
  /// **'Sufficient through next refill'**
  String get inventorySufficientNext;

  /// No description provided for @inventoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get inventoryEdit;

  /// No description provided for @inventoryAutoSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Sync Pharmacy'**
  String get inventoryAutoSyncTitle;

  /// No description provided for @inventoryAutoSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your pharmacy for automatic refill updates'**
  String get inventoryAutoSyncSubtitle;

  /// No description provided for @inventoryAutoSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy auto-sync integration pending'**
  String get inventoryAutoSyncPending;

  /// No description provided for @inventoryCountUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} count updated to {count}'**
  String inventoryCountUpdated(String name, int count);

  /// No description provided for @inventorySupplyDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{~1 day} other{~{count} days}}'**
  String inventorySupplyDays(int count);

  /// No description provided for @inventoryAdjustReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Reason (Optional)'**
  String get inventoryAdjustReasonLabel;

  /// No description provided for @inventoryAdjustReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for adjustment (optional)...'**
  String get inventoryAdjustReasonHint;

  /// No description provided for @inventoryAdjustSave.
  ///
  /// In en, this message translates to:
  /// **'Save Count'**
  String get inventoryAdjustSave;

  /// No description provided for @inventoryCurrentOnHand.
  ///
  /// In en, this message translates to:
  /// **'Current on hand: {quantity} {unit}'**
  String inventoryCurrentOnHand(int quantity, String unit);

  /// No description provided for @inventoryAfterRefill.
  ///
  /// In en, this message translates to:
  /// **'After refill: {quantity}'**
  String inventoryAfterRefill(int quantity);

  /// No description provided for @inventoryFullBottle.
  ///
  /// In en, this message translates to:
  /// **'Full bottle: {quantity}'**
  String inventoryFullBottle(int quantity);

  /// No description provided for @inventoryHalfPack.
  ///
  /// In en, this message translates to:
  /// **'Half pack: {quantity}'**
  String inventoryHalfPack(int quantity);

  /// No description provided for @medFormExtendedRelease.
  ///
  /// In en, this message translates to:
  /// **'Extended Release'**
  String get medFormExtendedRelease;

  /// No description provided for @medRouteOral.
  ///
  /// In en, this message translates to:
  /// **'Oral'**
  String get medRouteOral;

  /// No description provided for @medRouteSubcutaneous.
  ///
  /// In en, this message translates to:
  /// **'Subcutaneous'**
  String get medRouteSubcutaneous;

  /// No description provided for @medConditionDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get medConditionDiabetes;

  /// No description provided for @medConditionType2Diabetes.
  ///
  /// In en, this message translates to:
  /// **'Type 2 Diabetes'**
  String get medConditionType2Diabetes;

  /// No description provided for @medConditionHighBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'High Blood Pressure'**
  String get medConditionHighBloodPressure;

  /// No description provided for @medConditionHypertension.
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get medConditionHypertension;

  /// No description provided for @medConditionHeartHealth.
  ///
  /// In en, this message translates to:
  /// **'Heart Health'**
  String get medConditionHeartHealth;

  /// No description provided for @medConditionHighCholesterol.
  ///
  /// In en, this message translates to:
  /// **'High Cholesterol'**
  String get medConditionHighCholesterol;

  /// No description provided for @medConditionBacterialInfection.
  ///
  /// In en, this message translates to:
  /// **'Bacterial Infection'**
  String get medConditionBacterialInfection;

  /// No description provided for @medConditionPainInflammation.
  ///
  /// In en, this message translates to:
  /// **'Pain & Inflammation'**
  String get medConditionPainInflammation;

  /// No description provided for @medConditionBoneHealth.
  ///
  /// In en, this message translates to:
  /// **'Bone Health'**
  String get medConditionBoneHealth;

  /// No description provided for @medConditionAcidReflux.
  ///
  /// In en, this message translates to:
  /// **'Acid Reflux'**
  String get medConditionAcidReflux;

  /// No description provided for @addMedDailyDose.
  ///
  /// In en, this message translates to:
  /// **'Daily Dose'**
  String get addMedDailyDose;

  /// No description provided for @addMedCommonFor.
  ///
  /// In en, this message translates to:
  /// **'Common for: {condition}'**
  String addMedCommonFor(String condition);

  /// No description provided for @addManualColorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get addManualColorWhite;

  /// No description provided for @addManualColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get addManualColorYellow;

  /// No description provided for @addManualColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get addManualColorPink;

  /// No description provided for @addManualColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get addManualColorBlue;

  /// No description provided for @addManualColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get addManualColorOrange;

  /// No description provided for @addManualColorPeach.
  ///
  /// In en, this message translates to:
  /// **'Peach'**
  String get addManualColorPeach;

  /// No description provided for @addManualColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get addManualColorGreen;

  /// No description provided for @addManualDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved — complete it later!'**
  String get addManualDraftSaved;

  /// No description provided for @addMedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedTitle;

  /// No description provided for @addManualRxVerified.
  ///
  /// In en, this message translates to:
  /// **'RX VERIFIED'**
  String get addManualRxVerified;

  /// No description provided for @medsMedicationDetails.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION DETAILS'**
  String get medsMedicationDetails;

  /// No description provided for @medsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medsFieldName;

  /// No description provided for @medsFieldStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get medsFieldStrength;

  /// No description provided for @medsFieldForm.
  ///
  /// In en, this message translates to:
  /// **'Medication Form'**
  String get medsFieldForm;

  /// No description provided for @addManualSelectForm.
  ///
  /// In en, this message translates to:
  /// **'Select form'**
  String get addManualSelectForm;

  /// No description provided for @addManualColorOptional.
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get addManualColorOptional;

  /// No description provided for @medsFieldInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get medsFieldInstructions;

  /// No description provided for @addManualOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get addManualOptional;

  /// No description provided for @addManualInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Take with food after breakfast, avoid grapefruit...'**
  String get addManualInstructionsHint;

  /// No description provided for @addManualContinueToSchedule.
  ///
  /// In en, this message translates to:
  /// **'Continue to Schedule →'**
  String get addManualContinueToSchedule;

  /// No description provided for @addManualSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get addManualSaveDraft;

  /// No description provided for @addManualNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter medication name'**
  String get addManualNameHint;

  /// No description provided for @addManualMatchesIndex.
  ///
  /// In en, this message translates to:
  /// **'Matches clinical index'**
  String get addManualMatchesIndex;

  /// No description provided for @addManualStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get addManualStrengthHint;

  /// No description provided for @addManualFormOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addManualFormOther;

  /// No description provided for @addManualFormOtherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter another medication form'**
  String get addManualFormOtherSubtitle;

  /// No description provided for @addManualCustomForm.
  ///
  /// In en, this message translates to:
  /// **'Custom Medication Form'**
  String get addManualCustomForm;

  /// No description provided for @addManualCustomFormHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cream, Inhaler, Patch, Spray...'**
  String get addManualCustomFormHint;

  /// No description provided for @addManualCustomFormRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the medication form'**
  String get addManualCustomFormRequired;

  /// No description provided for @addManualInteractionTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Interaction Checks'**
  String get addManualInteractionTitle;

  /// No description provided for @addManualInteractionBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll cross-reference this dosage against your existing logged medications in the next step.'**
  String get addManualInteractionBody;

  /// No description provided for @addMedSelected.
  ///
  /// In en, this message translates to:
  /// **'{name} {strength} selected — details next!'**
  String addMedSelected(String name, String strength);

  /// No description provided for @addMedPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'Private and encrypted on this device'**
  String get addMedPrivateNote;

  /// No description provided for @addMedScanLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan Label'**
  String get addMedScanLabel;

  /// No description provided for @addMedSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get addMedSearch;

  /// No description provided for @addMedManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get addMedManualEntry;

  /// No description provided for @addMedMatchingCount.
  ///
  /// In en, this message translates to:
  /// **'Matching Medications ({count})'**
  String addMedMatchingCount(int count);

  /// No description provided for @addMedFdaApproved.
  ///
  /// In en, this message translates to:
  /// **'FDA Approved'**
  String get addMedFdaApproved;

  /// No description provided for @addMedTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip: Look for the imprint'**
  String get addMedTipTitle;

  /// No description provided for @addMedTipBody.
  ///
  /// In en, this message translates to:
  /// **'Most Metformin tablets have numbers like \'500\' or \'M\' pressed on the front to guarantee the exact dosage match.'**
  String get addMedTipBody;

  /// No description provided for @addMedCantFind.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your medication?'**
  String get addMedCantFind;

  /// No description provided for @addMedAddManually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get addMedAddManually;

  /// No description provided for @addMedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search for a medication'**
  String get addMedEmptyTitle;

  /// No description provided for @addMedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a medicine name above or scan its label'**
  String get addMedEmptySubtitle;

  /// No description provided for @addMedNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No medications found'**
  String get addMedNoResultsTitle;

  /// No description provided for @addMedNoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String addMedNoResultsFor(String query);

  /// No description provided for @addMedSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select ›'**
  String get addMedSelectAction;

  /// No description provided for @reviewScanNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the medication name.'**
  String get reviewScanNameRequired;

  /// No description provided for @reviewScanStrengthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the medication strength.'**
  String get reviewScanStrengthRequired;

  /// No description provided for @reviewScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Scan'**
  String get reviewScanTitle;

  /// No description provided for @scanCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Capture failed — try again.'**
  String get scanCaptureFailed;

  /// No description provided for @scanCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Could not capture image. Try again.'**
  String get scanCaptureError;

  /// No description provided for @scanGalleryError.
  ///
  /// In en, this message translates to:
  /// **'Could not open image. Try again.'**
  String get scanGalleryError;

  /// No description provided for @scanDetectedOne.
  ///
  /// In en, this message translates to:
  /// **'✓ Detected: {name}'**
  String scanDetectedOne(String name);

  /// No description provided for @scanDetectedCount.
  ///
  /// In en, this message translates to:
  /// **'✓ {count} medicines detected'**
  String scanDetectedCount(int count);

  /// No description provided for @scanTextNoMedicine.
  ///
  /// In en, this message translates to:
  /// **'Text was detected, but medicine details could not be identified.'**
  String get scanTextNoMedicine;

  /// No description provided for @scanNoText.
  ///
  /// In en, this message translates to:
  /// **'No text detected. Keep the document clear, flat and well lit.'**
  String get scanNoText;

  /// No description provided for @scanReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the image. Try again.'**
  String get scanReadError;

  /// No description provided for @scanRescanAgain.
  ///
  /// In en, this message translates to:
  /// **'Please scan the medicine again.'**
  String get scanRescanAgain;

  /// No description provided for @scanFitFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Fit the medicine label or full prescription inside the frame'**
  String get scanFitFrameHint;

  /// No description provided for @scanEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter medication manually'**
  String get scanEnterManually;

  /// No description provided for @scanRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get scanRetakePhoto;

  /// No description provided for @scanReadingPrescription.
  ///
  /// In en, this message translates to:
  /// **'Reading prescription...'**
  String get scanReadingPrescription;

  /// No description provided for @scanStatusReading.
  ///
  /// In en, this message translates to:
  /// **'READING'**
  String get scanStatusReading;

  /// No description provided for @scanStatusFound.
  ///
  /// In en, this message translates to:
  /// **'FOUND'**
  String get scanStatusFound;

  /// No description provided for @scanStatusInFrame.
  ///
  /// In en, this message translates to:
  /// **'IN FRAME'**
  String get scanStatusInFrame;

  /// No description provided for @scanStatusReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get scanStatusReady;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get scanCameraUnavailable;

  /// No description provided for @scanStartingCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting camera...'**
  String get scanStartingCamera;

  /// No description provided for @scanCapturingDocument.
  ///
  /// In en, this message translates to:
  /// **'Capturing document...'**
  String get scanCapturingDocument;

  /// No description provided for @scanReadingMedicineText.
  ///
  /// In en, this message translates to:
  /// **'Reading medicine text...'**
  String get scanReadingMedicineText;

  /// No description provided for @scanMedicineDetected.
  ///
  /// In en, this message translates to:
  /// **'Medicine detected'**
  String get scanMedicineDetected;

  /// No description provided for @scanMedicinesDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} medicines detected'**
  String scanMedicinesDetected(int count);

  /// No description provided for @scanImageCaptured.
  ///
  /// In en, this message translates to:
  /// **'Image captured'**
  String get scanImageCaptured;

  /// No description provided for @scanMedicineOrRxDetected.
  ///
  /// In en, this message translates to:
  /// **'Medicine or prescription detected'**
  String get scanMedicineOrRxDetected;

  /// No description provided for @scanPointCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Point camera at medicine or prescription'**
  String get scanPointCameraHint;

  /// No description provided for @scanFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get scanFlash;

  /// No description provided for @scanShutter.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanShutter;

  /// No description provided for @scanGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get scanGallery;

  /// No description provided for @scanTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get scanTryAgain;

  /// No description provided for @scanMedicineBadgeNumber.
  ///
  /// In en, this message translates to:
  /// **'MEDICINE {index} DETECTED'**
  String scanMedicineBadgeNumber(int index);

  /// No description provided for @scanMedicineBadgeSingular.
  ///
  /// In en, this message translates to:
  /// **'MEDICINE DETECTED'**
  String get scanMedicineBadgeSingular;

  /// No description provided for @scanFieldStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get scanFieldStrength;

  /// No description provided for @scanFieldForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get scanFieldForm;

  /// No description provided for @scanFieldFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get scanFieldFrequency;

  /// No description provided for @medsFieldInstructionsShort.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get medsFieldInstructionsShort;

  /// No description provided for @scanReviewAdd.
  ///
  /// In en, this message translates to:
  /// **'Review & Add Medication'**
  String get scanReviewAdd;

  /// No description provided for @stepSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get stepSchedule;

  /// No description provided for @reviewScanScanned.
  ///
  /// In en, this message translates to:
  /// **'SCANNED'**
  String get reviewScanScanned;

  /// No description provided for @reviewScanReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'We\'ve read these details from your label — check and correct if needed!'**
  String get reviewScanReadSuccess;

  /// No description provided for @reviewScanInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter medication instructions'**
  String get reviewScanInstructionsHint;

  /// No description provided for @reviewScanStrengthUnclear.
  ///
  /// In en, this message translates to:
  /// **'Strength field was unclear in the photo — please verify manually.'**
  String get reviewScanStrengthUnclear;

  /// No description provided for @reviewScanRequired.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get reviewScanRequired;

  /// No description provided for @reviewScanStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Enter strength e.g. 500mg'**
  String get reviewScanStrengthHint;

  /// No description provided for @reviewScanConfirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Continue →'**
  String get reviewScanConfirmContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
