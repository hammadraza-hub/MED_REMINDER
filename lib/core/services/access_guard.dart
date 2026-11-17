import 'dart:async';

import 'package:flutter/foundation.dart';

import '../app_exception.dart';

/// What the guard needs from the app. Replaced in tests.
class AccessGuardPorts {
  const AccessGuardPorts({
    required this.currentProfileId,
    required this.canRead,
    required this.ownProfileId,
    required this.select,
    required this.isOffline,
    required this.notice,
  });

  /// The profile on screen now.
  final String? Function() currentProfileId;

  /// True when the profile can still be read. Throw when the answer is
  /// unknown (e.g. no network): the guard then does nothing.
  final Future<bool> Function(String profileId) canRead;

  /// The user's own ("self") profile, or null when it cannot be found.
  final Future<String?> Function() ownProfileId;

  /// Makes [profileId] the profile on screen.
  final Future<void> Function(String profileId) select;
  final bool Function() isOffline;
  final void Function() notice;
}

/// A screen got "permission denied" for the profile it shows. Maybe the owner
/// removed this user from it. M20 step 7.
///
/// The guard asks the server whether the profile is still readable. If it is
/// not, the user's own profile is shown instead and a notice says why. Any
/// other answer (still readable, no network, unknown) changes nothing, so a
/// single odd error never throws the user out of a profile they may use.
class AccessGuard {
  AccessGuard(this._ports, {this.pause = const Duration(seconds: 15)});

  static AccessGuard? instance;

  /// Call when a read or write of the profile on screen was refused.
  static void reportPermissionDenied() {
    final guard = instance;
    if (guard != null) unawaited(guard.check());
  }

  /// Convenience for screens: reports [error] when it is a refusal.
  static void reportIfDenied(Object error) {
    if (AppException.fromAny(error).type == AppExceptionType.permission) {
      reportPermissionDenied();
    }
  }

  final AccessGuardPorts _ports;

  /// A refused screen often fires several errors at once; one check is enough.
  final Duration pause;

  bool _checking = false;
  DateTime? _lastCheck;

  Future<void> check({DateTime? now}) async {
    if (_checking) return;
    final at = now ?? DateTime.now();
    final last = _lastCheck;
    if (last != null && at.difference(last) < pause) return;
    if (_ports.isOffline()) return;

    final current = _ports.currentProfileId();
    if (current == null || current.isEmpty) return;

    _checking = true;
    _lastCheck = at;
    try {
      bool readable;
      try {
        readable = await _ports.canRead(current);
      } catch (_) {
        return; // unknown: leave everything as it is
      }
      if (readable) return;

      final own = await _ports.ownProfileId();
      if (own == null || own.isEmpty || own == current) return;
      await _ports.select(own);
      _ports.notice();
    } catch (e) {
      debugPrint('AccessGuard: check failed — $e');
    } finally {
      _checking = false;
    }
  }
}
