import 'dart:math' as math;

// ============================================================
// STREAKS & STATS DATA
//
// UI hardcoded statistics use nahi karti.
// Abhi deterministic dummy adherence history generate hoti hai.
//
// TODO Backend:
// Firebase/Firestore connect hone par current signed-in user's
// completed dose history ko selected date range mein ONE query
// se fetch karna hai.
//
// Suggested fields:
// • userId
// • medicationId
// • scheduledAt
// • completedAt
// • status: taken / missed / skipped
//
// Phir isi calculation layer ko backend records diye ja sakte hain.
// ============================================================

enum StreakDoseStatus { taken, missed, skipped }

enum StreakTrendRange { thirtyDays, ninetyDays }

// ============================================================
// DAILY HISTORY
// ============================================================

class StreakDayRecord {
  const StreakDayRecord({
    required this.date,
    required this.taken,
    required this.missed,
    required this.skipped,
  });

  final DateTime date;
  final int taken;
  final int missed;
  final int skipped;

  int get total => taken + missed + skipped;

  double get adherence {
    if (total == 0) {
      return 0;
    }

    return taken / total;
  }

  int get adherencePercent => (adherence * 100).round();

  /// A streak day means every relevant completed dose was taken.
  bool get isPerfectDay {
    return total > 0 && missed == 0 && skipped == 0 && taken > 0;
  }
}

// ============================================================
// TREND
// ============================================================

class StreakTrendPoint {
  const StreakTrendPoint({required this.date, required this.percent});

  final DateTime date;
  final int percent;
}

// ============================================================
// ACHIEVEMENTS
// ============================================================

class StreakAchievement {
  const StreakAchievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  final String id;
  final String title;
  final String subtitle;
  final StreakAchievementType type;
}

enum StreakAchievementType { streak, perfectWeek, firstRefill }

// ============================================================
// SUMMARY
// ============================================================

class StreakStatsSummary {
  const StreakStatsSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.monthAdherencePercent,
    required this.goalDays,
    required this.achievements,
  });

  final int currentStreak;
  final int longestStreak;
  final int monthAdherencePercent;
  final int goalDays;

  final List<StreakAchievement> achievements;

  double get goalProgress {
    if (goalDays <= 0) {
      return 0;
    }

    return (currentStreak / goalDays).clamp(0.0, 1.0);
  }

  int get daysUntilGoal {
    return math.max(0, goalDays - currentStreak);
  }
}

// ============================================================
// DATA PROVIDER / CALCULATION LAYER
// ============================================================

class StreaksStatsData {
  StreaksStatsData._();

  static const int streakGoalDays = 30;

  // ============================================================
  // DATE HELPERS
  // ============================================================

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  // ============================================================
  // DUMMY HISTORY
  // ============================================================

  static List<StreakDayRecord> recordsForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = dateOnly(startDate);
    final end = dateOnly(endDate);

    if (start.isAfter(end)) {
      return const [];
    }

    final records = <StreakDayRecord>[];

    final today = dateOnly(DateTime.now());

    var cursor = start;

