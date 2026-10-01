import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../meds/meds_data.dart';
import 'adherence_detail_screen.dart';
import 'calendar_data.dart';
import 'missed_dose_reason_modal.dart';

/// ============================================================
/// CALENDAR — DOSE HISTORY
///
/// Features:
/// • Month / Week view
/// • Previous / Next period
/// • Today shortcut
/// • Taken / Partial / Missed color-coded days
/// • Selected-day dose preview
/// • Missed-dose reason modal
/// • Adherence Detail navigation
///
/// Backend:
/// Data CalendarData se aata hai.
/// Future mein CalendarData Firebase repository se replace hoga.
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
  }

  // ================= DATA =================

  List<DoseHistoryItem> get _selectedDateDoses {
    // TODO Backend:
    // Firebase phase mein visible/required date range ki dose history
    // ek range query mein load karni hai.
    //
    // Har calendar cell/day ke liye separate Firestore query
    // nahi chalani.
    return CalendarData.dosesForDate(_selectedDate);
  }

  int get _daysInVisibleMonth {
    return DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
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

      return;
    }

    final selected = _selectedDate.subtract(const Duration(days: 7));

    setState(() {
      _selectedDate = selected;

      _visibleMonth = DateTime(selected.year, selected.month);
    });
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

      return;
    }

    final selected = _selectedDate.add(const Duration(days: 7));

    setState(() {
      _selectedDate = selected;

      _visibleMonth = DateTime(selected.year, selected.month);
    });
  }

  void _goToToday() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _selectedDate = today;

      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;

      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  // ================= VIEW SWITCH =================

  void _showMonthView() {
    setState(() {
      _monthView = true;

      _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  void _showWeekView() {
    setState(() {
      _monthView = false;
    });
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
  // MISSED DOSE REASON
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

    // TODO Backend:
    // Current signed-in user/member ke EXISTING dose-history
    // document ko dose.id se update karna hai.
    //
    // Suggested fields:
    // missedReasonType: result.type.name
    // missedReasonText: result.reasonText
    // missedReasonNote: result.note
    // reasonRecordedAt: serverTimestamp
    // recordedByUserId: currentUser.uid
    //
    // Duplicate dose-history record create NAHI karna.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Reason saved: ${result.reasonText}')),
      );
  }

  // ================= BUILD =================

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

                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.person, color: AppColors.headerDark),
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

    final adherence = CalendarData.adherenceForDate(date);

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
  // Missed dose tap → Missed Dose Reason modal.
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
