import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/members/local_member_repository.dart';
import '../../core/members/member_repository.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dose.dart' as dose_model;
import '../../repositories/auth_repository.dart';
import '../../repositories/dose_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/profile_photo_picker.dart';
import '../assistant/assistant_chat_screen.dart';
import '../doctors/doctors_screen.dart';
import '../meds/meds_screen.dart';
import '../../features/profile/profiles_screen.dart';
import 'home_data.dart';
import 'streaks_stats_screen.dart';
import 'vitals_list_screen.dart';
import '../meds/missed_dose_reason_sheet.dart';

/// ============================================================
/// HOME — app ka dil!
///
/// M7 UPDATE:
/// Doses ab Firestore se real-time aate hain (DoseRepository).
/// Logging actions (Take/Skip/Snooze/Undo) DoseRepository ke
/// through persist hote hain — local setState nahi.
/// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'all';

  final MemberRepository _memberRepository = LocalMemberRepository();

  StreamSubscription<List<MemberProfile>>? _membersSubscription;
  StreamSubscription<List<dose_model.Dose>>? _dosesSubscription;

  List<MemberProfile> _members = [];
  String? _selectedMemberId;
  bool _membersLoading = true;
  bool _didResolveInitialMember = false;

  // ============ DOSES (M7 — Firestore stream) ============
  List<dose_model.Dose> _doses = [];
  bool _dosesLoading = true;
  String? _dosesError;

  // ============ COMPUTED — DOSES (M7) ============

  int get _takenCount => _doses
      .where((d) => !d.isPrn && d.status == dose_model.DoseStatus.taken)
      .length;

  int get _pendingCount => _doses.where((d) => !d.isPrn && d.isPending).length;

  int get _missedCount =>
      _doses.where((d) => !d.isPrn && (d.isMissed || d.isOverdue)).length;

  double get _progress {
    final total = _takenCount + _pendingCount + _missedCount;
    if (total == 0) return 0.0;
    return _takenCount / total;
  }

  // ============ SELECTED MEMBER ============

  MemberProfile? get _selectedMember {
    final selectedId = _selectedMemberId;
    if (selectedId == null) return null;
    for (final member in _members) {
      if (member.id == selectedId) return member;
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
    if (ProfileController.instance.memberId == selected.id) {
      return ProfileController.instance.profileImagePath ??
          selected.profileImagePath;
    }
    return selected.profileImagePath;
  }

  // ============ FILTERED DOSES (M7) ============

  List<dose_model.Dose> get _filteredDoses {
    final nonPrn = _doses.where((d) => !d.isPrn).toList();
    switch (_selectedFilter) {
      case 'pending':
        return nonPrn
            .where(
              (d) =>
                  d.status == dose_model.DoseStatus.pending ||
                  d.status == dose_model.DoseStatus.snoozed ||
                  d.status == dose_model.DoseStatus.missed,
            )
            .toList();
      case 'taken':
        return nonPrn
            .where((d) => d.status == dose_model.DoseStatus.taken)
            .toList();
      default:
        return nonPrn;
    }
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    ProfileController.instance.addListener(_handleProfileChanged);
    _initializeMembers();
    _subscribeDoses();
  }

  @override
  void dispose() {
    ProfileController.instance.removeListener(_handleProfileChanged);
    _membersSubscription?.cancel();
    _dosesSubscription?.cancel();
    super.dispose();
  }

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
        _subscribeDoses();
        return;
      }
    }
  }

  // ============================================================
  // M7: DOSES STREAM (Firestore)
  // ============================================================

  void _subscribeDoses() {
    _dosesSubscription?.cancel();

    final memberId = ProfileController.instance.memberId;
    if (memberId == null || memberId.isEmpty) {
      setState(() {
        _doses = [];
        _dosesLoading = false;
      });
      return;
    }

    setState(() {
      _dosesLoading = true;
      _dosesError = null;
    });

    _dosesSubscription = DoseRepository.instance
        .watchTodaysDoses(memberId)
        .listen(
          (doses) {
            if (!mounted) return;
            setState(() {
              _doses = doses;
              _dosesLoading = false;
              _dosesError = null;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Home dose stream failed: $error');
            if (!mounted) return;
            setState(() {
              _dosesLoading = false;
              _dosesError = error.toString();
            });
          },
        );
  }

  // ============================================================
  // MEMBER INITIALIZATION
  // ============================================================

  Future<void> _initializeMembers() async {
    try {
      await _memberRepository.seedInitialMembersIfNeeded();
      if (!mounted) return;

      _membersSubscription = _memberRepository.watchActiveMembers().listen(
        (members) {
          if (!mounted) return;
          _handleMembersUpdate(members);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Home member stream failed: $error');
          if (!mounted) return;
          setState(() {
            _membersLoading = false;
          });
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Home member initialization failed: $error');
      if (!mounted) return;
      setState(() {
        _membersLoading = false;
      });
    }
  }

  void _handleMembersUpdate(List<MemberProfile> members) {
    final profileController = ProfileController.instance;
    MemberProfile? memberToSelect;

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

    final currentSelectedId = _selectedMemberId;
    if (memberToSelect == null && currentSelectedId != null) {
      for (final member in members) {
        if (member.id == currentSelectedId) {
          memberToSelect = member;
          break;
        }
      }
    }

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

    // Keep a valid selection that is not in the local list (e.g. the
    // Firestore-backed self profile); only auto-pick when nothing is set.
    final hasControllerSelection =
        (profileController.memberId ?? '').isNotEmpty;
    memberToSelect ??= hasControllerSelection
        ? null
        : (members.isNotEmpty ? members.first : null);
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
    if (ProfileController.instance.memberId == member.id) return;
    await ProfileController.instance.selectProfile(
      memberId: member.id,
      displayName: member.displayName,
      profileImagePath: member.profileImagePath,
    );
  }

  // ============================================================
  // DOSE ACTIONS (M7 — DoseRepository)
  // ============================================================

  Future<void> _markTaken(dose_model.Dose dose) async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;
    final userId = AuthRepository.instance.currentUid ?? 'unknown';

    try {
      await DoseRepository.instance.logDose(
        profileId: memberId,
        doseId: dose.id,
        status: dose_model.DoseStatus.taken,
        loggedBy: userId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).homeMarkedTaken(dose.medName),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _markUntaken(dose_model.Dose dose) async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;

    try {
      await DoseRepository.instance.undoDose(
        profileId: memberId,
        doseId: dose.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).homeMarkedUntaken(dose.medName),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _confirmSkipFromSheet(dose_model.Dose dose) async {
    final dt = dose.scheduledAt.toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final timeLabel = '$hour:$minute $amPm';

    final reason = await MissedDoseReasonSheet.show(
      context,
      medName: dose.medName,
      scheduledTimeLabel: timeLabel,
    );
    if (!mounted) return;
    await _skipDose(dose, reason: reason);
  }

  Future<void> _skipDose(dose_model.Dose dose, {String? reason}) async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;
    final userId = AuthRepository.instance.currentUid ?? 'unknown';

    try {
      await DoseRepository.instance.logDose(
        profileId: memberId,
        doseId: dose.id,
        status: dose_model.DoseStatus.skipped,
        loggedBy: userId,
        reasonText: reason,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason == null
                ? l10n.homeSkipped(dose.medName)
                : l10n.homeSkippedReason(dose.medName, reason),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _snoozeDose(dose_model.Dose dose, int minutes) async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;

    try {
      await DoseRepository.instance.snoozeDose(
        profileId: memberId,
        doseId: dose.id,
        snoozeDuration: Duration(minutes: minutes),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).homeSnoozed(dose.medName, minutes),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _openDoseSheet(dose_model.Dose dose) {
    _showInlineDoseActions(dose);
  }

  void _showInlineDoseActions(dose_model.Dose dose) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dose.medName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dose.doseLabel ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (dose.isPending || dose.isSnoozed || dose.isMissed) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _markTaken(dose);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Mark Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.formAccent,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmSkipFromSheet(dose);
                    },
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.formAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (dose.isPending) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _snoozeDose(dose, 15);
                    },
                    icon: const Icon(Icons.snooze_rounded),
                    label: const Text('Snooze 15 min'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.formAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (dose.canUndo()) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _markUntaken(dose);
                    },
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Undo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
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
  }

  void _openDoctors() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DoctorsScreen()));
  }

  void _openProfiles() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfilesScreen()));
  }

  void _openAssistant() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AssistantChatScreen()));
  }

  // ============================================================
  // FAMILY MEMBER SWITCH
  // ============================================================

  Future<void> _switchMember(MemberProfile member) async {
    if (member.id == _selectedMemberId) return;
    setState(() {
      _selectedMemberId = member.id;
    });
    await _syncSelectedProfile(member);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).homeSwitchedMember(member.displayName),
          ),
        ),
      );
  }

  // ============================================================
  // PROFILE PHOTO
  // ============================================================

  Future<void> _openProfilePhotoPicker() async {
    final selected = _selectedMember;
    if (selected == null) return;
    await showProfilePhotoPicker(context);
    if (!mounted) return;
    final controller = ProfileController.instance;
    if (controller.memberId != selected.id) return;
    await _memberRepository.saveMember(
      selected.copyWith(
        profileImagePath: controller.profileImagePath,
        removeProfileImage: controller.profileImagePath == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final greeting = switch (HomeData.greetingBucket()) {
      'morning' => l10n.homeGreetingMorning,
      'afternoon' => l10n.homeGreetingAfternoon,
      _ => l10n.homeGreetingEvening,
    };

    final dateLabel = MaterialLocalizations.of(context)
        .formatFullDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _HomeHeader(
            greeting: greeting,
            dateLabel: dateLabel,
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
          heroTag: null,
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
    final l10n = AppLocalizations.of(context);

    String filterLabel(String code) {
      return switch (code) {
        'pending' => l10n.homeFilterPending,
        'taken' => l10n.homeFilterTaken,
        _ => l10n.homeFilterAll,
      };
    }

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
            onAssistantTap: _openAssistant,
            onProfilesTap: _openProfiles,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeTodaySchedule,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.formAccent,
                  ),
                ),
              ),
              for (final filter in ['all', 'pending', 'taken'])
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: _FilterChip(
                    label: filterLabel(filter),
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
          if (_dosesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_dosesError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _buildDoseError(_dosesError!),
            )
          else if (_filteredDoses.isEmpty)
            _buildEmptyDoses()
          else
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

  Widget _buildEmptyDoses() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          const Icon(
            Icons.event_available,
            size: 48,
            color: AppColors.fieldHint,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).homeTodaySchedule,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No doses scheduled for today.',
            style: TextStyle(fontSize: 12, color: AppColors.fieldHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoseError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hintBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Failed to load doses',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(fontSize: 11, color: AppColors.fieldHint),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
    final l10n = AppLocalizations.of(context);

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
              Row(
                children: [
                  GestureDetector(
                    onTap: onProfilePhotoTap,
                    child: AppAvatar(
                      size: 34,
                      imagePath: selectedMemberImagePath,
                      useSelectedProfileImage: false,
                      ringColor: AppColors.surface,
                      ringWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      l10n.homeGreetingWithName(greeting, selectedMemberName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                              l10n.homeDayStreak(streakDays),
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
// ADD MEMBER
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
            AppLocalizations.of(context).homeAdd,
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
    final l10n = AppLocalizations.of(context);

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
                    Text(
                      l10n.homeDaily,
                      style: const TextStyle(
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
                _dotStat(AppColors.success, l10n.homeStatTaken(taken)),
                const SizedBox(height: 8),
                _dotStat(AppColors.accentOrange, l10n.homeStatPending(pending)),
                const SizedBox(height: 8),
                _dotStat(AppColors.error, l10n.homeStatMissed(missed)),
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
    required this.onAssistantTap,
    required this.onProfilesTap,
  });

  final VoidCallback onVitalsTap;
  final VoidCallback onDoctorsTap;
  final VoidCallback onAssistantTap;
  final VoidCallback onProfilesTap;

  static const List<String> _images = [
    'assets/images/vitals.png',
    'assets/images/doctors.png',
    'assets/images/AI_assets.png',
    'assets/images/family.png',
  ];

  String _itemLabel(AppLocalizations l10n, int index) {
    return switch (index) {
      0 => l10n.homeQuickVitals,
      1 => l10n.homeQuickDoctors,
      2 => l10n.homeQuickAI,
      _ => l10n.homeQuickFamily,
    };
  }

  void _onItemTap(BuildContext context, int index) {
    if (index == 0) {
      onVitalsTap();
      return;
    }
    if (index == 1) {
      onDoctorsTap();
      return;
    }
    if (index == 2) {
      onAssistantTap();
      return;
    }
    if (index == 3) {
      onProfilesTap();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.homeQuickAccess,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              l10n.homeShortcuts,
              style: const TextStyle(color: AppColors.formAccent, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (var i = 0; i < _images.length; i++) ...[
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
                        Image.asset(
                          _images[i],
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _itemLabel(l10n, i),
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
// DOSE CARD (M7 — dose_model.Dose)
// ============================================================

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.onTaken,
    required this.onSkip,
    required this.onSnooze,
    required this.onCardTap,
  });

  final dose_model.Dose dose;
  final VoidCallback onTaken;
  final void Function(String? reason) onSkip;
  final void Function(int minutes) onSnooze;
  final VoidCallback onCardTap;

  String get _timeLabel {
    final dt = dose.scheduledAt.toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  Future<void> _confirmSkipWithReason(BuildContext context) async {
    final reason = await MissedDoseReasonSheet.show(
      context,
      medName: dose.medName,
      scheduledTimeLabel: _timeLabel,
    );
    onSkip(reason);
  }

  String get _detailsLabel {
    if (dose.doseLabel != null && dose.doseLabel!.isNotEmpty) {
      return dose.doseLabel!;
    }
    return dose.medName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final isTaken = dose.status == dose_model.DoseStatus.taken;
    final isSkipped = dose.status == dose_model.DoseStatus.skipped;
    final isPending =
        dose.status == dose_model.DoseStatus.pending ||
        dose.status == dose_model.DoseStatus.snoozed;

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
                        dose.medName,
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
                        _detailsLabel,
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
                            _timeLabel,
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
                      '✓ ${l10n.homeActionTaken}',
                      filled: true,
                      onTap: onTaken,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _actionButton(
                      l10n.homeActionSkip,
                      onTap: () => _confirmSkipWithReason(context),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _actionButton(
                      l10n.homeActionSnooze,
                      onTap: () => onSnooze(10),
                    ),
                  ),
                ],
              ),
            ],
            if (isSkipped) ...[
              const SizedBox(height: 8),
              Text(
                l10n.homeSkippedNote,
                style: const TextStyle(
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
// STATUS BADGE (M7 — dose_model.DoseStatus)
// ============================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final dose_model.DoseStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (status) {
      case dose_model.DoseStatus.pending:
        return _badge(
          background: AppColors.pendingBackground,
          foreground: AppColors.statusPendingText,
          text: l10n.homeStatusPending,
        );
      case dose_model.DoseStatus.taken:
        return _badge(
          background: AppColors.successBackground,
          foreground: AppColors.success,
          text: '✓ ${l10n.homeStatusTaken}',
        );
      case dose_model.DoseStatus.snoozed:
        return _badge(
          background: AppColors.pendingBackground,
          foreground: AppColors.formAccent,
          text: l10n.homeStatusPending,
        );
      case dose_model.DoseStatus.missed:
        return _badge(
          background: AppColors.hintBackground,
          foreground: AppColors.error,
          text: l10n.homeStatusSkipped,
        );
      case dose_model.DoseStatus.skipped:
        return _badge(
          background: AppColors.hintBackground,
          foreground: AppColors.hintAccent,
          text: l10n.homeStatusSkipped,
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
