/// ============================================================
/// DATA MODELS — "backend-ready"
/// Backend aane par in classes mein fromJson() add hoga — UI same!
/// ============================================================

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
    required this.details,
    required this.time,
    required this.status,
    this.isRunningLow = false,
    this.daysLeft = 0,
  });

  final String name;
  final String doseAmount;
  final String details;
  final String time;
  DoseStatus status;
  bool isRunningLow;
  int daysLeft;

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
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ================= DATE =================
  static String dateLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[now.weekday - 1]}, '
        '${now.day} ${months[now.month - 1]} ${now.year}';
  }

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
      details: 'Tablet · 1x daily',
      time: '6:30 AM',
      status: DoseStatus.taken,
    ),
    Dose(
      name: 'Amlodipine',
      doseAmount: '5mg',
      details: 'Tablet · Before breakfast',
      time: '7:00 AM',
      status: DoseStatus.taken,
    ),
    Dose(
      name: 'Aspirin',
      doseAmount: '81mg',
      details: 'Tablet · After breakfast',
      time: '7:30 AM',
      status: DoseStatus.taken,
    ),
    Dose(
      name: 'Metformin',
      doseAmount: '500mg',
      details: 'Tablet · After breakfast',
      time: '8:30 AM',
      status: DoseStatus.pending,
      isRunningLow: true,
      daysLeft: 5,
    ),
    Dose(
      name: 'Vitamin D3 Drops',
      doseAmount: '1000 IU',
      details: 'Liquid · With dinner',
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
