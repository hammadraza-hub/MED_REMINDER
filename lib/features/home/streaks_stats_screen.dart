import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../models/dose.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/dose_repository.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'streaks_stats_data.dart';

/// ============================================================
/// STREAKS & STATS  (M7 — Firestore-backed)
///
/// Motivational view of medication consistency over time.
///
/// Features:
/// • Current streak + goal progress
/// • Best / longest streak
/// • This month adherence
/// • 30 / 90 day adherence trend (line chart)
/// • Recent achievements
///
/// Backend (M7):
/// • Firestore doses via DoseRepository.getDosesForDateRange()
///   — last 90 days fetched once on init.
/// • Profile ID from users/{uid}.selectedMemberId (same as
///   Calendar + Adherence Detail).
/// • Streak + trend + achievements computed locally from doses.
/// • UI 100% preserved — only data source swapped.
/// ============================================================
class StreaksStatsScreen extends StatefulWidget {
  const StreaksStatsScreen({super.key, this.userName = 'Sarah'});

  final String userName;

  @override
  State<StreaksStatsScreen> createState() => _StreaksStatsScreenState();
}

class _StreaksStatsScreenState extends State<StreaksStatsScreen> {
  StreakTrendRange _selectedTrendRange = StreakTrendRange.thirtyDays;

  // ================= FIRESTORE STATE (M7) =================

  /// Real Firestore profile ID (same source as CalendarScreen).
  String? _profileId;

  /// True while profile ID + doses are being fetched.
  bool _loading = true;

  /// Error message if fetch failed (null = OK).
  String? _error;

  /// All Firestore doses for the last 90 days (fetched once on init).
  /// Used for streak, trend, and achievements computation.
  List<Dose> _allDoses = const [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _fetchProfileAndDoses();
  }

  // ============================================================
  // FIRESTORE — PROFILE ID + DOSES
  // ============================================================

