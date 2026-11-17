/// How long ago a post was written, as a unit and a number, so the screen can
/// put it in the user's language. M19 step 3.
enum CommunityAgoUnit { justNow, minutes, hours, days, date }

class CommunityAgo {
  const CommunityAgo(this.unit, [this.value = 0]);

  final CommunityAgoUnit unit;
  final int value;

  @override
  bool operator ==(Object other) =>
      other is CommunityAgo && other.unit == unit && other.value == value;

  @override
  int get hashCode => Object.hash(unit, value);

  @override
  String toString() => 'CommunityAgo($unit, $value)';
}

class CommunityTime {
  CommunityTime._();

  /// Less than a minute (or a time slightly in the future, from a slow phone
  /// clock) = just now; then minutes, hours, days up to 6 days; after that a
  /// date.
  static CommunityAgo ago(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inMinutes < 1) return const CommunityAgo(CommunityAgoUnit.justNow);
    if (diff.inMinutes < 60) {
      return CommunityAgo(CommunityAgoUnit.minutes, diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return CommunityAgo(CommunityAgoUnit.hours, diff.inHours);
    }
    if (diff.inDays < 7) {
      return CommunityAgo(CommunityAgoUnit.days, diff.inDays);
    }
    return const CommunityAgo(CommunityAgoUnit.date);
  }
}
