// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String comingSoon(String title) {
    return '$title — قريبًا';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMeds => 'الأدوية';

  @override
  String get navCalendar => 'التقويم';

  @override
  String get navReports => 'التقارير';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsGroupPreferences => 'التفضيلات';

  @override
  String get settingsGroupAccountPlan => 'الحساب والخطة';

  @override
  String get settingsGroupSupportLegal => 'الدعم والقانون';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsNotificationsTrailing => 'نغمة واهتزاز';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageTrailing => 'العربية';

  @override
  String get settingsAccessibility => 'إمكانية الوصول';

  @override
  String get settingsPrivacySecurity => 'الخصوصية والأمان';

  @override
  String get settingsSubscription => 'الاشتراك';

  @override
  String get settingsDataExport => 'تصدير البيانات';

  @override
  String get settingsDataExportTrailing => 'CSV و PDF';

  @override
  String get settingsHelpSupport => 'المساعدة والدعم';

  @override
  String get settingsAbout => 'حول';

  @override
  String get settingsAboutTrailing => 'v1.2.0';

  @override
  String get settingsPro => 'احترافي';

  @override
  String get settingsCaregiverSync => 'المزامنة نشطة';

  @override
  String get settingsLogoutTitle => 'تسجيل الخروج؟';

  @override
  String get settingsLogoutMessage =>
      'ستحتاج إلى تسجيل الدخول مرة أخرى للوصول إلى خطة الرعاية.';

  @override
  String get settingsLogOut => 'تسجيل الخروج';

  @override
  String get settingsLogoutComingSoon => 'تسجيل الخروج — قريبًا';

  @override
  String get settingsFooterVersion =>
      'MedRemind Care Health Suite • إصدار 1.2.0 (412)';

  @override
  String get settingsHipaa => 'متوافق مع HIPAA ومشفّر';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageNote => 'يتم تحديث التطبيق فورًا بعد اختيار اللغة.';

  @override
  String get languageDeviceDefault =>
      'افتراضي الجهاز: لغة النظام (English - US)';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'طاب مساؤك';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting، $name 👋';
  }

  @override
  String homeDayStreak(int days) {
    return 'سلسلة $days يومًا';
  }

  @override
  String get homeAdd => 'إضافة';

  @override
  String get homeTodaySchedule => 'جدول اليوم';

  @override
  String get homeFilterAll => 'الكل';

  @override
  String get homeFilterPending => 'قيد الانتظار';

  @override
  String get homeFilterTaken => 'تم أخذها';

  @override
  String get homeDaily => 'يومي';

  @override
  String homeStatTaken(int count) {
    return '$count تم أخذها';
  }

  @override
  String homeStatPending(int count) {
    return '$count قيد الانتظار';
  }

  @override
  String homeStatMissed(int count) {
    return '$count فائتة';
  }

  @override
  String get homeQuickAccess => 'وصول سريع';

  @override
  String get homeShortcuts => 'اختصارات';

  @override
  String get homeQuickVitals => 'العلامات';

  @override
  String get homeQuickDoctors => 'الأطباء';

  @override
  String get homeQuickAI => 'مساعد AI';

  @override
  String get homeQuickFamily => 'العائلة';

  @override
  String homeScreenComingSoon(String name) {
    return 'شاشة $name قادمة قريبًا.';
  }

  @override
  String homeMarkedTaken(String name) {
    return 'تم وضع علامة تم أخذ $name ✓';
  }

  @override
  String homeMarkedUntaken(String name) {
    return 'تم إرجاع $name إلى غير مأخوذة 🔄';
  }

  @override
  String homeSkipped(String name) {
    return 'تم تخطي $name';
  }

  @override
  String homeSkippedReason(String name, String reason) {
    return 'تم تخطي $name — $reason';
  }

  @override
  String homeSnoozed(String name, int minutes) {
    return 'تم تأجيل $name — التذكير مرة أخرى خلال $minutes دقيقة';
  }

  @override
  String homeSwitchedMember(String name) {
    return 'تم التبديل إلى أدوية $name';
  }

  @override
  String get homeActionTaken => 'تم الأخذ';

  @override
  String get homeActionSkip => 'تخطٍّ';

  @override
  String get homeActionSnooze => 'تأجيل';

  @override
  String get homeStatusPending => 'قيد الانتظار';

  @override
  String get homeStatusTaken => 'تم الأخذ';

  @override
  String get homeStatusUpcoming => 'قادم';

  @override
  String get homeStatusSkipped => 'متخطّى';

  @override
  String homeRunningLow(String name, int days) {
    return '$name على وشك النفاد · تبقى $days أيام';
  }

  @override
  String get homeRefill => 'إعادة التعبئة →';

  @override
  String get homeSkippedNote => 'تم التخطي — سيعود التذكير غدًا';

  @override
  String get doseFormTablet => 'قرص';

  @override
  String get doseFormLiquid => 'سائل';

  @override
  String get doseScheduleDaily => 'مرة يوميًا';

  @override
  String get doseScheduleBeforeBreakfast => 'قبل الفطور';

  @override
  String get doseScheduleAfterBreakfast => 'بعد الفطور';

  @override
  String get doseScheduleWithDinner => 'مع العشاء';

  @override
  String doseDueSoon(String time) {
    return '$time · قريبًا';
  }

  @override
  String get doseMarkTaken => 'وضع علامة تم الأخذ';

  @override
  String get doseMarkUntaken => 'وضع علامة لم يُؤخذ';

  @override
  String get doseHideReason => 'إخفاء السبب';

  @override
  String get doseSkipDose => 'تخطي الجرعة';

  @override
  String get doseSnoozeFor => 'تأجيل لمدة';

  @override
  String get doseReasonLabel => 'السبب (اختياري)';

  @override
  String get doseReasonHint => 'مثال: غثيان';

  @override
  String get doseConfirmSkip => 'تأكيد التخطي';

  @override
  String get dataExportTitle => 'تصدير البيانات';

  @override
  String get dataExportHeroTitle => 'تصدير كل بياناتي';

  @override
  String get dataExportHeroSubtitle =>
      'احصل على نسخة كاملة من كل ما هو مخزّن في حسابك.';

  @override
  String get dataExportBadge => 'تصدير مشفّر بمعيار GDPR وHIPAA';

  @override
  String get dataExportIncludedTitle => 'ما الذي يشمله';

  @override
  String get dataExportModules => '4 وحدات';

  @override
  String get dataExportIncludedProfiles => 'جميع الملفات والأدوية';

  @override
  String get dataExportIncludedDoses => 'السجل الكامل للجرعات والالتزام';

  @override
  String get dataExportIncludedVitals => 'العلامات الحيوية والأعراض والملاحظات';

  @override
  String get dataExportIncludedPrescribers => 'الأطباء والمواعيد والصيدليات';

  @override
  String dataExportFormatNote(String formats) {
    return 'ستستلم أرشيف ZIP ($formats) عبر البريد الإلكتروني خلال 24 ساعة.';
  }

  @override
  String get dataExportFormats => 'JSON + CSV';

  @override
  String dataExportSentTo(String email) {
    return 'أُرسل مباشرةً إلى $email';
  }

  @override
  String get dataExportRequest => 'طلب التصدير';

  @override
  String get dataExportGenerating => 'جارٍ إنشاء الحزمة...';

  @override
  String get dataExportSubmitted => 'تم إرسال الطلب';

  @override
  String get dataExportSuccessTitle => 'تم طلب التصدير!';

  @override
  String get dataExportSuccessMessage =>
      'نقوم بتحضير أرشيف بياناتك الخام. ستتلقى رابطًا مباشرًا بمجرد اكتمال التجميع.';

  @override
  String get dataExportQueued => 'في قائمة الانتظار على الخادم';

  @override
  String get dataExportLastExportNever => 'آخر تصدير: أبدًا';

  @override
  String dataExportLastExportNow(String timestamp) {
    return 'آخر تصدير: الآن ($timestamp)';
  }

  @override
  String dataExportRetentionId(String id) {
    return 'معرّف الاحتفاظ بسجلات الحساب: $id';
  }

  @override
  String get helpSupportTitle => 'المساعدة والدعم';

  @override
  String get helpSupportSearchHint => 'ابحث في الأسئلة الشائعة...';

  @override
  String get helpSupportNoResults => 'لا توجد مقالات مطابقة.';

  @override
  String get helpSupportBannerTitle => 'مكتب مقدّمي الرعاية والمرضى';

  @override
  String get helpSupportBannerSubtitle => 'نحن هنا للحفاظ على مواعيد روتينك.';

  @override
  String get helpSupportFaqHeader => 'الأسئلة الشائعة';

  @override
  String helpSupportFaqCount(int count) {
    return '$count مقالات';
  }

  @override
  String get helpSupportStillNeedHelp => 'ما زلت بحاجة إلى مساعدة؟';

  @override
  String get helpSupportLiveOnline => 'الفريق متصل الآن';

  @override
  String get helpSupportEmailSupport => 'الدعم عبر البريد';

  @override
  String get helpSupportEmailAction => 'بريد';

  @override
  String get helpSupportSubmitRequest => 'إرسال طلب';

  @override
  String get helpSupportResponseTime => 'متوسط الرد أقل من ساعتين';

  @override
  String get helpSupportHelpful => 'هل كانت هذه الصفحة مفيدة؟';

  @override
  String get helpSupportYes => 'نعم';

  @override
  String get helpSupportNo => 'لا';

  @override
  String get helpSupportFeedbackThanks => 'شكرًا على ملاحظاتك!';

  @override
  String get helpSupportVersion => 'MedRemind v1.2.0 (إصدار 245)';

  @override
  String get helpSupportCompliance =>
      'شبكة مقدّمي رعاية مشفّرة • متوافق مع HIPAA';

  @override
  String helpSupportEmailClipped(String email) {
    return 'راسلنا على $email';
  }

  @override
  String get faqQ1 => 'كيف أغيّر وقت الجرعة؟';

  @override
  String get faqA1 =>
      'افتح تبويب الجدول أو الأدوية، وانقر على بطاقة الدواء المحددة، واختر تعديل الجدول، ثم اضبط تنبيهات الجرعة. تتم المزامنة فورًا بين أجهزة مقدّمي الرعاية.';

  @override
  String get faqQ2 => 'لماذا لم أستلم تذكيرًا؟';

  @override
  String get faqA2 =>
      'تأكد من تعطيل تحسين البطارية لتطبيق MedRemind في إعدادات الهاتف. تحقق أيضًا من منح أذونات التنبيهات الحرجة والإشعارات في إعدادات نظام التشغيل.';

  @override
  String get faqQ3 => 'كيف تعمل تنبيهات مقدّمي الرعاية؟';

  @override
  String get faqA3 =>
      'يتلقى مقدّمو الرعاية تأكيدات صامتة عند تسجيل الأدوية. إذا فاتت جرعة حاسمة لأكثر من 30 دقيقة، يُرسل إشعار مُصعَّد تلقائيًا إلى مقدّم الرعاية الأساسي.';

  @override
  String get faqQ4 => 'كيف أضيف فردًا من العائلة؟';

  @override
  String get faqA4 =>
      'انتقل إلى الملفات، وانقر على إضافة، ثم أرسل دعوة عبر البريد أو الهاتف. سيقبلون الرابط للاتصال.';

  @override
  String get aboutTitle => 'حول';

  @override
  String get aboutAppName => 'MedRemind';

  @override
  String get aboutVersion => 'الإصدار 1.2.0 (إصدار 245)';

  @override
  String get aboutUpToDate => 'محدّث ✓';

  @override
  String get aboutTerms => 'شروط الخدمة';

  @override
  String get aboutPrivacy => 'سياسة الخصوصية';

  @override
  String get aboutLicenses => 'تراخيص المصادر المفتوحة';

  @override
  String get aboutCredits => 'الاعتمادات';

  @override
  String get aboutCreditsDesign => 'التصميم';

  @override
  String get aboutCreditsDesignValue => 'فريق MedRemind';

  @override
  String get aboutCreditsDrugData => 'بيانات الأدوية';

  @override
  String get aboutCreditsDrugDataValue => 'RxNorm · OpenFDA';

  @override
  String get aboutCreditsIcons => 'الأيقونات';

  @override
  String get aboutCreditsIconsValue => 'مجموعات مفتوحة المصدر';

  @override
  String get aboutFooter => 'صُنع بعناية للعائلات التي تدير صحتها معًا.';

  @override
  String get aboutLegalBody1 =>
      'تلتزم MedRemind بدقة سريرية عالية وتصميم رحيم. تتوافق مصادر بياناتنا بدقة مع المعايير التي تنشرها المكتبة الوطنية للطب (RxNorm) وقاعدة بيانات إدارة الغذاء والدواء (FDA).';

  @override
  String get aboutLegalBody2 =>
      'تبقى جميع خوارزميات التعرف على الأقراص وتنبيهات مقدّمي الرعاية وسجلات الجرعات مشفّرة ومرتبطة بخزنة عائلتك المعيّنة. لا تتم تسييل المعايير الصحية ولا مشاركتها مع معلنين خارجيين.';

  @override
  String get aboutLegalComplianceTitle => 'الامتثال والتدقيق';

  @override
  String get aboutLegalComplianceValue =>
      'معتمد SOC-2 Type II · ضمانات أمان HIPAA · موثّق 2025';

  @override
  String get aboutDone => 'تم';

  @override
  String get upgradeTitle => 'ترقية';

  @override
  String get upgradePlanStatus => 'الخطة المجانية • جاهز للتوسّع';

  @override
  String get upgradeProGated => 'يتطلب Pro';

  @override
  String get upgradeHeroTitle => 'افتح كامل إمكانات MedRemind';

  @override
  String get upgradeHeroSubtitle =>
      'التفاعلات، إعادة التعبئة، التقارير والمشاركة العائلية';

  @override
  String get upgradeUnlockHeader => 'ما ستحصل عليه';

  @override
  String get upgradeUnlockInteractions => 'فحص التفاعلات الدوائية والحساسية';

  @override
  String get upgradeUnlockRefills => 'تتبّع المخزون وتنبيهات إعادة التعبئة';

  @override
  String get upgradeUnlockReports => 'تقارير PDF/CSV لطبيبك';

  @override
  String get upgradeUnlockFamily => 'ربط العائلة — حتى 5 ملفات';

  @override
  String get upgradeSeeComparison => 'عرض المقارنة الكاملة';

  @override
  String get upgradeChoosePlan => 'اختر خطتك';

  @override
  String get upgradeFreeTrial => 'تجربة مجانية لمدة 7 أيام';

  @override
  String get upgradeMonthly => 'شهري';

  @override
  String get upgradeAnnual => 'سنوي';

  @override
  String get upgradeSaveBadge => 'وفّر 52%';

  @override
  String get upgradePlanSoloName => 'Solo Pro';

  @override
  String get upgradePlanSoloSubtitle => 'كل شيء لشخص واحد';

  @override
  String get upgradePlanFamilyName => 'Family Pro';

  @override
  String get upgradePlanFamilySubtitle =>
      'حتى 5 ملفات مرتبطة + تنبيهات مقدّمي الرعاية';

  @override
  String get upgradePopular => 'شائع';

  @override
  String get upgradeSelected => 'محدّد';

  @override
  String upgradePriceAnnual(String price) {
    return '$price/سنة';
  }

  @override
  String upgradePriceMonthly(String price) {
    return '$price/شهر';
  }

  @override
  String upgradeWasPrice(String price) {
    return 'كان $price';
  }

  @override
  String get upgradeStartTrial => 'ابدأ التجربة المجانية 7 أيام';

  @override
  String get upgradeNothingDue => 'لا شيء مستحق اليوم. تذكير في اليوم الخامس.';

  @override
  String get upgradeCompareAll => 'قارن كل الميزات والخطط';

  @override
  String get upgradeRestorePurchase => 'استعادة الشراء';

  @override
  String get upgradeLegalNote =>
      'يمكنك الإلغاء في أي وقت من إعدادات App Store قبل 24 ساعة على الأقل من انتهاء التجربة. تتجدد الخطة تلقائيًا حتى الإلغاء.';

  @override
  String get upgradeComparisonTitle => 'مقارنة الخطط الكاملة';

  @override
  String get upgradeComparisonContinue => 'المتابعة بالخطة المحدّدة';

  @override
  String get upgradeFeatureReminders => 'تذكيرات الأدوية';

  @override
  String get upgradeFeatureRemindersValue => 'مجاني و Pro (غير محدود)';

  @override
  String get upgradeFeatureInteractions => 'فاحص التفاعلات الدوائية';

  @override
  String get upgradeFeatureRefills => 'تنبيهات ذكية لإعادة التعبئة';

  @override
  String get upgradeFeatureReports => 'تصدير التقارير الصحية PDF للطبيب';

  @override
  String get upgradeFeatureFamily => 'مزامنة العائلة ومقدّمي الرعاية';

  @override
  String get upgradeValuePro => 'حصري لـ Pro';

  @override
  String get upgradeValueFamily => 'Family Pro فقط';

  @override
  String get upgradeRestoreToast =>
      'جارٍ استعادة المشتريات... لم يتم العثور على اشتراكات سابقة.';

  @override
  String upgradeTrialToast(String plan, String cadence) {
    return 'بدء التجربة المجانية 7 أيام لخطة $plan ($cadence)';
  }

  @override
  String get compareTitle => 'مقارنة الخطط';

  @override
  String get compareGuarantee => 'ضمان استرداد لمدة 30 يومًا';

  @override
  String get compareAnnualSave => 'وفّر 40% سنويًا';

  @override
  String get compareColFeatures => 'الميزات';

  @override
  String get compareColFree => 'مجاني';

  @override
  String get compareFreeSubtitle => 'المبتدئ';

  @override
  String get compareColSolo => 'فردي';

  @override
  String get compareSoloSubtitle => 'الأكثر تفضيلًا';

  @override
  String get compareColFamily => 'عائلي';

  @override
  String get compareFamilySubtitle => 'رعاية كاملة';

  @override
  String get comparePriceLabel => 'السعر';

  @override
  String get compareBilledYearly => 'يُفاوتر سنويًا';

  @override
  String get compareForever => 'للأبد';

  @override
  String get comparePerYear => '/سنة';

  @override
  String get compareGroupDaily => 'أدوات الأدوية اليومية';

  @override
  String get compareGroupClinical => 'السلامة السريرية والتتبّع';

  @override
  String get compareGroupFamily => 'دائرة العائلة ومقدّمي الرعاية';

  @override
  String get compareFeatUnlimitedMeds => 'أدوية وتذكيرات غير محدودة';

  @override
  String get compareFeatAdherence => 'تقويم الالتزام والسلاسل';

  @override
  String get compareFeatInteractions => 'فحص التفاعلات والحساسية';

  @override
  String get compareFeatInventory => 'المخزون وتنبيهات إعادة التعبئة';

  @override
  String get compareFeatDoctorTools => 'أدوات الطبيب والمواعيد';

  @override
  String get compareFeatReports => 'تقارير صحية PDF/CSV';

  @override
  String get compareFeatHealthSync => 'مزامنة Apple Health و Fit';

  @override
  String get compareFeatFamilyLinking => 'ربط العائلة (حتى 5)';

  @override
  String get compareFeatMissedDose => 'تنبيه مقدّم الرعاية عند تفويت جرعة';

  @override
  String get compareFeatFamilyDashboard => 'لوحة العائلة الموحّدة';

  @override
  String get compareQuote =>
      '«أعطتني تنبيهات مقدّمي الرعاية راحة بال كاملة لأمي.»';

  @override
  String get compareQuoteAuthor => '— سارة م.، مشتركة Family Pro';

  @override
  String get compareChooseSolo => 'اختر Solo Pro';

  @override
  String get compareChooseFamily => 'اختر Family Pro';

  @override
  String get compareContinueFree => 'المتابعة بالخطة المجانية الأساسية';

  @override
  String get compareFreeSelected => 'تم اختيار الخطة المجانية الأساسية';

  @override
  String get compareFinePrint =>
      'الأسعار معروضة للفواتير السنوية. الخطط الشهرية متاحة أيضًا عند الدفع. يمكنك الإلغاء في أي وقت دون عناء.';

  @override
  String get compareEncrypted => 'تشفير 256 بت';

  @override
  String get compareAutoSync => 'مزامنة تلقائية';

  @override
  String get compareHipaaReady => 'متوافق مع HIPAA';

  @override
  String get paymentTitle => 'تم الدفع بنجاح';

  @override
  String get paymentProNowTitle => 'أنت الآن Pro!';

  @override
  String paymentWelcome(String plan, String name) {
    return 'مرحبًا بك في $plan، $name. جميع ميزات Pro مفتوحة.';
  }

  @override
  String get paymentPlanActive => 'الخطة نشطة • مزامنة رعاية غير محدودة';

  @override
  String get paymentOrderSummary => 'ملخص الطلب';

  @override
  String get paymentTrialActive => 'التجربة نشطة';

  @override
  String get paymentPlanLabel => 'الخطة';

  @override
  String get paymentFreeTrialLabel => 'التجربة المجانية';

  @override
  String paymentFreeTrialValue(String price) {
    return '7 أيام — ثم $price';
  }

  @override
  String get paymentNextBillingLabel => 'تاريخ الفاتورة التالية';

  @override
  String get paymentReceipt => 'الإيصال';

  @override
  String get paymentOrderIdLabel => 'رقم الطلب';

  @override
  String get paymentPaymentMethodLabel => 'طريقة الدفع';

  @override
  String get paymentReceiptSentLabel => 'أُرسل الإيصال إلى';

  @override
  String get paymentViewFullReceipt => 'عرض الإيصال الكامل';

  @override
  String get paymentStartPro => 'ابدأ استخدام Pro';

  @override
  String get paymentUnlockNote =>
      'فحوصات التفاعلات وتنبيهات إعادة التعبئة والتقارير أصبحت نشطة';
}
