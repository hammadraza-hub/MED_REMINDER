import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The time zone doses are generated in. M22 step 2.
///
/// PDF M6: "Generate dose documents for every schedule type in the profile's
/// time zone". A profile stores its zone as an IANA name ("Asia/Karachi",
/// "America/New_York"). Older profiles stored the phone's abbreviation ("PKT",
/// "EST"), which is not a zone: for those, and for a missing name, the phone's
/// own zone is used, and as the last resort UTC.
class DoseZone {
  DoseZone._();

  static bool _loaded = false;

  /// Loads the time-zone database once (cheap to call again).
  static void ensureData() {
    if (_loaded || tz.timeZoneDatabase.locations.isNotEmpty) {
      _loaded = true;
      return;
    }
    tz_data.initializeTimeZones();
    _loaded = true;
  }

  /// The phone's IANA zone name, or null when it cannot be read.
  static Future<String?> phoneZoneName() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final name = info.identifier;
      return name.isEmpty ? null : name;
    } catch (e) {
      debugPrint('DoseZone: phone zone unreadable (${e.runtimeType})');
      return null;
    }
  }

  /// The phone's IANA zone name for a NEW profile, never empty.
  static Future<String> phoneZoneNameOrUtc() async =>
      (await phoneZoneName()) ?? 'UTC';

  /// [name] when it is a real IANA zone, else the phone's zone, else UTC.
  static Future<tz.Location> forProfile(
    String? name, {
    Future<String?> Function()? phone,
  }) async {
    ensureData();
    final fromProfile = _known(name);
    if (fromProfile != null) return fromProfile;
    String? phoneName;
    try {
      phoneName = await (phone ?? phoneZoneName)();
    } catch (_) {
      phoneName = null; // never throw: UTC is the last resort
    }
    return _known(phoneName) ?? tz.UTC;
  }

  static tz.Location? _known(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return null;
    try {
      return tz.getLocation(n);
    } catch (_) {
      return null; // "PKT", "EST", "garbage": not an IANA name
    }
  }
}
