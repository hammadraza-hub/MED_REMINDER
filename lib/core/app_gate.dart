/// ============================================================
/// APP GATE — M13
///
/// Pure logic deciding whether the app may be used, based on
/// Remote Config values. No Flutter / Firebase imports so it is
/// trivially unit-testable.
///
///   - maintenance_mode == true            -> maintenance
///   - installed version < min_app_version -> updateRequired
///   - otherwise                           -> ok
/// ============================================================
enum AppGateStatus { ok, maintenance, updateRequired }

class AppGate {
  AppGate._();

  /// Compares two dotted versions ("1.2.10" vs "1.2.9").
  /// Ignores any build suffix ("1.2.3+4") and pre-release tag
  /// ("1.2.3-beta"). Missing parts count as 0. Non-numeric parts
  /// count as 0 so a malformed remote value can never lock users out
  /// with an exception.
  ///
  /// Returns <0 if [a] < [b], 0 if equal, >0 if [a] > [b].
  static int compareVersions(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }

  static List<int> _parts(String v) {
    final core = v.trim().split('+').first.split('-').first;
    if (core.isEmpty) return const [0];
    return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  static AppGateStatus evaluate({
    required String currentVersion,
    required String minVersion,
    required bool maintenanceMode,
  }) {
    if (maintenanceMode) return AppGateStatus.maintenance;
    if (compareVersions(currentVersion, minVersion) < 0) {
      return AppGateStatus.updateRequired;
    }
    return AppGateStatus.ok;
  }
}
