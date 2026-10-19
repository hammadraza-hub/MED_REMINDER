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

  @override
  String get doctorsTitle => 'डॉक्टर';

  @override
  String get doctorsAdd => 'डॉक्टर जोड़ें';

  @override
  String get doctorsAdded => 'डॉक्टर सफलतापूर्वक जोड़ा गया';

  @override
  String doctorsCountOnFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डॉक्टर फ़ाइल में',
      one: '1 डॉक्टर फ़ाइल में',
    );
    return '$_temp0';
  }

  @override
  String get doctorsEmptyTitle => 'कोई डॉक्टर फ़ाइल में नहीं';

  @override
  String get doctorsEmptySubtitle =>
      'प्रिस्क्रिप्शन लिंक करने के लिए डॉक्टर जोड़ें';

  @override
  String get doctorsUpcomingVisits => 'आगामी मुलाक़ातें';

  @override
  String doctorsAppointmentsScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count अपॉइंटमेंट निर्धारित',
      one: '1 अपॉइंटमेंट निर्धारित',
    );
    return '$_temp0';
  }

  @override
  String get doctorsView => 'देखें →';

  @override
  String get doctorsHint =>
      'विवरण देखने या संपादित करने के लिए डॉक्टर पर टैप करें';

  @override
  String doctorsMedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दवाएँ',
      one: '1 दवा',
    );
    return '$_temp0';
  }

  @override
  String get doctorsDetailsSection => 'डॉक्टर विवरण';

  @override
  String get doctorsFieldFullName => 'पूरा नाम *';

  @override
  String get doctorsHintFullName => 'पूरा नाम दर्ज करें';

  @override
  String get doctorsFieldSpecialty => 'विशेषज्ञता';

  @override
  String get doctorsHintSpecialty => 'विशेषज्ञता दर्ज करें';

  @override
  String get doctorsFieldPhone => 'फ़ोन नंबर';

  @override
  String get doctorsHintPhone => 'फ़ोन नंबर दर्ज करें';

  @override
  String get doctorsFieldClinic => 'क्लिनिक / पता (वैकल्पिक)';

  @override
  String get doctorsHintClinic => 'क्लिनिक या पता दर्ज करें';

  @override
  String get doctorsLinkMedications => 'दवाओं से लिंक करें';

  @override
  String get doctorsLinkPrompt => 'यह डॉक्टर कौन-सी दवाएँ लिखता है?';

  @override
  String get doctorsSave => 'डॉक्टर सहेजें';

  @override
  String get doctorsNameRequired => 'कृपया डॉक्टर का पूरा नाम दर्ज करें।';

  @override
  String get medsTitle => 'दवाइयाँ';

  @override
  String medsMemberMedications(String name) {
    return '$name की दवाइयाँ';
  }

  @override
  String medsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सक्रिय दवाएँ',
      one: '1 सक्रिय दवा',
    );
    return '$_temp0';
  }

  @override
  String get medsManageHeader => 'प्रबंधित करें';

  @override
  String get medsQuickTools => 'त्वरित उपकरण';

  @override
  String get medsInventory => 'इन्वेंटरी';

  @override
  String medsLowBadge(int count) {
    return '$count कम';
  }

  @override
  String get medsAllergies => 'एलर्जी';

  @override
  String get medsSideEffects => 'दुष्प्रभाव';

  @override
  String get medsPharmacy => 'फ़ार्मेसी';

  @override
  String get medsSearchHint => 'दवाएँ खोजें...';

  @override
  String medsTabActive(int count) {
    return 'सक्रिय ($count)';
  }

  @override
  String medsTabArchived(int count) {
    return 'संग्रहीत ($count)';
  }

  @override
  String get medsEmptyArchived => 'कोई संग्रहीत दवा नहीं';

  @override
  String get medsEmpty => 'कोई दवा नहीं मिली';

  @override
  String medsMovedToArchived(String name) {
    return '$name को संग्रह में ले जाया गया';
  }

  @override
  String get medsDiscontinueError =>
      'दवा बंद नहीं की जा सकी। कृपया पुनः प्रयास करें।';

  @override
  String get medsDiscontinueBarrierLabel => 'दवा बंद करना ब्रंद करें';

  @override
  String get medsDiscontinue => 'बंद करें';

  @override
  String get medsLowStock => 'कम स्टॉक';

  @override
  String get medsBadgeActive => 'सक्रिय';

  @override
  String get medsScheduleNotSet => 'शेड्यूल सेट नहीं है';

  @override
  String get medsFrequencyAsNeeded => 'आवश्यकतानुसार';

  @override
  String medsFrequencySelectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'चयनित दिनों में ${count}x',
      one: 'चयनित दिनों में 1x',
    );
    return '$_temp0';
  }

  @override
  String medsFrequencyCyclical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x चक्रीय',
      one: '1x चक्रीय',
    );
    return '$_temp0';
  }

  @override
  String get medsFrequencyTapering => 'घटता शेड्यूल';

  @override
  String medsFrequencyDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'रोज़ ${count}x',
      one: 'रोज़ 1x',
    );
    return '$_temp0';
  }

  @override
  String medsNextDoseTomorrow(String time) {
    return 'कल $time';
  }

  @override
  String medsNextDoseWeekday(String day, String time) {
    return '$day $time';
  }

  @override
  String medsEnds(String date) {
    return '$date को समाप्त';
  }

  @override
  String medsNext(String time) {
    return 'अगली: $time';
  }

  @override
  String get medsWeekdayMon => 'सोम';

  @override
  String get medsWeekdayTue => 'मंगल';

  @override
  String get medsWeekdayWed => 'बुध';

  @override
  String get medsWeekdayThu => 'गुरु';

  @override
  String get medsWeekdayFri => 'शुक्र';

  @override
  String get medsWeekdaySat => 'शनि';

  @override
  String get medsWeekdaySun => 'रवि';

  @override
  String get medsFormCapsule => 'कैप्सूल';

  @override
  String get medsFormDrops => 'बूँदें';

  @override
  String get medsFormInjection => 'इंजेक्शन';

  @override
  String medsDayOf(int day, int total) {
    return 'दिन $day / $total';
  }

  @override
  String medsDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन शेष',
      one: '1 दिन शेष',
    );
    return '$_temp0';
  }

  @override
  String medsUnitTablet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'गोलियाँ',
      one: 'गोली',
    );
    return '$_temp0';
  }

  @override
  String medsUnitCapsule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'कैप्सूल',
      one: 'कैप्सूल',
    );
    return '$_temp0';
  }

  @override
  String medsUnitBottle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'बोतलें',
      one: 'बोतल',
    );
    return '$_temp0';
  }

  @override
  String medsUnitDose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'खुराकें',
      one: 'खुराक',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTitle => 'इन्वेंटरी';

  @override
  String inventoryMedicationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दवाएँ',
      one: '1 दवा',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTrackedSupply => 'ट्रैक किया गया स्टॉक';

  @override
  String inventoryLowStockCount(int count) {
    return '$count कम स्टॉक';
  }

  @override
  String get inventoryFilterAll => 'सभी';

  @override
  String get inventoryFilterLow => 'कम स्टॉक';

  @override
  String get inventoryFilterOk => 'ठीक';

  @override
  String get inventoryEmptyFilter => 'इस फ़िल्टर में कोई दवा नहीं';

  @override
  String get inventoryStatusLow => 'कम';

  @override
  String get inventoryStatusOk => 'ठीक';

  @override
  String get inventoryRunningLow => 'खत्म होने वाला — रीफ़िल ऑर्डर करें';

  @override
  String get inventoryRefill => 'रीफ़िल →';

  @override
  String get inventoryAdjustCount => 'गिनती समायोजित करें';

  @override
  String get inventorySufficient => 'पर्याप्त स्टॉक';

  @override
  String get inventorySufficientNext => 'अगली रीफ़िल तक पर्याप्त';

  @override
  String get inventoryEdit => 'संपादित करें';

  @override
  String get inventoryAutoSyncTitle => 'ऑटो-सिंक फ़ार्मेसी';

  @override
  String get inventoryAutoSyncSubtitle =>
      'स्वचालित रीफ़िल अपडेट के लिए अपनी फ़ार्मेसी कनेक्ट करें';

  @override
  String get inventoryAutoSyncPending => 'फ़ार्मेसी ऑटो-सिंक एकीकरण लंबित है';

  @override
  String inventoryCountUpdated(String name, int count) {
    return '$name को $count पर अपडेट किया गया';
  }

  @override
  String inventorySupplyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count दिन',
      one: '~1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get inventoryAdjustReasonLabel => 'समायोजन का कारण (वैकल्पिक)';

  @override
  String get inventoryAdjustReasonHint => 'समायोजन का कारण (वैकल्पिक)...';

  @override
  String get inventoryAdjustSave => 'गिनती सहेजें';

  @override
  String inventoryCurrentOnHand(int quantity, String unit) {
    return 'वर्तमान में उपलब्ध: $quantity $unit';
  }

  @override
  String inventoryAfterRefill(int quantity) {
    return 'रीफ़िल के बाद: $quantity';
  }

  @override
  String inventoryFullBottle(int quantity) {
    return 'पूरी बोतल: $quantity';
  }

  @override
  String inventoryHalfPack(int quantity) {
    return 'आधा पैक: $quantity';
  }

  @override
  String get medFormExtendedRelease => 'एक्सटेंडेड रिलीज़';

  @override
  String get medRouteOral => 'मौखिक';

  @override
  String get medRouteSubcutaneous => 'चमड़े के नीचे';

  @override
  String get medConditionDiabetes => 'मधुमेह';

  @override
  String get medConditionType2Diabetes => 'टाइप 2 मधुमेह';

  @override
  String get medConditionHighBloodPressure => 'उच्च रक्तचाप';

  @override
  String get medConditionHypertension => 'उच्च रक्तचाप';

  @override
  String get medConditionHeartHealth => 'हृदय स्वास्थ्य';

  @override
  String get medConditionHighCholesterol => 'उच्च कोलेस्ट्रॉल';

  @override
  String get medConditionBacterialInfection => 'बैक्टीरियल संक्रमण';

  @override
  String get medConditionPainInflammation => 'दर्द और सूजन';

  @override
  String get medConditionBoneHealth => 'हड्डी स्वास्थ्य';

  @override
  String get medConditionAcidReflux => 'एसिड रिफ्लक्स';

  @override
  String get addMedDailyDose => 'दैनिक खुराक';

  @override
  String addMedCommonFor(String condition) {
    return '$condition के लिए सामान्य';
  }

  @override
  String get addManualColorWhite => 'सफ़ेद';

  @override
  String get addManualColorYellow => 'पीला';

  @override
  String get addManualColorPink => 'गुलाबी';

  @override
  String get addManualColorBlue => 'नीला';

  @override
  String get addManualColorOrange => 'नारंगी';

  @override
  String get addManualColorPeach => 'आड़ू';

  @override
  String get addManualColorGreen => 'हरा';

  @override
  String get addManualDraftSaved =>
      'ड्राफ़्ट सहेजा गया — इसे बाद में पूरा करें!';

  @override
  String get addMedTitle => 'दवा जोड़ें';

  @override
  String get addManualRxVerified => 'Rx सत्यापित';

  @override
  String get medsMedicationDetails => 'दवा विवरण';

  @override
  String get medsFieldName => 'दवा का नाम';

  @override
  String get medsFieldStrength => 'मात्रा';

  @override
  String get medsFieldForm => 'दवा का रूप';

  @override
  String get addManualSelectForm => 'रूप चुनें';

  @override
  String get addManualColorOptional => 'रंग (वैकल्पिक)';

  @override
  String get medsFieldInstructions => 'विशेष निर्देश';

  @override
  String get addManualOptional => 'वैकल्पिक';

  @override
  String get addManualInstructionsHint =>
      'उदा. नाश्ते के बाद भोजन के साथ लें, अंगूर से बचें...';

  @override
  String get addManualContinueToSchedule => 'शेड्यूल पर जारी रखें →';

  @override
  String get addManualSaveDraft => 'ड्राफ़्ट के रूप में सहेजें';

  @override
  String get addManualNameHint => 'दवा का नाम दर्ज करें';

  @override
  String get addManualMatchesIndex => 'नैदानिक सूचकांक से मेल खाता है';

  @override
  String get addManualStrengthHint => 'उदा. 500';

  @override
  String get addManualFormOther => 'अन्य';

  @override
  String get addManualFormOtherSubtitle => 'एक और दवा रूप दर्ज करें';

  @override
  String get addManualCustomForm => 'कस्टम दवा रूप';

  @override
  String get addManualCustomFormHint => 'उदा. क्रीम, इनहेलर, पैच, स्प्रे...';

  @override
  String get addManualCustomFormRequired => 'कृपया दवा का रूप दर्ज करें';

  @override
  String get addManualInteractionTitle => 'स्वचालित इंटरैक्शन जाँच';

  @override
  String get addManualInteractionBody =>
      'अगले चरण में हम इस खुराक की तुलना आपकी पहले से दर्ज दवाओं से करेंगे।';

  @override
  String addMedSelected(String name, String strength) {
    return '$name $strength चुना गया — आगे विवरण!';
  }

  @override
  String get addMedPrivateNote => 'इस डिवाइस पर निजी और एन्क्रिप्टेड';

  @override
  String get addMedScanLabel => 'लेबल स्कैन करें';

  @override
  String get addMedSearch => 'खोजें';

  @override
  String get addMedManualEntry => 'मैनुअल एंट्री';

  @override
  String addMedMatchingCount(int count) {
    return 'मेल खाती दवाएँ ($count)';
  }

  @override
  String get addMedFdaApproved => 'FDA अनुमोदित';

  @override
  String get addMedTipTitle => 'सुझाव: निशान देखें';

  @override
  String get addMedTipBody =>
      'अधिकांश मेटफॉर्मिन गोलियों पर \'500\' या \'M\' जैसे अंक सामने छपे होते हैं ताकि सटीक खुराक मेल सुनिश्चित हो।';

  @override
  String get addMedCantFind => 'अपनी दवा नहीं मिल रही?';

  @override
  String get addMedAddManually => 'मैन्युअल रूप से जोड़ें';

  @override
  String get addMedEmptyTitle => 'दवा खोजें';

  @override
  String get addMedEmptySubtitle =>
      'ऊपर दवा का नाम दर्ज करें या उसका लेबल स्कैन करें';

  @override
  String get addMedNoResultsTitle => 'कोई दवा नहीं मिली';

  @override
  String addMedNoResultsFor(String query) {
    return '\"$query\" के लिए कोई परिणाम नहीं';
  }

  @override
  String get addMedSelectAction => 'चुनें ›';

  @override
  String get reviewScanNameRequired => 'कृपया दवा का नाम दर्ज करें।';

  @override
  String get reviewScanStrengthRequired => 'कृपया दवा की मात्रा दर्ज करें।';

  @override
  String get reviewScanTitle => 'स्कैन की समीक्षा करें';

  @override
  String get scanCaptureFailed => 'कैप्चर विफल — पुनः प्रयास करें।';

  @override
  String get scanCaptureError => 'छवि कैप्चर नहीं हो सकी। पुनः प्रयास करें।';

  @override
  String get scanGalleryError => 'छवि नहीं खुल सकी। पुनः प्रयास करें।';

  @override
  String scanDetectedOne(String name) {
    return '✓ पता चला: $name';
  }

  @override
  String scanDetectedCount(int count) {
    return '✓ $count दवाएँ पता चलीं';
  }

  @override
  String get scanTextNoMedicine =>
      'पाठ पता चला, लेकिन दवा विवरण की पहचान नहीं हो सकी।';

  @override
  String get scanNoText =>
      'कोई पाठ नहीं मिला। दस्तावेज़ को स्पष्ट, सपाट और अच्छी रोशनी में रखें।';

  @override
  String get scanReadError => 'छवि पढ़ी नहीं जा सकी। पुनः प्रयास करें।';

  @override
  String get scanRescanAgain => 'कृपया दवा को फिर से स्कैन करें।';

  @override
  String get scanFitFrameHint =>
      'दवा का लेबल या पूरा नुस्खा फ्रेम के अंदर रखें';

  @override
  String get scanEnterManually => 'दवा मैन्युअल रूप से दर्ज करें';

  @override
  String get scanRetakePhoto => 'फ़ोटो दोबारा लें';

  @override
  String get scanReadingPrescription => 'नुस्खा पढ़ा जा रहा है...';

  @override
  String get scanStatusReading => 'पढ़ा जा रहा है';

  @override
  String get scanStatusFound => 'मिला';

  @override
  String get scanStatusInFrame => 'फ्रेम में';

  @override
  String get scanStatusReady => 'तैयार';

  @override
  String get scanCameraUnavailable => 'कैमरा उपलब्ध नहीं';

  @override
  String get scanStartingCamera => 'कैमरा शुरू हो रहा है...';

  @override
  String get scanCapturingDocument => 'दस्तावेज़ कैप्चर हो रहा है...';

  @override
  String get scanReadingMedicineText => 'दवा का पाठ पढ़ा जा रहा है...';

  @override
  String get scanMedicineDetected => 'दवा पता चली';

  @override
  String scanMedicinesDetected(int count) {
    return '$count दवाएँ पता चलीं';
  }

  @override
  String get scanImageCaptured => 'छवि कैप्चर की गई';

  @override
  String get scanMedicineOrRxDetected => 'दवा या नुस्खा पता चला';

  @override
  String get scanPointCameraHint => 'कैमरा दवा या नुस्खे की ओर करें';

  @override
  String get scanFlash => 'फ्लैश';

  @override
  String get scanShutter => 'स्कैन';

  @override
  String get scanGallery => 'गैलरी';

  @override
  String get scanTryAgain => 'पुनः प्रयास करें';

  @override
  String scanMedicineBadgeNumber(int index) {
    return 'दवा $index पता चली';
  }

  @override
  String get scanMedicineBadgeSingular => 'दवा पता चली';

  @override
  String get scanFieldStrength => 'मात्रा';

  @override
  String get scanFieldForm => 'रूप';

  @override
  String get scanFieldFrequency => 'आवृत्ति';

  @override
  String get medsFieldInstructionsShort => 'निर्देश';

  @override
  String get scanReviewAdd => 'समीक्षा करें और दवा जोड़ें';

  @override
  String get stepSchedule => 'शेड्यूल';

  @override
  String get reviewScanScanned => 'स्कैन किया गया';

  @override
  String get reviewScanReadSuccess =>
      'हमने ये विवरण आपके लेबल से पढ़े हैं — जाँचें और ज़रूरत हो तो ठीक करें!';

  @override
  String get reviewScanInstructionsHint => 'दवा के निर्देश दर्ज करें';

  @override
  String get reviewScanStrengthUnclear =>
      'फ़ोटो में मात्रा फ़ील्ड स्पष्ट नहीं थी — कृपया मैन्युअल रूप से जाँचें।';

  @override
  String get reviewScanRequired => 'आवश्यक';

  @override
  String get reviewScanStrengthHint => 'मात्रा दर्ज करें, उदा. 500mg';

  @override
  String get reviewScanConfirmContinue => 'पुष्टि करें और जारी रखें →';
}
