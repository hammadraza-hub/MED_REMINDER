import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/dose.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/dose_repository.dart';
import '../meds/meds_data.dart';
import 'adherence_detail_screen.dart';
import 'calendar_data.dart';
import 'missed_dose_reason_modal.dart';
import '../../widgets/app_avatar.dart';

/// ============================================================
/// CALENDAR — DOSE HISTORY  (M7 — Firestore-backed)
///
/// Features:
/// • Month / Week view
/// • Previous / Next period
/// • Today shortcut
/// • Taken / Partial / Missed color-coded days (real Firestore doses)
/// • Selected-day dose preview
/// • Missed-dose reason modal → persisted to Firestore
/// • Adherence Detail navigation
///
/// Backend:
/// • Single `Stream<List<Dose>>` per visible month (no per-cell queries)/// • DoseRepository.watchDosesForDateRange()
/// • Adherence computed locally from the streamed doses
///
/// TODO (you): Wire `_resolveProfileId()` to your auth/session service
/// (the same source HomeScreen uses). Currently returns empty string.
/// ============================================================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _monthView = true;

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  // ================= FIRESTORE STREAM STATE =================

  /// All doses for the currently visible month (real-time).
  List<Dose> _monthDoses = const [];

  /// Active stream subscription — cancelled/re-created on month change.
  StreamSubscription<List<Dose>>? _monthDosesSub;

  // ================= PROFILE ID (Firestore) =================

  /// Real Firestore profile ID (NOT the local SQLite memberId).
  /// Fetched from users/{uid}.selectedMemberId with fallback.
  String? _firestoreProfileId;

  /// True while profile ID is being fetched from Firestore.
  bool _profileLoading = true;

  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthNames = [
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

  static const List<String> _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // ================= INIT =================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDate = DateTime(now.year, now.month, now.day);

    _visibleMonth = DateTime(now.year, now.month);

    // Fetch real Firestore profile ID first, then subscribe to doses.
    _fetchFirestoreProfileId();
  }

  @override
  void dispose() {
    _monthDosesSub?.cancel();
    super.dispose();
  }

  // ================= PROFILE ID (Firestore) =================

  /// Fetch the real Firestore profile ID from users/{uid}.selectedMemberId.
  /// Fallback: query profiles collection where ownerUid == uid + kind == 'self'.
  /// Self-heals: writes the found ID back to users/{uid}.selectedMemberId.
  ///
  /// This is the SAME pattern MedsScreen uses — profile IDs match
  /// Firestore security rules' isOwner() check.
  Future<void> _fetchFirestoreProfileId() async {
    try {
      final uid = AuthRepository.instance.currentUid;
      if (uid == null) {
        if (mounted) setState(() => _profileLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final profileId = data['selectedMemberId'] as String?;
        if (profileId != null && profileId.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _firestoreProfileId = profileId;
            _profileLoading = false;
          });
          _subscribeMonthDoses();
          return;
        }
      }

      // Fallback: query profiles where ownerUid == uid + kind == 'self'.
      final querySnap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('ownerUid', isEqualTo: uid)
          .where('kind', isEqualTo: 'self')
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final fallbackId = querySnap.docs.first.id;

        // Self-heal: write back to users/{uid}.selectedMemberId.
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'selectedMemberId': fallbackId,
        }, SetOptions(merge: true));

        if (!mounted) return;
        setState(() {
          _firestoreProfileId = fallbackId;
          _profileLoading = false;
        });
        _subscribeMonthDoses();
        return;
      }

      // No profile found at all.
      if (!mounted) return;
      setState(() => _profileLoading = false);
    } catch (e) {
      debugPrint('CalendarScreen: failed to fetch profile ID — $e');
      if (!mounted) return;
      setState(() => _profileLoading = false);
    }
  }

  /// Returns the real Firestore profile ID (or empty string if not loaded).
  String _resolveProfileId() {
    return _firestoreProfileId ?? '';
  }

  // ================= FIRESTORE STREAM =================

  void _subscribeMonthDoses() {
    _monthDosesSub?.cancel();

    final profileId = _resolveProfileId();
    if (profileId.isEmpty) {
      // No profile yet — keep empty list, don't subscribe.
      setState(() => _monthDoses = const []);
      return;
    }

    // Fetch the whole visible month in one query.
    final from = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final to = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

    _monthDosesSub = DoseRepository.instance
        .watchDosesForDateRange(profileId, from, to)
        .listen(
          (doses) {
            if (!mounted) return;
            setState(() => _monthDoses = doses);
          },
          onError: (error) {
            if (!mounted) return;
            // Silent fail — calendar still renders, just empty.
            debugPrint('Calendar stream error: $error');
            setState(() => _monthDoses = const []);
          },
        );
  }

  // ================= DATA (computed from _monthDoses) =================

  /// Doses for the currently selected date (mapped to UI model).
  List<DoseHistoryItem> get _selectedDateDoses {
    final dayDoses = _monthDoses
        .where((d) => _isSameDate(d.scheduledAt.toLocal(), _selectedDate))
        .toList();
    return dayDoses.map(_doseToHistoryItem).toList();
  }

  int get _daysInVisibleMonth {
    return DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
  }

  // ================= DOSE → UI MAPPING =================

  DoseHistoryItem _doseToHistoryItem(Dose dose) {
    return DoseHistoryItem(
      id: dose.id,
      medicineName: dose.medName,
      strength: '',
      subtitle: dose.doseLabel ?? '',
      time: _formatTime(dose.scheduledAt.toLocal()),
      status: _mapDoseStatus(dose),
      medicineType: MedicineType.tablet,
      missedReason: dose.reasonText,
    );
  }

  DoseHistoryStatus _mapDoseStatus(Dose dose) {
    switch (dose.status) {
      case DoseStatus.taken:
        return DoseHistoryStatus.taken;
      case DoseStatus.skipped:
      case DoseStatus.missed:
        return DoseHistoryStatus.missed;
      case DoseStatus.snoozed:
        return DoseHistoryStatus.pending;
      case DoseStatus.pending:
        final now = DateTime.now();
        final scheduledLocal = dose.scheduledAt.toLocal();
        if (scheduledLocal.isAfter(now)) {
          return DoseHistoryStatus.upcoming;
        }
        if (dose.isOverdue) {
          return DoseHistoryStatus.missed;
        }
        return DoseHistoryStatus.pending;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  // ================= ADHERENCE (real computation) =================

  DayAdherenceStatus _computeAdherence(DateTime date) {
    final dayDoses = _monthDoses
        .where((d) => _isSameDate(d.scheduledAt.toLocal(), date))
        .where((d) => !d.isPrn) // PRN never counts
        .toList();

    if (dayDoses.isEmpty) return DayAdherenceStatus.none;

    int taken = 0, missed = 0;

    for (final dose in dayDoses) {
      final uiStatus = _mapDoseStatus(dose);
      if (uiStatus == DoseHistoryStatus.taken) {
        taken++;
      } else if (uiStatus == DoseHistoryStatus.missed) {
        missed++;
      }
      // pending / upcoming don't count toward day status until resolved
    }

    // Nothing resolved yet — day is "no data" (still upcoming/pending).
    if (taken == 0 && missed == 0) return DayAdherenceStatus.none;

    if (taken > 0 && missed == 0) return DayAdherenceStatus.taken;
    if (taken == 0 && missed > 0) return DayAdherenceStatus.missed;
    return DayAdherenceStatus.partial;
  }

  // ================= DATE HELPERS =================

  bool _isSameDate(DateTime first, DateTime second) {
    return CalendarData.isSameDate(first, second);
  }

  DateTime _clampedDateForMonth(int year, int month, int preferredDay) {
    final lastDay = DateTime(year, month + 1, 0).day;

    final day = preferredDay > lastDay ? lastDay : preferredDay;

    return DateTime(year, month, day);
  }

  // ================= NAVIGATION =================

  void _previousPeriod() {
    if (_monthView) {
      final previousMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month - 1,
      );

      final selected = _clampedDateForMonth(
        previousMonth.year,
        previousMonth.month,
        _selectedDate.day,
      );

      setState(() {
        _visibleMonth = previousMonth;
        _selectedDate = selected;
      });

      _subscribeMonthDoses();

      return;
    }

    final selected = _selectedDate.subtract(const Duration(days: 7));

    setState(() {
      _selectedDate = selected;

      _visibleMonth = DateTime(selected.year, selected.month);
    });

    _subscribeMonthDoses();
  }

  void _nextPeriod() {
    if (_monthView) {
      final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);

      final selected = _clampedDateForMonth(
        nextMonth.year,
        nextMonth.month,
        _selectedDate.day,
      );

      setState(() {
        _visibleMonth = nextMonth;
        _selectedDate = selected;
      });

      _subscribeMonthDoses();

      return;
    }

    final selected = _selectedDate.add(const Duration(days: 7));

    setState(() {
      _selectedDate = selected;

      _visibleMonth = DateTime(selected.year, selected.month);
    });

    _subscribeMonthDoses();
  }

  void _goToToday() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _selectedDate = today;

      _visibleMonth = DateTime(today.year, today.month);
    });

    _subscribeMonthDoses();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;

      _visibleMonth = DateTime(date.year, date.month);
    });

    // If user navigates to a different month via cell tap, resubscribe.
    _subscribeMonthDoses();
  }

  // ================= VIEW SWITCH =================

  void _showMonthView() {
    setState(() {
      _monthView = true;

      _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });

    _subscribeMonthDoses();
  }

  void _showWeekView() {
    setState(() {
      _monthView = false;
    });

    _subscribeMonthDoses();
  }

  // ================= USER ACTIONS =================

  void _openAdherenceDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdherenceDetailScreen(initialEndDate: _selectedDate),
      ),
    );
  }

  // ============================================================
  // MISSED DOSE REASON → FIRESTORE PERSISTENCE
  // ============================================================

  Future<void> _openMissedDoseReason(DoseHistoryItem dose) async {
    // Only missed doses should enter this flow.
    if (dose.status != DoseHistoryStatus.missed) {
      return;
    }

    final result = await showMissedDoseReasonModal(
      context,
      dose: dose,
      doseDate: _selectedDate,
    );

    if (!mounted || result == null) {
      // User ne:
      // • X press kiya
      // • outside tap kiya
      // • Skip for Now kiya
      //
      // Koi reason save nahi hoga.
      return;
    }

    // ================= PERSIST TO FIRESTORE =================
    //
    // Map modal result.type → Firestore MissedDoseReason enum.
    // Modal may have more granular types than Firestore's 4-value enum,
    // so we collapse them: forgot → forgot, side effect → sideEffect,
    // out of stock / ran out → ranOut, everything else → other.
    final reasonCode = _mapReasonType(result.type);

    // Combine reasonText + note into a single reasonText field.
    //
    // result.reasonText is non-nullable String.
    // result.note is nullable String?.
    final reasonText = result.reasonText;
    final note = result.note;

    final parts = <String>[
      if (reasonText.isNotEmpty) reasonText,
      if (note != null && note.isNotEmpty) note,
    ];
    final combinedText = parts.isEmpty ? null : parts.join(' — ');

    final profileId = _resolveProfileId();
    if (profileId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No profile — reason not saved')),
        );
      return;
    }

    try {
      await DoseRepository.instance.updateMissedReason(
        profileId: profileId,
        doseId: dose.id,
        reasonCode: reasonCode,
        reasonText: combinedText,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Reason saved: ${result.reasonText}')),
        );
      // Stream will auto-refresh _monthDoses → UI updates.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to save reason: $e')));
    }
  }

  /// Map modal's reason type → Firestore MissedDoseReason enum.
  /// Uses string matching so it works regardless of the modal's
  /// exact enum name.
  MissedDoseReason _mapReasonType(dynamic type) {
    final name = (type?.name ?? '').toString().toLowerCase();

    if (name.contains('forgot')) return MissedDoseReason.forgot;
    if (name.contains('side')) return MissedDoseReason.sideEffect;
    if (name.contains('out') ||
        name.contains('stock') ||
        name.contains('ran')) {
      return MissedDoseReason.ranOut;
    }
    return MissedDoseReason.other;
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    // Show loading state while profile ID is being fetched.
    if (_profileLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // No profile found — user needs to login / select profile.
    if (_firestoreProfileId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppColors.fieldHint,
                ),
                SizedBox(height: 16),
                Text(
                  'No profile found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please login or select a profile to view your calendar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
                  child: Column(
                    children: [
                      _buildCalendarCard(),

                      const SizedBox(height: 12),

                      _buildSelectedDateCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            children: [
              // ================= TOP ROW =================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Calendar',
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
                      IconButton(
                        onPressed: () {
                          // TODO Backend:
                          // Current user/member ka notification
                          // center / unread alerts load karne hain.
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.surface,
                        ),
                      ),

                      Positioned(
                        top: 8,
                        right: 8,
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

                  const AppAvatar(
                    size: 34,
                    ringColor: AppColors.surface,
                    ringWidth: 2,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ================= MONTH / WEEK =================
              Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.calendarToggleBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _viewButton(
                        title: 'Month',
                        selected: _monthView,
                        onTap: _showMonthView,
                      ),
                    ),

                    Expanded(
                      child: _viewButton(
                        title: 'Week',
                        selected: !_monthView,
                        onTap: _showWeekView,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ================= PERIOD NAV =================
              Row(
                children: [
                  _circleButton(
                    Icons.chevron_left_rounded,
                    onTap: _previousPeriod,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      _monthView
                          ? '${_monthNames[_visibleMonth.month - 1]} '
                                '${_visibleMonth.year}'
                          : _weekHeaderText(),
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  _circleButton(
                    Icons.chevron_right_rounded,
                    onTap: _nextPeriod,
                  ),

                  const SizedBox(width: 14),

                  InkWell(
                    onTap: _goToToday,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.calendarHeaderButton,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 11,
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

  // ================= WEEK HEADER TEXT =================

  String _weekHeaderText() {
    final start = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    final end = start.add(const Duration(days: 6));

    if (start.month == end.month && start.year == end.year) {
      return '${_shortMonthNames[start.month - 1]} '
          '${start.day} - ${end.day}, '
          '${start.year}';
    }

    if (start.year == end.year) {
      return '${_shortMonthNames[start.month - 1]} '
          '${start.day} - '
          '${_shortMonthNames[end.month - 1]} '
          '${end.day}, ${start.year}';
    }

    return '${_shortMonthNames[start.month - 1]} '
        '${start.day}, ${start.year} - '
        '${_shortMonthNames[end.month - 1]} '
        '${end.day}, ${end.year}';
  }

  // ================= VIEW BUTTON =================

  Widget _viewButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : AppColors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.formAccent : AppColors.headerSubtext,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ================= PERIOD BUTTON =================

  Widget _circleButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.calendarCircleButton,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: AppColors.surface),
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR CARD
  // ============================================================

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ================= WEEKDAY LABELS =================

          Row(
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.calendarWeekdayText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          if (_monthView) _buildMonthGrid() else _buildWeekGrid(),

          const SizedBox(height: 14),

          // ================= LEGEND =================
          const Wrap(
            spacing: 12,
            runSpacing: 5,
            alignment: WrapAlignment.center,
            children: [
              _Legend(color: AppColors.calendarTaken, text: 'Taken'),
              _Legend(color: AppColors.calendarPartial, text: 'Partial'),
              _Legend(color: AppColors.calendarMissed, text: 'Missed'),
              _Legend(color: AppColors.calendarToday, text: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTH GRID
  // ============================================================

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);

    final leadingEmptyCells = firstDay.weekday - 1;

    final daysInMonth = _daysInVisibleMonth;

    final requiredCells = leadingEmptyCells + daysInMonth;

    final rows = (requiredCells / 7).ceil();

    final totalCells = rows * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final day = index - leadingEmptyCells + 1;

        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);

        return _dateCell(date);
      },
    );
  }

  // ============================================================
  // WEEK GRID
  // ============================================================

  Widget _buildWeekGrid() {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return Row(
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 3,
              right: index == 6 ? 0 : 3,
            ),
            child: AspectRatio(aspectRatio: 1, child: _dateCell(date)),
          ),
        );
      }),
    );
  }

  // ============================================================
  // DATE CELL
  // ============================================================

  Widget _dateCell(DateTime date) {
    final selected = _isSameDate(date, _selectedDate);

    final today = _isSameDate(date, DateTime.now());

    final adherence = _computeAdherence(date);

    Color background;
    Color foreground;

    switch (adherence) {
      case DayAdherenceStatus.taken:
        background = AppColors.calendarTakenBackground;
        foreground = AppColors.calendarTaken;
        break;

      case DayAdherenceStatus.partial:
        background = AppColors.calendarPartialBackground;
        foreground = AppColors.calendarPartial;
        break;

      case DayAdherenceStatus.missed:
        background = AppColors.calendarMissedBackground;
        foreground = AppColors.calendarMissed;
        break;

      case DayAdherenceStatus.none:
        background = AppColors.calendarNoDataBackground;
        foreground = AppColors.calendarNoDataText;
        break;
    }

    // Today has its own visual state.
    if (today) {
      background = AppColors.calendarToday;
      foreground = AppColors.surface;
    }

    // Selected state has highest priority.
    if (selected) {
      background = AppColors.formAccent;
      foreground = AppColors.surface;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _selectDate(date),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: AppColors.headerDark, width: 2)
              : today
              ? Border.all(color: AppColors.calendarToday)
              : null,
        ),
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED DATE CARD
  // ============================================================

  Widget _buildSelectedDateCard() {
    final today = _isSameDate(_selectedDate, DateTime.now());

    final dateText =
        '${_shortMonthNames[_selectedDate.month - 1]} '
        '${_selectedDate.day}';

    final doses = _selectedDateDoses;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ================= DATE HEADER =================

          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.calendarTaken,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  today
                      ? 'Today · $dateText'
                      : '$dateText · ${_selectedDate.year}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${doses.length} doses',
                  style: const TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ================= DOSES =================
          if (doses.isEmpty) _buildNoDoses() else ...doses.map(_doseTile),

          const SizedBox(height: 4),

          // ================= ADHERENCE DETAIL =================
          TextButton(
            onPressed: _openAdherenceDetail,
            child: const Text(
              'View Full Adherence Report  →',
              style: TextStyle(color: AppColors.formAccent, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ================= NO DOSES =================

  Widget _buildNoDoses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      alignment: Alignment.center,
      child: const Text(
        'No doses scheduled for this day',
        style: TextStyle(color: AppColors.fieldHint, fontSize: 10),
      ),
    );
  }

  // ============================================================
  // DOSE TILE
  //
  // Missed dose tap → Missed Dose Reason modal → Firestore persist.
  // Taken/Pending/Upcoming dose → no reason modal.
  // ============================================================

  Widget _doseTile(DoseHistoryItem dose) {
    final statusColor = _statusColor(dose.status);

    final missed = dose.status == DoseHistoryStatus.missed;

    return InkWell(
      onTap: missed ? () => _openMissedDoseReason(dose) : null,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.calendarDoseBackground,
          borderRadius: BorderRadius.circular(11),
          border: missed
              ? Border.all(
                  color: AppColors.calendarMissed.withValues(alpha: 0.25),
                )
              : null,
        ),
        child: Row(
          children: [
            // ================= MEDICINE IMAGE =================

            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: dose.medicineImageAsset != null
                  ? Image.asset(
                      dose.medicineImageAsset!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          _medicineTypeIcon(dose.medicineType),
                          color: statusColor,
                          size: 19,
                        );
                      },
                    )
                  : Icon(
                      _medicineTypeIcon(dose.medicineType),
                      color: statusColor,
                      size: 19,
                    ),
            ),

            const SizedBox(width: 9),

            // ================= MEDICINE INFO =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    dose.subtitle,
                    style: const TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 8,
                    ),
                  ),

                  if (missed) ...[
                    const SizedBox(height: 3),

                    Text(
                      dose.missedReason != null
                          ? 'Tap to update missed-dose reason'
                          : 'Tap to add missed-dose reason',
                      style: const TextStyle(
                        color: AppColors.calendarMissed,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 7),

            // ================= TIME =================
            Text(
              dose.time,
              style: const TextStyle(
                color: AppColors.formSubtitle,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 7),

            // ================= STATUS =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dose.statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS COLOR =================

  Color _statusColor(DoseHistoryStatus status) {
    switch (status) {
      case DoseHistoryStatus.taken:
        return AppColors.calendarTaken;

      case DoseHistoryStatus.missed:
        return AppColors.calendarMissed;

      case DoseHistoryStatus.pending:
        return AppColors.statusPendingText;

      case DoseHistoryStatus.upcoming:
        return AppColors.statusUpcoming;
    }
  }

  // ================= MEDICINE FALLBACK ICON =================

  IconData _medicineTypeIcon(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return Icons.medication_outlined;

      case MedicineType.capsule:
        return Icons.medication_outlined;

      case MedicineType.liquid:
        return Icons.medication_liquid_outlined;

      case MedicineType.drops:
        return Icons.opacity_outlined;

      case MedicineType.injection:
        return Icons.vaccines_outlined;
    }
  }
}

// ============================================================
// LEGEND
// ============================================================

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 4),

        Text(
          text,
          style: const TextStyle(
            fontSize: 8,
            color: AppColors.calendarLegendText,
          ),
        ),
      ],
    );
  }
}
