import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'streaks_stats_data.dart';

/// ============================================================
/// STREAKS & STATS
///
/// Motivational view of medication consistency over time.
///
/// Features:
/// • Current streak
/// • Best / longest streak
/// • This month adherence
/// • 30 / 90 day adherence trend
/// • Recent achievements
///
/// Backend:
/// Screen direct hardcoded statistics use nahi karti.
/// StreaksStatsData abhi dummy history provide karta hai.
/// Future mein Firebase repository same data models/calculations
/// ko real user's dose history provide karegi.
/// ============================================================
class StreaksStatsScreen extends StatefulWidget {
  const StreaksStatsScreen({super.key, this.userName = 'Sarah'});

  final String userName;

  @override
  State<StreaksStatsScreen> createState() => _StreaksStatsScreenState();
}

class _StreaksStatsScreenState extends State<StreaksStatsScreen> {
  StreakTrendRange _selectedTrendRange = StreakTrendRange.thirtyDays;

  // ============================================================
  // COMPUTED DATA
  // ============================================================

  StreakStatsSummary get _summary {
    return StreaksStatsData.summary();
  }

  List<StreakTrendPoint> get _trendPoints {
    return StreaksStatsData.trend(range: _selectedTrendRange);
  }

  // ============================================================
  // SHARE
  // ============================================================

