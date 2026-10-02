import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';

/// ============================================================
/// SCHEDULE SCREEN — Step 2 of 2 (wizard FINAL!)
///
/// Review/Manual → YE SCREEN → Confirm → Medicine COMPLETE!
///
/// 5 schedule types (Tapering tak!) + dose names + meal toggle
/// + date range + smart validations!
///
/// System: AppColors + shared AppBottomNavigation + tablet cap
///
/// TODO Backend:
/// - Medication + schedule current authenticated user/family member ke
///   Firestore documents mein save karna
/// - Dose reminder notifications schedule/reschedule karna
/// - Inventory document medicationId ke against initialize/update karna
/// - Schedule edit mode mein existing schedule document update karna
/// ============================================================
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.medicineName, this.medicineStrength});

  final String? medicineName;
  final String? medicineStrength;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // ================= STATE =================
  String _scheduleType = 'Daily';

  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Mon-Fri

  int _weeksOn = 3;
  int _weeksOff = 1;

  List<TimeOfDay> _doseTimes = [
    const TimeOfDay(hour: 8, minute: 30),
    const TimeOfDay(hour: 20, minute: 0),
  ];

  List<String> _doseNames = ['Morning Dose', 'Evening Dose'];

  bool _mealRelativeTiming = true;
  String _selectedMealTiming = 'After meal';

  DateTime _startDate = DateTime.now();
  bool _hasEndDate = false;
  DateTime? _endDate;

  bool _isConfirming = false;

  // ================= DATA =================
  static const List<({String title, String description})> _scheduleTypes = [
    (title: 'Daily', description: 'Every day without exception'),
    (title: 'Specific Days', description: 'Choose days of the week'),
    (title: 'Cyclical', description: 'e.g. 3 weeks on, 1 week off'),
    (title: 'As Needed (PRN)', description: 'Take only when required'),
    (title: 'Tapering Dose', description: 'Gradually changing dosage'),
  ];

  static const List<(int, String)> _days = [
    (1, 'M'),
    (2, 'T'),
    (3, 'W'),
    (4, 'T'),
    (5, 'F'),
    (6, 'S'),
    (7, 'S'),
  ];

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildStepIndicator(),
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

      // Schedule belongs to the Meds flow.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ================= SHARED BOTTOM NAVIGATION =================
  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 14),
          child: Column(
            children: [
              // ---- Row 1: Back + Title + Cancel + Done ----
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(22),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.surface,
                        size: 25,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      'Schedule',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Cancel
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      minimumSize: const Size(0, 38),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Done ✓ (header se bhi confirm!)
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: _isConfirming ? null : _confirmSchedule,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.formAccent,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Done ✓',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 11),

              // ---- Row 2: Medicine info + doses badge ----
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.fieldFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.headerDark,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Flexible(
                    child: Text(
                      _medicineTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // LIVE doses count badge!
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      '${_doseTimes.length} Doses Daily',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  String get _medicineTitle {
    final name = widget.medicineName?.trim() ?? '';
    final strength = widget.medicineStrength?.trim() ?? '';

    if (name.isEmpty && strength.isEmpty) {
      return 'Medication';
    }

    if (strength.isEmpty) {
      return name;
    }

    if (name.isEmpty) {
      return strength;
    }

    return '$name $strength';
  }

  // ================= STEP INDICATOR — 2/2 ACTIVE! =================
  Widget _buildStepIndicator() {
    return Container(
      height: 56,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // Step 1: DONE!
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.surface,
              size: 16,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Review',
            style: TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 12),

          // Full progress!
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 2, color: AppColors.stepTrack),
                FractionallySizedBox(
                  widthFactor: 1.0,
                  child: Container(height: 2, color: AppColors.stepActive),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Step 2: ACTIVE!
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.stepActive,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '2',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 7),

          const Text(
            'Schedule',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTENT =================
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
      child: Column(
        children: [
          // 1. Schedule Type + Days
          _buildScheduleCard(),
          const SizedBox(height: 14),

          // 2. Cycle (sirf Cyclical mein!)
          if (_scheduleType == 'Cyclical') ...[
            _buildCycleCard(),
            const SizedBox(height: 14),
          ],

          // 3. Dose Times
          _buildDoseTimesCard(),
          const SizedBox(height: 14),

          // 4. Meal Timing
          _buildMealTimingCard(),
          const SizedBox(height: 14),

          // 5. Date Range
          _buildDateRangeCard(),
          const SizedBox(height: 18),

          // Confirm!
          _buildConfirmButton(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ================= SCHEDULE TYPE + DAYS =================
  Widget _buildScheduleCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('SCHEDULE TYPE'),
          const SizedBox(height: 12),

          ..._scheduleTypes.map(
            (option) => _buildScheduleOption(option.title, option.description),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.outline),
          const SizedBox(height: 15),

          _sectionTitle('REPEAT ON'),
          const SizedBox(height: 13),

          _buildDaySelector(),

          const SizedBox(height: 11),

          Text(
            _repeatHint,
            style: const TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOption(String title, String description) {
    final selected = _scheduleType == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _scheduleType = title;

          // Type ke hisaab se days RESET
          if (title == 'Daily') {
            _selectedDays
              ..clear()
              ..addAll({1, 2, 3, 4, 5, 6, 7});
          } else if (title == 'As Needed (PRN)' || title == 'Tapering Dose') {
            _selectedDays
              ..clear()
              ..addAll({1, 2, 3, 4, 5, 6, 7});
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.successBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.formAccent : Colors.transparent,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio dot
            Container(
              width: 21,
              height: 21,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.formAccent : AppColors.surface,
                border: Border.all(
                  color: selected ? AppColors.formAccent : AppColors.fieldHint,
                  width: 1.4,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.formAccent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ================= DAY SELECTOR =================
  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((day) {
        final selected = _selectedDays.contains(day.$1);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedDays.remove(day.$1);
              } else {
                _selectedDays.add(day.$1);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.formAccent : AppColors.fieldFill,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.formAccent : AppColors.outline,
              ),
            ),
            child: Text(
              day.$2,
              style: TextStyle(
                color: selected ? AppColors.surface : AppColors.formSubtitle,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String get _repeatHint {
    if (_selectedDays.isEmpty) {
      return 'Select reminder days';
    }

    if (_selectedDays.length == 7) {
      return 'Reminders will fire every day';
    }

    return 'Reminders will fire only on selected days';
  }

  // ================= CYCLE =================
  Widget _buildCycleCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CYCLE PATTERN'),
          const SizedBox(height: 16),

          _buildCycleRow(
            label: 'On for',
            value: _weeksOn,
            onChanged: (value) {
              setState(() {
                _weeksOn = value;
              });
            },
          ),

          const SizedBox(height: 16),

          _buildCycleRow(
            label: 'Off for',
            value: _weeksOff,
            onChanged: (value) {
              setState(() {
                _weeksOff = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Pattern summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              'Pattern: $_weeksOn ${_weekWord(_weeksOn)} on · '
              '$_weeksOff ${_weekWord(_weeksOff)} off',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.formAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Minus
        _circleCounterButton(
          icon: Icons.remove_rounded,
          filled: false,
          onTap: () {
            if (value > 1) {
              onChanged(value - 1);
            }
          },
        ),

        // Value
        SizedBox(
          width: 42,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        // Plus
        _circleCounterButton(
          icon: Icons.add_rounded,
          filled: true,
          onTap: () {
            if (value < 12) {
              onChanged(value + 1);
            }
          },
        ),

        const Spacer(),

        const Text(
          'weeks',
          style: TextStyle(
            color: AppColors.formAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _circleCounterButton({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.formAccent : AppColors.surface,
          border: Border.all(color: AppColors.formAccent, width: 1.2),
        ),
        child: Icon(
          icon,
          size: 21,
          color: filled ? AppColors.surface : AppColors.formAccent,
        ),
      ),
    );
  }

  String _weekWord(int count) {
    return count == 1 ? 'week' : 'weeks';
  }

  // ================= DOSE TIMES =================
  Widget _buildDoseTimesCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('DOSE TIMES')),

              // Add Another Time
              GestureDetector(
                onTap: _addDoseTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.formAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Add Time',
                        style: TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...List.generate(_doseTimes.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _doseTimes.length - 1 ? 0 : 9,
              ),
              child: _buildDoseRow(index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDoseRow(int index) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.formAccent, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.drag_indicator_rounded,
            color: AppColors.fieldHint,
            size: 21,
          ),

          const SizedBox(width: 8),

          // Dose name + meal
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _doseNames[index],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _mealRelativeTiming
                      ? _selectedMealTiming
                      : 'Fixed time — no meal link',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Time button
          GestureDetector(
            onTap: () => _pickTime(index),
            child: Container(
              width: 112,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.manageIconFill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_doseTimes[index]),
                    style: const TextStyle(
                      color: AppColors.formAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.formAccent,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Delete
          if (_doseTimes.length > 1)
            GestureDetector(
              onTap: () => _removeDose(index),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.error,
                  size: 21,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= MEAL TIMING =================
  Widget _buildMealTimingCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meal-Relative Timing',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Link dose timing to meals',
                      style: TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: _mealRelativeTiming,
                onChanged: (value) {
                  setState(() {
                    _mealRelativeTiming = value;
                  });
                },
              ),
            ],
          ),

          if (_mealRelativeTiming) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _mealTimingChip('Before meal')),
                const SizedBox(width: 7),
                Expanded(child: _mealTimingChip('With meal')),
                const SizedBox(width: 7),
                Expanded(child: _mealTimingChip('After meal')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealTimingChip(String title) {
    final selected = _selectedMealTiming == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealTiming = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.formAccent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: AppColors.surface,
              ),
              const SizedBox(width: 3),
            ],

            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.surface : AppColors.formAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DATE RANGE =================
  Widget _buildDateRangeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('DATE RANGE'),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Start
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Date',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    _dateField(
                      text: _formatDate(_startDate),
                      onTap: _pickStartDate,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 9),

              // End
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Date (optional)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    _dateField(
                      text: _hasEndDate && _endDate != null
                          ? _formatDate(_endDate!)
                          : 'No end date',
                      muted: !_hasEndDate,
                      onTap: _pickEndDate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String text,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: muted ? AppColors.fieldFill : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: muted ? AppColors.outline : AppColors.formAccent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: muted ? AppColors.fieldHint : AppColors.formAccent,
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted ? AppColors.fieldHint : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CONFIRM =================
  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _isConfirming ? null : _confirmSchedule,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          disabledBackgroundColor: AppColors.formAccent.withValues(alpha: 0.6),
          foregroundColor: AppColors.surface,
          elevation: 3,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isConfirming
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: AppColors.surface,
                ),
              )
            : const Text(
                'Confirm Schedule  →',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ================= ACTIONS =================
  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index],
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _doseTimes[index] = picked;
    });
  }

  Future<void> _addDoseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _doseTimes = [..._doseTimes, picked];

      _doseNames = [..._doseNames, 'Dose ${_doseTimes.length}'];
    });
  }

  void _removeDose(int index) {
    if (_doseTimes.length <= 1) {
      _showMessage('At least one dose time is required.');
      return;
    }

    setState(() {
      _doseTimes.removeAt(index);
      _doseNames.removeAt(index);
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = picked;

      // SMART — start aage badha to end reset!
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = null;
        _hasEndDate = false;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365 * 5)),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = picked;
      _hasEndDate = true;
    });
  }

  Future<void> _confirmSchedule() async {
    // Validations
    if (_selectedDays.isEmpty) {
      _showMessage('Please select at least one reminder day.');
      return;
    }

    if (_doseTimes.isEmpty) {
      _showMessage('Please add at least one dose time.');
      return;
    }

    setState(() => _isConfirming = true);

    try {
      // TODO Backend:
      // 1. Save/update medication for current user/family member.
      // 2. Save schedule type, selected days, cycle, dose times,
      //    meal timing and date range.
      // 3. Create/update inventory using medicationId.
      //    Do NOT create duplicate inventory documents.
      // 4. Schedule local/Firebase medication notifications.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text(
              '🎉 $_medicineTitle scheduled!\n'
              '${_doseTimes.length} doses · '
              '${_scheduleType.toLowerCase()}',
            ),
          ),
        );

      // Wizard COMPLETE — directly Meds tab.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MedRemindShell(initialIndex: 1),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= HELPERS =================
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.headerDark,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '${hour.toString().padLeft(2, '0')} : $minute $period';
  }

  String _formatDate(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}
