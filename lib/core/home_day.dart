import 'package:timezone/timezone.dart' as tz;

import 'dose_engine.dart';

/// "Today" for the Home list, in the PROFILE's time zone (doses are generated
/// there since M22; cutting the day by the phone's zone shows a dose on the
/// wrong day when the two zones differ).
class HomeDay {
  const HomeDay({required this.startUtc, required this.endUtc});

  /// The instant today starts / the next day starts (end is exclusive).
  final DateTime startUtc;
  final DateTime endUtc;

  static HomeDay of(tz.Location zone, {DateTime? now}) {
    final today = DoseEngine.todayIn(zone, now: now);
    final tomorrow = DateTime.utc(today.year, today.month, today.day + 1);
    return HomeDay(
      startUtc: DoseEngine.resolveSlot(
        zone,
        today.year,
        today.month,
        today.day,
        0,
        0,
      ),
      endUtc: DoseEngine.resolveSlot(
        zone,
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        0,
        0,
      ),
    );
  }

  /// How long until this day ends (the list must be re-read then). At least a
  /// second, so a timer can never fire in a loop.
  Duration untilEnd({DateTime? now}) {
    final d = endUtc.difference((now ?? DateTime.now()).toUtc());
    return d < const Duration(seconds: 1) ? const Duration(seconds: 1) : d;
  }
}
