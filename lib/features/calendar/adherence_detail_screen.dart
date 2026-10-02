import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../meds/meds_data.dart';
import 'adherence_data.dart';

/// ============================================================
/// ADHERENCE DETAIL
///
/// Deeper adherence view for:
/// • selected date range
/// • specific medication
///
/// Features:
/// • Overall percentage
/// • Taken / Missed / Skipped breakdown
/// • Per medication adherence bars
/// • Medication filter
/// • Date range filter
/// • Reports export navigation hook
///
/// Backend:
/// AdherenceData dummy provider abhi.
/// Future mein Firestore repository.
/// ============================================================
class AdherenceDetailScreen extends StatefulWidget {
  const AdherenceDetailScreen({super.key, this.initialEndDate});

  final DateTime? initialEndDate;

  @override
  State<AdherenceDetailScreen> createState() => _AdherenceDetailScreenState();
}

class _AdherenceDetailScreenState extends State<AdherenceDetailScreen> {
  AdherenceRange _selectedRange = AdherenceRange.sevenDays;

  DateTimeRangeValue? _customRange;

  String? _selectedMedication;

  late DateTime _endDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final source = widget.initialEndDate ?? DateTime.now();

    _endDate = DateTime(source.year, source.month, source.day);
  }

  // ============================================================
  // COMPUTED DATA
  // ============================================================

  DateTime get _startDate {
    return AdherenceData.rangeStart(
      range: _selectedRange,
      endDate: _endDate,
      customRange: _customRange,
    );
  }

  DateTime get _effectiveEndDate {
    if (_selectedRange == AdherenceRange.custom && _customRange != null) {
      return _customRange!.end;
    }

    return _endDate;
  }

  List<AdherenceRecord> get _allRecords {
    // TODO Backend:
    // Firestore se selected range ki complete dose history
    // ek range query mein fetch karni hai.
    return AdherenceData.recordsForRange(
      startDate: _startDate,
      endDate: _effectiveEndDate,
    );
  }

  List<AdherenceRecord> get _filteredRecords {
    if (_selectedMedication == null) {
      return _allRecords;
    }

    return _allRecords.where((record) {
      return record.displayName == _selectedMedication;
    }).toList();
  }

  AdherenceSummary get _summary {
    return AdherenceData.overallSummary(_filteredRecords);
  }

  List<MedicationAdherenceSummary> get _allMedicationSummaries {
    return AdherenceData.medicationSummaries(_allRecords);
  }

  List<MedicationAdherenceSummary> get _visibleMedicationSummaries {
    return AdherenceData.medicationSummaries(_filteredRecords);
  }

  // ============================================================
  // RANGE
  // ============================================================

  Future<void> _selectRange(AdherenceRange range) async {
    if (range != AdherenceRange.custom) {
      setState(() {
        _selectedRange = range;
        _customRange = null;
      });

      return;
    }

    final initialStart = _endDate.subtract(const Duration(days: 6));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(_endDate.year - 5),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: initialStart, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.formAccent,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedRange = AdherenceRange.custom;

      _customRange = DateTimeRangeValue(start: picked.start, end: picked.end);

      _endDate = picked.end;
    });
  }

  // ============================================================
  // EXPORT
  // ============================================================

  void _exportToReports() {
    // TODO Backend:
    // Selected adherence range + medication filter
    // ko Reports export/save flow mein persist karna hai.
    //
    // TODO Navigation:
    // ReportsScreen ready hone par Reports screen/tab
    // ko selected filters ke saath open karna hai.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Export to Reports — reports screen pending'),
        ),
      );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    // Adherence Detail Calendar feature ka child screen hai.
    // Shared bottom navigation exact selected tab open karegi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                  child: Column(
                    children: [
                      _buildOverallCard(),

                      const SizedBox(height: 14),

                      _buildMedicationCard(),

                      const SizedBox(height: 14),

                      _buildExportButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Calendar is index 2.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        onTap: _onBottomNavigationTap,
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
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 15),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.surface,
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      'Adherence Detail',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  FilledButton(
                    onPressed: _exportToReports,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.formAccent,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Export →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _rangeButton(
                      label: '7 Days',
                      range: AdherenceRange.sevenDays,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: _rangeButton(
                      label: '30 Days',
                      range: AdherenceRange.thirtyDays,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: _rangeButton(
                      label: '90 Days',
                      range: AdherenceRange.ninetyDays,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: _rangeButton(
                      label: 'Custom',
                      range: AdherenceRange.custom,
                      icon: Icons.calendar_month_outlined,
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

  Widget _rangeButton({
    required String label,
    required AdherenceRange range,
    IconData? icon,
  }) {
    final selected = _selectedRange == range;

    return GestureDetector(
      onTap: () => _selectRange(range),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surface
              : AppColors.calendarToggleBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected
                    ? AppColors.formAccent
                    : AppColors.headerSubtext,
              ),

              const SizedBox(width: 4),
            ],

            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.formAccent
                      : AppColors.headerSubtext,
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

  // ============================================================
  // OVERALL
  // ============================================================

  Widget _buildOverallCard() {
    final summary = _summary;

    final difference = summary.differenceFromPrevious;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Adherence',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _rangeSubtitle,
                      style: const TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 14),

                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${summary.adherencePercent}',
                            style: const TextStyle(
                              color: AppColors.formAccent,
                              fontSize: 36,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const TextSpan(
                            text: '%',
                            style: TextStyle(
                              color: AppColors.formAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      '${difference >= 0 ? '+' : ''}'
                      '$difference% vs prior period',
                      style: TextStyle(
                        color: difference >= 0
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              _buildGoalRing(summary),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  value: summary.taken,
                  label: 'Taken',
                  icon: Icons.check_rounded,
                  color: AppColors.calendarTaken,
                  background: AppColors.adherenceTakenBackground,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _summaryBox(
                  value: summary.missed,
                  label: 'Missed',
                  icon: Icons.close_rounded,
                  color: AppColors.calendarMissed,
                  background: AppColors.adherenceMissedBackground,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _summaryBox(
                  value: summary.skipped,
                  label: 'Skipped',
                  icon: Icons.skip_next_rounded,
                  color: AppColors.adherenceSkipped,
                  background: AppColors.adherenceSkippedBackground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _rangeSubtitle {
    if (_selectedMedication != null) {
      return '$_rangeLabel · $_selectedMedication';
    }

    return '$_rangeLabel · All Medications';
  }

  String get _rangeLabel {
    switch (_selectedRange) {
      case AdherenceRange.sevenDays:
        return 'Last 7 days';

      case AdherenceRange.thirtyDays:
        return 'Last 30 days';

      case AdherenceRange.ninetyDays:
        return 'Last 90 days';

      case AdherenceRange.custom:
        return 'Custom range';
    }
  }

  Widget _buildGoalRing(AdherenceSummary summary) {
    final goal = AdherenceData.adherenceGoalPercent();

    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: summary.adherenceProgress,
              strokeWidth: 7,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.formAccent,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${summary.adherencePercent}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'GOAL $goal%',
                style: const TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required int value,
    required String label,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.surface, size: 18),
          ),

          const SizedBox(height: 7),

          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(color: AppColors.formSubtitle, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PER MEDICATION
  // ============================================================

  Widget _buildMedicationCard() {
    final meds = _visibleMedicationSummaries;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Per Medication',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              _buildMedicationFilter(),
            ],
          ),

          const SizedBox(height: 16),

          if (meds.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'No adherence data',
                style: TextStyle(color: AppColors.fieldHint, fontSize: 13),
              ),
            )
          else
            ...meds.map(
              (med) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _medicationRow(med),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationFilter() {
    final meds = _allMedicationSummaries;

    return PopupMenuButton<String?>(
      tooltip: 'Filter medication',
      color: AppColors.surface,
      onSelected: (value) {
        setState(() {
          _selectedMedication = value;
        });
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String?>(
            value: null,
            child: Text(
              'All Meds',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),

          ...meds.map(
            (med) => PopupMenuItem<String?>(
              value: med.displayName,
              child: Text(
                med.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ];
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedMedication ?? 'All Meds',
            style: const TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 4),

          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.formSubtitle,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _medicationRow(MedicationAdherenceSummary med) {
    final color = _adherenceColor(med.adherencePercent);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.cardFill,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: med.medicineImageAsset != null
              ? Image.asset(
                  med.medicineImageAsset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _medicineTypeIcon(med.type),
                      color: color,
                      size: 22,
                    );
                  },
                )
              : Icon(_medicineTypeIcon(med.type), color: color, size: 22),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      med.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '${med.adherencePercent}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: med.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.progressTrackLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      med.breakdownLabel,
                      style: const TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(
                    med.frequencyLabel,
                    style: const TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _adherenceColor(int percent) {
    if (percent >= 85) {
      return AppColors.calendarTaken;
    }

    if (percent >= 70) {
      return AppColors.adherenceSkipped;
    }

    return AppColors.calendarMissed;
  }

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

  // ============================================================
  // EXPORT
  // ============================================================

  /// Reference design ke mutabiq:
  /// Green + Red + Blue three-bar chart icon.
  Widget _buildExportBarsIcon() {
    return SizedBox(
      width: 25,
      height: 23,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 5,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.adherenceExportGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 3),

          Container(
            width: 5,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.adherenceExportRed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 3),

          Container(
            width: 5,
            height: 17,
            decoration: BoxDecoration(
              color: AppColors.adherenceExportBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _exportToReports,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.formAccent,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.formAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Row(
          children: [
            _buildExportBarsIcon(),

            const SizedBox(width: 9),

            const Expanded(
              child: Text(
                'Export This View to Reports',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),

            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
