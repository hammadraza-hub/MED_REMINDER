/// Which day a note's time falls on, relative to "now". M16 step 6.
enum NoteDay { today, yesterday, other }

class NoteDayResolver {
  NoteDayResolver._();

  /// Calendar days in local time (not "24 hours ago"), so a note written at
  /// 11 pm is still "Yesterday" at 1 am, and the 1st of a month works.
  static NoteDay of(DateTime date, {DateTime? now}) {
    final n = (now ?? DateTime.now()).toLocal();
    final d = date.toLocal();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return NoteDay.today;
    if (diff == 1) return NoteDay.yesterday;
    return NoteDay.other;
  }
}
