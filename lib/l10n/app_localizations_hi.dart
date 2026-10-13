// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String comingSoon(String title) {
    return '$title — जल्द आ रहा है';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get navHome => 'होम';

  @override
  String get navMeds => 'दवाइयाँ';

  @override
  String get navCalendar => 'कैलेंडर';

  @override
  String get navReports => 'रिपोर्ट';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsGroupPreferences => 'प्राथमिकताएँ';

  @override
  String get settingsGroupAccountPlan => 'खाता और योजना';

  @override
  String get settingsGroupSupportLegal => 'सहायता और कानूनी';

  @override
  String get settingsNotifications => 'सूचनाएँ';

  @override
  String get settingsNotificationsTrailing => 'ध्वनि और कंपन';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsLanguageTrailing => 'हिन्दी';

  @override
  String get settingsAccessibility => 'सुगम्यता';

  @override
  String get settingsPrivacySecurity => 'गोपनीयता और सुरक्षा';

  @override
  String get settingsSubscription => 'सदस्यता';

  @override
  String get settingsDataExport => 'डेटा निर्यात';

  @override
  String get settingsDataExportTrailing => 'CSV और PDF';

  @override
  String get settingsHelpSupport => 'सहायता और समर्थन';

  @override
  String get settingsAbout => 'परिचय';

  @override
  String get settingsAboutTrailing => 'v1.2.0';

  @override
  String get settingsPro => 'प्रो';

  @override
  String get settingsCaregiverSync => 'केयरगिवर सिंक सक्रिय';

  @override
  String get settingsLogoutTitle => 'लॉग आउट करें?';

  @override
  String get settingsLogoutMessage =>
      'अपनी देखभाल योजना तक पहुँचने के लिए आपको फिर से साइन इन करना होगा।';

  @override
  String get settingsLogOut => 'लॉग आउट';

  @override
  String get settingsLogoutComingSoon => 'लॉग आउट — जल्द आ रहा है';

  @override
  String get settingsFooterVersion =>
      'MedRemind Care Health Suite • v1.2.0 (बिल्ड 412)';

  @override
  String get settingsHipaa => 'HIPAA अनुरूप और एन्क्रिप्टेड';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageNote => 'भाषा चुनने के तुरंत बाद ऐप अपडेट हो जाता है।';

  @override
  String get languageDeviceDefault =>
      'डिवाइस डिफ़ॉल्ट: सिस्टम भाषा (English - US)';

  @override
  String get homeGreetingMorning => 'सुप्रभात';

  @override
  String get homeGreetingAfternoon => 'नमस्ते';

  @override
  String get homeGreetingEvening => 'शुभ संध्या';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting, $name 👋';
  }

  @override
  String homeDayStreak(int days) {
    return '$days दिन की स्ट्रीक';
  }

  @override
  String get homeAdd => 'जोड़ें';

  @override
  String get homeTodaySchedule => 'आज का शेड्यूल';

  @override
  String get homeFilterAll => 'सभी';

  @override
  String get homeFilterPending => 'बाकी';

  @override
  String get homeFilterTaken => 'ली गई';

  @override
  String get homeDaily => 'दैनिक';

  @override
  String homeStatTaken(int count) {
    return '$count ली गई';
  }

  @override
  String homeStatPending(int count) {
    return '$count बाकी';
  }

  @override
  String homeStatMissed(int count) {
    return '$count छूटी';
  }

  @override
  String get homeQuickAccess => 'त्वरित पहुँच';

  @override
  String get homeShortcuts => 'शॉर्टकट';

  @override
  String get homeQuickVitals => 'वाइटल्स';

  @override
  String get homeQuickDoctors => 'डॉक्टर';

  @override
  String get homeQuickAI => 'AI सहायक';

  @override
  String get homeQuickFamily => 'परिवार';

  @override
  String homeScreenComingSoon(String name) {
    return '$name स्क्रीन जल्द आ रही है।';
  }

  @override
  String homeMarkedTaken(String name) {
    return '$name को लिया गया ✓';
  }

  @override
  String homeMarkedUntaken(String name) {
    return '$name को बाकी किया गया 🔄';
  }

  @override
  String homeSkipped(String name) {
    return '$name छोड़ी गई';
  }

  @override
  String homeSkippedReason(String name, String reason) {
    return '$name छोड़ी गई — $reason';
  }

  @override
  String homeSnoozed(String name, int minutes) {
    return '$name स्नूज़ — $minutes मिनट बाद फिर रिमाइंडर';
  }

  @override
  String homeSwitchedMember(String name) {
    return '$name की दवाओं पर स्विच किया';
  }

  @override
  String get homeActionTaken => 'ली गई';

  @override
  String get homeActionSkip => 'छोड़ें';

  @override
  String get homeActionSnooze => 'स्नूज़';

  @override
  String get homeStatusPending => 'बाकी';

  @override
  String get homeStatusTaken => 'ली गई';

  @override
  String get homeStatusUpcoming => 'आने वाली';

  @override
  String get homeStatusSkipped => 'छोड़ी गई';

  @override
  String homeRunningLow(String name, int days) {
    return '$name कम हो रही है · $days दिन बाकी';
  }

  @override
  String get homeRefill => 'रीफ़िल →';

  @override
  String get homeSkippedNote => 'छोड़ी गई — कल फिर रिमाइंडर आएगा';

  @override
  String get doseFormTablet => 'गोली';

  @override
  String get doseFormLiquid => 'तरल';

  @override
  String get doseScheduleDaily => 'दिन में 1 बार';

  @override
  String get doseScheduleBeforeBreakfast => 'नाश्ते से पहले';

  @override
  String get doseScheduleAfterBreakfast => 'नाश्ते के बाद';

  @override
  String get doseScheduleWithDinner => 'रात के खाने के साथ';

  @override
  String doseDueSoon(String time) {
    return '$time · जल्द';
  }

  @override
  String get doseMarkTaken => 'ली गई के रूप में चिह्नित करें';

  @override
  String get doseMarkUntaken => 'बाकी के रूप में चिह्नित करें';

  @override
  String get doseHideReason => 'कारण छिपाएँ';

  @override
  String get doseSkipDose => 'खुराक छोड़ें';

  @override
  String get doseSnoozeFor => 'स्नूज़ करें';

  @override
  String get doseReasonLabel => 'कारण (वैकल्पिक)';

  @override
  String get doseReasonHint => 'जैसे, जी मिचलाना';

  @override
  String get doseConfirmSkip => 'छोड़ना पुष्टि करें';

  @override
  String get dataExportTitle => 'डेटा निर्यात';

  @override
  String get dataExportHeroTitle => 'मेरा सारा डेटा निर्यात करें';

  @override
  String get dataExportHeroSubtitle =>
      'आपके खाते में संग्रहीत सब कुछ की पूरी प्रति प्राप्त करें।';

  @override
  String get dataExportBadge => 'एन्क्रिप्टेड GDPR और HIPAA मानक निर्यात';

  @override
  String get dataExportIncludedTitle => 'इसमें क्या शामिल है';

  @override
  String get dataExportModules => '4 मॉड्यूल';

  @override
  String get dataExportIncludedProfiles => 'सभी प्रोफ़ाइल और दवाएँ';

  @override
  String get dataExportIncludedDoses => 'पूरा डोज़ इतिहास और पालन';

  @override
  String get dataExportIncludedVitals => 'वाइटल्स, लक्षण और नोट्स';

  @override
  String get dataExportIncludedPrescribers => 'डॉक्टर, अपॉइंटमेंट और फ़ार्मेसी';

  @override
  String dataExportFormatNote(String formats) {
    return 'आपको 24 घंटे के भीतर ईमेल से ZIP आर्काइव ($formats) प्राप्त होगा।';
  }

  @override
  String get dataExportFormats => 'JSON + CSV';

  @override
  String dataExportSentTo(String email) {
    return 'सीधे $email पर भेजा गया';
  }

  @override
  String get dataExportRequest => 'निर्यात का अनुरोध करें';

  @override
  String get dataExportGenerating => 'पैकेज बन रहा है...';

  @override
  String get dataExportSubmitted => 'अनुरोध सबमिट हुआ';

  @override
  String get dataExportSuccessTitle => 'निर्यात का अनुरोध किया गया!';

  @override
  String get dataExportSuccessMessage =>
      'हम आपका रॉ डेटा आर्काइव तैयार कर रहे हैं। संकलन पूरा होते ही आपको सीधा लिंक मिलेगा।';

  @override
  String get dataExportQueued => 'सर्वर बैच में कतार में';

  @override
  String get dataExportLastExportNever => 'अंतिम निर्यात: कभी नहीं';

  @override
  String dataExportLastExportNow(String timestamp) {
    return 'अंतिम निर्यात: अभी-अभी ($timestamp)';
  }

  @override
  String dataExportRetentionId(String id) {
    return 'खाता रिकॉर्ड प्रतिधारण ID: $id';
  }

  @override
  String get helpSupportTitle => 'सहायता और समर्थन';

  @override
  String get helpSupportSearchHint => 'FAQ खोजें...';

  @override
  String get helpSupportNoResults => 'कोई मेल खाता लेख नहीं।';

  @override
  String get helpSupportBannerTitle => 'देखभालकर्ता और रोगी डेस्क';

  @override
  String get helpSupportBannerSubtitle =>
      'हम आपकी दिनचर्या समय पर रखने के लिए यहाँ हैं।';

  @override
  String get helpSupportFaqHeader => 'अक्सर पूछे जाने वाले';

  @override
  String helpSupportFaqCount(int count) {
    return '$count लेख';
  }

  @override
  String get helpSupportStillNeedHelp => 'अभी भी सहायता चाहिए?';

  @override
  String get helpSupportLiveOnline => 'टीम ऑनलाइन है';

  @override
  String get helpSupportEmailSupport => 'ईमेल सहायता';

  @override
  String get helpSupportEmailAction => 'ईमेल';

  @override
  String get helpSupportSubmitRequest => 'अनुरोध भेजें';

  @override
  String get helpSupportResponseTime => 'औसतन 2 घंटे से कम में जवाब';

  @override
  String get helpSupportHelpful => 'क्या यह पेज उपयोगी रहा?';

  @override
  String get helpSupportYes => 'हाँ';

  @override
  String get helpSupportNo => 'नहीं';

  @override
  String get helpSupportFeedbackThanks => 'आपकी प्रतिक्रिया के लिए धन्यवाद!';

  @override
  String get helpSupportVersion => 'MedRemind v1.2.0 (बिल्ड 245)';

  @override
  String get helpSupportCompliance =>
      'एन्क्रिप्टेड देखभालकर्ता नेटवर्क • HIPAA अनुरूप';

  @override
  String helpSupportEmailClipped(String email) {
    return 'हमें $email पर ईमेल करें';
  }

  @override
  String get faqQ1 => 'मैं डोज़ का समय कैसे बदलूँ?';

  @override
  String get faqA1 =>
      'अपना शेड्यूल या दवा टैब खोलें, उस दवा कार्ड पर टैप करें, शेड्यूल संपादित करें चुनें, और अपनी डोज़ अलर्ट समायोजित करें। बदलाव देखभालकर्ता उपकरणों पर तुरंत सिंक हो जाते हैं।';

  @override
  String get faqQ2 => 'मुझे रिमाइंडर क्यों नहीं मिला?';

  @override
  String get faqA2 =>
      'सुनिश्चित करें कि फ़ोन सेटिंग्स में MedRemind के लिए बैटरी ऑप्टिमाइज़ेशन बंद है। यह भी जाँचें कि क्रिटिकल अलर्ट और नोटिफ़िकेशन अनुमतियाँ आपके ऑपरेटिंग सिस्टम सेटिंग्स में दी गई हैं।';

  @override
  String get faqQ3 => 'देखभालकर्ता अलर्ट कैसे काम करते हैं?';

  @override
  String get faqA3 =>
      'दवाएँ दर्ज होने पर देखभालकर्ताओं को मौन पुष्टि मिलती है। यदि कोई महत्वपूर्ण डोज़ 30 मिनट से अधिक छूट जाए, तो मुख्य देखभालकर्ता को स्वतः एस्केलेटेड सूचना भेजी जाती है।';

  @override
  String get faqQ4 => 'मैं परिवार का सदस्य कैसे जोड़ूँ?';

  @override
  String get faqA4 =>
      'प्रोफ़ाइल पर जाएँ, जोड़ें पर टैप करें, फिर ईमेल या फ़ोन से निमंत्रण भेजें। वे जुड़ने के लिए लिंक स्वीकार करेंगे।';

  @override
  String get aboutTitle => 'परिचय';

  @override
  String get aboutAppName => 'MedRemind';

  @override
  String get aboutVersion => 'संस्करण 1.2.0 (बिल्ड 245)';

  @override
  String get aboutUpToDate => 'अद्यतित ✓';

  @override
  String get aboutTerms => 'सेवा की शर्तें';

  @override
  String get aboutPrivacy => 'गोपनीयता नीति';

  @override
  String get aboutLicenses => 'ओपन सोर्स लाइसेंस';

  @override
  String get aboutCredits => 'श्रेय';

  @override
  String get aboutCreditsDesign => 'डिज़ाइन';

  @override
  String get aboutCreditsDesignValue => 'MedRemind टीम';

  @override
  String get aboutCreditsDrugData => 'दवा डेटा';

  @override
  String get aboutCreditsDrugDataValue => 'RxNorm · OpenFDA';

  @override
  String get aboutCreditsIcons => 'आइकन';

  @override
  String get aboutCreditsIconsValue => 'ओपन सोर्स सेट';

  @override
  String get aboutFooter =>
      'उन परिवारों के लिए प्यार से बनाया गया जो मिलकर स्वास्थ्य संभालते हैं।';

  @override
  String get aboutLegalBody1 =>
      'MedRemind उच्च क्लिनिकल सटीकता और करुणामय डिज़ाइन के लिए प्रतिबद्ध है। हमारे डेटा स्रोत नेशनल लाइब्रेरी ऑफ़ मेडिसिन (RxNorm) और FDA नियामक डेटाबेस द्वारा प्रकाशित मानकों के अनुरूप हैं।';

  @override
  String get aboutLegalBody2 =>
      'सभी पिल पहचान एल्गोरिद्म, देखभालकर्ता अलर्ट और डोज़ लॉग आपके निर्धारित परिवार-वॉल्ट से एन्क्रिप्टेड रूप से बंधे रहते हैं। स्वास्थ्य डेटा का मुद्रीकरण नहीं किया जाता और न ही तीसरे पक्ष के विज्ञापनदाताओं के साथ साझा किया जाता है।';

  @override
  String get aboutLegalComplianceTitle => 'अनुपालन और ऑडिट';

  @override
  String get aboutLegalComplianceValue =>
      'SOC-2 Type II प्रमाणित · HIPAA सुरक्षा उपाय · 2025 सत्यापित';

  @override
  String get aboutDone => 'हो गया';

  @override
  String get upgradeTitle => 'अपग्रेड';

  @override
  String get upgradePlanStatus => 'मुफ़्त प्लान • विस्तार के लिए तैयार';

  @override
  String get upgradeProGated => 'प्रो के लिए';

  @override
  String get upgradeHeroTitle => 'MedRemind की पूरी शक्ति अनलॉक करें';

  @override
  String get upgradeHeroSubtitle =>
      'इंटरैक्शन, रीफ़िल, रिपोर्ट और फ़ैमिली शेयरिंग';

  @override
  String get upgradeUnlockHeader => 'आप क्या अनलॉक करेंगे';

  @override
  String get upgradeUnlockInteractions => 'दवा इंटरैक्शन और एलर्जी जाँच';

  @override
  String get upgradeUnlockRefills => 'इन्वेंटरी ट्रैकिंग और रीफ़िल अलर्ट';

  @override
  String get upgradeUnlockReports => 'आपके डॉक्टर के लिए PDF/CSV रिपोर्ट';

  @override
  String get upgradeUnlockFamily => 'फ़ैमिली लिंकिंग — 5 प्रोफ़ाइल तक';

  @override
  String get upgradeSeeComparison => 'पूरी तुलना देखें';

  @override
  String get upgradeChoosePlan => 'अपना प्लान चुनें';

  @override
  String get upgradeFreeTrial => '7-दिन मुफ़्त ट्रायल';

  @override
  String get upgradeMonthly => 'मासिक';

  @override
  String get upgradeAnnual => 'वार्षिक';

  @override
  String get upgradeSaveBadge => '52% बचाएँ';

  @override
  String get upgradePlanSoloName => 'Solo Pro';

  @override
  String get upgradePlanSoloSubtitle => 'एक व्यक्ति के लिए सब कुछ';

  @override
  String get upgradePlanFamilyName => 'Family Pro';

  @override
  String get upgradePlanFamilySubtitle =>
      '5 लिंक्ड प्रोफ़ाइल तक + केयरगिवर अलर्ट';

  @override
  String get upgradePopular => 'लोकप्रिय';

  @override
  String get upgradeSelected => 'चयनित';

  @override
  String upgradePriceAnnual(String price) {
    return '$price/वर्ष';
  }

  @override
  String upgradePriceMonthly(String price) {
    return '$price/माह';
  }

  @override
  String upgradeWasPrice(String price) {
    return 'पहले $price';
  }

  @override
  String get upgradeStartTrial => '7-दिन मुफ़्त ट्रायल शुरू करें';

  @override
  String get upgradeNothingDue => 'आज कुछ देय नहीं। दिन 5 पर रिमाइंडर।';

  @override
  String get upgradeCompareAll => 'सभी सुविधाएँ और प्लान तुलना करें';

  @override
  String get upgradeRestorePurchase => 'खरीद बहाल करें';

  @override
  String get upgradeLegalNote =>
      'ट्रायल समाप्त होने से कम से कम 24 घंटे पहले App Store सेटिंग्स में कभी भी रद्द करें। रद्द होने तक प्लान स्वतः नवीनीकृत होता रहता है।';

  @override
  String get upgradeComparisonTitle => 'पूर्ण प्लान तुलना';

  @override
  String get upgradeComparisonContinue => 'चयनित प्लान के साथ जारी रखें';

  @override
  String get upgradeFeatureReminders => 'दवा अनुस्मारक';

  @override
  String get upgradeFeatureRemindersValue => 'मुफ़्त और प्रो (असीमित)';

  @override
  String get upgradeFeatureInteractions => 'दवा इंटरैक्शन चेकर';

  @override
  String get upgradeFeatureRefills => 'स्मार्ट रीफ़िल अलर्ट';

  @override
  String get upgradeFeatureReports => 'डॉक्टर के लिए PDF हेल्थ एक्सपोर्ट';

  @override
  String get upgradeFeatureFamily => 'फ़ैमिली और केयरगिवर सिंक';

  @override
  String get upgradeValuePro => 'केवल प्रो';

  @override
  String get upgradeValueFamily => 'केवल Family Pro';

  @override
  String get upgradeRestoreToast =>
      'खरीद बहाल की जा रही है... कोई पिछली सदस्यता नहीं मिली।';

  @override
  String upgradeTrialToast(String plan, String cadence) {
    return '$plan ($cadence) के लिए 7-दिन का ट्रायल शुरू हो रहा है';
  }

  @override
  String get compareTitle => 'प्लान तुलना करें';

  @override
  String get compareGuarantee => '30-दिन मनी बैक गारंटी';

  @override
  String get compareAnnualSave => 'सालाना 40% बचाएँ';

  @override
  String get compareColFeatures => 'सुविधाएँ';

  @override
  String get compareColFree => 'मुफ़्त';

  @override
  String get compareFreeSubtitle => 'शुरुआती';

  @override
  String get compareColSolo => 'सोलो';

  @override
  String get compareSoloSubtitle => 'सबसे पसंदीदा';

  @override
  String get compareColFamily => 'फ़ैमिली';

  @override
  String get compareFamilySubtitle => 'पूरी देखभाल';

  @override
  String get comparePriceLabel => 'मूल्य';

  @override
  String get compareBilledYearly => 'सालाना बिल';

  @override
  String get compareForever => 'हमेशा के लिए';

  @override
  String get comparePerYear => '/वर्ष';

  @override
  String get compareGroupDaily => 'दैनिक दवा उपकरण';

  @override
  String get compareGroupClinical => 'क्लिनिकल सुरक्षा और ट्रैकिंग';

  @override
  String get compareGroupFamily => 'फ़ैमिली और केयरगिवर सर्कल';

  @override
  String get compareFeatUnlimitedMeds => 'असीमित दवाएँ और रिमाइंडर';

  @override
  String get compareFeatAdherence => 'अनुपालन कैलेंडर और स्ट्रीक';

  @override
  String get compareFeatInteractions => 'इंटरैक्शन और एलर्जी जाँच';

  @override
  String get compareFeatInventory => 'इन्वेंटरी और रीफ़िल अलर्ट';

  @override
  String get compareFeatDoctorTools => 'डॉक्टर और अपॉइंटमेंट टूल';

  @override
  String get compareFeatReports => 'PDF/CSV हेल्थ रिपोर्ट';

  @override
  String get compareFeatHealthSync => 'Apple Health और Fit सिंक';

  @override
  String get compareFeatFamilyLinking => 'फ़ैमिली लिंकिंग (5 तक)';

  @override
  String get compareFeatMissedDose => 'छूटी डोज़ पर केयरगिवर अलर्ट';

  @override
  String get compareFeatFamilyDashboard => 'संयुक्त फ़ैमिली डैशबोर्ड';

  @override
  String get compareQuote =>
      '“केयरगिवर अलर्ट ने माँ के लिए मुझे पूरी मानसिक शांति दी।”';

  @override
  String get compareQuoteAuthor => '— Sarah M., Family Pro ग्राहक';

  @override
  String get compareChooseSolo => 'Solo Pro चुनें';

  @override
  String get compareChooseFamily => 'Family Pro चुनें';

  @override
  String get compareContinueFree => 'मुफ़्त बेसिक प्लान के साथ जारी रखें';

  @override
  String get compareFreeSelected => 'मुफ़्त बेसिक प्लान चयनित';

  @override
  String get compareFinePrint =>
      'मूल्य वार्षिक बिलिंग के लिए हैं। मासिक प्लान भी चेकआउट पर उपलब्ध हैं। बिना किसी परेशानी के कभी भी रद्द करें।';

  @override
  String get compareEncrypted => '256-बिट एन्क्रिप्टेड';

  @override
  String get compareAutoSync => 'ऑटो-सिंक';

  @override
  String get compareHipaaReady => 'HIPAA तैयार';

  @override
  String get paymentTitle => 'भुगतान सफल';

  @override
  String get paymentProNowTitle => 'आप अब Pro हैं!';

  @override
  String paymentWelcome(String plan, String name) {
    return '$plan में आपका स्वागत है, $name। सभी Pro सुविधाएँ अनलॉक हैं।';
  }

  @override
  String get paymentPlanActive => 'प्लान सक्रिय • असीमित केयर सिंक';

  @override
  String get paymentOrderSummary => 'ऑर्डर सारांश';

  @override
  String get paymentTrialActive => 'ट्रायल सक्रिय';

  @override
  String get paymentPlanLabel => 'प्लान';

  @override
  String get paymentFreeTrialLabel => 'मुफ़्त ट्रायल';

  @override
  String paymentFreeTrialValue(String price) {
    return '7 दिन — फिर $price';
  }

  @override
  String get paymentNextBillingLabel => 'अगली बिलिंग तिथि';

  @override
  String get paymentReceipt => 'रसीद';

  @override
  String get paymentOrderIdLabel => 'ऑर्डर आईडी';

  @override
  String get paymentPaymentMethodLabel => 'भुगतान विधि';

  @override
  String get paymentReceiptSentLabel => 'रसीद भेजी गई';

  @override
  String get paymentViewFullReceipt => 'पूरी रसीद देखें';

  @override
  String get paymentStartPro => 'Pro का उपयोग शुरू करें';

  @override
  String get paymentUnlockNote =>
      'इंटरैक्शन जाँच, रीफ़िल अलर्ट और रिपोर्ट अब सक्रिय हैं';
}
