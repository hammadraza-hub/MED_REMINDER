import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/schedule.dart';

/// Schedule Picker Screen (M5)
///
/// Lets the user configure a medication schedule.
/// Supports all 5 PRD schedule types:
///   1. daily      — Every day at specified times
///   2. weekdays   — Specific days of week
///   3. cyclical   — N days on, N days off
///   4. prn        — As needed (no fixed times)
///   5. taper      — Gradually decreasing dose
///
/// Returns a Schedule object via Navigator.pop(context, schedule).
///
/// Usage: Call via Navigator.push, returns a Schedule object on save.
class SchedulePickerScreen extends StatefulWidget {
  /// Optional initial schedule (for editing existing medication's schedule)
  final Schedule? initialSchedule;

  const SchedulePickerScreen({super.key, this.initialSchedule});

  @override
  State<SchedulePickerScreen> createState() => _SchedulePickerScreenState();
}

class _SchedulePickerScreenState extends State<SchedulePickerScreen> {
  ScheduleType _selectedType = ScheduleType.daily;
  List<String> _times = [];
  List<int> _weekdays = [];
  int? _cycleOn;
  int? _cycleOff;
  DateTime? _cycleStart;
  List<TaperStep> _taperSteps = [];
  MealRelation _mealRelation = MealRelation.noRelation;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Initialize from existing schedule (if editing)
    if (widget.initialSchedule != null) {
      final s = widget.initialSchedule!;
      _selectedType = s.type;
      _times = List.from(s.times);
      _weekdays = List.from(s.weekdays);
      _cycleOn = s.cycleOn;
      _cycleOff = s.cycleOff;
      _cycleStart = s.cycleStart;
      _taperSteps = List.from(s.taperSteps);
      _mealRelation = s.mealRelation;
      _startDate = s.startDate;
      _endDate = s.endDate;
    } else {
      _startDate = DateTime.now();
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    final schedule = Schedule(
      type: _selectedType,
      times: _times,
      weekdays: _weekdays,
      cycleOn: _cycleOn,
      cycleOff: _cycleOff,
      cycleStart: _cycleStart,
      taperSteps: _taperSteps,
      mealRelation: _mealRelation,
      startDate: _startDate,
      endDate: _endDate,
    );

    // Validate
    final error = schedule.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    Navigator.of(context).pop(schedule);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.formAccent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            ..._buildTypeSpecificFields(),
            const SizedBox(height: 20),
            _buildMealRelationSection(),
            const SizedBox(height: 20),
            _buildDateRangeSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYPE SELECTOR
  // ============================================================

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...ScheduleType.values.map((type) => _buildTypeCard(type)),
      ],
    );
  }

  Widget _buildTypeCard(ScheduleType type) {
    final isSelected = type == _selectedType;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.formAccent.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.formAccent : AppColors.outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.formAccent : AppColors.fieldHint,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.formAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TYPE-SPECIFIC FIELDS
  // ============================================================

  List<Widget> _buildTypeSpecificFields() {
    switch (_selectedType) {
      case ScheduleType.daily:
        return [_buildTimesSection()];
      case ScheduleType.weekdays:
        return [
          _buildWeekdaysSection(),
          const SizedBox(height: 16),
          _buildTimesSection(),
        ];
      case ScheduleType.cyclical:
        return [
          _buildCyclicalSection(),
          const SizedBox(height: 16),
          _buildTimesSection(),
        ];
      case ScheduleType.prn:
        return [_buildPrnInfoCard()];
      case ScheduleType.taper:
        return [_buildTaperSection()];
    }
  }

  // ============================================================
  // TIMES SECTION (for daily, weekdays, cyclical, taper)
  // ============================================================

  Widget _buildTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Times',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.formAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_times.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outline),
            ),
            child: const Text(
              'No times added. Tap "Add Time" to add a dosing time.',
              style: TextStyle(color: AppColors.fieldHint, fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _times.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.outline),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => setState(() => _times.removeAt(entry.key)),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _addTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select dosing time',
    );
    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _times.add(timeStr));
    }
  }

  // ============================================================
  // WEEKDAYS SECTION
  // ============================================================

  Widget _buildWeekdaysSection() {
    const dayLabels = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days of Week',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = _weekdays.contains(day);
            return ChoiceChip(
              label: Text(dayLabels[day]),
              selected: isSelected,
              selectedColor: AppColors.formAccent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _weekdays.add(day);
                    _weekdays.sort();
                  } else {
                    _weekdays.remove(day);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  // ============================================================
  // CYCLICAL SECTION
  // ============================================================

  Widget _buildCyclicalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cycle Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'Days On',
                value: _cycleOn,
                onChanged: (v) => setState(() => _cycleOn = v),
                hint: 'e.g., 21',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumberField(
                label: 'Days Off',
                value: _cycleOff,
                onChanged: (v) => setState(() => _cycleOff = v),
                hint: 'e.g., 7',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDateField(
          label: 'Cycle Start Date',
          value: _cycleStart,
          onChanged: (date) => setState(() => _cycleStart = date),
        ),
      ],
    );
  }

  // ============================================================
  // PRN INFO CARD
  // ============================================================

  Widget _buildPrnInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.formAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.formAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.formAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'As Needed (PRN)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.formAccent,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This medication will be taken as needed. '
                  'No specific times are required. '
                  'Add instructions in the medication details.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAPER SECTION
  // ============================================================

  Widget _buildTaperSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Taper Steps',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _addTaperStep,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Step'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.formAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_taperSteps.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outline),
            ),
            child: const Text(
              'No taper steps. Add steps to gradually decrease the dose.',
              style: TextStyle(color: AppColors.fieldHint, fontSize: 13),
            ),
          )
        else
          ..._taperSteps.asMap().entries.map((entry) {
            return _buildTaperStepCard(entry.key, entry.value);
          }),
      ],
    );
  }

  Widget _buildTaperStepCard(int index, TaperStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: () => setState(() => _taperSteps.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    label: 'Days',
                    value: step.days,
                    onChanged: (v) =>
                        _updateTaperStep(index, step.copyWith(days: v ?? 0)),
                    hint: 'e.g., 7',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    label: 'Dose Amount',
                    value: step.doseAmount.toInt(),
                    onChanged: (v) => _updateTaperStep(
                      index,
                      step.copyWith(doseAmount: v?.toDouble() ?? 0),
                    ),
                    hint: 'e.g., 5',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Times for this taper step
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...step.times.map(
                  (time) => Chip(
                    label: Text(time, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.outline),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _updateTaperStep(
                      index,
                      step.copyWith(
                        times: step.times.where((t) => t != time).toList(),
                      ),
                    ),
                  ),
                ),
                ActionChip(
                  label: const Text('+ Time', style: TextStyle(fontSize: 12)),
                  onPressed: () => _addTimeToTaperStep(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addTaperStep() {
    setState(() {
      _taperSteps.add(
        const TaperStep(days: 7, doseAmount: 1, times: ['08:00']),
      );
    });
  }

  void _updateTaperStep(int index, TaperStep updated) {
    setState(() {
      _taperSteps[index] = updated;
    });
  }

  Future<void> _addTimeToTaperStep(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final step = _taperSteps[index];
      _updateTaperStep(index, step.copyWith(times: [...step.times, timeStr]));
    }
  }

  // ============================================================
  // MEAL RELATION SECTION
  // ============================================================

  Widget _buildMealRelationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Relation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<MealRelation>(
          initialValue: _mealRelation,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: MealRelation.values.map((relation) {
            return DropdownMenuItem(
              value: relation,
              child: Text(relation.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _mealRelation = value);
            }
          },
        ),
      ],
    );
  }

  // ============================================================
  // DATE RANGE SECTION
  // ============================================================

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildDateField(
          label: 'Start Date',
          value: _startDate,
          onChanged: (date) => setState(() => _startDate = date),
        ),
        const SizedBox(height: 12),
        _buildDateField(
          label: 'End Date (optional)',
          value: _endDate,
          onChanged: (date) => setState(() => _endDate = date),
          clearable: true,
        ),
      ],
    );
  }

  // ============================================================
  // REUSABLE FIELD WIDGETS
  // ============================================================

  Widget _buildNumberField({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.fieldHint),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: (text) {
            final parsed = int.tryParse(text);
            onChanged(parsed);
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
    bool clearable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.fieldHint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.fieldHint,
                    ),
                  ),
                ),
                if (clearable && value != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() {}),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
