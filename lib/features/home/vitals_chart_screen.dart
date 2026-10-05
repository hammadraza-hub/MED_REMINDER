import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'add_vitals_entry_data.dart';
import 'add_vitals_entry_screen.dart';
import 'home_data.dart';
import 'vitals_chart_data.dart';
import 'vitals_data.dart';

/// ============================================================
/// VITALS CHART / TREND
///
/// PURPOSE:
/// Ek selected vital ko time ke sath visualize karna.
///
/// FEATURES:
/// - 7D / 30D / 90D / 365D
/// - Line chart
/// - Blood Pressure dual lines
/// - Reference range shading
/// - Point tap → exact reading/date
/// - Latest reading
/// - Dynamic trend insight
/// - Log New Reading
///
/// TODO Backend:
/// - memberId + vital type se Firestore history stream.
/// - Range-specific queries.
/// - Newly logged reading ke baad realtime chart refresh.
/// ============================================================
class VitalsChartScreen extends StatefulWidget {
  const VitalsChartScreen({
    super.key,
    required this.userName,
    required this.vitalType,
  });

  final String userName;
  final VitalType vitalType;

  @override
  State<VitalsChartScreen> createState() => _VitalsChartScreenState();
}

class _VitalsChartScreenState extends State<VitalsChartScreen> {
  VitalChartRange _selectedRange = VitalChartRange.days7;

  late final List<VitalChartReading> _allReadings;

  VitalChartReading? _selectedReading;

  @override
  void initState() {
    super.initState();

    // TODO Backend:
    // widget.userName ki jagah memberId use karke
    // Firestore vitals stream query karni hai.
    _allReadings = VitalsChartData.history(widget.vitalType);
  }

  List<VitalChartReading> get _readings {
    return VitalsChartData.filteredHistory(_allReadings, _selectedRange);
  }

  VitalChartReading? get _latest {
    return VitalsChartData.latest(_readings);
  }

