/// Schedule model — represents a medication's dosing schedule.
///
/// M5 — Medications & Schedules
///
/// Supports all 5 PRD schedule types:
///   1. daily      — Every day at specified times (e.g., 08:00, 20:00)
///   2. weekdays   — Specific days of week (1=Mon, 7=Sun)
///   3. cyclical   — N days on, N days off, starting from cycleStart
///   4. prn        — As needed (no fixed schedule, just instructions)
///   5. taper      — Gradually decreasing dose over multiple steps
///
/// Per the M5 plan, schedule is EMBEDDED in the medication document
/// (not a separate collection). One medication = one schedule.
///
/// Spark / Phase A:
///   • Schedule model fully defined + serializable
///   • All 5 types supported in UI
///   • NO dose generation (M6 trigger required, Blaze plan)
///
/// Blaze / Phase B (deferred):
///   • M6 trigger reads schedule + generates scheduled doses
class Schedule {
  final ScheduleType type;

  /// Times in 24-hour "HH:mm" format (e.g., ["08:00", "20:00"]).
  /// Empty for PRN type.
  final List<String> times;

  /// Weekdays (1=Mon, 7=Sun). Empty for non-weekday types.
  /// E.g., [1, 3, 5] = Mon, Wed, Fri
  final List<int> weekdays;

  /// Days "on" in cyclical schedule (e.g., 21 days on).
  final int? cycleOn;

  /// Days "off" in cyclical schedule (e.g., 7 days off).
  final int? cycleOff;

  /// Start date of cyclical schedule (cycle day 1).
  final DateTime? cycleStart;

  /// Taper steps (for taper type only).
  /// Each step has: days (duration), doseAmount, times.
  final List<TaperStep> taperSteps;

  /// Relation to meals.
  final MealRelation mealRelation;

  /// Schedule start date (when medication becomes active).
  final DateTime startDate;

  /// Schedule end date (nullable — null = ongoing).
  final DateTime? endDate;

  /// Schema version (for future migrations).
  final int version;