  void _shareStats() {
    // TODO Backend / Share:
    // User ki current stats ka shareable report/image/text
    // generate karke platform share sheet open karni hai.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Share stats — sharing integration pending'),
        ),
      );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    // Streaks & Stats Home feature ka child screen hai.
    // Shared bottom navigation exact selected main tab open karegi.
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                  child: Column(
                    children: [
                      _buildCurrentStreakCard(),

                      const SizedBox(height: 12),

                      _buildMiniStats(),

                      const SizedBox(height: 12),

                      _buildTrendCard(),

                      const SizedBox(height: 12),

                      _buildAchievementsCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Streaks & Stats Home flow ka part hai.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
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
      color: AppColors.streakHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
                      'Streaks & Stats',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: _shareStats,
                    borderRadius: BorderRadius.circular(22),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.share_outlined,
                        color: AppColors.surface,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 11),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.streakHeaderCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 Keep it up, ${widget.userName}!',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'You’re building a strong medication routine.',
                      style: TextStyle(
                        color: AppColors.headerSubtext,
                        fontSize: 12,
                        height: 1.3,
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
  // CURRENT STREAK
  // ============================================================

  Widget _buildCurrentStreakCard() {
    final summary = _summary;

    return _card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.streakFireBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 27)),
          ),

          const SizedBox(height: 9),

          const Text(
            'Current Streak',
            style: TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${summary.currentStreak}',
                    style: const TextStyle(
                      color: AppColors.streakHeader,
                      fontSize: 38,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const TextSpan(
                    text: ' Days',
                    style: TextStyle(
                      color: AppColors.streakHeader,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const TextSpan(text: ' 🔥', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Goal: ${summary.goalDays} days',
            style: const TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Text(
                '0',
                style: TextStyle(color: AppColors.formSubtitle, fontSize: 10),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.progressTrackLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    FractionallySizedBox(
                      widthFactor: summary.goalProgress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.streakMint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              Text(
                '${summary.goalDays}',
                style: const TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Text(
            summary.daysUntilGoal > 0
                ? '${summary.daysUntilGoal} more days to reach your goal! 🎉'
                : 'Goal reached — keep the streak going! 🎉',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.streakMint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MINI STATS
  // ============================================================

  Widget _buildMiniStats() {
    final summary = _summary;

    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.streakGold,
            iconBackground: AppColors.streakGoldBackground,
            label: 'Best Streak',
            value: '${summary.longestStreak} Days',
            footer: 'Personal best 🏆',
            footerColor: AppColors.streakGold,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _miniStatCard(
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.streakMint,
            iconBackground: AppColors.streakMintBackground,
            label: 'This Month',
            value: '${summary.monthAdherencePercent}%',
            footer: 'Adherence rate',
            footerColor: AppColors.formSubtitle,
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required String value,
    required String footer,
    required Color footerColor,
  }) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(height: 9),

          Text(
            label,
            style: const TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.streakHeader,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            footer,
            textAlign: TextAlign.center,
            style: TextStyle(color: footerColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TREND
  // ============================================================

  Widget _buildTrendCard() {
    return _card(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Adherence Trend',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              _trendButton(label: '30D', range: StreakTrendRange.thirtyDays),

              const SizedBox(width: 6),

              _trendButton(label: '90D', range: StreakTrendRange.ninetyDays),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 145,
            width: double.infinity,
            child: _TrendChart(points: _trendPoints, targetPercent: 80),
          ),
        ],
      ),
    );
  }

  Widget _trendButton({
    required String label,
    required StreakTrendRange range,
  }) {
    final selected = _selectedTrendRange == range;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTrendRange = range;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.streakMint
              : AppColors.streakMintBackground,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.surface : AppColors.streakMint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACHIEVEMENTS
  // ============================================================

  Widget _buildAchievementsCard() {
    final achievements = _summary.achievements;

    return _card(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Achievements',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          if (achievements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Keep going to unlock achievements',
                  style: TextStyle(color: AppColors.formSubtitle, fontSize: 12),
                ),
              ),
            )
          else
            ...achievements.map((achievement) => _achievementRow(achievement)),
        ],
      ),
    );
  }

  Widget _achievementRow(StreakAchievement achievement) {
    final iconData = _achievementIcon(achievement.type);

    final iconColor = _achievementColor(achievement.type);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.progressTrackLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.streakAchievementBackground,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.35)),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  achievement.subtitle,
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Icon(iconData, color: iconColor, size: 17),
        ],
      ),
    );
  }

  IconData _achievementIcon(StreakAchievementType type) {
    switch (type) {
      case StreakAchievementType.streak:
        return Icons.local_fire_department_rounded;

      case StreakAchievementType.perfectWeek:
        return Icons.star_outline_rounded;

      case StreakAchievementType.firstRefill:
        return Icons.emoji_events_outlined;
    }
  }

  Color _achievementColor(StreakAchievementType type) {
    switch (type) {
      case StreakAchievementType.streak:
        return AppColors.streakGold;

      case StreakAchievementType.perfectWeek:
        return AppColors.streakHeader;

      case StreakAchievementType.firstRefill:
        return AppColors.streakFire;
    }
  }

  // ============================================================
  // SHARED CARD
  // ============================================================

  Widget _card({required Widget child, required EdgeInsetsGeometry padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: AppColors.streakCardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================
// TREND CHART
//
// No external chart package required.
// Data points StreaksStatsData se aate hain.
// ============================================================

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, required this.targetPercent});

  final List<StreakTrendPoint> points;
  final int targetPercent;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text(
          'No trend data',
          style: TextStyle(color: AppColors.formSubtitle, fontSize: 12),
        ),
      );
    }

    return CustomPaint(
      painter: _TrendChartPainter(points: points, targetPercent: targetPercent),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.points, required this.targetPercent});

  final List<StreakTrendPoint> points;
  final int targetPercent;

  @override
  void paint(Canvas canvas, Size size) {
    // Extra room left/bottom because chart labels are now readable.
    const left = 36.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 24.0;

    final chartWidth = size.width - left - right;

    final chartHeight = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = AppColors.streakTrendGrid
      ..strokeWidth = 1;

    final targetPaint = Paint()
      ..color = AppColors.streakTrendTarget
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = AppColors.streakTrend
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines.
    for (final percent in [50, 80, 100]) {
      final y = _yForPercent(percent, top, chartHeight);

      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    // Target line.
    final targetY = _yForPercent(targetPercent, top, chartHeight);

    const dashWidth = 4.0;
    const dashGap = 3.0;

    var dashX = left;

    while (dashX < left + chartWidth) {
      canvas.drawLine(
        Offset(dashX, targetY),
        Offset(math.min(dashX + dashWidth, left + chartWidth), targetY),
        targetPaint,
      );

      dashX += dashWidth + dashGap;
    }

    // Trend line.
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * (i / (points.length - 1));

      final y = _yForPercent(points[i].percent, top, chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Latest point.
    final latestX = points.length == 1
        ? left + chartWidth / 2
        : left + chartWidth;

    final latestY = _yForPercent(points.last.percent, top, chartHeight);

    canvas.drawCircle(
      Offset(latestX, latestY),
      4,
      Paint()..color = AppColors.surface,
    );

    canvas.drawCircle(
      Offset(latestX, latestY),
      3,
      Paint()..color = AppColors.streakTrend,
    );

    _drawText(canvas, '100%', const Offset(0, 2), AppColors.formSubtitle);

    _drawText(
      canvas,
      '80%',
      Offset(3, targetY - 5),
      AppColors.streakTrendTarget,
    );

    _drawText(
      canvas,
      '50%',
      Offset(3, _yForPercent(50, top, chartHeight) - 5),
      AppColors.formSubtitle,
    );

    _drawRightText(
      canvas,
      'Target $targetPercent%',
      Offset(left + chartWidth, targetY - 16),
      color: AppColors.streakTrendTarget,
    );

    final firstLabel = _dateLabel(points.first.date);

    final middleLabel = _dateLabel(points[points.length ~/ 2].date);

    final lastLabel = _dateLabel(points.last.date);

    _drawText(
      canvas,
      firstLabel,
      Offset(left, size.height - 14),
      AppColors.formSubtitle,
    );

    _drawCenteredText(
      canvas,
      middleLabel,
      Offset(left + chartWidth / 2, size.height - 14),
    );

    _drawRightText(
      canvas,
      lastLabel,
      Offset(left + chartWidth, size.height - 14),
    );
  }

  double _yForPercent(int percent, double top, double chartHeight) {
    final value = percent.clamp(40, 100).toDouble();

    return top + chartHeight * (1 - ((value - 40) / 60));
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  void _drawCenteredText(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.formSubtitle,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  void _drawRightText(
    Canvas canvas,
    String text,
    Offset right, {
    Color color = AppColors.formSubtitle,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(right.dx - painter.width, right.dy));
  }

  String _dateLabel(DateTime date) {
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

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.targetPercent != targetPercent;
  }
}
