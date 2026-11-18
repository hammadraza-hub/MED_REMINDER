import 'package:shared_preferences/shared_preferences.dart';

/// The first-time setup of a NEW account: health profile -> notifications ->
/// family. It is marked pending when the account is created and cleared when
/// the person reaches the end of the flow, so it also runs for someone who
/// verifies the email later and only then signs in for the first time, and it
/// runs again if they quit half way. Existing accounts have no mark, so they
/// are never sent through it.
///
/// Stored on the phone (per uid): the flow is for the device where the account
/// was created.
class SetupFlow {
  SetupFlow._();

  static String _key(String uid) => 'setup_pending_$uid';

  static Future<void> markPending(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(uid), true);
    } catch (_) {
      // Without the mark the person simply goes to Home.
    }
  }

  static Future<bool> isPending(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(uid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }
}