  /// Same pattern as CalendarScreen + AdherenceDetailScreen:
  /// users/{uid}.selectedMemberId → fallback query → self-heal.
  Future<void> _fetchProfileAndDoses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_profileId == null || _profileId!.isEmpty) {
        final uid = AuthRepository.instance.currentUid;
        if (uid == null) {
          setState(() {
            _error = 'Not logged in';
            _loading = false;
          });
          return;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        String? profileId;

        if (userDoc.exists) {
          final data = userDoc.data()!;
          profileId = data['selectedMemberId'] as String?;
        }

        if (profileId == null || profileId.isEmpty) {
          final querySnap = await FirebaseFirestore.instance
              .collection('profiles')
              .where('ownerUid', isEqualTo: uid)
              .where('kind', isEqualTo: 'self')
              .limit(1)
              .get();

          if (querySnap.docs.isNotEmpty) {
            profileId = querySnap.docs.first.id;

            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'selectedMemberId': profileId,
            }, SetOptions(merge: true));
          }
        }

        if (profileId == null || profileId.isEmpty) {
          setState(() {
            _error = 'No profile found';
            _loading = false;
          });
          return;
        }

        _profileId = profileId;
      }

      await _loadDoses();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  /// Fetch last 90 days of doses — enough for streak + 90D trend.
  Future<void> _loadDoses() async {
    if (_profileId == null || _profileId!.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final from = today.subtract(
        const Duration(days: 89),
      ); // 90 days incl today

      final doses = await DoseRepository.instance.getDosesForDateRange(
        _profileId!,
        from,
        today,
      );

      if (!mounted) return;

      setState(() {
        _allDoses = doses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load doses: $e';
        _loading = false;
      });
    }
  }

  // ============================================================
  // COMPUTED DATA (M7 — real Firestore computation)
  // ============================================================

  /// Computed streak summary from real Firestore doses.
  /// Replaces StreaksStatsData.summary() (dummy).
  StreakStatsSummary get _summary {
    return _computeSummary();
  }

  /// Computed trend points from real Firestore doses.
  /// Replaces StreaksStatsData.trend() (dummy).
  List<StreakTrendPoint> get _trendPoints {
    return _computeTrendPoints();
  }

  // ============================================================
  // SUMMARY COMPUTATION
  // ============================================================

  StreakStatsSummary _computeSummary() {
    // Bucket doses by day (excluding PRN).
    final Map<String, _DayBucket> dayBuckets = {};

    for (final dose in _allDoses) {
      if (dose.isPrn) continue;

      final local = dose.scheduledAt.toLocal();
      final key = _dayKey(local);

      final bucket = dayBuckets.putIfAbsent(key, () => _DayBucket(date: local));

      switch (dose.status) {
        case DoseStatus.taken:
          bucket.taken++;
          break;
        case DoseStatus.skipped:
          bucket.skipped++;
          break;
        case DoseStatus.missed:
          bucket.missed++;
          break;
        case DoseStatus.pending:
          if (dose.isOverdue) bucket.missed++;
          break;
        case DoseStatus.snoozed:
          break;
      }
    }

    final sortedBuckets = dayBuckets.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final currentStreak = _computeCurrentStreak(sortedBuckets);
    final longestStreak = _computeLongestStreak(sortedBuckets);
    final monthAdherence = _computeMonthAdherence(dayBuckets);
    final totalTaken = sortedBuckets.fold<int>(0, (acc, b) => acc + b.taken);
    // === GOAL ===
    // Goal = 30 days (reasonable default; could be user-configurable later).
    // goalProgress + daysUntilGoal are COMPUTED GETTERS on StreakStatsSummary
    // (derived from currentStreak + goalDays) — don't pass them here.
    const goalDays = 30;

    // === ACHIEVEMENTS ===
    final achievements = _computeAchievements(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalTaken: totalTaken,
    );

    return StreakStatsSummary(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      goalDays: goalDays,
      monthAdherencePercent: monthAdherence,
      achievements: achievements,
    );
  }

  int _computeCurrentStreak(List<_DayBucket> buckets) {
    if (buckets.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final lastBucket = buckets.last;
    final lastDate = _dateOnly(lastBucket.date);

    // Streak must include today or yesterday.
    if (lastDate != today && lastDate != yesterday) return 0;

    int streak = 0;
    DateTime cursor = lastDate;

    for (final bucket in buckets.reversed) {
      final bucketDate = _dateOnly(bucket.date);
      if (bucketDate != cursor) break;

      // Good day: at least 1 taken AND 0 missed.
      if (bucket.taken > 0 && bucket.missed == 0) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int _computeLongestStreak(List<_DayBucket> buckets) {
    if (buckets.isEmpty) return 0;

    int longest = 0;
    int current = 0;
    DateTime? expectedNext;

    for (final bucket in buckets) {
      final bucketDate = _dateOnly(bucket.date);
      final isGood = bucket.taken > 0 && bucket.missed == 0;

      if (isGood) {
        if (expectedNext == null || bucketDate == expectedNext) {
          current++;
          expectedNext = bucketDate.add(const Duration(days: 1));
        } else {
          current = 1;
          expectedNext = bucketDate.add(const Duration(days: 1));
        }
        if (current > longest) longest = current;
      } else {
        current = 0;
        expectedNext = null;
      }
    }

    return longest;
  }

  int _computeMonthAdherence(Map<String, _DayBucket> buckets) {
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    int taken = 0, missed = 0, skipped = 0;

    buckets.forEach((key, bucket) {
      if (key.startsWith(monthPrefix)) {
        taken += bucket.taken;
        missed += bucket.missed;
        skipped += bucket.skipped;
      }
    });

    final total = taken + missed + skipped;
    if (total == 0) return 0;
    return ((taken / total) * 100).round();
  }

  // ============================================================
  // ACHIEVEMENTS COMPUTATION
  // ============================================================

  List<StreakAchievement> _computeAchievements({
    required int currentStreak,
    required int longestStreak,
    required int totalTaken,
  }) {
    final list = <StreakAchievement>[];

    // Streak achievement — tiered.
    if (currentStreak >= 30) {
      list.add(
        StreakAchievement(
          id: 'streak_30',
          type: StreakAchievementType.streak,
          title: '30-Day Streak',
          subtitle: 'A full month of consistency — outstanding! 🔥',
        ),
      );
    } else if (currentStreak >= 14) {
      list.add(
        StreakAchievement(
          id: 'streak_14',
          type: StreakAchievementType.streak,
          title: '14-Day Streak',
          subtitle: 'Two weeks strong — keep it up!',
        ),
      );
    } else if (currentStreak >= 7) {
      list.add(
        StreakAchievement(
          id: 'streak_7',
          type: StreakAchievementType.streak,
          title: '7-Day Streak',
          subtitle: 'A full week of taking meds on time!',
        ),
      );
    } else if (currentStreak >= 3) {
      list.add(
        StreakAchievement(
          id: 'streak_3',
          type: StreakAchievementType.streak,
          title: '3-Day Streak',
          subtitle: 'Building momentum — keep going!',
        ),
      );
    }

    // Perfect Week — any 7-day perfect streak in history.
    if (longestStreak >= 7) {
      list.add(
        StreakAchievement(
          id: 'perfect_week',
          type: StreakAchievementType.perfectWeek,
          title: 'Perfect Week',
          subtitle: '7 days with zero missed doses 🌟',
        ),
      );
    }

    // First Refill / Consistency — total doses taken milestone.
    if (totalTaken >= 30) {
      list.add(
        StreakAchievement(
          id: 'consistency_30',
          type: StreakAchievementType.firstRefill,
          title: 'Consistency Champion',
          subtitle: '30 doses taken — you’re building a habit!',
        ),
      );
    } else if (totalTaken >= 1) {
      list.add(
        StreakAchievement(
          id: 'first_steps',
          type: StreakAchievementType.firstRefill,
          title: 'First Steps',
          subtitle: 'Started your medication journey 💊',
        ),
      );
    }

    return list;
  }

  // ============================================================
  // TREND COMPUTATION
  // ============================================================

  List<StreakTrendPoint> _computeTrendPoints() {
    final rangeDays = _selectedTrendRange == StreakTrendRange.ninetyDays
        ? 90
        : 30;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: rangeDays - 1));

    // Bucket doses by day.
    final Map<String, _DayBucket> dayMap = {};
    for (final dose in _allDoses) {
      if (dose.isPrn) continue;
      final local = dose.scheduledAt.toLocal();
      final key = _dayKey(local);
      dayMap.putIfAbsent(key, () => _DayBucket(date: local));
      switch (dose.status) {
        case DoseStatus.taken:
          dayMap[key]!.taken++;
          break;
        case DoseStatus.skipped:
          dayMap[key]!.skipped++;
          break;
        case DoseStatus.missed:
          dayMap[key]!.missed++;
          break;
        case DoseStatus.pending:
          if (dose.isOverdue) dayMap[key]!.missed++;
          break;
        case DoseStatus.snoozed:
          break;
      }
    }

    // Build one trend point per day in the range.
    final points = <StreakTrendPoint>[];
    for (int i = 0; i < rangeDays; i++) {
      final date = startDate.add(Duration(days: i));
      final key = _dayKey(date);
      final bucket = dayMap[key];

      final total = bucket?.total ?? 0;
      final percent = total == 0 ? 0 : ((bucket!.taken / total) * 100).round();

      points.add(StreakTrendPoint(date: date, percent: percent));
    }

    return points;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

          Expanded(child: _buildBodyContent()),
        ],
      ),

      // Streaks & Stats Home flow ka part hai.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  /// M7: Body content swaps based on loading/error/ready state.
  /// Header always shows.
  Widget _buildBodyContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.calendarMissed,
              ),

              const SizedBox(height: 12),

              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _fetchProfileAndDoses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
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
// DAY BUCKET (helper for streak + trend computation)
// ============================================================

class _DayBucket {
  final DateTime date;
  int taken = 0;
  int missed = 0;
  int skipped = 0;

  _DayBucket({required this.date});

  int get total => taken + missed + skipped;
}

// ============================================================
// TREND CHART
//
// No external chart package required.
// Data points now come from real Firestore doses (M7).
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
