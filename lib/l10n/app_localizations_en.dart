// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String comingSoon(String title) {
    return '$title — coming soon';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get navHome => 'Home';

  @override
  String get navMeds => 'Meds';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupPreferences => 'Preferences';

  @override
  String get settingsGroupAccountPlan => 'Account & Plan';

  @override
  String get settingsGroupSupportLegal => 'Support & Legal';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsTrailing => 'Chime & Vibrate';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageTrailing => 'English (US)';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsPrivacySecurity => 'Privacy & Security';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsDataExport => 'Data Export';

  @override
  String get settingsDataExportTrailing => 'CSV & PDF';

  @override
  String get settingsHelpSupport => 'Help & Support';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutTrailing => 'v1.2.0';

  @override
  String get settingsPro => 'PRO';

  @override
  String get settingsCaregiverSync => 'Caregiver Sync Active';

  @override
  String get settingsLogoutTitle => 'Log out?';

  @override
  String get settingsLogoutMessage =>
      'You will need to sign in again to access your care plan.';

  @override
  String get settingsLogOut => 'Log Out';

  @override
  String get settingsLogoutComingSoon => 'Log Out — coming soon';

  @override
  String get settingsFooterVersion =>
      'MedRemind Care Health Suite • v1.2.0 (Build 412)';

  @override
  String get settingsHipaa => 'HIPAA Compliant & Encrypted';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageNote =>
      'The app updates instantly after selecting a language.';

  @override
  String get languageDeviceDefault =>
      'Device default: System Language (English - US)';

  @override
  String get homeGreetingMorning => 'Good Morning';

  @override
  String get homeGreetingAfternoon => 'Good Afternoon';

  @override
  String get homeGreetingEvening => 'Good Evening';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting, $name 👋';
  }

  @override
  String homeDayStreak(int days) {
    return '$days Day Streak';
  }

  @override
  String get homeAdd => 'Add';

  @override
  String get homeTodaySchedule => 'Today\'s Schedule';

  @override
  String get homeFilterAll => 'All';

  @override
  String get homeFilterPending => 'Pending';

  @override
  String get homeFilterTaken => 'Taken';

  @override
  String get homeDaily => 'Daily';

  @override
  String homeStatTaken(int count) {
    return '$count Taken';
  }

  @override
  String homeStatPending(int count) {
    return '$count Pending';
  }

  @override
  String homeStatMissed(int count) {
    return '$count Missed';
  }

  @override
  String get homeQuickAccess => 'QUICK ACCESS';

  @override
  String get homeShortcuts => 'Shortcuts';

  @override
  String get homeQuickVitals => 'Vitals';

  @override
  String get homeQuickDoctors => 'Doctors';

  @override
  String get homeQuickAI => 'AI Assist';

  @override
  String get homeQuickFamily => 'Family';

  @override
  String homeScreenComingSoon(String name) {
    return '$name screen coming next.';
  }

  @override
  String homeMarkedTaken(String name) {
    return '$name marked as taken ✓';
  }

  @override
  String homeMarkedUntaken(String name) {
    return '$name marked as untaken 🔄';
  }

  @override
  String homeSkipped(String name) {
    return '$name skipped';
  }

  @override
  String homeSkippedReason(String name, String reason) {
    return '$name skipped — $reason';
  }

  @override
  String homeSnoozed(String name, int minutes) {
    return '$name snoozed — reminder again in $minutes min';
  }

  @override
  String homeSwitchedMember(String name) {
    return 'Switched to $name\'s medicines';
  }

  @override
  String get homeActionTaken => 'Taken';

  @override
  String get homeActionSkip => 'Skip';

  @override
  String get homeActionSnooze => 'Snooze';

  @override
  String get homeStatusPending => 'PENDING';

  @override
  String get homeStatusTaken => 'TAKEN';

  @override
  String get homeStatusUpcoming => 'UPCOMING';

  @override
  String get homeStatusSkipped => 'SKIPPED';

  @override
  String homeRunningLow(String name, int days) {
    return '$name running low · $days days left';
  }

  @override
  String get homeRefill => 'Refill →';

  @override
  String get homeSkippedNote => 'Skipped — reminder will come again tomorrow';

  @override
  String get doseFormTablet => 'Tablet';

  @override
  String get doseFormLiquid => 'Liquid';

  @override
  String get doseScheduleDaily => '1x daily';

  @override
  String get doseScheduleBeforeBreakfast => 'Before breakfast';

  @override
  String get doseScheduleAfterBreakfast => 'After breakfast';

  @override
  String get doseScheduleWithDinner => 'With dinner';

  @override
  String doseDueSoon(String time) {
    return '$time · Due soon';
  }

  @override
  String get doseMarkTaken => 'Mark as Taken';

  @override
  String get doseMarkUntaken => 'Mark as Untaken';

  @override
  String get doseHideReason => 'Hide Reason';

  @override
  String get doseSkipDose => 'Skip Dose';

  @override
  String get doseSnoozeFor => 'SNOOZE FOR';

  @override
  String get doseReasonLabel => 'Reason (optional)';

  @override
  String get doseReasonHint => 'e.g., Feeling nauseous';

  @override
  String get doseConfirmSkip => 'Confirm Skip';

  @override
  String get dataExportTitle => 'Data Export';

  @override
  String get dataExportHeroTitle => 'Export All My Data';

  @override
  String get dataExportHeroSubtitle =>
      'Get a complete copy of everything stored in your account.';

  @override
  String get dataExportBadge => 'Encrypted GDPR & HIPAA standard export';

  @override
  String get dataExportIncludedTitle => 'What\'s Included';

  @override
  String get dataExportModules => '4 Modules';

  @override
  String get dataExportIncludedProfiles => 'All profiles & medications';

  @override
  String get dataExportIncludedDoses => 'Complete dose history & adherence';

  @override
  String get dataExportIncludedVitals => 'Vitals, symptoms & notes';

  @override
  String get dataExportIncludedPrescribers =>
      'Prescribers, appointments & pharmacies';

  @override
  String dataExportFormatNote(String formats) {
    return 'You\'ll receive a ZIP archive ($formats) via email within 24 hours.';
  }

  @override
  String get dataExportFormats => 'JSON + CSV';

  @override
  String dataExportSentTo(String email) {
    return 'Sent directly to $email';
  }

  @override
  String get dataExportRequest => 'Request Export';

  @override
  String get dataExportGenerating => 'Generating Package...';

  @override
  String get dataExportSubmitted => 'Request Submitted';

  @override
  String get dataExportSuccessTitle => 'Export Requested!';

  @override
  String get dataExportSuccessMessage =>
      'We\'re preparing your raw data archive. You will receive a direct link once compilation completes.';

  @override
  String get dataExportQueued => 'Queued in server batch';

  @override
  String get dataExportLastExportNever => 'Last export: Never';

  @override
  String dataExportLastExportNow(String timestamp) {
    return 'Last export: Just now ($timestamp)';
  }

  @override
  String dataExportRetentionId(String id) {
    return 'Account records retention ID: $id';
  }

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get helpSupportSearchHint => 'Search FAQ...';

  @override
  String get helpSupportNoResults => 'No matching articles.';

  @override
  String get helpSupportBannerTitle => 'Caregiver & Patient Desk';

  @override
  String get helpSupportBannerSubtitle =>
      'We\'re here to keep your routines on schedule.';

  @override
  String get helpSupportFaqHeader => 'Frequently Asked';

  @override
  String helpSupportFaqCount(int count) {
    return '$count articles';
  }

  @override
  String get helpSupportStillNeedHelp => 'Still Need Help?';

  @override
  String get helpSupportLiveOnline => 'Live Team Online';

  @override
  String get helpSupportEmailSupport => 'Email Support';

  @override
  String get helpSupportEmailAction => 'Email';

  @override
  String get helpSupportSubmitRequest => 'Submit a Request';

  @override
  String get helpSupportResponseTime => 'Average response under 2 hours';

  @override
  String get helpSupportHelpful => 'Was this page helpful?';

  @override
  String get helpSupportYes => 'Yes';

  @override
  String get helpSupportNo => 'No';

  @override
  String get helpSupportFeedbackThanks => 'Thanks for your feedback!';

  @override
  String get helpSupportVersion => 'MedRemind v1.2.0 (build 245)';

  @override
  String get helpSupportCompliance =>
      'Encrypted Caregiver Network • HIPAA Compliant';

  @override
  String helpSupportEmailClipped(String email) {
    return 'Email us at $email';
  }

  @override
  String get faqQ1 => 'How do I change a dose time?';

  @override
  String get faqA1 =>
      'Open your Schedule or Medication tab, tap the specific medication card, select Edit Schedule, and adjust your dosage alerts. Changes sync instantly across caregiver devices.';

  @override
  String get faqQ2 => 'Why didn\'t I get a reminder?';

  @override
  String get faqA2 =>
      'Ensure battery optimization is disabled for MedRemind in phone Settings. Also verify that Critical Alerts and notification permissions are granted in your operating system settings.';

  @override
  String get faqQ3 => 'How do caregiver alerts work?';

  @override
  String get faqA3 =>
      'Caregivers receive silent affirmations when medicines are logged. If a crucial dose is missed for over 30 minutes, an escalated notification is automatically sent to the primary caregiver.';

  @override
  String get faqQ4 => 'How do I add a family member?';

  @override
  String get faqA4 =>
      'Go to Profiles, tap Add, then send an invite by email or phone. They accept the link to connect.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutAppName => 'MedRemind';

  @override
  String get aboutVersion => 'Version 1.2.0 (build 245)';

  @override
  String get aboutUpToDate => 'UP TO DATE ✓';

  @override
  String get aboutTerms => 'Terms of Service';

  @override
  String get aboutPrivacy => 'Privacy Policy';

  @override
  String get aboutLicenses => 'Open Source Licenses';

  @override
  String get aboutCredits => 'Credits';

  @override
  String get aboutCreditsDesign => 'Design';

  @override
  String get aboutCreditsDesignValue => 'MedRemind Team';

  @override
  String get aboutCreditsDrugData => 'Drug data';

  @override
  String get aboutCreditsDrugDataValue => 'RxNorm · OpenFDA';

  @override
  String get aboutCreditsIcons => 'Icons';

  @override
  String get aboutCreditsIconsValue => 'Open source sets';

  @override
  String get aboutFooter =>
      'Made with care for families managing health together.';

  @override
  String get aboutLegalBody1 =>
      'MedRemind is committed to high clinical accuracy and compassionate design. Our data sources conform strictly to standards published by the National Library of Medicine (RxNorm) and the FDA regulatory database.';

  @override
  String get aboutLegalBody2 =>
      'All pill recognition heuristics, caregiver dispatch alerts, and dosage logs remain cryptographically bound to your designated family vault. Health parameters are not monetized or shared with third-party advertisers.';

  @override
  String get aboutLegalComplianceTitle => 'Compliance & Audits';

  @override
  String get aboutLegalComplianceValue =>
      'SOC-2 Type II Certified · HIPAA Security Safeguards · Verified 2025';

  @override
  String get aboutDone => 'Done';

  @override
  String get upgradeTitle => 'Upgrade';

  @override
  String get upgradePlanStatus => 'Free Plan • Ready to expand';

  @override
  String get upgradeProGated => 'Pro Gated';

  @override
  String get upgradeHeroTitle => 'Unlock the full power of MedRemind';

  @override
  String get upgradeHeroSubtitle =>
      'Interactions, refills, reports & family sharing';

  @override
  String get upgradeUnlockHeader => 'What you\'ll unlock';

  @override
  String get upgradeUnlockInteractions => 'Drug interaction & allergy checking';

  @override
  String get upgradeUnlockRefills => 'Inventory tracking & refill alerts';

  @override
  String get upgradeUnlockReports => 'PDF/CSV reports for your doctor';

  @override
  String get upgradeUnlockFamily => 'Family linking — up to 5 profiles';

  @override
  String get upgradeSeeComparison => 'See full comparison breakdown';

  @override
  String get upgradeChoosePlan => 'Choose your plan';

  @override
  String get upgradeFreeTrial => '7-Day Free Trial';

  @override
  String get upgradeMonthly => 'Monthly';

  @override
  String get upgradeAnnual => 'Annual';

  @override
  String get upgradeSaveBadge => 'Save 52%';

  @override
  String get upgradePlanSoloName => 'Solo Pro';

  @override
  String get upgradePlanSoloSubtitle => 'Everything for one person';

  @override
  String get upgradePlanFamilyName => 'Family Pro';

  @override
  String get upgradePlanFamilySubtitle =>
      'Up to 5 linked profiles + caregiver alerts';

  @override
  String get upgradePopular => 'Popular';

  @override
  String get upgradeSelected => 'Selected';

  @override
  String upgradePriceAnnual(String price) {
    return '$price/yr';
  }

  @override
  String upgradePriceMonthly(String price) {
    return '$price/mo';
  }

  @override
  String upgradeWasPrice(String price) {
    return 'was $price';
  }

  @override
  String get upgradeStartTrial => 'Start 7-Day Free Trial';

  @override
  String get upgradeNothingDue => 'Nothing due today. Reminder sent on Day 5.';

  @override
  String get upgradeCompareAll => 'Compare all features & plans';

  @override
  String get upgradeRestorePurchase => 'Restore Purchase';

  @override
  String get upgradeLegalNote =>
      'Cancel anytime in App Store settings at least 24 hours before trial ends. Plan auto-renews until cancelled.';

  @override
  String get upgradeComparisonTitle => 'Full Plan Comparison';

  @override
  String get upgradeComparisonContinue => 'Continue with Selected Plan';

  @override
  String get upgradeFeatureReminders => 'Medication Reminders';

  @override
  String get upgradeFeatureRemindersValue => 'Free & Pro (Unlimited)';

  @override
  String get upgradeFeatureInteractions => 'Drug Interactions Checker';

  @override
  String get upgradeFeatureRefills => 'Refill Smart Alerts';

  @override
  String get upgradeFeatureReports => 'Doctor PDF Health Exports';

  @override
  String get upgradeFeatureFamily => 'Family & Caregiver Sync';

  @override
  String get upgradeValuePro => 'Pro Exclusive';

  @override
  String get upgradeValueFamily => 'Family Pro Only';

  @override
  String get upgradeRestoreToast =>
      'Restoring purchases... No prior subscriptions found.';

  @override
  String upgradeTrialToast(String plan, String cadence) {
    return 'Starting 7-day trial for $plan ($cadence)';
  }

  @override
  String get compareTitle => 'Compare Plans';

  @override
  String get compareGuarantee => '30-Day Money Back Guarantee';

  @override
  String get compareAnnualSave => 'Annual Save 40%';

  @override
  String get compareColFeatures => 'Features';

  @override
  String get compareColFree => 'Free';

  @override
  String get compareFreeSubtitle => 'Starter';

  @override
  String get compareColSolo => 'Solo';

  @override
  String get compareSoloSubtitle => 'Most Loved';

  @override
  String get compareColFamily => 'Family';

  @override
  String get compareFamilySubtitle => 'Full Care';

  @override
  String get comparePriceLabel => 'Price';

  @override
  String get compareBilledYearly => 'Billed yearly';

  @override
  String get compareForever => 'forever';

  @override
  String get comparePerYear => '/year';

  @override
  String get compareGroupDaily => 'Daily Medication Tools';

  @override
  String get compareGroupClinical => 'Clinical Safety & Tracking';

  @override
  String get compareGroupFamily => 'Family & Caregiver Circle';

  @override
  String get compareFeatUnlimitedMeds => 'Unlimited meds & reminders';

  @override
  String get compareFeatAdherence => 'Adherence calendar & streaks';

  @override
  String get compareFeatInteractions => 'Interaction & allergy checks';

  @override
  String get compareFeatInventory => 'Inventory & refill alerts';

  @override
  String get compareFeatDoctorTools => 'Doctor & appointment tools';

  @override
  String get compareFeatReports => 'PDF/CSV health reports';

  @override
  String get compareFeatHealthSync => 'Apple Health & Fit sync';

  @override
  String get compareFeatFamilyLinking => 'Family linking (up to 5)';

  @override
  String get compareFeatMissedDose => 'Missed-dose caregiver alert';

  @override
  String get compareFeatFamilyDashboard => 'Combined family dashboard';

  @override
  String get compareQuote =>
      '“Caregiver alerts gave me total peace of mind for mom.”';

  @override
  String get compareQuoteAuthor => '— Sarah M., Family Pro Subscriber';

  @override
  String get compareChooseSolo => 'Choose Solo Pro';

  @override
  String get compareChooseFamily => 'Choose Family Pro';

  @override
  String get compareContinueFree => 'Continue with Free basic plan';

  @override
  String get compareFreeSelected => 'Free basic plan selected';

  @override
  String get compareFinePrint =>
      'Prices shown for annual billing. Monthly plans also available at checkout. Cancel anytime with zero hassle.';

  @override
  String get compareEncrypted => '256-bit Encrypted';

  @override
  String get compareAutoSync => 'Auto-sync';

  @override
  String get compareHipaaReady => 'HIPAA Ready';

  @override
  String get paymentTitle => 'Payment Successful';

  @override
  String get paymentProNowTitle => 'You\'re Pro now!';

  @override
  String paymentWelcome(String plan, String name) {
    return 'Welcome to $plan, $name. All Pro features are unlocked.';
  }

  @override
  String get paymentPlanActive => 'Plan Active • Unlimited Care Sync';

  @override
  String get paymentOrderSummary => 'Order Summary';

  @override
  String get paymentTrialActive => 'Trial Active';

  @override
  String get paymentPlanLabel => 'Plan';

  @override
  String get paymentFreeTrialLabel => 'Free trial';

  @override
  String paymentFreeTrialValue(String price) {
    return '7 days — then $price';
  }

  @override
  String get paymentNextBillingLabel => 'Next billing date';

  @override
  String get paymentReceipt => 'Receipt';

  @override
  String get paymentOrderIdLabel => 'Order ID';

  @override
  String get paymentPaymentMethodLabel => 'Payment method';

  @override
  String get paymentReceiptSentLabel => 'Receipt sent to';

  @override
  String get paymentViewFullReceipt => 'View full receipt';

  @override
  String get paymentStartPro => 'Start Using Pro';

  @override
  String get paymentUnlockNote =>
      'Interaction checks, refill alerts & reports are now active';
}
