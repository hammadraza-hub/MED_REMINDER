/// ============================================================
/// PROFILES DATA — managed family members + demo adherence
///
/// MEMBER IDs:
/// Existing ProfileController IDs ke saath match karte hain:
/// local_sarah / local_mom / local_jake
///
/// Isliye tap-to-switch seedha ProfileController.selectProfile()
/// ko kaam karta hai — saari member-isolated screens auto-reload.
///
/// ADHERENCE STATS:
/// Abhi demo static hain (design mock).
/// TODO Backend:
/// Firestore se per-member adherence derive hoga (DoseEvents se).
/// ============================================================

class ManagedProfile {
  const ManagedProfile({
    required this.memberId,
    required this.displayName,
    required this.relationship,
    required this.medicationCount,
    required this.adherencePercent,
    required this.adherenceLabel,
    this.imagePath,
    this.todayLabel,
    this.todayIsPositive = true,
    this.statusChip,
    this.isStatusChipWarning = false,
    this.overdueLabel,
  });

  /// Stable member identity — ProfileController IDs se match.
  final String memberId;

  final String displayName;

  /// Self / Mother / Son etc.
  final String relationship;

  final String? imagePath;

  final int medicationCount;

  /// Today status line — "Today: 3/4 taken · 1 pending"
  final String? todayLabel;

  /// true → green check style | false → warning style
  final bool todayIsPositive;

  /// Right-side chip — "Needs Check-in"
  final String? statusChip;

  /// true → red chip | false → default chip
  final bool isStatusChipWarning;

  final int adherencePercent;

  /// "30d Score" / "30d Adherence"
  final String adherenceLabel;

  /// Overdue warning line — "1 afternoon dose overdue"
  final String? overdueLabel;
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class ProfilesData {
  /// Managed profiles list — seed + UI ke liye.
  ///
  /// MEMBER ISOLATION NOTE:
  /// Ye list khud "saare managed members" hai — isliye filter
  /// nahi lagta (yahi screen ka maqsad hai). Har card ka data
  /// uske apne memberId se juda hai.
  static List<ManagedProfile> managedProfiles() {
    return const [
      ManagedProfile(
        memberId: 'local_sarah',
        displayName: 'Sarah',
        relationship: 'Self',
        medicationCount: 3,
        todayLabel: 'Today: 3/4 taken · 1 pending',
        todayIsPositive: false,
        adherencePercent: 95,
        adherenceLabel: '30d Score',
      ),
      ManagedProfile(
        memberId: 'local_mom',
        displayName: 'Mom',
        relationship: 'Mother',
        medicationCount: 2,
        todayLabel: 'Today: All doses taken',
        todayIsPositive: true,
        adherencePercent: 86,
        adherenceLabel: '30d Adherence',
      ),
      ManagedProfile(
        memberId: 'local_jake',
        displayName: 'Jake',
        relationship: 'Son',
        medicationCount: 1,
        todayIsPositive: false,
        statusChip: 'Needs Check-in',
        isStatusChipWarning: true,
        adherencePercent: 76,
        adherenceLabel: '30d Adherence',
        overdueLabel: '1 afternoon dose overdue',
      ),
    ];
  }
}
