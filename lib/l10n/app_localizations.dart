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
