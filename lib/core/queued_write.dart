import 'dart:async';

/// What happened to a save. M20 step 4.
enum SaveOutcome {
  /// The server confirmed it.
  saved,

  /// Offline or slow: Firestore kept it on the phone and will send it when
  /// the connection is back.
  queued,
}

/// Runs a Firestore write without leaving the user on a spinner.
///
/// A Firestore write future does not complete while the phone is offline, even
/// though the data is saved locally and will sync later. So we wait [grace];
/// if the server has not answered by then the save is reported as
/// [SaveOutcome.queued] and the screen can say "saved on this phone".
/// A real error (e.g. permission denied) that arrives within [grace] is
/// rethrown.
///
/// Limit: a rule rejection that happens after "queued" cannot be reported
/// here; it only shows up later (M20 step 7 handles that).
Future<SaveOutcome> queuedWrite(
  Future<void> Function() write, {
  Duration grace = const Duration(seconds: 3),
}) async {
  final done = write();
  var stoppedWaiting = false;
  // An error that arrives after we stopped waiting (the server refused a save
  // that had been queued offline) cannot go to the caller any more: it goes
  // to [QueuedWriteErrors.onLate] so the user is told. It must also never
  // crash the zone.
  unawaited(
    done.then<void>(
      (_) {},
      onError: (Object error) {
        if (stoppedWaiting) QueuedWriteErrors.onLate?.call(error);
      },
    ),
  );
  try {
    await done.timeout(grace);
    return SaveOutcome.saved;
  } on TimeoutException {
    stoppedWaiting = true;
    return SaveOutcome.queued;
  }
}

/// Where errors of saves that had already been reported as "queued" end up.
class QueuedWriteErrors {
  QueuedWriteErrors._();

  /// Set in `main()`: shows a notice. Null in tests unless set.
  static void Function(Object error)? onLate;
}

/// Stops a button from starting the same save twice.
class SaveGuard {
  bool _busy = false;
  bool get busy => _busy;

  /// Runs [run] unless one is already running (then returns null).
  Future<T?> run<T>(Future<T> Function() run) async {
    if (_busy) return null;
    _busy = true;
    try {
      return await run();
    } finally {
      _busy = false;
    }
  }
}
