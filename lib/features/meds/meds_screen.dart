import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/medications/local_medication_repository.dart';
import '../../core/medications/local_medication_schedule_repository.dart';
import '../../core/medications/medication_repository.dart';
import '../../core/medications/medication_schedule_repository.dart';
import '../../core/profile/profile_controller.dart';
import '../../widgets/app_avatar.dart';
import 'add_medication_screen.dart';
import 'discontinue_medication_screen.dart';
import 'edit_medication_screen.dart';
import 'inventory_data.dart';
import 'inventory_screen.dart';
import 'meds_data.dart';
import 'side_effects_screen.dart';

/// ============================================================
/// MEDS — saari medications
///
/// CURRENT DATA ARCHITECTURE:
///
/// Medications:
/// UI → MedicationRepository → LocalMedicationRepository → SQLite
///
/// Schedules:
/// UI → MedicationScheduleRepository
///    → LocalMedicationScheduleRepository
///    → SQLite
///
/// Selected family member:
/// ProfileController.memberId
///
/// Inventory:
/// Existing InventoryData temporarily preserved.
/// InventoryRecords migration next phase mein hogi.
///
/// Active medicine:
/// Left swipe → Discontinue → confirmation → SQLite archive.
///
/// IMPORTANT:
/// Swipe sirf action reveal karta hai.
/// Medicine confirmation ke baad hi discontinue/archive hoti hai.
///
/// Seeded Sarah medicines ke schedule rows abhi SQLite mein nahi hain,
/// isliye unke liye legacy schedule presentation fallback temporarily
/// preserve hai. Newly-added medicines SQLite schedules use karti hain.
///
/// TODO Backend:
/// FirebaseMedicationRepository aur
/// FirebaseMedicationScheduleRepository same contracts implement karengi.
/// Screen ko Firestore-specific code ki zarurat nahi hogi.
/// ============================================================
class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  final _searchController = TextEditingController();

  final MedicationRepository _medicationRepository =
      LocalMedicationRepository();

  final MedicationScheduleRepository _scheduleRepository =
      LocalMedicationScheduleRepository();

  StreamSubscription<List<MedicationProfile>>? _activeSubscription;
  StreamSubscription<List<MedicationProfile>>? _archivedSubscription;

  /// Har medication ka apna schedule stream hai.
  final Map<String, StreamSubscription<List<MedicationScheduleProfile>>>
  _scheduleSubscriptions = {};

  /// medicationId → persisted schedules
  final Map<String, List<MedicationScheduleProfile>> _schedulesByMedication =
      {};

  bool _showArchived = false;
  bool _medicationsLoading = true;

  String? _listeningMemberId;

  List<MedicationProfile> _activeProfiles = [];
  List<MedicationProfile> _archivedProfiles = [];

  /// Existing presentation data ab sirf:
  /// - seeded medicines ke schedule fallback
  /// - inventory/course presentation
  ///
  /// ke liye temporarily use hota hai.
  late final List<Medicine> _legacyPresentationData = [
    ...MedsData.medicines(),
    ...MedsData.archived(),
  ];

  @override
  void initState() {
    super.initState();

    ProfileController.instance.addListener(_handleSelectedMemberChanged);

    _loadSelectedMemberMedications();
  }

  @override
  void dispose() {
    ProfileController.instance.removeListener(_handleSelectedMemberChanged);

    _activeSubscription?.cancel();
    _archivedSubscription?.cancel();

    for (final subscription in _scheduleSubscriptions.values) {
      subscription.cancel();
    }

    _scheduleSubscriptions.clear();
    _schedulesByMedication.clear();

    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // SELECTED MEMBER
  // ============================================================

  void _handleSelectedMemberChanged() {
    final memberId = ProfileController.instance.memberId;

    if (memberId == null ||
        memberId.isEmpty ||
        memberId == _listeningMemberId) {
      return;
    }

    _loadSelectedMemberMedications();
  }

  Future<void> _loadSelectedMemberMedications() async {
    final memberId = ProfileController.instance.memberId;

    if (memberId == null || memberId.isEmpty) {
      await _cancelScheduleSubscriptions();

      if (!mounted) {
        return;
      }

      setState(() {
        _listeningMemberId = null;
        _activeProfiles = [];
        _archivedProfiles = [];
        _schedulesByMedication.clear();
        _medicationsLoading = false;
      });

      return;
    }

    if (_listeningMemberId == memberId &&
        (_activeSubscription != null || _archivedSubscription != null)) {
      return;
    }

    await _activeSubscription?.cancel();
    await _archivedSubscription?.cancel();
    await _cancelScheduleSubscriptions();

    _activeSubscription = null;
    _archivedSubscription = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _listeningMemberId = memberId;
      _activeProfiles = [];
      _archivedProfiles = [];
      _schedulesByMedication.clear();
      _medicationsLoading = true;
    });

    try {
      await _medicationRepository.seedInitialMedicationsIfNeeded(memberId);

      if (!mounted || _listeningMemberId != memberId) {
        return;
      }

      _activeSubscription = _medicationRepository
          .watchActiveMedications(memberId)
          .listen(
            (medications) {
              if (!mounted || _listeningMemberId != memberId) {
                return;
              }

              setState(() {
                _activeProfiles = medications;
                _medicationsLoading = false;
              });

              _syncScheduleSubscriptions();
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Active medications stream failed: $error');
              debugPrintStack(stackTrace: stackTrace);

              if (!mounted || _listeningMemberId != memberId) {
                return;
              }

              setState(() {
                _medicationsLoading = false;
              });
            },
          );

      _archivedSubscription = _medicationRepository
          .watchArchivedMedications(memberId)
          .listen(
            (medications) {
              if (!mounted || _listeningMemberId != memberId) {
                return;
              }

              setState(() {
                _archivedProfiles = medications;
                _medicationsLoading = false;
              });

              _syncScheduleSubscriptions();
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Archived medications stream failed: $error');
              debugPrintStack(stackTrace: stackTrace);

              if (!mounted || _listeningMemberId != memberId) {
                return;
              }

              setState(() {
                _medicationsLoading = false;
              });
            },
          );
    } catch (error, stackTrace) {
      debugPrint('Medication initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted || _listeningMemberId != memberId) {
        return;
      }

      setState(() {
        _medicationsLoading = false;
      });
    }
  }

  // ============================================================
  // SCHEDULE STREAMS
  // ============================================================

  Future<void> _cancelScheduleSubscriptions() async {
    final subscriptions = _scheduleSubscriptions.values.toList();

    _scheduleSubscriptions.clear();

    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  void _syncScheduleSubscriptions() {
    final currentMemberId = _listeningMemberId;

    if (currentMemberId == null) {
      return;
    }

    final medicationIds = <String>{
      ..._activeProfiles.map((profile) => profile.id),
      ..._archivedProfiles.map((profile) => profile.id),
    };

    final staleIds = _scheduleSubscriptions.keys
        .where((id) => !medicationIds.contains(id))
        .toList();

    for (final id in staleIds) {
      _scheduleSubscriptions.remove(id)?.cancel();
      _schedulesByMedication.remove(id);
    }

    for (final medicationId in medicationIds) {
      if (_scheduleSubscriptions.containsKey(medicationId)) {
        continue;
      }

      _scheduleSubscriptions[medicationId] = _scheduleRepository
          .watchSchedulesForMedication(medicationId)
          .listen(
            (schedules) {
              if (!mounted || _listeningMemberId != currentMemberId) {
                return;
              }

              final validSchedules =
                  schedules
                      .where((schedule) => schedule.memberId == currentMemberId)
                      .toList()
                    ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

              setState(() {
                _schedulesByMedication[medicationId] = validSchedules;
              });
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint(
                'Medication schedule stream failed for $medicationId: $error',
              );
              debugPrintStack(stackTrace: stackTrace);
            },
          );
    }
  }

  // ============================================================
  // UI MEDICINE MAPPING
  // ============================================================

  List<_MedicationListItem> get _activeItems {
    return _activeProfiles.map(_toListItem).toList();
  }

  List<_MedicationListItem> get _archivedItems {
    return _archivedProfiles.map(_toListItem).toList();
  }

  _MedicationListItem _toListItem(MedicationProfile profile) {
    final legacy = _findLegacyPresentation(profile);

    final schedules =
        _schedulesByMedication[profile.id] ??
        const <MedicationScheduleProfile>[];

    final enabledSchedules = schedules
        .where((schedule) => schedule.isEnabled)
        .toList();

    final hasPersistedSchedule = enabledSchedules.isNotEmpty;

    // 🆕 MODULE 1: Schedule fallback remove — sirf persisted SQLite schedules.
    final frequency = hasPersistedSchedule
        ? _scheduleFrequency(enabledSchedules)
        : 'Schedule not set';

    final nextDose = hasPersistedSchedule
        ? _nextDoseLabel(enabledSchedules)
        : '—';

    return _MedicationListItem(
      profile: profile,
      schedules: enabledSchedules,
      medicine: Medicine(
        name: profile.name,
        dose: profile.displayStrength,
        type: _medicineTypeFromProfile(profile),
        frequency: frequency,
        nextDose: nextDose,

        // InventoryRecords migration abhi pending hai.
        supplyDaysLeft: legacy?.supplyDaysLeft ?? 0,
        isLowStock: legacy?.isLowStock ?? false,

        // 🆕 MODULE 2: Course ab SQLite medications se aa raha hai.
        courseDay: profile.courseDay,
        courseTotalDays: profile.courseTotalDays,

        isArchived: !profile.isActive,
      ),
      imagePath: profile.imagePath,
    );
  }

  /// 🆕 MODULE 1:
  /// Legacy presentation ab sirf SEEDED medication IDs par apply hoti
  /// hai — name matching remove kar diya. Is se user-added medicines
  /// par Sarah ka legacy inventory/course data ghalat na lage.
  ///
  /// NOTE: supplyDaysLeft / isLowStock / course abhi bhi legacy se
  /// aa rahe hain — Module 2 (course fields) aur Module 4
  /// (InventoryRecords) mein migrate honge.
  Medicine? _findLegacyPresentation(MedicationProfile profile) {
    switch (profile.id) {
      case 'local_sarah_metformin':
        return _findLegacyMedicineByName('Metformin');
      case 'local_sarah_amlodipine':
        return _findLegacyMedicineByName('Amlodipine');
      case 'local_sarah_vitamin_d3_drops':
        return _findLegacyMedicineByName('Vitamin D3 Drops');
      case 'local_sarah_amoxicillin':
        return _findLegacyMedicineByName('Amoxicillin');
      default:
        return null;
    }
  }

  Medicine? _findLegacyMedicineByName(String name) {
    final normalizedName = name.trim().toLowerCase();

    for (final medicine in _legacyPresentationData) {
      if (medicine.name.trim().toLowerCase() == normalizedName) {
        return medicine;
      }
    }

    return null;
  }

  MedicineType _medicineTypeFromProfile(MedicationProfile profile) {
    switch (profile.medicineForm?.trim().toLowerCase()) {
      case 'capsule':
        return MedicineType.capsule;

      case 'liquid':
        return MedicineType.liquid;

      case 'drops':
        return MedicineType.drops;

      case 'injection':
        return MedicineType.injection;

      case 'tablet':
      default:
        return MedicineType.tablet;
    }
  }

  // ============================================================
  // SCHEDULE PRESENTATION
  // ============================================================

  String _scheduleFrequency(List<MedicationScheduleProfile> schedules) {
    if (schedules.isEmpty) {
      return 'Schedule not set';
    }

    final scheduleType = schedules.first.scheduleType.trim().toLowerCase();

    switch (scheduleType) {
      case 'prn':
        return 'As needed';

      case 'specific_days':
        return schedules.length == 1
            ? '1x on selected days'
            : '${schedules.length}x on selected days';

      case 'cyclical':
        return schedules.length == 1
            ? '1x cyclical'
            : '${schedules.length}x cyclical';

      case 'tapering':
        return 'Tapering schedule';

      case 'daily':
      default:
        return schedules.length == 1
            ? '1x daily'
            : '${schedules.length}x daily';
    }
  }

  String _nextDoseLabel(List<MedicationScheduleProfile> schedules) {
    if (schedules.isEmpty) {
      return '—';
    }

    final next = _findNextScheduleOccurrence(schedules);

    if (next == null) {
      return '—';
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final nextDay = DateTime(next.year, next.month, next.day);

    final difference = nextDay.difference(today).inDays;

    final time = _formatTime(next);

    if (difference == 0) {
      return time;
    }

    if (difference == 1) {
      return 'Tomorrow $time';
    }

    return '${_shortWeekday(next.weekday)} $time';
  }

  DateTime? _findNextScheduleOccurrence(
    List<MedicationScheduleProfile> schedules,
  ) {
    final now = DateTime.now();

    DateTime? closest;

    for (final schedule in schedules) {
      if (!schedule.isEnabled) {
        continue;
      }

      final time = _parseStoredTime(schedule.timeOfDay);

      if (time == null) {
        continue;
      }

      for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
        final date = now.add(Duration(days: dayOffset));

        final candidate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (!candidate.isAfter(now)) {
          continue;
        }

        if (!_scheduleAppliesOnDate(schedule, candidate)) {
          continue;
        }

        if (closest == null || candidate.isBefore(closest)) {
          closest = candidate;
        }

        break;
      }
    }

    return closest;
  }

  bool _scheduleAppliesOnDate(
    MedicationScheduleProfile schedule,
    DateTime date,
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final start = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );

    if (dateOnly.isBefore(start)) {
      return false;
    }

    if (schedule.endDate != null) {
      final end = DateTime(
        schedule.endDate!.year,
        schedule.endDate!.month,
        schedule.endDate!.day,
      );

      if (dateOnly.isAfter(end)) {
        return false;
      }
    }

    final type = schedule.scheduleType.trim().toLowerCase();

    if (type == 'prn') {
      // PRN ka fixed "next dose" technically due nahi hota.
      // Current UI expects a time, so configured reminder time use hota hai.
      // DoseEvents migration ke baad PRN presentation improve hogi.
      return true;
    }

    final weekdays = _parseWeekdays(schedule.daysOfWeek);

    if (weekdays.isEmpty) {
      return true;
    }

    return weekdays.contains(date.weekday);
  }

  Set<int> _parseWeekdays(String? storedDays) {
    if (storedDays == null || storedDays.trim().isEmpty) {
      return <int>{};
    }

    return storedDays
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
        .toSet();
  }

  TimeOfDay? _parseStoredTime(String storedTime) {
    final parts = storedTime.split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    final twelveHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final minuteText = minute.toString().padLeft(2, '0');

    return '$twelveHour:$minuteText $period';
  }

  String _shortWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
      default:
        return 'Sun';
    }
  }

  // ============================================================
  // FILTERED — search + tab
  // ============================================================

  List<_MedicationListItem> get _filteredMeds {
    final source = _showArchived ? _archivedItems : _activeItems;
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return source;
    }

    return source.where((item) {
      return item.profile.name.toLowerCase().contains(query) ||
          item.profile.displayStrength.toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // INVENTORY LOW STOCK COUNT
  //
  // Inventory migration abhi pending hai.
  // Existing InventoryData calculated source preserve kiya gaya hai.
  // ============================================================

  int get _lowStockCount {
    final inventoryItems = InventoryData.inventory();

    return InventoryData.lowStockCount(inventoryItems);
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _addMedicine() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddMedicationScreen()));

    // Medication repository stream new medication automatically show karegi.
    //
    // TODO Backend:
    // Firebase implementation mein same repository contract use hoga.
  }

  // ================= INVENTORY =================

  Future<void> _openInventory() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const InventoryScreen()));

    if (!mounted) {
      return;
    }

    // Existing InventoryData in-memory adjustment ke liye rebuild.
    //
    // TODO Local Storage:
    // InventoryRecords repository stream migration ke baad manual
    // setState ki zarurat nahi hogi.
    setState(() {});
  }
  // ================= SIDE EFFECTS =================

  Future<void> _openSideEffects() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SideEffectsScreen()));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// ============================================================
  /// DISCONTINUE MEDICINE
  ///
  /// Confirmation modal open hoti hai.
  ///
  /// null   → Keep Active / Back / outside tap
  /// String → Archive confirm
  ///
  /// IMPORTANT:
  /// SQLite update sirf successful confirmation ke baad.
  /// ============================================================
  Future<void> _discontinueMedicine(_MedicationListItem item) async {
    final reason = await showGeneralDialog<String?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close discontinue medication',
      barrierColor: AppColors.headerDark.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return DiscontinueMedicationScreen(medicine: item.medicine);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    if (reason == null || !mounted) {
      return;
    }

    try {
      // 🆕 MODULE 2: Modal ka reason SQLite mein persist hota hai.
      await _medicationRepository.discontinueMedication(
        medicationId: item.profile.id,
        discontinuedAt: DateTime.now(),
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.profile.name} moved to Archived')),
      );
      // Existing DoseEvents/history delete nahi karni.
      //
      // TODO Backend:
      // Firebase repository isActive/discontinuedAt/reason save karegi
      // aur historical dose data preserve karegi.
    } catch (error, stackTrace) {
      debugPrint('Discontinue medication failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not discontinue medication. Please try again.'),
        ),
      );
    }
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
          _buildHeader(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildContent(),
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
          onPressed: _addMedicine,
          backgroundColor: AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 7,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearch(),

          const SizedBox(height: 12),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MANAGE',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Quick Tools',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _ManageTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  badge: _lowStockCount > 0 ? '$_lowStockCount LOW' : null,
                  onTap: _openInventory,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _ManageTile(
                  icon: Icons.shield_outlined,
                  label: 'Allergies',
                  count: '${MedsData.allergiesCount()}',
                  onTap: () {
                    _showMessage('Allergies — coming soon');
                  },
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _ManageTile(
                  icon: Icons.assignment_outlined,
                  label: 'Side Effects',
                  onTap: _openSideEffects,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _ManageTile(
                  icon: Icons.local_pharmacy_outlined,
                  label: 'Pharmacy',
                  onTap: () {
                    _showMessage('Pharmacy — coming soon');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildTabs(),

          const SizedBox(height: 16),

          if (_medicationsLoading)
            _buildLoadingState()
          else if (_filteredMeds.isEmpty)
            _buildEmptyState()
          else
            ..._filteredMeds.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _showArchived
                    ? _MedicineCard(
                        medicine: item.medicine,
                        imagePath: item.imagePath,
                        onTap: () {
                          _openMedicine(item);
                        },
                      )
                    : _SwipeMedicineCard(
                        medicine: item.medicine,
                        imagePath: item.imagePath,
                        onTap: () {
                          _openMedicine(item);
                        },
                        onDiscontinue: () {
                          _discontinueMedicine(item);
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // OPEN MEDICINE
  // ============================================================

  Future<void> _openMedicine(_MedicationListItem item) async {
    final medicine = item.medicine;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditMedicationScreen(
          medicineName: medicine.name,
          medicineStrength: medicine.dose,
          medicineForm: medicine.typeLabel,
          dosesPerDay: item.schedules.isNotEmpty
              ? item.schedules.length
              : _dosesPerDayFromFrequency(medicine.frequency),
          pillsRemaining: medicine.supplyDaysLeft,
          isLowStock: medicine.isLowStock,
        ),
      ),
    );

    // TODO Local Storage:
    // EditMedicationScreen ko stable medicationId dena aur medication +
    // schedule repositories se actual persisted editing karna next step hai.
    //
    // TODO Backend:
    // Same edit controller/repository boundary backend implementation
    // ke saath reuse hogi.
  }

  int _dosesPerDayFromFrequency(String frequency) {
    if (frequency.contains('3x')) {
      return 3;
    }

    if (frequency.contains('2x')) {
      return 2;
    }

    return 1;
  }

  // ============================================================
  // DARK HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Medications',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 20,
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

                  const SizedBox(width: 15),

                  const AppAvatarPlaceholder(),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ProfileController.instance.displayName}\'s Medications',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${_activeProfiles.length} active medications',
                          style: const TextStyle(
                            color: AppColors.headerSubtext,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: _addMedicine,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.formAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.surface,
                        size: 26,
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

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.formAccent),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),

          const Icon(
            Icons.search_rounded,
            color: AppColors.formAccent,
            size: 23,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Search medications...',
                hintStyle: TextStyle(color: AppColors.searchHint, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),

          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.formAccent,
              ),
            )
          else
            const Icon(
              Icons.tune_rounded,
              color: AppColors.formAccent,
              size: 23,
            ),

          const SizedBox(width: 15),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Row(
      children: [
        _TabButton(
          label: 'Active (${_activeProfiles.length})',
          selected: !_showArchived,
          onTap: () {
            setState(() {
              _showArchived = false;
            });
          },
        ),

        const SizedBox(width: 8),

        _TabButton(
          label: 'Archived (${_archivedProfiles.length})',
          selected: _showArchived,
          onTap: () {
            setState(() {
              _showArchived = true;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.formAccent),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medication_outlined,
            color: AppColors.fieldHint,
            size: 45,
          ),

          const SizedBox(height: 10),

          Text(
            _showArchived ? 'No archived medicines' : 'No medicines found',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICATION LIST ITEM
// ============================================================

class _MedicationListItem {
  const _MedicationListItem({
    required this.profile,
    required this.medicine,
    required this.schedules,
    this.imagePath,
  });

  final MedicationProfile profile;
  final Medicine medicine;
  final List<MedicationScheduleProfile> schedules;
  final String? imagePath;
}

// ============================================================
// HEADER AVATAR
// ============================================================

class AppAvatarPlaceholder extends StatelessWidget {
  const AppAvatarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppAvatar(
      size: 35,
      ringColor: AppColors.surface,
      ringWidth: 2,
    );
  }
}

// ============================================================
// TAB BUTTON
// ============================================================

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.surface : AppColors.formAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MANAGE TILE
// ============================================================

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.count,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  final String? badge;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 66,
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
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.manageIconFill,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.formAccent),
                ),

                const SizedBox(height: 5),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (badge != null)
            Positioned(
              top: -6,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lowBadgeBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.lowBadgeBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.lowBadgeText,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (count != null)
            Positioned(
              top: -6,
              right: 5,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.formAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count!,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SWIPE MEDICINE CARD
// ============================================================

class _SwipeMedicineCard extends StatefulWidget {
  const _SwipeMedicineCard({
    required this.medicine,
    required this.onTap,
    required this.onDiscontinue,
    this.imagePath,
  });

  final Medicine medicine;
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback onDiscontinue;

  @override
  State<_SwipeMedicineCard> createState() => _SwipeMedicineCardState();
}

class _SwipeMedicineCardState extends State<_SwipeMedicineCard> {
  static const double _actionWidth = 100;

  double _dragOffset = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-_actionWidth, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    setState(() {
      if (velocity < -300 || _dragOffset < -(_actionWidth / 2)) {
        _dragOffset = -_actionWidth;
      } else {
        _dragOffset = 0;
      }
    });
  }

  void _closeAction() {
    if (_dragOffset == 0) {
      return;
    }

    setState(() {
      _dragOffset = 0;
    });
  }

  void _handleDiscontinueTap() {
    _closeAction();
    widget.onDiscontinue();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Material(
                  color: AppColors.error,
                  child: InkWell(
                    onTap: _handleDiscontinueTap,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          color: AppColors.surface,
                          size: 23,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Discontinue',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              onTap: () {
                if (_dragOffset != 0) {
                  _closeAction();
                  return;
                }

                widget.onTap();
              },
              child: _MedicineCardContent(
                medicine: widget.medicine,
                imagePath: widget.imagePath,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICINE CARD
// ============================================================

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.onTap,
    this.imagePath,
  });

  final Medicine medicine;
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _MedicineCardContent(medicine: medicine, imagePath: imagePath),
    );
  }
}

// ============================================================
// MEDICINE CARD CONTENT
// ============================================================

class _MedicineCardContent extends StatelessWidget {
  const _MedicineCardContent({required this.medicine, this.imagePath});

  final Medicine medicine;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final isLow =
        medicine.isLowStock ||
        (medicine.isCourse && medicine.supplyDaysLeft <= 5);

    final isCourse = medicine.isCourse;

    final effectiveImagePath = imagePath ?? medicine.typeImageAsset;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardFill,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: effectiveImagePath != null
                  ? _MedicationImage(
                      path: effectiveImagePath,
                      fallbackIcon: medicine.typeIcon,
                      fallbackColor: isLow
                          ? AppColors.lowBadgeText
                          : AppColors.formAccent,
                    )
                  : Center(
                      child: Icon(
                        medicine.typeIcon,
                        color: isLow
                            ? AppColors.lowBadgeText
                            : AppColors.formAccent,
                        size: 25,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${medicine.name} ${medicine.dose}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    if (isLow)
                      _MedicineBadge(
                        text: 'LOW STOCK',
                        background: AppColors.lowBadgeBackground,
                        foreground: AppColors.lowBadgeText,
                      )
                    else if (isCourse)
                      const _MedicineBadge(
                        text: 'ACTIVE',
                        background: AppColors.successBackground,
                        foreground: AppColors.success,
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${medicine.typeLabel} · ${medicine.frequency}',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      isCourse
                          ? Icons.error_outline_rounded
                          : Icons.access_time_rounded,
                      size: 12,
                      color: isCourse
                          ? AppColors.lowBadgeText
                          : AppColors.formSubtitle,
                    ),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        isCourse
                            ? 'Ends ${medicine.endsOnLabel}'
                            : 'Next: ${medicine.nextDose}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCourse
                              ? AppColors.lowBadgeText
                              : AppColors.formSubtitle,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: medicine.progressValue,
                              minHeight: 6,
                              backgroundColor: AppColors.progressTrackLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isLow
                                    ? AppColors.lowBadgeText
                                    : AppColors.formAccent,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            medicine.supplyLabel,
                            style: TextStyle(
                              color: isLow
                                  ? AppColors.lowBadgeText
                                  : AppColors.formSubtitle,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 13),

                    const Padding(
                      padding: EdgeInsets.only(top: 0),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.formSubtitle,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICATION IMAGE
//
// Supports:
// - bundled asset
// - local file path
//
// TODO Backend:
// Firebase Storage / remote URL image support can be added through
// repository/domain image references without changing medication data flow.
// ============================================================

class _MedicationImage extends StatelessWidget {
  const _MedicationImage({
    required this.path,
    required this.fallbackIcon,
    required this.fallbackColor,
  });

  final String path;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return Center(child: Icon(fallbackIcon, color: fallbackColor, size: 25));
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return fallback();
        },
      );
    }

    final file = File(path);

    if (!file.existsSync()) {
      return fallback();
    }

    return Image.file(
      file,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return fallback();
      },
    );
  }
}

// ============================================================
// MEDICINE BADGE
// ============================================================

class _MedicineBadge extends StatelessWidget {
  const _MedicineBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