    while (!cursor.isAfter(end)) {
      // Future dates adherence history mein include nahi hongi.
      if (cursor.isAfter(today)) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      final differenceFromToday = today.difference(cursor).inDays;

      int taken;
      int missed;
      int skipped;

      // --------------------------------------------------------
      // Dummy pattern:
      // Recent consecutive days ko perfect rakha gaya hai
      // taa-ke Current Streak visible ho.
      //
      // TODO Backend:
      // Ye complete block Firestore dose records se replace hoga.
      // --------------------------------------------------------
      if (differenceFromToday <= 11) {
        taken = 3;
        missed = 0;
        skipped = 0;
      } else if (differenceFromToday % 13 == 0) {
        taken = 2;
        missed = 1;
        skipped = 0;
      } else if (differenceFromToday % 17 == 0) {
        taken = 2;
        missed = 0;
        skipped = 1;
      } else if (differenceFromToday >= 18 && differenceFromToday <= 45) {
        taken = 3;
        missed = 0;
        skipped = 0;
      } else if (differenceFromToday % 8 == 0) {
        taken = 2;
        missed = 1;
        skipped = 0;
      } else {
        taken = 3;
        missed = 0;
        skipped = 0;
      }

      records.add(
        StreakDayRecord(
          date: cursor,
          taken: taken,
          missed: missed,
          skipped: skipped,
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return records;
  }

  // ============================================================
  // FULL SUMMARY
  // ============================================================

  static StreakStatsSummary summary({DateTime? endDate}) {
    final end = dateOnly(endDate ?? DateTime.now());

    // Enough history to calculate longest streak.
    final historyStart = end.subtract(const Duration(days: 364));

    final records = recordsForRange(startDate: historyStart, endDate: end);

    final current = currentStreak(records, endDate: end);

    final longest = longestStreak(records);

    final monthStart = DateTime(end.year, end.month, 1);

    final monthRecords = records.where((record) {
      return !record.date.isBefore(monthStart) && !record.date.isAfter(end);
    }).toList();

    final monthPercent = adherencePercent(monthRecords);

    return StreakStatsSummary(
      currentStreak: current,
      longestStreak: longest,
      monthAdherencePercent: monthPercent,
      goalDays: streakGoalDays,
      achievements: achievements(
        currentStreak: current,
        longestStreak: longest,
        endDate: end,
      ),
    );
  }

  // ============================================================
  // CURRENT STREAK
  // ============================================================

  static int currentStreak(
    List<StreakDayRecord> records, {
    required DateTime endDate,
  }) {
    if (records.isEmpty) {
      return 0;
    }

    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));

    final end = dateOnly(endDate);

    var streak = 0;
    var expectedDate = end;

    for (final record in sorted) {
      if (record.date.isAfter(expectedDate)) {
        continue;
      }

      if (!_isSameDate(record.date, expectedDate)) {
        break;
      }

      if (!record.isPerfectDay) {
        break;
      }

      streak++;

      expectedDate = expectedDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // ============================================================
  // LONGEST STREAK
  // ============================================================

  static int longestStreak(List<StreakDayRecord> records) {
    if (records.isEmpty) {
      return 0;
    }

    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));

    var longest = 0;
    var running = 0;

    DateTime? previousDate;

    for (final record in sorted) {
      final continuous =
          previousDate == null ||
          record.date.difference(previousDate).inDays == 1;

      if (!continuous) {
        running = 0;
      }

      if (record.isPerfectDay) {
        running++;
        longest = math.max(longest, running);
      } else {
        running = 0;
      }

      previousDate = record.date;
    }

    return longest;
  }

  // ============================================================
  // ADHERENCE
  // ============================================================

  static int adherencePercent(List<StreakDayRecord> records) {
    var taken = 0;
    var total = 0;

    for (final record in records) {
      taken += record.taken;
      total += record.total;
    }

    if (total == 0) {
      return 0;
    }

    return ((taken / total) * 100).round();
  }

  // ============================================================
  // TREND
  // ============================================================

  static List<StreakTrendPoint> trend({
    required StreakTrendRange range,
    DateTime? endDate,
  }) {
    final end = dateOnly(endDate ?? DateTime.now());

    final days = range == StreakTrendRange.thirtyDays ? 30 : 90;

    final start = end.subtract(Duration(days: days - 1));

    final records = recordsForRange(startDate: start, endDate: end);

    if (records.isEmpty) {
      return const [];
    }

    // We aggregate points so the graph remains clean.
    final bucketSize = range == StreakTrendRange.thirtyDays ? 5 : 15;

    final points = <StreakTrendPoint>[];

    for (var i = 0; i < records.length; i += bucketSize) {
      final bucketEnd = math.min(i + bucketSize, records.length);

      final bucket = records.sublist(i, bucketEnd);

      points.add(
        StreakTrendPoint(
          date: bucket.last.date,
          percent: adherencePercent(bucket),
        ),
      );
    }

    return points;
  }

  // ============================================================
  // ACHIEVEMENTS
  // ============================================================

  static List<StreakAchievement> achievements({
    required int currentStreak,
    required int longestStreak,
    required DateTime endDate,
  }) {
    final result = <StreakAchievement>[];

    if (currentStreak >= 10) {
      result.add(
        const StreakAchievement(
          id: '10_day_streak',
          title: '10 Day Streak! 🔥',
          subtitle: 'Consistency achievement unlocked',
          type: StreakAchievementType.streak,
        ),
      );
    }

    if (longestStreak >= 7) {
      result.add(
        const StreakAchievement(
          id: 'perfect_week',
          title: 'Perfect Week',
          subtitle: 'All doses taken for 7 days',
          type: StreakAchievementType.perfectWeek,
        ),
      );
    }

    // TODO Backend:
    // Medication refill history se actual first refill event/date
    // read karke achievement unlock karni hai.
    result.add(
      StreakAchievement(
        id: 'first_refill',
        title: 'First Refill Logged',
        subtitle: 'Achievement recorded ${_shortDate(endDate)}',
        type: StreakAchievementType.firstRefill,
      ),
    );

    return result;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String _shortDate(DateTime date) {
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
