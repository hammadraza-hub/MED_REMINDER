import 'package:flutter/material.dart';

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

  final List<_DoseItem> _doses = const [
    _DoseItem(
      name: 'Metformin 500mg',
      subtitle: 'Tablet · Oral',
      time: '8:30 AM',
      status: 'PENDING',
      color: Color(0xFFFFB020),
    ),
    _DoseItem(
      name: 'Amlodipine 5mg',
      subtitle: 'Tablet · Blood Pressure',
      time: '7:00 AM',
      status: 'TAKEN',
      color: Color(0xFF199D76),
    ),
    _DoseItem(
      name: 'Vitamin D3 Drops',
      subtitle: 'Liquid · Dietary Supplement',
      time: '8:00 PM',
      status: 'UPCOMING',
      color: Color(0xFF159D89),
    ),
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _visibleMonth = DateTime(now.year, now.month);

    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  int get _daysInVisibleMonth {
    return DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
  }

  void _previousPeriod() {
    if (_monthView) {
      setState(() {
        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      });
    } else {
      setState(() {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));

        _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
      });
    }
  }

  void _nextPeriod() {
    if (_monthView) {
      setState(() {
        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      });
    } else {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 7));

        _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
      });
    }
  }

  void _goToToday() {
    final now = DateTime.now();

    setState(() {
      _visibleMonth = DateTime(now.year, now.month);

      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    _buildCalendarCard(),
                    const SizedBox(height: 12),
                    _buildSelectedDateCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF074D6A),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Calendar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ),
              const CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF074D6A)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Month / Week
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF326B82),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _viewButton(
                    title: 'Month',
                    selected: _monthView,
                    onTap: () {
                      setState(() {
                        _monthView = true;
                        _visibleMonth = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                        );
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _viewButton(
                    title: 'Week',
                    selected: !_monthView,
                    onTap: () {
                      setState(() {
                        _monthView = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _circleButton(Icons.chevron_left_rounded, onTap: _previousPeriod),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _monthView
                      ? '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}'
                      : _weekHeaderText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _circleButton(Icons.chevron_right_rounded, onTap: _nextPeriod),
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
                    color: const Color(0xFF1E607B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _weekHeaderText() {
    final start = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    final end = start.add(const Duration(days: 6));

    if (start.month == end.month && start.year == end.year) {
      return '${_shortMonthNames[start.month - 1]} '
          '${start.day} - ${end.day}, ${start.year}';
    }

    if (start.year == end.year) {
      return '${_shortMonthNames[start.month - 1]} ${start.day} - '
          '${_shortMonthNames[end.month - 1]} ${end.day}, '
          '${start.year}';
    }

    return '${_shortMonthNames[start.month - 1]} ${start.day}, ${start.year} - '
        '${_shortMonthNames[end.month - 1]} ${end.day}, ${end.year}';
  }

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
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? const Color(0xFF08705E) : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFF28677F),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF39768A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          if (_monthView) _buildMonthGrid() else _buildWeekGrid(),

          const SizedBox(height: 14),

          const Wrap(
            spacing: 12,
            runSpacing: 5,
            alignment: WrapAlignment.center,
            children: [
              _Legend(color: Color(0xFF008768), text: 'Taken'),
              _Legend(color: Color(0xFFFFAD17), text: 'Partial'),
              _Legend(color: Color(0xFFE94F5D), text: 'Missed'),
              _Legend(color: Color(0xFF08728D), text: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _dateCell(DateTime date) {
    final selected = _isSameDate(date, _selectedDate);

    final today = _isSameDate(date, DateTime.now());

    final belongsToVisibleMonth =
        date.year == _visibleMonth.year && date.month == _visibleMonth.month;

    Color background = const Color(0xFFE7F5EF);

    Color foreground = const Color(0xFF08775C);

    // Demo adherence colors.
    // Later these can be connected to real medication data.
    if ([3, 11].contains(date.day)) {
      background = const Color(0xFFFFF1CF);
      foreground = const Color(0xFFF39A00);
    }

    if (date.day == 7) {
      background = const Color(0xFFFFE6E8);
      foreground = const Color(0xFFEB4252);
    }

    if (_monthView && !belongsToVisibleMonth) {
      background = const Color(0xFFF3F7F9);
      foreground = const Color(0xFFB8C9D1);
    }

    if (today) {
      background = const Color(0xFF08728D);
      foreground = Colors.white;
    }

    if (selected) {
      background = const Color(0xFF08775C);
      foreground = Colors.white;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _selectedDate = date;

          _visibleMonth = DateTime(date.year, date.month);
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: const Color(0xFF075A78), width: 2)
              : today
              ? Border.all(color: const Color(0xFF08728D))
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

  Widget _buildSelectedDateCard() {
    final today = _isSameDate(_selectedDate, DateTime.now());

    final dateText =
        '${_shortMonthNames[_selectedDate.month - 1]} '
        '${_selectedDate.day}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: Color(0xFF008768), size: 8),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  today
                      ? 'Today · $dateText'
                      : '$dateText · ${_selectedDate.year}',
                  style: const TextStyle(
                    color: Color(0xFF174B60),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_doses.length} doses',
                  style: const TextStyle(color: Color(0xFF08775C), fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._doses.map(_doseTile),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: const Text(
              'View Full Adherence Report  →',
              style: TextStyle(color: Color(0xFF08775C), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doseTile(_DoseItem dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white,
            child: Icon(Icons.medication_rounded, color: dose.color, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.name,
                  style: const TextStyle(
                    color: Color(0xFF164A61),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dose.subtitle,
                  style: const TextStyle(color: Color(0xFF6D99A8), fontSize: 8),
                ),
              ],
            ),
          ),
          Text(
            dose.time,
            style: const TextStyle(
              color: Color(0xFF176A86),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: dose.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dose.status,
              style: TextStyle(
                color: dose.color,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseItem {
  const _DoseItem({
    required this.name,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.color,
  });

  final String name;
  final String subtitle;
  final String time;
  final String status;
  final Color color;
}

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
          style: const TextStyle(fontSize: 8, color: Color(0xFF416979)),
        ),
      ],
    );
  }
}
