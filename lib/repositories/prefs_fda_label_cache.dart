import 'package:shared_preferences/shared_preferences.dart';

import '../core/ai/fda_label_client.dart';

/// Keeps FDA labels on the phone (shared_preferences) so they work offline and
/// the free openFDA limit (1000 requests a day per IP) is not used up.
class PrefsFdaLabelCache implements FdaLabelCache {
  static const String _prefix = 'fda_label_';

  /// Old entries are dropped when more than this many are stored.
  static const int maxEntries = 60;

  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$key');
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    if (keys.length >= maxEntries && !keys.contains('$_prefix$key')) {
      keys.sort();
      for (final k in keys.take(keys.length - maxEntries + 1)) {
        await prefs.remove(k);
      }
    }
    await prefs.setString('$_prefix$key', value);
  }
}
