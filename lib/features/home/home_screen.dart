import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/members/local_member_repository.dart';
import '../../core/members/member_repository.dart';
import '../../core/profile/profile_controller.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/profile_photo_picker.dart';
import '../doctors/doctors_screen.dart';
import '../meds/meds_screen.dart';
import '../../features/profile/profiles_screen.dart';
import 'dose_action_sheet.dart';
import 'home_data.dart';
import 'streaks_stats_screen.dart';
import 'vitals_list_screen.dart';

/// ============================================================
/// HOME — app ka dil!
///
/// CURRENT DATA ARCHITECTURE:
///
/// Family members:
/// Home
///   ↓
/// MemberRepository
///   ↓
/// LocalMemberRepository
///   ↓
/// Drift / SQLite
///
/// Selected profile:
/// Home
///   ↓
/// ProfileController
///   ↓
/// LocalProfileRepository
///
/// Doses:
/// Abhi HomeData dummy/in-memory source se.
/// Next local-storage phase mein DoseRepository par migrate honge.
///
/// NAVIGATION:
/// Quick Access "Family" tile + header "Add" button
/// → ProfilesScreen (managed profiles switch/invite).
///
/// FUTURE BACKEND:
/// Local repositories ko Firebase/real backend repositories se
/// replace kiya jayega. UI structure same reh sakta hai.
/// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  final MemberRepository _memberRepository = LocalMemberRepository();

  StreamSubscription<List<MemberProfile>>? _membersSubscription;

  List<MemberProfile> _members = [];

  String? _selectedMemberId;

  bool _membersLoading = true;

  /// Initial persisted member sirf first DB snapshot par resolve hoga.
  ///
  /// Uske baad member/photo DB stream update hone par currently selected
  /// Home member preserve hoga aur Sarah par reset nahi hoga.
  bool _didResolveInitialMember = false;

  // ============ DOSES ============
  // TODO Local Storage:
  // DoseRepository + Drift DoseEvents/Schedules migration ke baad
  // selected memberId aur selected date ke against load karna hai.
  late final List<Dose> _doses = HomeData.todayDoses();

  // ============ COMPUTED — DOSES ============

  int get _takenCount => HomeData.takenCount(_doses);

  int get _pendingCount => HomeData.pendingCount(_doses);

  int get _missedCount => HomeData.missedCount(_doses);

  double get _progress => HomeData.progress(_doses);

  // ============ SELECTED MEMBER ============

  MemberProfile? get _selectedMember {
    final selectedId = _selectedMemberId;

    if (selectedId == null) {
      return null;
    }

    for (final member in _members) {
      if (member.id == selectedId) {
        return member;
      }
    }

    return null;
  }

  String get _selectedMemberName {
    return _selectedMember?.displayName ??
        ProfileController.instance.displayName;
  }

  String? get _selectedMemberImagePath {
    final selected = _selectedMember;

    if (selected == null) {
      return ProfileController.instance.profileImagePath;
    }

    // Selected member ki latest controller image use kar sakte hain
    // jab tak Members SQLite stream updated record emit karti hai.
    if (ProfileController.instance.memberId == selected.id) {
      return ProfileController.instance.profileImagePath ??
          selected.profileImagePath;
    }

    return selected.profileImagePath;
  }

  // ============ FILTERED DOSES ============

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

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Profiles screen (ya koi bhi jagah) se member switch hone par
    // Home header/greeting sync rahe — controller listener.
    ProfileController.instance.addListener(_handleProfileChanged);

    _initializeMembers();
  }

  @override
  void dispose() {
    ProfileController.instance.removeListener(_handleProfileChanged);

    _membersSubscription?.cancel();

    super.dispose();
  }

  /// Profiles screen se switch → controller memberId update karta hai.
  /// Home ka local selection bhi usi par sync karo — warna Home apni
  /// purani local state par Sarah dikhta reh jata hai.
  void _handleProfileChanged() {
    final controllerMemberId = ProfileController.instance.memberId;

    if (controllerMemberId == null || controllerMemberId == _selectedMemberId) {
      return;
    }

    for (final member in _members) {
      if (member.id == controllerMemberId) {
        setState(() {
          _selectedMemberId = member.id;
        });

        return;
      }
    }
  }

  // ============================================================
  // MEMBER INITIALIZATION
  // ============================================================

  Future<void> _initializeMembers() async {
    try {
      await _memberRepository.seedInitialMembersIfNeeded();

      if (!mounted) {
        return;
      }

      _membersSubscription = _memberRepository.watchActiveMembers().listen(
        (members) {
          if (!mounted) {
            return;
          }

          _handleMembersUpdate(members);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Home member stream failed: $error');
          debugPrintStack(stackTrace: stackTrace);

          if (!mounted) {
            return;
          }

          setState(() {
            _membersLoading = false;
          });
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Home member initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _membersLoading = false;
      });
    }
  }

  void _handleMembersUpdate(List<MemberProfile> members) {
    final profileController = ProfileController.instance;

    MemberProfile? memberToSelect;

    // ============================================================
    // FIRST DATABASE SNAPSHOT
    // ============================================================
    //
    // ProfileController.initialize() app startup par persisted stable
    // memberId restore karta hai. First SQLite member snapshot mein
    // us exact member ko select karna hai.
    if (!_didResolveInitialMember) {
      final persistedMemberId = profileController.memberId;

      if (persistedMemberId != null) {
        for (final member in members) {
          if (member.id == persistedMemberId) {
            memberToSelect = member;
            break;
          }
        }
      }
    }

    // ============================================================
    // CURRENT HOME SELECTION
    // ============================================================
    //
    // Initial resolution ke baad DB stream update — for example profile
    // photo save — current member selection ko preserve kare.
    final currentSelectedId = _selectedMemberId;

    if (memberToSelect == null && currentSelectedId != null) {
      for (final member in members) {
        if (member.id == currentSelectedId) {
          memberToSelect = member;
          break;
        }
      }
    }

    // Fallback priority:
    // 1. Current controller member (Profiles screen se switch ho sakta hai)
    // 2. First active member (fresh install/default — Sarah)
    if (memberToSelect == null) {
      final controllerMemberId = profileController.memberId;

      if (controllerMemberId != null) {
        for (final member in members) {
          if (member.id == controllerMemberId) {
            memberToSelect = member;
            break;
          }
        }
      }
    }

    memberToSelect ??= members.isNotEmpty ? members.first : null;
    setState(() {
      _members = members;
      _selectedMemberId = memberToSelect?.id;
      _membersLoading = false;
      _didResolveInitialMember = true;
    });

    if (memberToSelect != null) {
      _syncSelectedProfile(memberToSelect);
    }
  }

  Future<void> _syncSelectedProfile(MemberProfile member) async {
    // Safety:
    // Agar controller already isi member par hai (Profiles screen se
    // switch hua), to dobara selectProfile() call karne se loop
    // trigger nahi hoga, lekin phir bhi skip karna cleaner hai.
    if (ProfileController.instance.memberId == member.id) {
      return;
    }

    await ProfileController.instance.selectProfile(
      memberId: member.id,
      displayName: member.displayName,
      profileImagePath: member.profileImagePath,
    );

    // TODO Backend:
    // Firebase phase mein selected member document Firestore stream se
    // aayega. ProfileController stable memberId ke saath sync hoga.
  }

  // ============================================================
  // DOSE ACTIONS
  // ============================================================

  void _markTaken(Dose dose) {
    setState(() => dose.status = DoseStatus.taken);

    // TODO Local Storage:
    // DoseRepository ke through existing DoseEvent ko status=taken
    // aur completedAt=current timestamp ke saath update karna hai.
    //
    // TODO Backend:
    // Firebase repository later same domain action persist karegi.

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${dose.name} marked as taken ✓')));
  }

  void _markUntaken(Dose dose) {
    setState(() => dose.status = DoseStatus.pending);

    // TODO Local Storage:
    // Existing DoseEvent ko pending revert aur completedAt clear karna.
    // Adherence/streak raw DoseEvents se recalculate honge.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${dose.name} marked as untaken 🔄')),
    );
  }

  void _skipDose(Dose dose, {String? reason}) {
    setState(() => dose.status = DoseStatus.skipped);

    // TODO Local Storage:
    // Existing DoseEvent mein status=skipped, optional reason aur
    // action timestamp persist karna hai.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reason == null
              ? '${dose.name} skipped'
              : '${dose.name} skipped — $reason',
        ),
      ),
    );
  }

  void _snoozeDose(Dose dose, int minutes) {
    // TODO Local Storage / Notifications:
    // DoseEvent/schedule mein snoozedUntil persist karke local
    // notification selected duration ke liye reschedule karni hai.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${dose.name} snoozed — $minutes min mein phir reminder!',
        ),
      ),
    );
  }

  void _openDoseSheet(Dose dose) {
    showDoseActionSheet(
      context,
      dose: dose,
      onTaken: () => _markTaken(dose),
      onUntaken: () => _markUntaken(dose),
      onSkip: (reason) => _skipDose(dose, reason: reason),
      onSnooze: (minutes) => _snoozeDose(dose, minutes),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openStreaksStats() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StreaksStatsScreen(userName: _selectedMemberName),
      ),
    );
  }

  void _openVitals() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VitalsListScreen(
          userName: _selectedMemberName,
          profileImagePath: _selectedMemberImagePath,
        ),
      ),
    );

    // TODO Local Storage:
    // Vitals screens ko next migration mein userName ki jagah
    // stable memberId bhi pass/use karna hai.
  }

  void _openDoctors() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DoctorsScreen()));
  }

  void _openProfiles() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfilesScreen()));
  }

  // ============================================================
  // FAMILY MEMBER SWITCH
  // ============================================================

  Future<void> _switchMember(MemberProfile member) async {
    if (member.id == _selectedMemberId) {
      return;
    }

    setState(() {
      _selectedMemberId = member.id;
    });

    // ProfileController:
    // - app-wide selected member update karega
    // - SharedPreferences mein selected stable memberId persist karega
    // - selected profile metadata persist karega
    await _syncSelectedProfile(member);

    if (!mounted) {
      return;
    }

    // TODO Local Storage:
    // Medicines, doses, adherence, inventory aur vitals repositories
    // ko selected member.id ke against query karna hai.
    //
    // TODO Backend:
    // Firebase phase mein exact same memberId-oriented flow rahega.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("Switched to ${member.displayName}'s medicines"),
        ),
      );
  }

  // ============================================================
  // PROFILE PHOTO
  // ============================================================

  Future<void> _openProfilePhotoPicker() async {
    final selected = _selectedMember;

    if (selected == null) {
      return;
    }

    // Picker ProfileController ke CURRENT selected memberId ke liye
    // permanent local image file create/remove karta hai.
    await showProfilePhotoPicker(context);

    if (!mounted) {
      return;
    }

    final controller = ProfileController.instance;

    // Safety:
    // Async picker ke dauran selected member unexpectedly change ho
    // jaye to doosre member record mein image persist na ho.
    if (controller.memberId != selected.id) {
      return;
    }

    // Image path member-specific SQLite record mein persist hota hai.
    //
    // Example:
    // local_sarah → Sarah image
    // local_mom   → Mom image
    // local_jake  → Jake image
    await _memberRepository.saveMember(
      selected.copyWith(
        profileImagePath: controller.profileImagePath,
        removeProfileImage: controller.profileImagePath == null,
        updatedAt: DateTime.now(),
      ),
    );

    // TODO Backend / Firebase Storage:
    // FirebaseMemberRepository phase mein member document ka
    // profileImageUrl Storage upload result se update hoga.
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Column(
        children: [
          _HomeHeader(
            greeting: HomeData.greeting(),
            dateLabel: HomeData.dateLabel(),
            streakDays: HomeData.streakDays(),
            selectedMemberImagePath: _selectedMemberImagePath,
            selectedMemberName: _selectedMemberName,
            selectedMemberId: _selectedMemberId,
            members: _members,
            membersLoading: _membersLoading,
            onMemberTap: _switchMember,
            onStreakTap: _openStreaksStats,
            onProfilePhotoTap: _openProfilePhotoPicker,
            onAddMemberTap: _openProfiles,
          ),

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

      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          right: MediaQuery.sizeOf(context).width > 480
              ? (MediaQuery.sizeOf(context).width - 480) / 2 + 16
              : 0,
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MedsScreen()));
          },
          backgroundColor: AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 5,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 27),
        ),
      ),
    );
  }

  // ============================================================
  // HOME CONTENT
  // ============================================================

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressCard(
            progress: _progress,
            taken: _takenCount,
            pending: _pendingCount,
            missed: _missedCount,
          ),

          const SizedBox(height: 16),

          _QuickAccessSection(
            onVitalsTap: _openVitals,
            onDoctorsTap: _openDoctors,
            onProfilesTap: _openProfiles,
          ),

          const SizedBox(height: 16),

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
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          for (final dose in _filteredDoses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DoseCard(
                dose: dose,
                onTaken: () => _markTaken(dose),
                onSkip: (reason) => _skipDose(dose, reason: reason),
                onSnooze: (minutes) => _snoozeDose(dose, minutes),
                onCardTap: () => _openDoseSheet(dose),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// DARK HEADER — selected profile + family + streak
// ============================================================

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.dateLabel,
    required this.streakDays,
    this.selectedMemberImagePath,
    required this.selectedMemberName,
    required this.selectedMemberId,
    required this.members,
    required this.membersLoading,
    required this.onMemberTap,
    required this.onStreakTap,
    required this.onProfilePhotoTap,
    required this.onAddMemberTap,
  });

  final String greeting;
  final String dateLabel;
  final int streakDays;

  final String? selectedMemberImagePath;
  final String selectedMemberName;
  final String? selectedMemberId;

  final List<MemberProfile> members;

  final bool membersLoading;

  final ValueChanged<MemberProfile> onMemberTap;

  final VoidCallback onStreakTap;

  final VoidCallback onProfilePhotoTap;

  final VoidCallback onAddMemberTap;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
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
              // ============ ROW 1 ============
              Row(
                children: [
                  GestureDetector(
                    onTap: onProfilePhotoTap,
                    child: AppAvatar(
                      size: 34,
                      imagePath: selectedMemberImagePath,

                      // Explicit selected member image use hogi.
                      // Null hone par global image leak nahi hogi.
                      useSelectedProfileImage: false,

                      ringColor: AppColors.surface,
                      ringWidth: 2,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      '$greeting, $selectedMemberName 👋',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.surface,
                        size: 24,
                      ),
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 7,
                          height: 7,
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

              const SizedBox(height: 12),

              // ============ ROW 2 ============
              if (membersLoading && members.isEmpty)
                const SizedBox(
                  height: 60,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        if (i != 0) const SizedBox(width: 17),

                        _FamilyMemberAvatar(
                          member: members[i],
                          isSelected: members[i].id == selectedMemberId,
                          onTap: () => onMemberTap(members[i]),
                        ),
                      ],

                      if (members.isNotEmpty) const SizedBox(width: 17),

                      _AddMemberButton(onTap: onAddMemberTap),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // ============ ROW 3 ============
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppColors.headerSubtext,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      onTap: onStreakTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        decoration: BoxDecoration(
                          color: AppColors.formAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.homeStreakFlame,
                              size: 18,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              '$streakDays Day Streak',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(width: 3),

                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.surface,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
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
// FAMILY MEMBER AVATAR
// ============================================================

class _FamilyMemberAvatar extends StatelessWidget {
  const _FamilyMemberAvatar({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final MemberProfile member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AppAvatar(
            size: 40,

            // IMPORTANT:
            // Family row mein sirf isi exact member ka SQLite image path
            // render hoga.
            //
            // Sarah ki selected/global image Mom/Jake par fallback
            // nahi hogi.
            imagePath: member.profileImagePath,
            useSelectedProfileImage: false,

            ringColor: isSelected
                ? AppColors.avatarSelected
                : AppColors.surface.withValues(alpha: 0.54),
            ringWidth: isSelected ? 2 : 1,
          ),

          const SizedBox(height: 4),

          Text(
            member.displayName,
            style: TextStyle(
              color: isSelected
                  ? AppColors.surface
                  : AppColors.surface.withValues(alpha: 0.70),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD MEMBER → ProfilesScreen (managed profiles + invite)
// ============================================================

class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.transparent,
            child: Icon(Icons.add, color: AppColors.surface, size: 22),
          ),

          const SizedBox(height: 4),

          Text(
            'Add',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha: 0.70),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROGRESS CARD
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
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
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
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Daily',
                      style: TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),
          const SizedBox(width: 8),

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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// QUICK ACCESS
// ============================================================

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.onVitalsTap,
    required this.onDoctorsTap,
    required this.onProfilesTap,
  });

  final VoidCallback onVitalsTap;
  final VoidCallback onDoctorsTap;
  final VoidCallback onProfilesTap;

  static const List<({IconData icon, String label})> _items = [
    (icon: Icons.monitor_heart_outlined, label: 'Vitals'),
    (icon: Icons.medical_services_outlined, label: 'Doctors'),
    (icon: Icons.auto_awesome, label: 'AI Assist'),
    (icon: Icons.groups_2_outlined, label: 'Family'),
  ];

  void _onItemTap(BuildContext context, int index) {
    if (index == 0) {
      onVitalsTap();
      return;
    }

    if (index == 1) {
      onDoctorsTap();
      return;
    }

    if (index == 3) {
      onProfilesTap();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${_items[index].label} screen coming next.')),
      );
  }

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
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Shortcuts',
              style: TextStyle(color: AppColors.formAccent, fontSize: 13),
            ),
          ],
        ),

        const SizedBox(height: 9),

        Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i != 0) const SizedBox(width: 7),

              Expanded(
                child: GestureDetector(
                  onTap: () => _onItemTap(context, i),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.035),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            _items[i].icon,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.formAccent,
                            fontSize: 12,
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
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.formAccent : AppColors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.formAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.surface : AppColors.formAccent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DOSE CARD
// ============================================================

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.onTaken,
    required this.onSkip,
    required this.onSnooze,
    required this.onCardTap,
  });

  final Dose dose;
  final VoidCallback onTaken;
  final void Function(String? reason) onSkip;
  final void Function(int minutes) onSnooze;
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.status == DoseStatus.taken;
    final isSkipped = dose.status == DoseStatus.skipped;
    final isPending = dose.status == DoseStatus.pending;

    return GestureDetector(
      onTap: (isPending || isTaken) ? onCardTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: isPending
              ? Border.all(color: AppColors.formAccent, width: 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? AppColors.formAccent.withValues(alpha: 0.30)
                  : AppColors.textPrimary.withValues(alpha: 0.035),
              offset: const Offset(0, 4),
              blurRadius: isPending ? 0 : 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardFill,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isTaken ? Icons.check_rounded : Icons.medication_outlined,
                    size: 24,
                    color: isTaken
                        ? AppColors.success
                        : isPending
                        ? AppColors.formAccent
                        : AppColors.fieldHint,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dose.name} ${dose.doseAmount}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: isTaken
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        dose.details,
                        style: const TextStyle(
                          color: AppColors.formSubtitle,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Icon(
                            isTaken ? Icons.check_circle : Icons.access_time,
                            size: 14,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _StatusBadge(status: dose.status),
              ],
            ),

            if (isPending) ...[
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      '✓ Taken',
                      filled: true,
                      onTap: onTaken,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: _actionButton('Skip', onTap: () => onSkip(null)),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: _actionButton('Snooze', onTap: () => onSnooze(10)),
                  ),
                ],
              ),
            ],

            if (isPending && dose.isRunningLow) ...[
              const SizedBox(height: 10),

              Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.hintBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.hintAccent,
                      size: 16,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        '${dose.name} running low · '
                        '${dose.daysLeft} days left',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.hintAccent,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        // TODO Local Storage / Navigation:
                        // Inventory/refill repository ke through
                        // selected medication refill flow open karna.
                      },
                      child: const Text(
                        'Refill →',
                        style: TextStyle(
                          color: AppColors.hintAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isSkipped) ...[
              const SizedBox(height: 8),

              const Text(
                'Skipped — kal se phir reminder aayega',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    String label, {
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.formAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? AppColors.surface : AppColors.formAccent,
            fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