  const Schedule({
    required this.type,
    this.times = const [],
    this.weekdays = const [],
    this.cycleOn,
    this.cycleOff,
    this.cycleStart,
    this.taperSteps = const [],
    this.mealRelation = MealRelation.noRelation,
    required this.startDate,
    this.endDate,
    this.version = 1,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      type: ScheduleType.fromString(json['type'] as String? ?? 'daily'),
      times: List<String>.from(json['times'] as List? ?? []),
      weekdays: List<int>.from(json['weekdays'] as List? ?? []),
      cycleOn: json['cycleOn'] as int?,
      cycleOff: json['cycleOff'] as int?,
      cycleStart: _parseDateTime(json['cycleStart']),
      taperSteps: (json['taperSteps'] as List? ?? [])
          .map((e) => TaperStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      mealRelation: MealRelation.fromString(
        json['mealRelation'] as String? ?? 'none',
      ),
      startDate: _parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(json['endDate']),
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type.value,
      'times': times,
      'weekdays': weekdays,
      'mealRelation': mealRelation.value,
      'startDate': startDate.toIso8601String(),
      'version': version,
    };

    if (cycleOn != null) json['cycleOn'] = cycleOn;
    if (cycleOff != null) json['cycleOff'] = cycleOff;
    if (cycleStart != null) {
      json['cycleStart'] = cycleStart!.toIso8601String();
    }
    if (endDate != null) {
      json['endDate'] = endDate!.toIso8601String();
    }
    if (taperSteps.isNotEmpty) {
      json['taperSteps'] = taperSteps.map((s) => s.toJson()).toList();
    }

    return json;
  }

  Schedule copyWith({
    ScheduleType? type,
    List<String>? times,
    List<int>? weekdays,
    int? cycleOn,
    int? cycleOff,
    DateTime? cycleStart,
    List<TaperStep>? taperSteps,
    MealRelation? mealRelation,
    DateTime? startDate,
    DateTime? endDate,
    int? version,
  }) {
    return Schedule(
      type: type ?? this.type,
      times: times ?? this.times,
      weekdays: weekdays ?? this.weekdays,
      cycleOn: cycleOn ?? this.cycleOn,
      cycleOff: cycleOff ?? this.cycleOff,
      cycleStart: cycleStart ?? this.cycleStart,
      taperSteps: taperSteps ?? this.taperSteps,
      mealRelation: mealRelation ?? this.mealRelation,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      version: version ?? this.version,
    );
  }

  /// Helper: validate schedule shape (matches firestore.rules logic)
  /// Returns null if valid, error message if invalid.
  String? validate() {
    // PRN type: no times required
    if (type == ScheduleType.prn) {
      return null;
    }

    // All other types require at least one time
    if (times.isEmpty) {
      return 'Schedule must have at least one time (HH:mm)';
    }

    // Weekdays type: must have at least one weekday
    if (type == ScheduleType.weekdays && weekdays.isEmpty) {
      return 'Weekdays schedule must specify at least one day';
    }

    // Cyclical type: must have cycleOn + cycleOff + cycleStart
    if (type == ScheduleType.cyclical) {
      if (cycleOn == null || cycleOff == null || cycleStart == null) {
        return 'Cyclical schedule requires cycleOn, cycleOff, and cycleStart';
      }
      if (cycleOn! <= 0 || cycleOff! <= 0) {
        return 'cycleOn and cycleOff must be positive integers';
      }
    }

    // Taper type: must have at least one taper step
    if (type == ScheduleType.taper) {
      if (taperSteps.isEmpty) {
        return 'Taper schedule must have at least one step';
      }
      for (final step in taperSteps) {
        if (step.days <= 0) {
          return 'Each taper step must have days > 0';
        }
        if (step.doseAmount <= 0) {
          return 'Each taper step must have doseAmount > 0';
        }
        if (step.times.isEmpty) {
          return 'Each taper step must have at least one time';
        }
      }
    }

    // Validate times format (HH:mm, 24-hour)
    for (final time in times) {
      if (!RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(time)) {
        return 'Invalid time format: $time. Expected HH:mm (24-hour)';
      }
    }

    // Validate weekdays range (1-7)
    for (final day in weekdays) {
      if (day < 1 || day > 7) {
        return 'Invalid weekday: $day. Must be 1 (Mon) to 7 (Sun)';
      }
    }

    // EndDate >= startDate
    if (endDate != null && endDate!.isBefore(startDate)) {
      return 'endDate must be on or after startDate';
    }

    return null; // Valid
  }

  /// Helper: human-readable description of the schedule
  String get description {
    switch (type) {
      case ScheduleType.daily:
        final timeStr = times.join(', ');
        return 'Daily at $timeStr';
      case ScheduleType.weekdays:
        final dayNames = weekdays.map(_weekdayName).join(', ');
        final timeStr = times.join(', ');
        return 'On $dayNames at $timeStr';
      case ScheduleType.cyclical:
        return '$cycleOn days on, $cycleOff days off (starting ${cycleStart?.toIso8601String().split('T').first ?? '...'})';
      case ScheduleType.prn:
        return 'As needed (PRN)';
      case ScheduleType.taper:
        return 'Tapering schedule (${taperSteps.length} steps)';
    }
  }

  static String _weekdayName(int day) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day];
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class TaperStep {
  /// Number of days this step lasts.
  final int days;

  /// Dose amount for this step (e.g., 5.0, 2.5).
  final double doseAmount;

  /// Times for this step (e.g., ["08:00"]).
  final List<String> times;

  const TaperStep({
    required this.days,
    required this.doseAmount,
    required this.times,
  });

  factory TaperStep.fromJson(Map<String, dynamic> json) {
    return TaperStep(
      days: (json['days'] as num?)?.toInt() ?? 0,
      doseAmount: (json['doseAmount'] as num?)?.toDouble() ?? 0.0,
      times: List<String>.from(json['times'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'days': days, 'doseAmount': doseAmount, 'times': times};
  }

  TaperStep copyWith({int? days, double? doseAmount, List<String>? times}) {
    return TaperStep(
      days: days ?? this.days,
      doseAmount: doseAmount ?? this.doseAmount,
      times: times ?? this.times,
    );
  }

  @override
  String toString() =>
      'TaperStep(days: $days, doseAmount: $doseAmount, times: $times)';
}

/// Schedule type enum — corresponds to PRD's 5 schedule types.
enum ScheduleType {
  daily,
  weekdays,
  cyclical,
  prn,
  taper;

  String get value => name;

  static ScheduleType fromString(String value) {
    return ScheduleType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ScheduleType.daily,
    );
  }

  /// Human-readable label for UI
  String get label {
    switch (this) {
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekdays:
        return 'Specific Days';
      case ScheduleType.cyclical:
        return 'Cyclical (On/Off)';
      case ScheduleType.prn:
        return 'As Needed (PRN)';
      case ScheduleType.taper:
        return 'Tapering';
    }
  }

  /// Brief description for picker UI
  String get description {
    switch (this) {
      case ScheduleType.daily:
        return 'Every day at fixed times';
      case ScheduleType.weekdays:
        return 'Specific days of the week';
      case ScheduleType.cyclical:
        return 'N days on, N days off';
      case ScheduleType.prn:
        return 'Take only when needed';
      case ScheduleType.taper:
        return 'Gradually decrease dose';
    }
  }
}

/// Meal relation enum — when to take medication relative to meals.
enum MealRelation {
  beforeMeal,
  afterMeal,
  withMeal,
  noRelation;

  String get value {
    switch (this) {
      case MealRelation.beforeMeal:
        return 'before';
      case MealRelation.afterMeal:
        return 'after';
      case MealRelation.withMeal:
        return 'with';
      case MealRelation.noRelation:
        return 'none';
    }
  }

  static MealRelation fromString(String value) {
    switch (value.toLowerCase()) {
      case 'before':
        return MealRelation.beforeMeal;
      case 'after':
        return MealRelation.afterMeal;
      case 'with':
        return MealRelation.withMeal;
      default:
        return MealRelation.noRelation;
    }
  }

  String get label {
    switch (this) {
      case MealRelation.beforeMeal:
        return 'Before meal';
      case MealRelation.afterMeal:
        return 'After meal';
      case MealRelation.withMeal:
        return 'With meal';
      case MealRelation.noRelation:
        return 'No specific relation';
    }
  }
}
