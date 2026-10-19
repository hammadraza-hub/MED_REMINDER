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

  @override
  String get doctorsTitle => 'Doctors';

  @override
  String get doctorsAdd => 'Add Doctor';

  @override
  String get doctorsAdded => 'Doctor added successfully';

  @override
  String doctorsCountOnFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doctors on file',
      one: '1 doctor on file',
    );
    return '$_temp0';
  }

  @override
  String get doctorsEmptyTitle => 'No doctors on file';

  @override
  String get doctorsEmptySubtitle => 'Add a doctor to link prescriptions';

  @override
  String get doctorsUpcomingVisits => 'Upcoming Visits';

  @override
  String doctorsAppointmentsScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointments scheduled',
      one: '1 appointment scheduled',
    );
    return '$_temp0';
  }

  @override
  String get doctorsView => 'View →';

  @override
  String get doctorsHint => 'Tap a doctor to view details or edit';

  @override
  String doctorsMedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meds',
      one: '1 med',
    );
    return '$_temp0';
  }

  @override
  String get doctorsDetailsSection => 'DOCTOR DETAILS';

  @override
  String get doctorsFieldFullName => 'Full Name *';

  @override
  String get doctorsHintFullName => 'Enter full name';

  @override
  String get doctorsFieldSpecialty => 'Specialty';

  @override
  String get doctorsHintSpecialty => 'Enter specialty';

  @override
  String get doctorsFieldPhone => 'Phone Number';

  @override
  String get doctorsHintPhone => 'Enter phone number';

  @override
  String get doctorsFieldClinic => 'Clinic / Address (optional)';

  @override
  String get doctorsHintClinic => 'Enter clinic or address';

  @override
  String get doctorsLinkMedications => 'LINK TO MEDICATIONS';

  @override
  String get doctorsLinkPrompt =>
      'Which medications does this doctor prescribe?';

  @override
  String get doctorsSave => 'Save Doctor';

  @override
  String get doctorsNameRequired => 'Please enter the doctor\'s full name.';

  @override
  String get medsTitle => 'Medications';

  @override
  String medsMemberMedications(String name) {
    return '$name\'s Medications';
  }

  @override
  String medsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active medications',
      one: '1 active medication',
    );
    return '$_temp0';
  }

  @override
  String get medsManageHeader => 'MANAGE';

  @override
  String get medsQuickTools => 'Quick Tools';

  @override
  String get medsInventory => 'Inventory';

  @override
  String medsLowBadge(int count) {
    return '$count LOW';
  }

  @override
  String get medsAllergies => 'Allergies';

  @override
  String get medsSideEffects => 'Side Effects';

  @override
  String get medsPharmacy => 'Pharmacy';

  @override
  String get medsSearchHint => 'Search medications...';

  @override
  String medsTabActive(int count) {
    return 'Active ($count)';
  }

  @override
  String medsTabArchived(int count) {
    return 'Archived ($count)';
  }

  @override
  String get medsEmptyArchived => 'No archived medicines';

  @override
  String get medsEmpty => 'No medicines found';

  @override
  String medsMovedToArchived(String name) {
    return '$name moved to Archived';
  }

  @override
  String get medsDiscontinueError =>
      'Could not discontinue medication. Please try again.';

  @override
  String get medsDiscontinueBarrierLabel => 'Close discontinue medication';

  @override
  String get medsDiscontinue => 'Discontinue';

  @override
  String get medsLowStock => 'LOW STOCK';

  @override
  String get medsBadgeActive => 'ACTIVE';

  @override
  String get medsScheduleNotSet => 'Schedule not set';

  @override
  String get medsFrequencyAsNeeded => 'As needed';

  @override
  String medsFrequencySelectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x on selected days',
      one: '1x on selected days',
    );
    return '$_temp0';
  }

  @override
  String medsFrequencyCyclical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x cyclical',
      one: '1x cyclical',
    );
    return '$_temp0';
  }

  @override
  String get medsFrequencyTapering => 'Tapering schedule';

  @override
  String medsFrequencyDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x daily',
      one: '1x daily',
    );
    return '$_temp0';
  }

  @override
  String medsNextDoseTomorrow(String time) {
    return 'Tomorrow $time';
  }

  @override
  String medsNextDoseWeekday(String day, String time) {
    return '$day $time';
  }

  @override
  String medsEnds(String date) {
    return 'Ends $date';
  }

  @override
  String medsNext(String time) {
    return 'Next: $time';
  }

  @override
  String get medsWeekdayMon => 'Mon';

  @override
  String get medsWeekdayTue => 'Tue';

  @override
  String get medsWeekdayWed => 'Wed';

  @override
  String get medsWeekdayThu => 'Thu';

  @override
  String get medsWeekdayFri => 'Fri';

  @override
  String get medsWeekdaySat => 'Sat';

  @override
  String get medsWeekdaySun => 'Sun';

  @override
  String get medsFormCapsule => 'Capsule';

  @override
  String get medsFormDrops => 'Drops';

  @override
  String get medsFormInjection => 'Injection';

  @override
  String medsDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String medsDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String medsUnitTablet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tablets',
      one: 'tablet',
    );
    return '$_temp0';
  }

  @override
  String medsUnitCapsule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'capsules',
      one: 'capsule',
    );
    return '$_temp0';
  }

  @override
  String medsUnitBottle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bottles',
      one: 'bottle',
    );
    return '$_temp0';
  }

  @override
  String medsUnitDose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'doses',
      one: 'dose',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String inventoryMedicationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Medications',
      one: '1 Medication',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTrackedSupply => 'Tracked supply';

  @override
  String inventoryLowStockCount(int count) {
    return '$count LOW STOCK';
  }

  @override
  String get inventoryFilterAll => 'All';

  @override
  String get inventoryFilterLow => 'Low Stock';

  @override
  String get inventoryFilterOk => 'OK';

  @override
  String get inventoryEmptyFilter => 'No medications in this filter';

  @override
  String get inventoryStatusLow => 'LOW';

  @override
  String get inventoryStatusOk => 'OK';

  @override
  String get inventoryRunningLow => 'Running low — order refill';

  @override
  String get inventoryRefill => 'Refill →';

  @override
  String get inventoryAdjustCount => 'Adjust Count';

  @override
  String get inventorySufficient => 'Sufficient supply';

  @override
  String get inventorySufficientNext => 'Sufficient through next refill';

  @override
  String get inventoryEdit => 'Edit';

  @override
  String get inventoryAutoSyncTitle => 'Auto-Sync Pharmacy';

  @override
  String get inventoryAutoSyncSubtitle =>
      'Connect your pharmacy for automatic refill updates';

  @override
  String get inventoryAutoSyncPending =>
      'Pharmacy auto-sync integration pending';

  @override
  String inventoryCountUpdated(String name, int count) {
    return '$name count updated to $count';
  }

  @override
  String inventorySupplyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count days',
      one: '~1 day',
    );
    return '$_temp0';
  }

  @override
  String get inventoryAdjustReasonLabel => 'Adjustment Reason (Optional)';

  @override
  String get inventoryAdjustReasonHint => 'Reason for adjustment (optional)...';

  @override
  String get inventoryAdjustSave => 'Save Count';

  @override
  String inventoryCurrentOnHand(int quantity, String unit) {
    return 'Current on hand: $quantity $unit';
  }

  @override
  String inventoryAfterRefill(int quantity) {
    return 'After refill: $quantity';
  }

  @override
  String inventoryFullBottle(int quantity) {
    return 'Full bottle: $quantity';
  }

  @override
  String inventoryHalfPack(int quantity) {
    return 'Half pack: $quantity';
  }

  @override
  String get medFormExtendedRelease => 'Extended Release';

  @override
  String get medRouteOral => 'Oral';

  @override
  String get medRouteSubcutaneous => 'Subcutaneous';

  @override
  String get medConditionDiabetes => 'Diabetes';

  @override
  String get medConditionType2Diabetes => 'Type 2 Diabetes';

  @override
  String get medConditionHighBloodPressure => 'High Blood Pressure';

  @override
  String get medConditionHypertension => 'Hypertension';

  @override
  String get medConditionHeartHealth => 'Heart Health';

  @override
  String get medConditionHighCholesterol => 'High Cholesterol';

  @override
  String get medConditionBacterialInfection => 'Bacterial Infection';

  @override
  String get medConditionPainInflammation => 'Pain & Inflammation';

  @override
  String get medConditionBoneHealth => 'Bone Health';

  @override
  String get medConditionAcidReflux => 'Acid Reflux';

  @override
  String get addMedDailyDose => 'Daily Dose';

  @override
  String addMedCommonFor(String condition) {
    return 'Common for: $condition';
  }

  @override
  String get addManualColorWhite => 'White';

  @override
  String get addManualColorYellow => 'Yellow';

  @override
  String get addManualColorPink => 'Pink';

  @override
  String get addManualColorBlue => 'Blue';

  @override
  String get addManualColorOrange => 'Orange';

  @override
  String get addManualColorPeach => 'Peach';

  @override
  String get addManualColorGreen => 'Green';

  @override
  String get addManualDraftSaved => 'Draft saved — complete it later!';

  @override
  String get addMedTitle => 'Add Medication';

  @override
  String get addManualRxVerified => 'RX VERIFIED';

  @override
  String get medsMedicationDetails => 'MEDICATION DETAILS';

  @override
  String get medsFieldName => 'Medication Name';

  @override
  String get medsFieldStrength => 'Strength';

  @override
  String get medsFieldForm => 'Medication Form';

  @override
  String get addManualSelectForm => 'Select form';

  @override
  String get addManualColorOptional => 'Color (optional)';

  @override
  String get medsFieldInstructions => 'Special Instructions';

  @override
  String get addManualOptional => 'Optional';

  @override
  String get addManualInstructionsHint =>
      'e.g. Take with food after breakfast, avoid grapefruit...';

  @override
  String get addManualContinueToSchedule => 'Continue to Schedule →';

  @override
  String get addManualSaveDraft => 'Save as Draft';

  @override
  String get addManualNameHint => 'Enter medication name';

  @override
  String get addManualMatchesIndex => 'Matches clinical index';

  @override
  String get addManualStrengthHint => 'e.g. 500';

  @override
  String get addManualFormOther => 'Other';

  @override
  String get addManualFormOtherSubtitle => 'Enter another medication form';

  @override
  String get addManualCustomForm => 'Custom Medication Form';

  @override
  String get addManualCustomFormHint => 'e.g. Cream, Inhaler, Patch, Spray...';

  @override
  String get addManualCustomFormRequired => 'Please enter the medication form';

  @override
  String get addManualInteractionTitle => 'Automatic Interaction Checks';

  @override
  String get addManualInteractionBody =>
      'We\'ll cross-reference this dosage against your existing logged medications in the next step.';

  @override
  String addMedSelected(String name, String strength) {
    return '$name $strength selected — details next!';
  }

  @override
  String get addMedPrivateNote => 'Private and encrypted on this device';

  @override
  String get addMedScanLabel => 'Scan Label';

  @override
  String get addMedSearch => 'Search';

  @override
  String get addMedManualEntry => 'Manual Entry';

  @override
  String addMedMatchingCount(int count) {
    return 'Matching Medications ($count)';
  }

  @override
  String get addMedFdaApproved => 'FDA Approved';

  @override
  String get addMedTipTitle => 'Tip: Look for the imprint';

  @override
  String get addMedTipBody =>
      'Most Metformin tablets have numbers like \'500\' or \'M\' pressed on the front to guarantee the exact dosage match.';

  @override
  String get addMedCantFind => 'Can\'t find your medication?';

  @override
  String get addMedAddManually => 'Add Manually';

  @override
  String get addMedEmptyTitle => 'Search for a medication';

  @override
  String get addMedEmptySubtitle =>
      'Enter a medicine name above or scan its label';

  @override
  String get addMedNoResultsTitle => 'No medications found';

  @override
  String addMedNoResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get addMedSelectAction => 'Select ›';

  @override
  String get reviewScanNameRequired => 'Please enter the medication name.';

  @override
  String get reviewScanStrengthRequired =>
      'Please enter the medication strength.';

  @override
  String get reviewScanTitle => 'Review Scan';

  @override
  String get scanCaptureFailed => 'Capture failed — try again.';

  @override
  String get scanCaptureError => 'Could not capture image. Try again.';

  @override
  String get scanGalleryError => 'Could not open image. Try again.';

  @override
  String scanDetectedOne(String name) {
    return '✓ Detected: $name';
  }

  @override
  String scanDetectedCount(int count) {
    return '✓ $count medicines detected';
  }

  @override
  String get scanTextNoMedicine =>
      'Text was detected, but medicine details could not be identified.';

  @override
  String get scanNoText =>
      'No text detected. Keep the document clear, flat and well lit.';

  @override
  String get scanReadError => 'Could not read the image. Try again.';

  @override
  String get scanRescanAgain => 'Please scan the medicine again.';

  @override
  String get scanFitFrameHint =>
      'Fit the medicine label or full prescription inside the frame';

  @override
  String get scanEnterManually => 'Enter medication manually';

  @override
  String get scanRetakePhoto => 'Retake Photo';

  @override
  String get scanReadingPrescription => 'Reading prescription...';

  @override
  String get scanStatusReading => 'READING';

  @override
  String get scanStatusFound => 'FOUND';

  @override
  String get scanStatusInFrame => 'IN FRAME';

  @override
  String get scanStatusReady => 'READY';

  @override
  String get scanCameraUnavailable => 'Camera unavailable';

  @override
  String get scanStartingCamera => 'Starting camera...';

  @override
  String get scanCapturingDocument => 'Capturing document...';

  @override
  String get scanReadingMedicineText => 'Reading medicine text...';

  @override
  String get scanMedicineDetected => 'Medicine detected';

  @override
  String scanMedicinesDetected(int count) {
    return '$count medicines detected';
  }

  @override
  String get scanImageCaptured => 'Image captured';

  @override
  String get scanMedicineOrRxDetected => 'Medicine or prescription detected';

  @override
  String get scanPointCameraHint => 'Point camera at medicine or prescription';

  @override
  String get scanFlash => 'Flash';

  @override
  String get scanShutter => 'Scan';

  @override
  String get scanGallery => 'Gallery';

  @override
  String get scanTryAgain => 'Try Again';

  @override
  String scanMedicineBadgeNumber(int index) {
    return 'MEDICINE $index DETECTED';
  }

  @override
  String get scanMedicineBadgeSingular => 'MEDICINE DETECTED';

  @override
  String get scanFieldStrength => 'Strength';

  @override
  String get scanFieldForm => 'Form';

  @override
  String get scanFieldFrequency => 'Frequency';

  @override
  String get medsFieldInstructionsShort => 'Instructions';

  @override
  String get scanReviewAdd => 'Review & Add Medication';

  @override
  String get stepSchedule => 'Schedule';

  @override
  String get reviewScanScanned => 'SCANNED';

  @override
  String get reviewScanReadSuccess =>
      'We\'ve read these details from your label — check and correct if needed!';

  @override
  String get reviewScanInstructionsHint => 'Enter medication instructions';

  @override
  String get reviewScanStrengthUnclear =>
      'Strength field was unclear in the photo — please verify manually.';

  @override
  String get reviewScanRequired => 'REQUIRED';

  @override
  String get reviewScanStrengthHint => 'Enter strength e.g. 500mg';

  @override
  String get reviewScanConfirmContinue => 'Confirm & Continue →';
}
