import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'vitals_data.dart';
import 'add_vitals_entry_screen.dart';

/// ============================================================
/// VITALS LIST
///
/// PURPOSE:
/// User ke tamam tracked health metrics ka overview.
///
/// KEY ELEMENTS:
/// - Blood Pressure
/// - Blood Glucose
/// - Weight
/// - Heart Rate
/// - Latest value
/// - Trend
/// - Mini historical trend
///
/// ACTIONS:
/// - Vital card tap → Vitals Chart / Trend
/// - + button → Add Vitals Entry
///
/// NAVIGATION:
/// Home child screen → shared bottom navigation currentIndex = 0
///
/// TODO Backend:
/// - Current authenticated user/family member ke vitals Firestore se load.
/// - Real-time streams se latest values update.
/// - Profile/caregiver sync state backend se load.
/// ============================================================
class VitalsListScreen extends StatefulWidget {
  const VitalsListScreen({super.key, required this.userName});

  final String userName;

  @override
  State<VitalsListScreen> createState() => _VitalsListScreenState();
}

class _VitalsListScreenState extends State<VitalsListScreen> {
  late final List<VitalMetric> _metrics;

  @override
  void initState() {
    super.initState();

    // TODO Backend:
    // Firestore/user-specific vitals stream se replace karna.
    _metrics = VitalsData.metrics();
  }

  // ================= NAVIGATION =================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  void _openVitalChart(VitalMetric metric) {
    // TODO Navigation:
    // Next screen:
    // VitalsChartScreen(metric: metric)
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${metric.title} chart / trend screen next.')),
      );
  }

  Future<void> _addVitalEntry() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddVitalsEntryScreen(userName: widget.userName),
      ),
    );

    if (!mounted || result == null) return;

    // TODO Backend:
    // Firebase/Firestore realtime stream lagne ke baad Vitals List
    // automatically selected member ki latest entries se refresh hogi.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Vital entry saved successfully ✓')),
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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildBody(),
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
                const Expanded(
                  child: Text(
                    'Vitals List',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // TODO Backend:
                // Authenticated user's actual AppAvatar/photo use karna.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.fieldHint,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BODY =================

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileRow(),
          const SizedBox(height: 14),

          _buildMetricsSummary(),
          const SizedBox(height: 10),

          _buildMorningStatus(),
          const SizedBox(height: 12),

          ..._metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VitalMetricCard(
                metric: metric,
                onTap: () => _openVitalChart(metric),
              ),
            ),
          ),

          const SizedBox(height: 2),
          _buildTrendFooter(),
        ],
      ),
    );
  }

  // ================= PROFILE =================

  Widget _buildProfileRow() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: VitalsData.caregiverSyncLive
                ? AppColors.success
                : AppColors.fieldHint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),

        Text(
          VitalsData.caregiverSyncLive
              ? 'Caregiver Sync Live'
              : 'Caregiver Sync Offline',
          style: const TextStyle(
            color: AppColors.formAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        const Text(
          'PROFILE: ',
          style: TextStyle(
            color: AppColors.formAccent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),

        Text(
          widget.userName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ================= SUMMARY =================

  Widget _buildMetricsSummary() {
    final latest = VitalsData.latestUpdate(_metrics);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_metrics.length} Metrics Tracked',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.formAccent,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        latest == null
                            ? 'No vitals logged yet'
                            : 'Last updated ${_formatRelativeDateTime(latest)}',
                        style: const TextStyle(
                          color: AppColors.formSubtitle,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Material(
            color: AppColors.formAccent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _addVitalEntry,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.surface,
                  size: 29,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MORNING STATUS =================

  Widget _buildMorningStatus() {
    final completed = VitalsData.completedMorningLogs(_metrics);
    final percentage = VitalsData.morningLogPercentage(_metrics);

    return Container(
      constraints: const BoxConstraints(minHeight: 43),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.formAccent,
            size: 17,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              completed == _metrics.length && _metrics.isNotEmpty
                  ? 'All morning logs completed'
                  : '$completed of ${_metrics.length} morning logs completed',
              style: const TextStyle(
                color: AppColors.formSubtitle,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$percentage% On Schedule',
            style: const TextStyle(
              color: AppColors.formAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================= FOOTER =================

  Widget _buildTrendFooter() {
    return GestureDetector(
      onTap: () {
        if (_metrics.isNotEmpty) {
          _openVitalChart(_metrics.first);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successBackground,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Row(
          children: [
            ContainerIcon(icon: Icons.query_stats_rounded),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Tap any card to explore historical trends',
                style: TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Trends',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.formAccent,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDateTime(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final valueDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(valueDay).inDays;

    final time = _formatTime(date);

    if (difference == 0) {
      return 'today, $time';
    }

    if (difference == 1) {
      return 'yesterday, $time';
    }

    return _formatDate(date);
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

    return '${months[date.month - 1]} ${date.day}';
  }
}

// ============================================================
// VITAL METRIC CARD
// ============================================================

class _VitalMetricCard extends StatelessWidget {
  const _VitalMetricCard({required this.metric, required this.onTap});

  final VitalMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.fromLTRB(13, 13, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VitalIcon(metric: metric),
                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _entryDateTime(metric.recordedAt),
                          style: const TextStyle(
                            color: AppColors.formAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            metric.value,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            metric.trendIcon,
                            size: 16,
                            color: _trendColor(metric),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric.unit,
                        style: const TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric.detailText,
                      style: TextStyle(
                        color: metric.type == VitalType.bloodGlucose
                            ? AppColors.success
                            : AppColors.formSubtitle,
                        fontSize: 11,
                        fontWeight: metric.type == VitalType.bloodGlucose
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  SizedBox(
                    width: 70,
                    height: 25,
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        values: metric.history,
                        color: AppColors.formAccent,
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

  static String _entryDateTime(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final entryDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(entryDay).inDays;

    String dayLabel;

    if (difference == 0) {
      dayLabel = 'Today';
    } else if (difference == 1) {
      dayLabel = 'Yesterday';
    } else {
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

      dayLabel = '${months[date.month - 1]} ${date.day}';
    }

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$dayLabel, $hour:$minute $period';
  }

  static Color _trendColor(VitalMetric metric) {
    switch (metric.calculatedTrend) {
      case VitalTrend.up:
        return AppColors.hintAccent;
      case VitalTrend.down:
        return AppColors.formAccent;
      case VitalTrend.stable:
        return AppColors.formAccent;
    }
  }
}

// ============================================================
// VITAL ICON
// ============================================================

class _VitalIcon extends StatelessWidget {
  const _VitalIcon({required this.metric});

  final VitalMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(metric.icon, color: _iconColor, size: 24),
    );
  }

  Color get _iconColor {
    switch (metric.type) {
      case VitalType.bloodPressure:
        return AppColors.error;
      case VitalType.bloodGlucose:
        return AppColors.error;
      case VitalType.weight:
        return AppColors.formAccent;
      case VitalType.heartRate:
        return AppColors.error;
    }
  }
}

// ============================================================
// SMALL FOOTER ICON
// ============================================================

class ContainerIcon extends StatelessWidget {
  const ContainerIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.formAccent, size: 20),
    );
  }
}

// ============================================================
// SPARKLINE
//
// UI ko history values hardcode karne ki zarurat nahi.
// Future Firestore vital entries → history → same painter.
// ============================================================

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);

    final range = math.max(maxValue - minValue, 1.0);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (var index = 0; index < values.length; index++) {
      final x = (index / (values.length - 1)) * size.width;

      final normalized = (values[index] - minValue) / range;

      final y = size.height - (normalized * (size.height - 5)) - 2.5;

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
