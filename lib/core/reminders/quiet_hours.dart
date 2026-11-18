/// Quiet hours (M8): they only DELAY refill and appointment alerts. The
/// person's own dose reminders never use this class.
class QuietHours {
  const QuietHours({
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
  });

  /// Minutes after local midnight (0..1439).
  factory QuietHours.fromParts({
    required bool enabled,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) => QuietHours(
    enabled: enabled,
    startMinutes: startHour * 60 + startMinute,
    endMinutes: endHour * 60 + endMinute,
  );

  static const QuietHours off = QuietHours(
    enabled: false,
    startMinutes: 0,
    endMinutes: 0,
  );

  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  /// True when the local time of [at] is inside the window. The window may
  /// cross midnight (22:00-07:00); start == end is an empty window.
  bool contains(DateTime at) {
    if (!enabled || startMinutes == endMinutes) return false;
    final l = at.toLocal();
    final m = l.hour * 60 + l.minute;
    return startMinutes < endMinutes
        ? m >= startMinutes && m < endMinutes
        : m >= startMinutes || m < endMinutes;
  }

  /// [at] itself, or the next end of the window when [at] falls inside it.
  DateTime shift(DateTime at) {
    if (!contains(at)) return at;
    final l = at.toLocal();
    final m = l.hour * 60 + l.minute;
    // After midnight inside a crossing window the end is still today.
    final endToday = m < endMinutes;
    final day = endToday ? l.day : l.day + 1;
    return DateTime(l.year, l.month, day, endMinutes ~/ 60, endMinutes % 60);
  }
}
