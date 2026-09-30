import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';

/// ============================================================
/// SCHEDULE SCREEN — Step 2 of 2 (wizard FINAL!)
///
/// Review/Manual → YE SCREEN → Confirm → Medicine COMPLETE!
///
/// 5 schedule types (Tapering tak!) + dose names + meal toggle
/// + date range + smart validations!
///
/// System: AppColors + suite bar + tablet cap
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

      // Suite bar — poori app jaisi!
      bottomNavigationBar: const _SuiteBottomBar(currentIndex: 1),
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
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 12),
          child: Column(
            children: [
              // ---- Row 1: Back + Title + Cancel + Done ----
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(22),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Cancel
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Done ✓ (header se bhi confirm!)
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: _isConfirming ? null : _confirmSchedule,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.formAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Done ✓',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),

              // ---- Row 2: Medicine info + doses badge ----
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.headerDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      _medicineTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // LIVE doses count badge!
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      '${_doseTimes.length} Doses Daily',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
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

    if (name.isEmpty && strength.isEmpty) return 'Medication';
    if (strength.isEmpty) return name;
    if (name.isEmpty) return strength;
    return '$name $strength';
  }

  // ================= STEP INDICATOR — 2/2 ACTIVE! =================
  Widget _buildStepIndicator() {
    return Container(
      height: 44,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Step 1: DONE!
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'Review',
            style: TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),

          // Full progress!
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 1.3, color: AppColors.stepTrack),
                FractionallySizedBox(
                  widthFactor: 1.0,
                  child: Container(height: 1.6, color: AppColors.stepActive),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Step 2: ACTIVE!
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.stepActive,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '2',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Schedule',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 9.5,
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
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 26),
      child: Column(
        children: [
          // 1. Schedule Type + Days (ek card — design!)
          _buildScheduleCard(),
          const SizedBox(height: 12),

          // 2. Cycle (sirf Cyclical mein!)
          if (_scheduleType == 'Cyclical') ...[
            _buildCycleCard(),
            const SizedBox(height: 12),
          ],

          // 3. Dose Times
          _buildDoseTimesCard(),
          const SizedBox(height: 12),

          // 4. Meal Timing
          _buildMealTimingCard(),
          const SizedBox(height: 12),

          // 5. Date Range
          _buildDateRangeCard(),
          const SizedBox(height: 14),

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
          const SizedBox(height: 10),

          // 5 options (Tapering tak!)
          ..._scheduleTypes.map(
            (option) => _buildScheduleOption(option.title, option.description),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.outline),
          const SizedBox(height: 13),

          _sectionTitle('REPEAT ON'),
          const SizedBox(height: 11),
          _buildDaySelector(),
          const SizedBox(height: 9),

          // Live hint — guidance!
          Text(
            _repeatHint,
            style: const TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 10.5,
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

          // Type ke hisaab se days RESET (consistency!)
          if (title == 'Daily') {
            _selectedDays
              ..clear()
              ..addAll({1, 2, 3, 4, 5, 6, 7});
          } else if (title == 'As Needed (PRN)' || title == 'Tapering Dose') {
            // In types mein days matter nahi — sab rakho
            _selectedDays
              ..clear()
              ..addAll({1, 2, 3, 4, 5, 6, 7});
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
              width: 19,
              height: 19,
              margin: const EdgeInsets.only(top: 2),
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
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.formAccent,
                size: 19,
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
            width: 38,
            height: 38,
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
                color: selected ? Colors.white : AppColors.formSubtitle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String get _repeatHint {
    if (_selectedDays.isEmpty) return 'Select reminder days';
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
          const SizedBox(height: 14),

          _buildCycleRow(
            label: 'On for',
            value: _weeksOn,
            onChanged: (v) => setState(() => _weeksOn = v),
          ),
          const SizedBox(height: 14),
          _buildCycleRow(
            label: 'Off for',
            value: _weeksOff,
            onChanged: (v) => setState(() => _weeksOff = v),
          ),
          const SizedBox(height: 14),

          // Pattern summary — ek line mein!
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                fontSize: 11,
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
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Minus
        _circleCounterButton(
          icon: Icons.remove_rounded,
          filled: false,
          onTap: () {
            if (value > 1) onChanged(value - 1);
          },
        ),

        // Value
        SizedBox(
          width: 38,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        // Plus
        _circleCounterButton(
          icon: Icons.add_rounded,
          filled: true,
          onTap: () {
            if (value < 12) onChanged(value + 1);
          },
        ),

        const Spacer(),
        const Text(
          'weeks',
          style: TextStyle(
            color: AppColors.formAccent,
            fontSize: 11,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.formAccent : AppColors.surface,
          border: Border.all(color: AppColors.formAccent, width: 1.2),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? Colors.white : AppColors.formAccent,
        ),
      ),
    );
  }

  String _weekWord(int count) => count == 1 ? 'week' : 'weeks';

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
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 17,
                        color: AppColors.formAccent,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Add Another Time',
                        style: TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...List.generate(_doseTimes.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _doseTimes.length - 1 ? 0 : 8,
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
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.formAccent, width: 1),
      ),
      child: Row(
        children: [
          // Drag indicator (reorder hint!)
          const Icon(
            Icons.drag_indicator_rounded,
            color: AppColors.fieldHint,
            size: 20,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _mealRelativeTiming
                      ? _selectedMealTiming
                      : 'Fixed time — no meal link',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Time button — ASLI TIME PICKER!
          GestureDetector(
            onTap: () => _pickTime(index),
            child: Container(
              width: 108,
              height: 38,
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.formAccent,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),

          // Delete (1 se zyada ho to)
          if (_doseTimes.length > 1)
            GestureDetector(
              onTap: () => _removeDose(index),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= MEAL TIMING (global switch!) =================
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Link dose timing to meals',
                      style: TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Switch — deprecated params ki jagah clean!
              Switch(
                value: _mealRelativeTiming,
                onChanged: (v) => setState(() => _mealRelativeTiming = v),
              ),
            ],
          ),

          // Timing chips (sirf ON hone par!)
          if (_mealRelativeTiming) ...[
            const SizedBox(height: 10),
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
      onTap: () => setState(() => _selectedMealTiming = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.formAccent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.formAccent,
                  fontSize: 10.5,
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
          const SizedBox(height: 12),
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _dateField(
                      text: _formatDate(_startDate),
                      onTap: _pickStartDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),

              // End (optional)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Date (optional)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
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
        height: 46,
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
              size: 17,
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
                  fontSize: 11,
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
      height: 54,
      child: FilledButton(
        onPressed: _isConfirming ? null : _confirmSchedule,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          disabledBackgroundColor: AppColors.formAccent.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
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
                  color: Colors.white,
                ),
              )
            : const Text(
                'Confirm Schedule  →',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

    if (picked == null || !mounted) return;
    setState(() => _doseTimes[index] = picked);
  }

  Future<void> _addDoseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );

    if (picked == null || !mounted) return;

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

    if (picked == null || !mounted) return;

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

    if (picked == null || !mounted) return;

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
      // TODO Backend: medicine + schedule save (Phase 2)
      // Data: type, days, cycle, doseTimes, mealTiming, dateRange
      await Future<void>.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text(
              '🎉 ${_medicineTitle} scheduled!\n'
              '${_doseTimes.length} doses · '
              '${_scheduleType.toLowerCase()}',
            ),
          ),
        );

      // Wizard COMPLETE — stack saaf → MedRemindShell!
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MedRemindShell()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
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
      padding: const EdgeInsets.all(14),
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
        fontSize: 11,
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ============================================================
// SUITE BOTTOM BAR — app jaisi!
// ============================================================
class _SuiteBottomBar extends StatelessWidget {
  const _SuiteBottomBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.formAccent,
      unselectedItemColor: AppColors.fieldHint,
      backgroundColor: AppColors.surface,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_rounded),
          label: 'Meds',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Family',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MedRemindShell()),
          (route) => false,
        );
      },
    );
  }
}
