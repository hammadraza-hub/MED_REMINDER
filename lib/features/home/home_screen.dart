import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/app_avatar.dart';
import 'home_data.dart';

/// ============================================================
/// HOME — app ka dil!
///
/// UI Layer: SIRF dikhata hai — saara data HomeData se aata hai.
/// Bottom navigation MainShell ka kaam hai — ye screen bar NAHI rakhti!
/// Backend aane par: HomeData ke methods Firebase se data denge,
/// ye screen ka EK LINE change nahi hoga! 🎯
/// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';
  String _selectedMember = 'Sarah'; // konsa member selected — UI state

  // ============ STATE — HomeData se initialize ============
  // Backend: ye lists Firebase Stream se update hongi
  late final List<Dose> _doses = HomeData.todayDoses();
  List<FamilyMember> _members = HomeData.familyMembers();

  // ============ COMPUTED — HomeData ke pure functions ============
  int get _takenCount => HomeData.takenCount(_doses);
  int get _pendingCount => HomeData.pendingCount(_doses);
  int get _missedCount => HomeData.missedCount(_doses);
  double get _progress => HomeData.progress(_doses);

  // ============ FILTERED ============
  List<Dose> get _filteredDoses {
    switch (_selectedFilter) {
      case 'Pending':
        return _doses.where((d) => d.status == DoseStatus.pending).toList();
      case 'Taken':
        return _doses.where((d) => d.status == DoseStatus.taken).toList();
      default:
        return _doses;
    }
  }

  // ============ DOSE ACTIONS — backend: yahan DB update hoga ============
  void _markTaken(Dose dose) {
    setState(() => dose.status = DoseStatus.taken);
    // TODO Backend: FirebaseFirestore.updateDose(dose.id, taken)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${dose.name} marked as taken ✓')));
  }

  void _skipDose(Dose dose) {
    setState(() => dose.status = DoseStatus.skipped);
    // TODO Backend: update DB
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${dose.name} skipped')));
  }

  void _snoozeDose(Dose dose) {
    // TODO Backend: notification reschedule
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${dose.name} snoozed — 10 min mein phir reminder!'),
      ),
    );
  }

  void _switchMember(FamilyMember member) {
    if (member.name == _selectedMember) return; // pehle se selected

    setState(() => _selectedMember = member.name);
    // TODO Backend: is member ke doses reload karo

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Switched to ${member.name}'s medicines")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Column(
        children: [
          // ============ DARK HEADER ============
          _HomeHeader(
            greeting: HomeData.greeting(), // TIME-based!
            dateLabel: HomeData.dateLabel(),
            streakDays: HomeData.streakDays(),
            userImagePath: HomeData.userProfileImage(), // null → icon
            selectedMemberName: _selectedMember,
            members: _members,
            onMemberTap: _switchMember,
          ),

          // ============ SCROLLABLE CONTENT (tablet: 480px column) ============
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildHomeContent(),
              ),
            ),
          ),
        ],
      ),

      // ============ FLOATING ADD BUTTON (tablet-aware) ============
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          // Tablet par content column ke hisab se align
          right: MediaQuery.sizeOf(context).width > 480
              ? (MediaQuery.sizeOf(context).width - 480) / 2 + 16
              : 0,
        ),
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Add Medicine screen — agla step
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add medicine — screen agle step mein!'),
              ),
            );
          },
          backgroundColor: AppColors.formAccent,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 27),
        ),
      ),
    );
  }

  // ================= HOME CONTENT =================
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Progress Card (LIVE) ----
          _ProgressCard(
            progress: _progress,
            taken: _takenCount,
            pending: _pendingCount,
            missed: _missedCount,
          ),
          const SizedBox(height: 16),

          // ---- Quick Access ----
          const _QuickAccessSection(),
          const SizedBox(height: 16),

          // ---- Schedule + Filters ----
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.formAccent,
                  ),
                ),
              ),
              for (final filter in ['All', 'Pending', 'Taken'])
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: _FilterChip(
                    label: filter,
                    isSelected: filter == _selectedFilter,
                    onTap: () => setState(() => _selectedFilter = filter),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ---- Dose Cards (EK renderer — sab medicines!) ----
          for (final dose in _filteredDoses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DoseCard(
                dose: dose,
                onTaken: () => _markTaken(dose),
                onSkip: () => _skipDose(dose),
                onSnooze: () => _snoozeDose(dose),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// DARK HEADER — greeting + family + streak
// ============================================================
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.dateLabel,
    required this.streakDays,
    this.userImagePath,
    required this.selectedMemberName,
    required this.members,
    required this.onMemberTap,
  });

  final String greeting;
  final String dateLabel;
  final int streakDays;
  final String? userImagePath;
  final String selectedMemberName;
  final List<FamilyMember> members;
  final ValueChanged<FamilyMember> onMemberTap;

  @override
  Widget build(BuildContext context) {
    // Dark header → white status bar icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============ ROW 1: Avatar + Greeting + Bell ============
              Row(
                children: [
                  // Image ho to image, warna icon — khud decide!
                  AppAvatar(
                    size: 30,
                    imagePath: userImagePath,
                    ringColor: AppColors.surface,
                    ringWidth: 2,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$greeting, Sarah 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Notification bell + red dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.notificationDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 11),

              // ============ ROW 2: Family Members ============
              Row(
                children: [
                  for (var i = 0; i < members.length; i++) ...[
                    if (i != 0) const SizedBox(width: 17),
                    _FamilyMemberAvatar(
                      member: members[i],
                      isSelected: members[i].name == selectedMemberName,
                      onTap: () => onMemberTap(members[i]),
                    ),
                  ],
                  const SizedBox(width: 17),

                  // Add member
                  const _AddMemberButton(),
                ],
              ),
              const SizedBox(height: 10),

              // ============ ROW 3: Date + Streak ============
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppColors.headerSubtext,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.formAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.streakFlame,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streakDays Day Streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FAMILY MEMBER AVATAR — tap → switch
// ============================================================
class _FamilyMemberAvatar extends StatelessWidget {
  const _FamilyMemberAvatar({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final FamilyMember member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Smart avatar — member ki image ya icon, khud decide!
          AppAvatar(
            size: 38,
            imagePath: member.imagePath,
            ringColor: isSelected ? AppColors.avatarSelected : Colors.white54,
            ringWidth: isSelected ? 2 : 1,
          ),
          const SizedBox(height: 3),
          Text(
            member.name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Add member flow — Family screen reuse ho sakti hai!
      },
      child: const Column(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.transparent,
            child: Icon(Icons.add, color: Colors.white, size: 20),
          ),
          SizedBox(height: 3),
          Text('Add', style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

// ============================================================
// PROGRESS CARD — ring + dots (LIVE!)
// ============================================================
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.taken,
    required this.pending,
    required this.missed,
  });

  final double progress;
  final int taken;
  final int pending;
  final int missed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ---- Ring ----
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress, // LIVE — backend: doses se compute
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.formAccent,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Daily',
                      style: TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 8),

          // ---- Dot Stats (LIVE values!) ----
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dotStat(AppColors.success, '$taken Taken'),
                const SizedBox(height: 8),
                _dotStat(AppColors.accentOrange, '$pending Pending'),
                const SizedBox(height: 8),
                _dotStat(AppColors.error, '$missed Missed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dotStat(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// QUICK ACCESS — 4 tiles
// ============================================================
class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection();

  static const List<({IconData icon, String label})> _items = [
    (icon: Icons.monitor_heart_outlined, label: 'Vitals'),
    (icon: Icons.medical_services_outlined, label: 'Doctors'),
    (icon: Icons.auto_awesome, label: 'AI Assist'),
    (icon: Icons.groups_2_outlined, label: 'Family'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUICK ACCESS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Shortcuts',
              style: TextStyle(color: AppColors.formAccent, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i != 0) const SizedBox(width: 7),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Feature screens — baad mein
                  },
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            _items[i].icon,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].label,
                          style: const TextStyle(
                            color: AppColors.formAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ============================================================
// FILTER CHIP
// ============================================================
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.formAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.formAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.formAccent,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DOSE CARD — EK renderer, SAB medicines!
// (Aur yahi asli OOP hai — 5 medicines, 1 widget!) 💪
// ============================================================
class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.onTaken,
    required this.onSkip,
    required this.onSnooze,
  });

  final Dose dose;
  final VoidCallback onTaken;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.status == DoseStatus.taken;
    final isSkipped = dose.status == DoseStatus.skipped;
    final isPending = dose.status == DoseStatus.pending;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        // Pending card = green highlight border + shadow (design!)
        border: isPending
            ? Border.all(color: AppColors.formAccent, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isPending
                ? AppColors.formAccent.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.035),
            offset: const Offset(0, 4),
            blurRadius: isPending ? 0 : 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // ================= ROW 1: Info =================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardFill,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isTaken ? Icons.check_rounded : Icons.medication_outlined,
                  size: 22,
                  color: isTaken
                      ? AppColors.success
                      : (isPending
                            ? AppColors.formAccent
                            : AppColors.fieldHint),
                ),
              ),
              const SizedBox(width: 11),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dose.name} ${dose.doseAmount}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dose.details,
                      style: const TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isTaken ? Icons.check_circle : Icons.access_time,
                          size: 11,
                          color: isTaken
                              ? AppColors.success
                              : AppColors.formSubtitle,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dose.time,
                          style: TextStyle(
                            color: isTaken
                                ? AppColors.success
                                : AppColors.formSubtitle,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              _StatusBadge(status: dose.status),
            ],
          ),

          // ================= ROW 2: Buttons (sirf pending) =================
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _actionButton('✓ Taken', filled: true, onTap: onTaken),
                ),
                const SizedBox(width: 7),
                Expanded(child: _actionButton('Skip', onTap: onSkip)),
                const SizedBox(width: 7),
                Expanded(child: _actionButton('Snooze', onTap: onSnooze)),
              ],
            ),
          ],

          // ================= ROW 3: Refill (pending + low) =================
          if (isPending && dose.isRunningLow) ...[
            const SizedBox(height: 10),
            Container(
              height: 31,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: AppColors.hintBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.hintAccent,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${dose.name} running low · ${dose.daysLeft} days left',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.hintAccent,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Refill flow — baad mein
                    },
                    child: const Text(
                      'Refill →',
                      style: TextStyle(
                        color: AppColors.hintAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Skipped message
          if (isSkipped) ...[
            const SizedBox(height: 8),
            Text(
              'Skipped — kal se phir reminder aayega',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(
    String label, {
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap, // LIVE — parent se callback!
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.formAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColors.formAccent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DoseStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DoseStatus.pending:
        return _badge(
          background: AppColors.pendingBackground,
          foreground: AppColors.statusPendingText,
          text: 'PENDING',
        );
      case DoseStatus.taken:
        return _badge(
          background: AppColors.successBackground,
          foreground: AppColors.success,
          text: '✓ TAKEN',
        );
      case DoseStatus.upcoming:
        return _badge(
          background: AppColors.successBackground,
          foreground: AppColors.formAccent,
          text: 'UPCOMING',
        );
      case DoseStatus.skipped:
        return _badge(
          background: AppColors.hintBackground,
          foreground: AppColors.hintAccent,
          text: 'SKIPPED',
        );
    }
  }

  Widget _badge({
    required Color background,
    required Color foreground,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