  // ================= NAVIGATION =================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  Future<void> _logNewReading() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddVitalsEntryScreen(
          userName: widget.userName,
          initialType: _addVitalType,
        ),
      ),
    );

    if (!mounted || result == null) return;

    // TODO Backend:
    // Firestore stream lagne ke baad new reading automatically
    // _allReadings / chart mein appear hogi.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Vital reading saved successfully ✓')),
      );
  }

  AddVitalType get _addVitalType {
    switch (widget.vitalType) {
      case VitalType.bloodPressure:
        return AddVitalType.bloodPressure;
      case VitalType.bloodGlucose:
        return AddVitalType.glucose;
      case VitalType.weight:
        return AddVitalType.weight;
      case VitalType.heartRate:
        return AddVitalType.heartRate;
    }
  }

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

          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 2),

                Expanded(
                  child: Text(
                    VitalsChartData.titleFor(widget.vitalType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                AppAvatar(
                  size: 36,
                  imagePath: HomeData.userProfileImage(),
                  ringColor: AppColors.surface,
                  ringWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= CONTENT =================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRangeSelector(),

          const SizedBox(height: 14),

          _buildChartCard(),

          const SizedBox(height: 14),

          _buildLatestReadingCard(),

          const SizedBox(height: 14),

          _buildTrendCard(),

          const SizedBox(height: 16),

          _buildLogButton(),

          const SizedBox(height: 7),

          _buildBackButton(),
        ],
      ),
    );
  }

  // ================= RANGE =================

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: VitalChartRange.values
            .map((range) => Expanded(child: _rangeButton(range)))
            .toList(),
      ),
    );
  }

  Widget _rangeButton(VitalChartRange range) {
    final selected = _selectedRange == range;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = range;
          _selectedReading = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          VitalsChartData.rangeLabel(range),
          style: TextStyle(
            color: selected ? AppColors.surface : AppColors.formAccent,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ================= CHART CARD =================

  Widget _buildChartCard() {
    final readings = _readings;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: AppColors.headerDark,
                size: 21,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  VitalsChartData.chartTitleFor(widget.vitalType),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                'AVG ${VitalsChartData.averageLabel(widget.vitalType, readings)}',
                style: const TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildLegend(),

          const SizedBox(height: 10),

          SizedBox(
            height: 190,
            child: readings.isEmpty
                ? const Center(
                    child: Text(
                      'No readings available for this period.',
                      style: TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 13,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          _selectNearestPoint(
                            details.localPosition,
                            Size(constraints.maxWidth, constraints.maxHeight),
                          );
                        },
                        child: CustomPaint(
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          painter: _VitalsLineChartPainter(
                            type: widget.vitalType,
                            readings: readings,
                            referenceRange: VitalsChartData.referenceRange(
                              widget.vitalType,
                            ),
                            selectedReading: _selectedReading,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_selectedReading != null) ...[
            const SizedBox(height: 10),
            _buildSelectedReading(),
          ],

          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_outlined,
                color: AppColors.formAccent,
                size: 15,
              ),
              SizedBox(width: 5),
              Text(
                'Tap any point to inspect individual readings',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    if (widget.vitalType == VitalType.bloodPressure) {
      return Row(
        children: [
          _legendItem(AppColors.headerDark, 'Systolic'),
          const SizedBox(width: 12),
          _legendItem(AppColors.formAccent, 'Diastolic'),
          const SizedBox(width: 12),
          if (VitalsChartData.referenceRange(widget.vitalType) != null)
            _referenceLegend(
              VitalsChartData.referenceRange(widget.vitalType)!.label,
            ),
        ],
      );
    }

    final reference = VitalsChartData.referenceRange(widget.vitalType);

    return Row(
      children: [
        _legendItem(
          AppColors.formAccent,
          VitalsChartData.chartTitleFor(widget.vitalType),
        ),
        if (reference != null) ...[
          const SizedBox(width: 12),
          _referenceLegend(reference.label),
        ],
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.formSubtitle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _referenceLegend(String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.successBackground,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= POINT TAP =================

  void _selectNearestPoint(Offset position, Size size) {
    final readings = _readings;

    if (readings.isEmpty) return;

    const leftPadding = 34.0;
    const rightPadding = 10.0;

    final usableWidth = math.max(1.0, size.width - leftPadding - rightPadding);

    final relativeX = (position.dx - leftPadding).clamp(0.0, usableWidth);

    final ratio = relativeX / usableWidth;

    final index = (ratio * (readings.length - 1)).round().clamp(
      0,
      readings.length - 1,
    );

    setState(() {
      _selectedReading = readings[index];
    });
  }

  Widget _buildSelectedReading() {
    final reading = _selectedReading!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppColors.formAccent,
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _formatFullDate(reading.recordedAt),
              style: const TextStyle(
                color: AppColors.formSubtitle,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${VitalsChartData.readingValue(widget.vitalType, reading)} ${VitalsChartData.unitFor(widget.vitalType)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================= LATEST =================

  Widget _buildLatestReadingCard() {
    final latest = _latest;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.outline),
      ),
      child: latest == null
          ? const Text(
              'No latest reading available.',
              style: TextStyle(color: AppColors.formSubtitle, fontSize: 13),
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Latest Reading',
                        style: TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            VitalsChartData.readingValue(
                              widget.vitalType,
                              latest,
                            ),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              VitalsChartData.unitFor(widget.vitalType),
                              style: const TextStyle(
                                color: AppColors.formAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      _statusBadge(
                        VitalsChartData.statusFor(widget.vitalType, latest),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.formAccent,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _latestTimeLabel(latest.recordedAt),
                          style: const TextStyle(
                            color: AppColors.formAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    if (widget.vitalType == VitalType.bloodPressure &&
                        latest.secondaryValue != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: AppColors.error,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Pulse 72 bpm',
                              style: TextStyle(
                                color: AppColors.formSubtitle,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }

  Widget _statusBadge(String status) {
    final review = status == 'Review';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: review
              ? AppColors.hintBackground
              : AppColors.successBackground,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: review ? AppColors.hintAccent : AppColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ================= TREND =================

  Widget _buildTrendCard() {
    final readings = _readings;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.formAccent,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  VitalsChartData.trendSummary(
                    widget.vitalType,
                    readings,
                    _selectedRange,
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  VitalsChartData.trendDetail(widget.vitalType, readings),
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUTTONS =================

  Widget _buildLogButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _logNewReading,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.formAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
        label: const Text(
          'Log New Reading',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.arrow_back_rounded, size: 17),
      label: const Text(
        'Back to Vitals',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(foregroundColor: AppColors.formAccent),
    );
  }

  // ================= FORMATTERS =================

  String _latestTimeLabel(DateTime date) {
    final now = DateTime.now();

    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (sameDay) {
      return 'Today, ${_formatTime(date)}';
    }

    return _formatFullDate(date);
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatFullDate(DateTime date) {
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
        '${date.day}, ${date.year} · '
        '${_formatTime(date)}';
  }
}

// ============================================================
// CUSTOM LINE CHART
// ============================================================

class _VitalsLineChartPainter extends CustomPainter {
  const _VitalsLineChartPainter({
    required this.type,
    required this.readings,
    required this.referenceRange,
    required this.selectedReading,
  });

  final VitalType type;
  final List<VitalChartReading> readings;
  final VitalReferenceRange? referenceRange;
  final VitalChartReading? selectedReading;

  static const double _left = 34;
  static const double _right = 10;
  static const double _top = 10;
  static const double _bottom = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final values = <double>[
      ...readings.map((reading) => reading.primaryValue),
      ...readings.map((reading) => reading.secondaryValue).whereType<double>(),
    ];

    if (referenceRange != null) {
      values
        ..add(referenceRange!.minimum)
        ..add(referenceRange!.maximum);
    }

    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);

    final padding = math.max((maxValue - minValue) * 0.20, 5.0);

    minValue -= padding;
    maxValue += padding;

    final chartWidth = size.width - _left - _right;

    final chartHeight = size.height - _top - _bottom;

    double xFor(int index) {
      if (readings.length == 1) {
        return _left + chartWidth / 2;
      }

      return _left + (index / (readings.length - 1)) * chartWidth;
    }

    double yFor(double value) {
      final ratio = (value - minValue) / (maxValue - minValue);

      return _top + chartHeight - (ratio * chartHeight);
    }

    // ================= REFERENCE BAND =================
    if (referenceRange != null) {
      final topY = yFor(referenceRange!.maximum);
      final bottomY = yFor(referenceRange!.minimum);

      final referencePaint = Paint()
        ..color = AppColors.successBackground.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(_left, topY, size.width - _right, bottomY),
        referencePaint,
      );
    }

    // ================= GRID =================
    final gridPaint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.85)
      ..strokeWidth = 1;

    const gridLines = 4;

    for (var i = 0; i <= gridLines; i++) {
      final y = _top + (chartHeight / gridLines) * i;

      canvas.drawLine(
        Offset(_left, y),
        Offset(size.width - _right, y),
        gridPaint,
      );

      final value = maxValue - ((maxValue - minValue) / gridLines) * i;

      final painter = TextPainter(
        text: TextSpan(
          text: type == VitalType.weight
              ? value.toStringAsFixed(1)
              : value.round().toString(),
          style: const TextStyle(color: AppColors.formSubtitle, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }

    // ================= PRIMARY LINE =================
    _drawSeries(
      canvas: canvas,
      readings: readings,
      xFor: xFor,
      yFor: yFor,
      color: type == VitalType.bloodPressure
          ? AppColors.headerDark
          : AppColors.formAccent,
      valueFor: (reading) => reading.primaryValue,
    );

    // ================= DIASTOLIC =================
    if (type == VitalType.bloodPressure) {
      _drawSeries(
        canvas: canvas,
        readings: readings,
        xFor: xFor,
        yFor: yFor,
        color: AppColors.formAccent,
        valueFor: (reading) => reading.secondaryValue ?? reading.primaryValue,
      );
    }

    // ================= DATE LABELS =================
    _drawDateLabels(canvas, size, xFor);

    // ================= SELECTED GUIDE =================
    if (selectedReading != null) {
      final index = readings.indexOf(selectedReading!);

      if (index >= 0) {
        final x = xFor(index);

        final guidePaint = Paint()
          ..color = AppColors.formAccent.withValues(alpha: 0.35)
          ..strokeWidth = 1;

        canvas.drawLine(
          Offset(x, _top),
          Offset(x, _top + chartHeight),
          guidePaint,
        );
      }
    }
  }

  void _drawSeries({
    required Canvas canvas,
    required List<VitalChartReading> readings,
    required double Function(int) xFor,
    required double Function(double) yFor,
    required Color color,
    required double Function(VitalChartReading) valueFor,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    for (var i = 0; i < readings.length; i++) {
      final x = xFor(i);
      final y = yFor(valueFor(readings[i]));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (var i = 0; i < readings.length; i++) {
      final x = xFor(i);
      final y = yFor(valueFor(readings[i]));

      final selected = identical(readings[i], selectedReading);

      if (selected) {
        canvas.drawCircle(Offset(x, y), 6, Paint()..color = AppColors.surface);
      }

      canvas.drawCircle(Offset(x, y), selected ? 4 : 3, pointPaint);
    }
  }

  void _drawDateLabels(Canvas canvas, Size size, double Function(int) xFor) {
    if (readings.isEmpty) return;

    final indexes = <int>{0, readings.length ~/ 2, readings.length - 1}.toList()
      ..sort();

    for (final index in indexes) {
      final date = readings[index].recordedAt;

      final text = '${_month(date.month)} ${date.day}';

      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: AppColors.formAccent,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      var x = xFor(index) - painter.width / 2;

      x = x.clamp(_left, size.width - _right - painter.width);

      painter.paint(canvas, Offset(x, size.height - painter.height));
    }
  }

  String _month(int month) {
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

    return months[month - 1];
  }

  @override
  bool shouldRepaint(covariant _VitalsLineChartPainter oldDelegate) {
    return oldDelegate.readings != readings ||
        oldDelegate.selectedReading != selectedReading ||
        oldDelegate.type != type ||
        oldDelegate.referenceRange != referenceRange;
  }
}
