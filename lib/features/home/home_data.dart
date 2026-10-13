/// ============================================================
/// DATA MODELS — "backend-ready"
/// Backend aane par in classes mein fromJson() add hoga — UI same!
///
/// IMPORTANT (localization):
/// Dose ke form/schedule jaise display text ko enum ke roop mein
/// rakha jata hai aur UI par AppLocalizations se resolve hota hai —
/// is liye language change par yeh bhi translate hota hai.
/// ============================================================
library;

import '../../l10n/app_localizations.dart';

/// Dose ki form (display text localized).
enum DoseForm { tablet, liquid }

/// Dose ka schedule (display text localized).
enum DoseSchedule { daily, beforeBreakfast, afterBreakfast, withDinner }

/// Dose form ka localized label.
String doseFormLabel(AppLocalizations l10n, DoseForm form) {
  return switch (form) {
    DoseForm.tablet => l10n.doseFormTablet,
    DoseForm.liquid => l10n.doseFormLiquid,
  };
}

/// Dose schedule ka localized label.
String doseScheduleLabel(AppLocalizations l10n, DoseSchedule schedule) {
  return switch (schedule) {
    DoseSchedule.daily => l10n.doseScheduleDaily,
    DoseSchedule.beforeBreakfast => l10n.doseScheduleBeforeBreakfast,
    DoseSchedule.afterBreakfast => l10n.doseScheduleAfterBreakfast,
    DoseSchedule.withDinner => l10n.doseScheduleWithDinner,
  };
}

/// Family member (header switcher)
class FamilyMember {
  const FamilyMember({
    required this.name,
    this.imagePath, // null → icon avatar | set → image avatar
  });

  final String name;

  /// Backend: family collection se photoURL
  final String? imagePath;
}

/// Dose states — type-safe
enum DoseStatus { taken, pending, upcoming, skipped }

/// Ek dose — poori info
class Dose {
  Dose({
    required this.name,
    required this.doseAmount,
    required this.form,
    required this.schedule,
    required this.time,
    required this.status,
    this.isRunningLow = false,
    this.daysLeft = 0,
  });

  final String name;
  final String doseAmount;
  final DoseForm form;
  final DoseSchedule schedule;
  final String time;
  DoseStatus status;
  bool isRunningLow;
  int daysLeft;

  /// UI-friendly localized dose detail line.
  String localizedDetails(AppLocalizations l10n) =>
      '${doseFormLabel(l10n, form)} · ${doseScheduleLabel(l10n, schedule)}';

  /// Backend: Dose.fromJson(json)
}

/// ============================================================
/// DATA PROVIDER — abhi dummy, baad mein backend
/// ============================================================
class HomeData {
  // ================= USER PROFILE IMAGE =================
  /// null = icon | TEST: 'assets/images/apni_image.png' likho!
  ///
  /// Backend: FirebaseAuth.instance.currentUser?.photoURL
  static String? userProfileImage() => null;

  // ================= GREETING — time ke hisab se =================
  //
  // Sirf bucket return karte hain; display text UI par
  // AppLocalizations se aata hai (is liye localized rehta hai).
  static String greetingBucket() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  // DATE:
  // UI par MaterialLocalizations.formatFullDate() use hota hai —
  // woh current locale ke hisab se localized date deta hai.

  // ================= STREAK =================
  /// Backend: dose history se calculate
  static int streakDays() => 12;

  // ================= FAMILY MEMBERS =================
  /// Backend: user ki family collection se
  ///
  /// TEST (image dekhne ke liye): koi image assets mein daal kar likho:
  /// FamilyMember(name: 'Mom', imagePath: 'assets/images/mom.png'),
  /// → Mom ki jagah image, baqi icon. Path hatao → icon wapas!
  static List<FamilyMember> familyMembers() => const [
    FamilyMember(name: 'Sarah'),
    FamilyMember(name: 'Mom'),
    FamilyMember(name: 'Jake'),
  ];

  // ================= TODAY'S DOSES =================
  /// Backend: selected member + date ke doses
  static List<Dose> todayDoses() => [
    Dose(
      name: 'Lisinopril',
      doseAmount: '10mg',
      form: DoseForm.tablet,
      schedule: DoseSchedule.daily,
      time: '6:30 AM',
      status: DoseStatus.taken,
    ),
    Dose(
      name: 'Amlodipine',
      doseAmount: '5mg',
      form: DoseForm.tablet,
      schedule: DoseSchedule.beforeBreakfast,
      time: '7:00 AM',
      status: DoseStatus.taken,
    ),
    Dose(
      name: 'Aspirin',
      doseAmount: '81mg',
      form: DoseForm.tablet,
      schedule: DoseSchedule.afterBreakfast,
      time: '7:30 AM',
      status: DoseStatus.taken,
    ),
    Dose(
      name: 'Metformin',
      doseAmount: '500mg',
      form: DoseForm.tablet,
      schedule: DoseSchedule.afterBreakfast,
      time: '8:30 AM',
      status: DoseStatus.pending,
      isRunningLow: true,
      daysLeft: 5,
    ),
    Dose(
      name: 'Vitamin D3 Drops',
      doseAmount: '1000 IU',
      form: DoseForm.liquid,
      schedule: DoseSchedule.withDinner,
      time: '8:00 PM',
      status: DoseStatus.upcoming,
    ),
  ];

  // ================= STATS — computed =================
  static int takenCount(List<Dose> doses) =>
      doses.where((d) => d.status == DoseStatus.taken).length;

  static int pendingCount(List<Dose> doses) =>
      doses.where((d) => d.status == DoseStatus.pending).length;

  static int missedCount(List<Dose> doses) =>
      doses.where((d) => d.status == DoseStatus.skipped).length;

  static double progress(List<Dose> doses) {
    final total = takenCount(doses) + pendingCount(doses);
    return total == 0 ? 0 : takenCount(doses) / total;
  }
}
