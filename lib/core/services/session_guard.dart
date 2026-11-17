import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notices a session that ended by itself. M20 step 7.
///
/// The signed-in state is watched for the whole life of the app. A change
/// from signed in to signed out that the user did not ask for (the account
/// was deleted or disabled, the password changed, the token was revoked) means
/// the session is lost: [onLost] runs once, and the app sends the user back to
/// sign in with a short explanation.
///
/// Going offline never ends a session: Firebase only signs the user out when
/// the server says so, so there is nothing to do while the phone is offline.
class SessionGuard {
  SessionGuard({
    required this.signedIn,
    required this.onLost,
    DateTime Function()? now,
    this.expectationLife = const Duration(seconds: 10),
  }) : _now = now ?? DateTime.now;

  /// Wired in `main()`; tests build their own.
  static SessionGuard? instance;

  /// Tells the guard that the next sign-out is the user's own (sign out
  /// button, account deletion, a login that is turned away). Safe to call when
  /// no guard is running.
  static void expectSignOut() => instance?._expect();

  /// True while a user is signed in (from `authStateChanges`).
  final Stream<bool> signedIn;
  final Future<void> Function() onLost;
  final Duration expectationLife;
  final DateTime Function() _now;

  StreamSubscription<bool>? _sub;
  bool _wasSignedIn = false;
  DateTime? _expectedAt;

  void _expect() => _expectedAt = _now();

  bool get _isExpected {
    final at = _expectedAt;
    return at != null && _now().difference(at) <= expectationLife;
  }

  void start() {
    if (_sub != null) return;
    _sub = signedIn.listen((signedIn) {
      if (signedIn) {
        _wasSignedIn = true;
        return;
      }
      final lost = _wasSignedIn && !_isExpected;
      _wasSignedIn = false;
      _expectedAt = null;
      if (lost) {
        unawaited(
          onLost().catchError(
            (Object e) => debugPrint('SessionGuard: onLost failed — $e'),
          ),
        );
      }
    }, onError: (Object e) => debugPrint('SessionGuard: stream error — $e'));
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
