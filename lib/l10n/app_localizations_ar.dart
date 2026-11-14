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
  String get settingsDataExportTrailing => 'ZIP';

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
  String settingsFooterVersion(String version, String build) {
    return 'MedRemind Care Health Suite • إصدار $version ($build)';
  }

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
  String get dataExportBadge => 'يُنشأ على هذا الجهاز فقط';

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
    return 'يتم إنشاء ملف ZIP ($formats) على هذا الجهاز. أنت تختار مكان حفظه أو مشاركته.';
  }

  @override
  String get dataExportFormats => 'JSON + CSV';

  @override
  String dataExportSentTo(String email) {
    return 'بيانات الحساب $email';
  }

  @override
  String get dataExportRequest => 'إنشاء التصدير';

  @override
  String get dataExportGenerating => 'جارٍ تجهيز بياناتك...';

  @override
  String get dataExportSubmitted => 'التصدير جاهز';

  @override
  String get dataExportSuccessTitle => 'التصدير جاهز!';

  @override
  String get dataExportSuccessMessage =>
      'تم إنشاء ملف ZIP. يحتوي على بياناتك الصحية، لذا احتفظ به في مكان آمن.';

  @override
  String get dataExportQueued => 'لا يحتفظ به التطبيق بعد المشاركة';

  @override
  String get dataExportShareAgain => 'إنشاء مرة أخرى';

  @override
  String get dataExportFailed =>
      'تعذّر إنشاء التصدير. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get accountDeleteSheetTitle => 'حذف الحساب؟';

  @override
  String get accountDeleteButton => 'حذف الحساب';

  @override
  String accountDeleteSheetBody(int days) {
    return 'سيتم جدولة حذف حسابك بعد $days أيام. يمكنك الإلغاء من هذه الشاشة حتى ذلك الحين. بعدها ستُحذف ملفاتك الشخصية وأدويتك وسجل الجرعات نهائيًا.';
  }

  @override
  String get accountDeleteExportTitle => 'احفظ بياناتك أولًا';

  @override
  String get accountDeleteExportHint => 'أنشئ ملف ZIP بكل بياناتك قبل الحذف.';

  @override
  String get accountDeleteExportButton => 'تصدير';

  @override
  String get accountDeleteConfirm => 'جدولة الحذف';

  @override
  String get accountDeleteKeep => 'الإبقاء على الحساب';

  @override
  String get accountDeleteScheduledTitle => 'تمت جدولة الحذف';

  @override
  String accountDeleteScheduledBody(int days) {
    return 'سيتم حذف حسابك بعد $days أيام. يمكنك الإلغاء الآن.';
  }

  @override
  String get accountDeleteDueBody => 'انتهت فترة الانتظار. حسابك جاهز للحذف.';

  @override
  String get accountDeleteCancel => 'إلغاء الحذف';

  @override
  String get accountDeleteRequested => 'تمت جدولة الحذف.';

  @override
  String get accountDeleteCancelled => 'تم إلغاء الحذف. حسابك لا يزال نشطًا.';

  @override
  String get accountDeleteFailed =>
      'تعذّر تحديث طلبك. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get accountDeleteFooter => 'نوصي بتصدير بياناتك أولًا.';

  @override
  String get accountPurgeRunning => 'جارٍ حذف حسابك...';

  @override
  String get accountPurgeRunningHint => 'أبقِ التطبيق مفتوحًا حتى ينتهي الحذف.';

  @override
  String get accountPurgeNeedsLogin =>
      'لأمانك، سجّل الدخول مرة أخرى لإكمال حذف حسابك. لم يتم حذف أي شيء بعد.';

  @override
  String get accountPurgeLoginButton => 'تسجيل الدخول مرة أخرى';

  @override
  String get accountPurgeFailed =>
      'تعذّر إكمال الحذف. ما تم حذفه يبقى محذوفًا. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get accountPurgeRetry => 'إعادة المحاولة';

  @override
  String get accountDeleteSummaryTitle => 'ما الذي سيتم حذفه';

  @override
  String accountDeleteOthersLose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيفقد $count أشخاص آخرين الوصول',
      one: 'سيفقد شخص آخر الوصول',
    );
    return '$_temp0';
  }

  @override
  String accountDeleteMemberOf(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ستتم إزالتك أيضًا من $count ملفات شخصية تمت مشاركتها معك. تبقى بياناتها لدى مالكيها.',
      one: 'ستتم إزالتك أيضًا من ملف شخصي واحد تمت مشاركته معك. تبقى بياناته لدى مالكه.',
    );
    return '$_temp0';
  }

  @override
  String get accountDeleteSubscriptionNote =>
      'حذف حسابك لا يلغي الاشتراك المدفوع. ألغِه من المتجر لتجنب أي رسوم إضافية.';

  @override
  String get accountDeleteSubscriptionButton => 'إدارة الاشتراك';

  @override
  String get vitalsErrEmpty => 'يرجى إدخال قيمة.';

  @override
  String get vitalsErrNotNumber => 'يرجى إدخال رقم صحيح.';

  @override
  String vitalsErrRange(String min, String max, String unit) {
    return 'يجب أن تكون القيمة بين $min و$max $unit.';
  }

  @override
  String get vitalsErrDiastolicMissing =>
      'يرجى إدخال قيمة الانبساطي (الرقم السفلي).';

  @override
  String vitalsErrDiastolicRange(String min, String max) {
    return 'يجب أن يكون الانبساطي بين $min و$max ملم زئبق.';
  }

  @override
  String get vitalsErrDiastolicNotLower =>
      'يجب أن يكون الانبساطي أقل من الانقباضي.';

  @override
  String vitalsErrPulseRange(String min, String max) {
    return 'يجب أن يكون النبض بين $min و$max نبضة/د.';
  }

  @override
  String get vitalsErrFuture => 'لا يمكن أن يكون الوقت في المستقبل.';

  @override
  String get vitalsErrNoProfile =>
      'لم يتم اختيار ملف شخصي. ارجع وحاول مرة أخرى.';

  @override
  String get vitalsSaveFailed =>
      'تعذّر حفظ القراءة. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get vitalsSavePermission =>
      'ليس لديك صلاحية إضافة قراءات لهذا الملف الشخصي.';

  @override
  String get vitalsOptional => 'اختياري';

  @override
  String vitalsLast(String value, String unit, String when) {
    return 'الأخيرة: $value $unit ($when)';
  }

  @override
  String get vitalsNoReadings => 'لا توجد قراءات بعد. اضغط + لتسجيل أول قراءة.';

  @override
  String get vitalsLoadFailed =>
      'تعذّر تحميل القراءات. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get vitalsRetry => 'إعادة المحاولة';

  @override
  String vitalsLoggedToday(int count, int total) {
    return 'تم تسجيل $count من $total مؤشرات اليوم';
  }

  @override
  String get symptomNoMedication => 'لا يوجد دواء مرتبط';

  @override
  String get symptomPrivacyNote =>
      'مرئي فقط للأشخاص الذين لديهم صلاحية الوصول إلى البيانات الصحية لهذا الملف الشخصي';

  @override
  String get healthSyncTitle => 'مزامنة البيانات الصحية';

  @override
  String healthSyncSubtitle(String app) {
    return 'استورد ضغط الدم والجلوكوز والوزن ومعدل ضربات القلب من $app.';
  }

  @override
  String get healthSyncButton => 'مزامنة الآن';

  @override
  String healthSyncLast(String when) {
    return 'آخر مزامنة: $when';
  }

  @override
  String get healthSyncNever => 'لم تتم المزامنة بعد';

  @override
  String healthSyncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم استيراد $count قراءات جديدة',
      one: 'تم استيراد قراءة جديدة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get healthSyncNothingNew => 'محدّث بالفعل';

  @override
  String get healthSyncProOnly => 'مزامنة البيانات الصحية جزء من خطة Pro.';

  @override
  String get healthSyncSeePlans => 'عرض الخطط';

  @override
  String healthSyncDenied(String app) {
    return 'لم يتم منح الإذن. يمكنك السماح بالوصول من $app.';
  }

  @override
  String healthSyncUnavailable(String app) {
    return '$app غير متاح على هذا الجهاز.';
  }

  @override
  String get healthSyncFailed =>
      'فشلت المزامنة. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get symptomSelectMedication => 'اختر الدواء (اختياري)';

  @override
  String get symptomNoMedicationsFound =>
      'لم يتم العثور على أدوية لهذا الملف الشخصي.';

  @override
  String get symptomErrNameEmpty => 'يرجى إدخال اسم العرض.';

  @override
  String symptomErrNameTooLong(int max) {
    return 'اسم العرض طويل جدًا (الحد الأقصى $max حرفًا).';
  }

  @override
  String symptomErrNotesTooLong(int max) {
    return 'الملاحظات طويلة جدًا (الحد الأقصى $max حرفًا).';
  }

  @override
  String get symptomSaveFailed =>
      'تعذّر حفظ العرض. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get symptomSavePermission =>
      'ليس لديك صلاحية إضافة أعراض لهذا الملف الشخصي.';

  @override
  String get symptomRecorded => 'تم تسجيل العرض';

  @override
  String symptomRecordedFor(String name) {
    return 'تم تسجيل العرض لـ $name';
  }

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
  String helpSupportVersion(String version, String build) {
    return 'MedRemind v$version (إصدار $build)';
  }

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
  String aboutVersion(String version, String build) {
    return 'الإصدار $version (إصدار $build)';
  }

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

  @override
  String get doctorsTitle => 'الأطباء';

  @override
  String get doctorsAdd => 'إضافة طبيب';

  @override
  String get doctorsAdded => 'تمت إضافة الطبيب بنجاح';

  @override
  String doctorsCountOnFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أطباء مسجّلون',
      one: 'طبيب واحد مسجّل',
    );
    return '$_temp0';
  }

  @override
  String get doctorsEmptyTitle => 'لا يوجد أطباء مسجّلون';

  @override
  String get doctorsEmptySubtitle => 'أضف طبيبًا لربط الوصفات الطبية';

  @override
  String get doctorsUpcomingVisits => 'الزيارات القادمة';

  @override
  String doctorsAppointmentsScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مواعيد مجدولة',
      one: 'موعد واحد مجدول',
    );
    return '$_temp0';
  }

  @override
  String get doctorsView => 'عرض →';

  @override
  String get doctorsHint => 'اضغط على طبيب لعرض التفاصيل أو التعديل';

  @override
  String doctorsMedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أدوية',
      one: 'دواء واحد',
    );
    return '$_temp0';
  }

  @override
  String get doctorsDetailsSection => 'بيانات الطبيب';

  @override
  String get doctorsFieldFullName => 'الاسم الكامل *';

  @override
  String get doctorsHintFullName => 'أدخل الاسم الكامل';

  @override
  String get doctorsFieldSpecialty => 'التخصص';

  @override
  String get doctorsHintSpecialty => 'أدخل التخصص';

  @override
  String get doctorsFieldPhone => 'رقم الهاتف';

  @override
  String get doctorsHintPhone => 'أدخل رقم الهاتف';

  @override
  String get doctorsFieldClinic => 'العيادة / العنوان (اختياري)';

  @override
  String get doctorsHintClinic => 'أدخل العيادة أو العنوان';

  @override
  String get doctorsLinkMedications => 'ربط بالأدوية';

  @override
  String get doctorsLinkPrompt => 'ما الأدوية التي يصفها هذا الطبيب؟';

  @override
  String get doctorsSave => 'حفظ الطبيب';

  @override
  String get doctorsNameRequired => 'يرجى إدخال الاسم الكامل للطبيب.';

  @override
  String get medsTitle => 'الأدوية';

  @override
  String medsMemberMedications(String name) {
    return 'أدوية $name';
  }

  @override
  String medsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أدوية نشطة',
      one: 'دواء نشط واحد',
    );
    return '$_temp0';
  }

  @override
  String get medsManageHeader => 'إدارة';

  @override
  String get medsQuickTools => 'أدوات سريعة';

  @override
  String get medsInventory => 'المخزون';

  @override
  String medsLowBadge(int count) {
    return '$count منخفض';
  }

  @override
  String get medsAllergies => 'الحساسية';

  @override
  String get medsSideEffects => 'الآثار الجانبية';

  @override
  String get medsPharmacy => 'الصيدلية';

  @override
  String get medsSearchHint => 'ابحث عن الأدوية...';

  @override
  String medsTabActive(int count) {
    return 'النشطة ($count)';
  }

  @override
  String medsTabArchived(int count) {
    return 'المؤرشفة ($count)';
  }

  @override
  String get medsEmptyArchived => 'لا توجد أدوية مؤرشفة';

  @override
  String get medsEmpty => 'لم يتم العثور على أدوية';

  @override
  String medsMovedToArchived(String name) {
    return 'تم نقل $name إلى الأرشيف';
  }

  @override
  String get medsDiscontinueError => 'تعذّر إيقاف الدواء. حاول مرة أخرى.';

  @override
  String get medsDiscontinueBarrierLabel => 'إغلاق إيقاف الدواء';

  @override
  String get medsDiscontinue => 'إيقاف';

  @override
  String get medsLowStock => 'مخزون منخفض';

  @override
  String get medsBadgeActive => 'نشط';

  @override
  String get medsScheduleNotSet => 'لم يتم ضبط الجدول';

  @override
  String get medsFrequencyAsNeeded => 'عند الحاجة';

  @override
  String medsFrequencySelectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count× في الأيام المحددة',
      one: '1× في الأيام المحددة',
    );
    return '$_temp0';
  }

  @override
  String medsFrequencyCyclical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count× دوري',
      one: '1× دوري',
    );
    return '$_temp0';
  }

  @override
  String get medsFrequencyTapering => 'جدول تدريجي';

  @override
  String medsFrequencyDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count× يوميًا',
      one: '1× يوميًا',
    );
    return '$_temp0';
  }

  @override
  String medsNextDoseTomorrow(String time) {
    return 'غدًا $time';
  }

  @override
  String medsNextDoseWeekday(String day, String time) {
    return '$day $time';
  }

  @override
  String medsEnds(String date) {
    return 'ينتهي في $date';
  }

  @override
  String medsNext(String time) {
    return 'التالي: $time';
  }

  @override
  String get medsWeekdayMon => 'الإثنين';

  @override
  String get medsWeekdayTue => 'الثلاثاء';

  @override
  String get medsWeekdayWed => 'الأربعاء';

  @override
  String get medsWeekdayThu => 'الخميس';

  @override
  String get medsWeekdayFri => 'الجمعة';

  @override
  String get medsWeekdaySat => 'السبت';

  @override
  String get medsWeekdaySun => 'الأحد';

  @override
  String get medsFormCapsule => 'كبسولة';

  @override
  String get medsFormDrops => 'قطرات';

  @override
  String get medsFormInjection => 'حقنة';

  @override
  String medsDayOf(int day, int total) {
    return 'اليوم $day من $total';
  }

  @override
  String medsDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count أيام',
      one: 'بقي يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String medsUnitTablet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أقراص',
      one: 'قرص',
    );
    return '$_temp0';
  }

  @override
  String medsUnitCapsule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'كبسولات',
      one: 'كبسولة',
    );
    return '$_temp0';
  }

  @override
  String medsUnitBottle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'زجاجات',
      one: 'زجاجة',
    );
    return '$_temp0';
  }

  @override
  String medsUnitDose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جرعات',
      one: 'جرعة',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTitle => 'المخزون';

  @override
  String inventoryMedicationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أدوية',
      one: 'دواء واحد',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTrackedSupply => 'المخزون المتتبَّع';

  @override
  String inventoryLowStockCount(int count) {
    return '$count مخزون منخفض';
  }

  @override
  String get inventoryFilterAll => 'الكل';

  @override
  String get inventoryFilterLow => 'مخزون منخفض';

  @override
  String get inventoryFilterOk => 'جيد';

  @override
  String get inventoryEmptyFilter => 'لا توجد أدوية في هذا الفلتر';

  @override
  String get inventoryStatusLow => 'منخفض';

  @override
  String get inventoryStatusOk => 'جيد';

  @override
  String get inventoryRunningLow => 'على وشك النفاد — اطلب إعادة التعبئة';

  @override
  String get inventoryRefill => 'إعادة تعبئة →';

  @override
  String get inventoryAdjustCount => 'ضبط العدد';

  @override
  String get inventorySufficient => 'كمية كافية';

  @override
  String get inventorySufficientNext => 'كافٍ حتى إعادة التعبئة التالية';

  @override
  String get inventoryEdit => 'تعديل';

  @override
  String get inventoryAutoSyncTitle => 'مزامنة تلقائية مع الصيدلية';

  @override
  String get inventoryAutoSyncSubtitle =>
      'اربط صيدليتك للحصول على تحديثات تلقائية لإعادة التعبئة';

  @override
  String get inventoryAutoSyncPending =>
      'مزامنة الصيدلية التلقائية قيد الانتظار';

  @override
  String inventoryCountUpdated(String name, int count) {
    return 'تم تحديث $name إلى $count';
  }

  @override
  String inventorySupplyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count أيام',
      one: '~1 يوم',
    );
    return '$_temp0';
  }

  @override
  String get inventoryAdjustReasonLabel => 'سبب التعديل (اختياري)';

  @override
  String get inventoryAdjustReasonHint => 'سبب التعديل (اختياري)...';

  @override
  String get inventoryAdjustSave => 'حفظ العدد';

  @override
  String inventoryCurrentOnHand(int quantity, String unit) {
    return 'المتوفر حاليًا: $quantity $unit';
  }

  @override
  String inventoryAfterRefill(int quantity) {
    return 'بعد إعادة التعبئة: $quantity';
  }

  @override
  String inventoryFullBottle(int quantity) {
    return 'زجاجة كاملة: $quantity';
  }

  @override
  String inventoryHalfPack(int quantity) {
    return 'نصف عبوة: $quantity';
  }

  @override
  String get medFormExtendedRelease => 'إطلاق ممتد';

  @override
  String get medRouteOral => 'فموي';

  @override
  String get medRouteSubcutaneous => 'تحت الجلد';

  @override
  String get medConditionDiabetes => 'السكري';

  @override
  String get medConditionType2Diabetes => 'السكري من النوع 2';

  @override
  String get medConditionHighBloodPressure => 'ارتفاع ضغط الدم';

  @override
  String get medConditionHypertension => 'ارتفاع ضغط الدم';

  @override
  String get medConditionHeartHealth => 'صحة القلب';

  @override
  String get medConditionHighCholesterol => 'ارتفاع الكوليسترول';

  @override
  String get medConditionBacterialInfection => 'عدوى بكتيرية';

  @override
  String get medConditionPainInflammation => 'الألم والالتهاب';

  @override
  String get medConditionBoneHealth => 'صحة العظام';

  @override
  String get medConditionAcidReflux => 'الارتجاع الحمضي';

  @override
  String get addMedDailyDose => 'جرعة يومية';

  @override
  String addMedCommonFor(String condition) {
    return 'شائع لـ: $condition';
  }

  @override
  String get addManualColorWhite => 'أبيض';

  @override
  String get addManualColorYellow => 'أصفر';

  @override
  String get addManualColorPink => 'وردي';

  @override
  String get addManualColorBlue => 'أزرق';

  @override
  String get addManualColorOrange => 'برتقالي';

  @override
  String get addManualColorPeach => 'خوخي';

  @override
  String get addManualColorGreen => 'أخضر';

  @override
  String get addManualDraftSaved => 'تم حفظ المسودة — أكملها لاحقًا!';

  @override
  String get addMedTitle => 'إضافة دواء';

  @override
  String get addManualRxVerified => 'وصفة موثّقة';

  @override
  String get medsMedicationDetails => 'تفاصيل الدواء';

  @override
  String get medsFieldName => 'اسم الدواء';

  @override
  String get medsFieldStrength => 'التركيز';

  @override
  String get medsFieldForm => 'شكل الدواء';

  @override
  String get addManualSelectForm => 'اختر الشكل';

  @override
  String get addManualColorOptional => 'اللون (اختياري)';

  @override
  String get medsFieldInstructions => 'تعليمات خاصة';

  @override
  String get addManualOptional => 'اختياري';

  @override
  String get addManualInstructionsHint =>
      'مثال: تناوله مع الطعام بعد الإفطار، تجنّب الجريب فروت...';

  @override
  String get addManualContinueToSchedule => 'المتابعة إلى الجدول ←';

  @override
  String get addManualSaveDraft => 'حفظ كمسودة';

  @override
  String get addManualNameHint => 'أدخل اسم الدواء';

  @override
  String get addManualMatchesIndex => 'مطابق للفهرس السريري';

  @override
  String get addManualStrengthHint => 'مثال: 500';

  @override
  String get addManualFormOther => 'أخرى';

  @override
  String get addManualFormOtherSubtitle => 'أدخل شكل دواء آخر';

  @override
  String get addManualCustomForm => 'شكل دواء مخصص';

  @override
  String get addManualCustomFormHint => 'مثال: كريم، بخاخ، لاصقة، سبراي...';

  @override
  String get addManualCustomFormRequired => 'يرجى إدخال شكل الدواء';

  @override
  String get addManualInteractionTitle => 'فحوصات التفاعل التلقائية';

  @override
  String get addManualInteractionBody =>
      'سنقارن هذه الجرعة بأدويتك المسجلة مسبقًا في الخطوة التالية.';

  @override
  String addMedSelected(String name, String strength) {
    return 'تم اختيار $name $strength — التفاصيل بعد ذلك!';
  }

  @override
  String get addMedPrivateNote => 'خاص ومشفّر على هذا الجهاز';

  @override
  String get addMedScanLabel => 'مسح الملصق';

  @override
  String get addMedSearch => 'بحث';

  @override
  String get addMedManualEntry => 'إدخال يدوي';

  @override
  String addMedMatchingCount(int count) {
    return 'الأدوية المطابقة ($count)';
  }

  @override
  String get addMedFdaApproved => 'معتمد من FDA';

  @override
  String get addMedTipTitle => 'نصيحة: ابحث عن النقش';

  @override
  String get addMedTipBody =>
      'معظم أقراص الميتفورمين تحمل أرقامًا مثل \'500\' أو \'M\' مطبوعة على الوجه لضمان مطابقة الجرعة بدقة.';

  @override
  String get addMedCantFind => 'لم تجد دواءك؟';

  @override
  String get addMedAddManually => 'إضافة يدوية';

  @override
  String get addMedEmptyTitle => 'ابحث عن دواء';

  @override
  String get addMedEmptySubtitle => 'أدخل اسم الدواء أعلاه أو امسح ملصقه';

  @override
  String get addMedNoResultsTitle => 'لم يتم العثور على أدوية';

  @override
  String addMedNoResultsFor(String query) {
    return 'لا نتائج لـ \"$query\"';
  }

  @override
  String get addMedSelectAction => 'اختر ‹';

  @override
  String get reviewScanNameRequired => 'يرجى إدخال اسم الدواء.';

  @override
  String get reviewScanStrengthRequired => 'يرجى إدخال تركيز الدواء.';

  @override
  String get reviewScanTitle => 'مراجعة المسح';

  @override
  String get scanCaptureFailed => 'فشل الالتقاط — حاول مجددًا.';

  @override
  String get scanCaptureError => 'تعذّر التقاط الصورة. حاول مجددًا.';

  @override
  String get scanGalleryError => 'تعذّر فتح الصورة. حاول مجددًا.';

  @override
  String scanDetectedOne(String name) {
    return '✓ تم اكتشاف: $name';
  }

  @override
  String scanDetectedCount(int count) {
    return '✓ تم اكتشاف $count من الأدوية';
  }

  @override
  String get scanTextNoMedicine =>
      'تم اكتشاف نص، لكن تعذّر التعرّف على تفاصيل الدواء.';

  @override
  String get scanNoText =>
      'لم يتم اكتشاف نص. اجعل المستند واضحًا ومسطحًا وجيد الإضاءة.';

  @override
  String get scanReadError => 'تعذّر قراءة الصورة. حاول مجددًا.';

  @override
  String get scanRescanAgain => 'يرجى مسح الدواء مرة أخرى.';

  @override
  String get scanFitFrameHint => 'ضع ملصق الدواء أو الوصفة كاملة داخل الإطار';

  @override
  String get scanEnterManually => 'إدخال الدواء يدويًا';

  @override
  String get scanRetakePhoto => 'إعادة التقاط الصورة';

  @override
  String get scanReadingPrescription => 'جارٍ قراءة الوصفة...';

  @override
  String get scanStatusReading => 'جارٍ القراءة';

  @override
  String get scanStatusFound => 'تم العثور';

  @override
  String get scanStatusInFrame => 'داخل الإطار';

  @override
  String get scanStatusReady => 'جاهز';

  @override
  String get scanCameraUnavailable => 'الكاميرا غير متاحة';

  @override
  String get scanStartingCamera => 'جارٍ تشغيل الكاميرا...';

  @override
  String get scanCapturingDocument => 'جارٍ التقاط المستند...';

  @override
  String get scanReadingMedicineText => 'جارٍ قراءة نص الدواء...';

  @override
  String get scanMedicineDetected => 'تم اكتشاف دواء';

  @override
  String scanMedicinesDetected(int count) {
    return 'تم اكتشاف $count من الأدوية';
  }

  @override
  String get scanImageCaptured => 'تم التقاط الصورة';

  @override
  String get scanMedicineOrRxDetected => 'تم اكتشاف دواء أو وصفة';

  @override
  String get scanPointCameraHint => 'وجّه الكاميرا نحو الدواء أو الوصفة';

  @override
  String get scanFlash => 'الفلاش';

  @override
  String get scanShutter => 'مسح';

  @override
  String get scanGallery => 'المعرض';

  @override
  String get scanTryAgain => 'حاول مجددًا';

  @override
  String scanMedicineBadgeNumber(int index) {
    return 'تم اكتشاف الدواء $index';
  }

  @override
  String get scanMedicineBadgeSingular => 'تم اكتشاف دواء';

  @override
  String get scanFieldStrength => 'التركيز';

  @override
  String get scanFieldForm => 'الشكل';

  @override
  String get scanFieldFrequency => 'التكرار';

  @override
  String get medsFieldInstructionsShort => 'التعليمات';

  @override
  String get scanReviewAdd => 'مراجعة وإضافة الدواء';

  @override
  String get stepSchedule => 'الجدول';

  @override
  String get reviewScanScanned => 'تم المسح';

  @override
  String get reviewScanReadSuccess =>
      'قرأنا هذه التفاصيل من ملصقك — تحقق منها وصحّح إذا لزم الأمر!';

  @override
  String get reviewScanInstructionsHint => 'أدخل تعليمات الدواء';

  @override
  String get reviewScanStrengthUnclear =>
      'كان حقل التركيز غير واضح في الصورة — يرجى التحقق يدويًا.';

  @override
  String get reviewScanRequired => 'مطلوب';

  @override
  String get reviewScanStrengthHint => 'أدخل التركيز، مثال: 500mg';

  @override
  String get reviewScanConfirmContinue => 'تأكيد ومتابعة ←';

  @override
  String get couldNotLoadSettings => 'Could not load settings';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Sync reminder habits with your daily rhythm';

  @override
  String get sectionAlertTypes => 'Alert Types';

  @override
  String get sectionEscalationTiming => 'Escalation Timing';

  @override
  String get sectionQuietHours => 'Quiet Hours';

  @override
  String get alertDoseTitle => 'Dose Reminders';

  @override
  String get alertDoseSubtitle => 'Remind me at each dose time';

  @override
  String get alertRefillTitle => 'Refill Alerts';

  @override
  String get alertRefillSubtitle => 'When supply runs low';

  @override
  String get alertCaregiverTitle => 'Caregiver Alerts';

  @override
  String get alertCaregiverSubtitle => 'Alert family if a dose is missed';

  @override
  String get escalationLabel => 'Re-remind after';

  @override
  String get escalationMinutesDesc => 'If a dose is unconfirmed, remind again';

  @override
  String get quietHoursLabel => 'Quiet Hours';

  @override
  String get quietHoursRange => '10:00 PM – 7:00 AM';

  @override
  String get btnSavePreferences => 'Save Preferences';

  @override
  String get snackbarSaved => 'Preferences saved';

  @override
  String get snackbarSavedDone => 'Preferences Saved!';

  @override
  String snackbarSaveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String minutesFormat(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get permTitle => 'Enable Dose Reminders';

  @override
  String get permSubtitle =>
      'MedRemind needs your permission to send dose reminders — at the right time, even when the app is closed.';

  @override
  String get permCardNotificationsTitle => 'Show notifications';

  @override
  String get permCardNotificationsSubtitle =>
      'Receive dose reminders with Taken / Skip / Snooze buttons.';

  @override
  String get permCardExactAlarmsTitle => 'Set exact alarms';

  @override
  String get permCardExactAlarmsSubtitle =>
      'Reminders fire at the exact dose time (required on Android 12+).';

  @override
  String get permBatteryTitle =>
      'Battery optimisation (Xiaomi / Oppo / Samsung)';

  @override
  String get permBatterySubtitle =>
      'Some phone makers kill background apps aggressively. If reminders don\'t fire, whitelist MedRemind in battery settings.';

  @override
  String get permStatusGranted => 'Permissions granted — reminders are on.';

  @override
  String get permStatusDenied =>
      'Permissions denied — you can enable them later in Settings.';

  @override
  String get permStatusError => 'Could not verify permissions — try again.';

  @override
  String get permBtnContinue => 'Continue Anyway';

  @override
  String get permBtnSkip => 'Skip for now';

  @override
  String get appBlockedUpdateTitle => 'التحديث مطلوب';

  @override
  String get appBlockedUpdateBody =>
      'يلزم إصدار أحدث من MedRemind للحفاظ على تذكيراتك آمنة ودقيقة. يرجى التحديث للمتابعة.';

  @override
  String get appBlockedUpdateButton => 'حدّث الآن';

  @override
  String get appBlockedMaintenanceTitle => 'قيد الصيانة';

  @override
  String get appBlockedMaintenanceBody =>
      'MedRemind غير متاح مؤقتًا أثناء إجراء تحسينات. ستظل التذكيرات المجدولة بالفعل على هذا الجهاز تعمل. يرجى المحاولة مرة أخرى قريبًا.';

  @override
  String get appBlockedRetryButton => 'حاول مرة أخرى';

  @override
  String get legalReconsentTitle => 'لقد حدّثنا شروطنا';

  @override
  String get legalReconsentBody =>
      'لمواصلة استخدام MedRemind، يرجى مراجعة شروط الخدمة وسياسة الخصوصية المحدّثة والموافقة عليها. ستظل التذكيرات المجدولة تعمل في هذه الأثناء.';

  @override
  String get legalReconsentAgree =>
      'لقد قرأت شروط الخدمة وسياسة الخصوصية وأوافق عليهما';

  @override
  String get legalReconsentAccept => 'موافقة ومتابعة';

  @override
  String get legalReconsentSignOut => 'تسجيل الخروج';

  @override
  String get legalReconsentError =>
      'تعذّر حفظ اختيارك. يرجى المحاولة مرة أخرى.';

  @override
  String get supportRequestTitle => 'إرسال طلب';

  @override
  String get supportRequestIntro =>
      'أخبرنا بما حدث أو بما تحتاجه. سيردّ عليك فريقنا عبر البريد الإلكتروني.';

  @override
  String get supportRequestSubjectLabel => 'الموضوع';

  @override
  String get supportRequestSubjectHint => 'مثال: التذكيرات لا ترنّ';

  @override
  String get supportRequestBodyLabel => 'التفاصيل';

  @override
  String get supportRequestBodyHint => 'صف المشكلة وما كنت تتوقع حدوثه';

  @override
  String get supportRequestSend => 'إرسال الطلب';

  @override
  String get supportRequestSubjectRequired => 'يرجى إدخال الموضوع';

  @override
  String get supportRequestBodyRequired => 'يرجى وصف طلبك';

  @override
  String get supportRequestSent =>
      'تم إرسال الطلب. شكرًا لك، سنردّ عبر البريد الإلكتروني.';

  @override
  String get supportRequestQueued =>
      'لا يوجد اتصال. تم حفظ طلبك وسيُرسل تلقائيًا عند عودة الاتصال.';

  @override
  String get supportRequestError => 'تعذّر إرسال طلبك. يرجى المحاولة مرة أخرى.';

  @override
  String get supportRequestSignIn => 'يرجى تسجيل الدخول لإرسال طلب.';

  @override
  String helpSupportEmailOpenFailed(String email) {
    return 'تعذّر فتح تطبيق البريد. راسلنا على $email';
  }

  @override
  String get appLockTitle => 'MedRemind مقفل';

  @override
  String get appLockSubtitle =>
      'افتح القفل ببصمتك أو وجهك أو رمز PIN الخاص بالهاتف للمتابعة.';

  @override
  String get appLockUnlock => 'فتح القفل';

  @override
  String get appLockSignOut => 'تسجيل الخروج';

  @override
  String get appLockReasonUnlock => 'فتح قفل MedRemind';

  @override
  String get appLockReasonEnable => 'أكّد لتفعيل قفل التطبيق';

  @override
  String get appLockReasonDisable => 'أكّد لإيقاف قفل التطبيق';

  @override
  String get appLockUnsupported =>
      'قم أولًا بإعداد قفل الشاشة أو البصمة على هذا الهاتف لاستخدام قفل التطبيق.';

  @override
  String get appLockNotVerified =>
      'تعذّر التحقق من هويتك. يرجى المحاولة مرة أخرى.';
}
