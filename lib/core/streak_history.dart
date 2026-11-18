import 'package:timezone/timezone.dart' as tz;

import '../models/dose.dart';
import 'dose_engine.dart';
import 'streak_calculator.dart';

/// Reads the doses of the PAST days once and keeps them, so the streak on Home
/// and the Streaks screen cost no Firestore reads when today's doses change or
/// the screen is opened again.
///
/// Before: every taken / skipped dose re-read 60 days (Home), and every opening
/// of the Streaks screen re-read 90 days, in the PHONE's time zone. Now:
///  * the past 89 days are read once per profile and per day (a new date throws
///    the history away); Home and the Streaks screen share it
///    ([StreakHistoryRegistry]);
///  * today's doses come from the caller (Home's live list), with no extra read;
///  * only when the streak runs back to the oldest day loaded, ONE more read
///    fetches the 120 days before it (a long streak is not capped);
///  * a change to a PAST dose (for example marked taken from the calendar)
///    makes the history be read again ([noteDoseChange]).
class StreakHistory {
  StreakHistory({required this.zone, required this.loader});

  final tz.Location zone;

  /// Reads the doses whose time is in [startUtc, endUtc). Replaceable, so a
  /// screen that finds the history already there can use its own data source.
  Future<List<Dose>> Function(DateTime startUtc, DateTime endUtc) loader;

  /// Days read the first time (the past days before today): with today that
  /// is the 90 days the Streaks screen shows.
  static const int firstWindowDays = 89;

  /// Days read once more when the streak reaches the start of the window.
  static const int extraWindowDays = 120;

  List<Dose> _past = const [];
  DateTime? _loadedFor; // the date (in the zone) the history was read on
  DateTime? _oldest; // first date covered
  bool _extended = false;
  Future<void>? _loading;

  /// How many reads (calls of [loader]) were made. Tests use it.
  int loads = 0;

  /// The doses of the past days that are loaded (oldest first).
  List<Dose> get past => _past;

  DateTime _date(DateTime utcDate, int addDays) =>
      DateTime.utc(utcDate.year, utcDate.month, utcDate.day + addDays);

  DateTime _startOf(DateTime date) =>
      DoseEngine.resolveSlot(zone, date.year, date.month, date.day, 0, 0);

  Future<List<Dose>> _read(DateTime fromDate, DateTime beforeDate) {
    loads++;
    return loader(_startOf(fromDate), _startOf(beforeDate));
  }

  /// Makes sure the history of today's date is loaded (one read, or none).
  Future<void> ensureLoaded({DateTime? now}) async {
    final today = DoseEngine.todayIn(zone, now: now ?? DateTime.now());
    if (_loadedFor != today) {
      await (_loading ??= _loadFirst(today)
          .whenComplete(() => _loading = null));
    }
  }

  /// The full streak result from the cached past plus [todayDoses].
  Future<StreakResult> result(
    Iterable<Dose> todayDoses, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    await ensureLoaded(now: at);

    var r = _compute(todayDoses, at);
    if (_runReachesWindowStart(r) && !_extended) {
      await (_loading ??= _loadMore().whenComplete(() => _loading = null));
      r = _compute(todayDoses, at);
    }
    return r;
  }

  /// The current streak, from the cached past plus [todayDoses].
  Future<int> current(Iterable<Dose> todayDoses, {DateTime? now}) async =>
      (await result(todayDoses, now: now)).current;

  /// A dose was changed. If it belongs to a day BEFORE today, the cached past
  /// is out of date: forget it, so the next call reads it again. Today's
  /// doses are not cached, so changing one costs nothing. [doseId] is
  /// `{medId}_{yyyyMMddHHmm}`; as-needed doses (`_prn_`) never count.
  void noteDoseChange(String doseId, {DateTime? now}) {
    final m = RegExp(r'_(\d{4})(\d{2})(\d{2})\d{4}$').firstMatch(doseId);
    if (m == null || doseId.contains('_prn_')) return;
    final day = DateTime.utc(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
    final today = DoseEngine.todayIn(zone, now: now ?? DateTime.now());
    if (day.isBefore(today)) _loadedFor = null;
  }

  /// The streak runs back to (about) the first day loaded, so it may continue
  /// before it. A new account, whose data starts later, does not qualify.
  bool _runReachesWindowStart(StreakResult r) {
    final oldest = _oldest;
    final first = r.oldestDay;
    if (!r.reachedStart || oldest == null || first == null) return false;
    return first.difference(oldest).inDays <= 7;
  }

  StreakResult _compute(Iterable<Dose> todayDoses, DateTime at) =>
      StreakCalculator.compute([..._past, ...todayDoses], now: at, zone: zone);

  Future<void> _loadFirst(DateTime today) async {
    final from = _date(today, -firstWindowDays);
    final past = await _read(from, today); // today itself comes from the caller
    _past = past;
    _oldest = from;
    _extended = false;
    _loadedFor = today; // set only after a successful read: a failure retries
  }

  Future<void> _loadMore() async {
    final oldest = _oldest;
    if (oldest == null) return;
    final from = _date(oldest, -extraWindowDays);
    final older = await _read(from, oldest);
    _past = [...older, ..._past];
    _oldest = from;
    _extended = true;
  }
}

/// One [StreakHistory] per profile, shared by every screen that shows a streak.
class StreakHistoryRegistry {
  StreakHistoryRegistry._();

  static final StreakHistoryRegistry instance = StreakHistoryRegistry._();

  final Map<String, StreakHistory> _byProfile = {};

  /// The history of [profileId]. A different zone (the profile's zone was
  /// changed) starts a new one. The caller's [loader] is used from now on.
  StreakHistory forProfile(
    String profileId,
    tz.Location zone,
    Future<List<Dose>> Function(DateTime startUtc, DateTime endUtc) loader,
  ) {
    final existing = _byProfile[profileId];
    if (existing != null && existing.zone.name == zone.name) {
      existing.loader = loader;
      return existing;
    }
    return _byProfile[profileId] = StreakHistory(zone: zone, loader: loader);
  }

  /// Called after a dose changed (see [StreakHistory.noteDoseChange]).
  void noteDoseChange(String profileId, String doseId) =>
      _byProfile[profileId]?.noteDoseChange(doseId);

  /// Forget everything (sign-out, tests).
  void clear() => _byProfile.clear();
}
