import 'dart:async';

import 'package:flutter/foundation.dart';

import 'services/connectivity_service.dart';

/// One piece of startup work that needs the network. M20 step 3.
class StartupTask {
  const StartupTask(
    this.name,
    this.run, {
    this.limit = const Duration(seconds: 4),
    this.beforeApp = true,
  });

  /// For the log.
  final String name;

  /// The work. It may be slow or never finish (a Firestore write does not
  /// finish while the phone is offline); the caller never waits longer than
  /// [limit].
  final Future<void> Function() run;

  /// The most the app waits for it.
  final Duration limit;

  /// True: runs (bounded) before the first screen. False: starts after the
  /// first screen is up and is never waited for.
  final bool beforeApp;
}

/// Keeps network work from blocking the first screen.
///
/// Before this, `main()` awaited Firestore reads and writes before `runApp`,
/// so an unreachable Firestore left the app on the native splash for ever.
/// Now:
///  * while the phone is offline the network tasks are skipped at once and
///    remembered;
///  * online, each task gets a short limit; a task that is too slow, or fails,
///    is remembered too;
///  * remembered tasks run again when the phone comes back online (and, for
///    slow or failing ones, a few more times with growing pauses).
///
/// Everything local (preferences, reminders, app lock) is not a [StartupTask]:
/// it still runs in `main()` before the app opens.
class AppStartup {
  AppStartup(
    this._connectivity, {
    required this.tasks,
    this.catchUpLimit = const Duration(seconds: 30),
    this.retryDelays = const [
      Duration(seconds: 30),
      Duration(seconds: 60),
      Duration(seconds: 120),
    ],
    void Function(String message)? log,
  }) : _log = log ?? ((m) => debugPrint('AppStartup: $m'));

  final ConnectivityService _connectivity;

  /// All the network tasks.
  final List<StartupTask> tasks;
  final void Function(String) _log;

  /// How long a catch-up run may take per task (nobody is waiting for it).
  final Duration catchUpLimit;

  /// Pauses before the retries of tasks that were online but too slow.
  final List<Duration> retryDelays;

  final List<StartupTask> _pending = [];
  Timer? _retryTimer;
  int _retries = 0;
  bool _catchingUp = false;
  bool _listening = false;
  bool _disposed = false;

  /// Names of the tasks that have not finished yet.
  List<String> get pendingNames => [for (final t in _pending) t.name];

  /// Runs `run` and gives up after [limit]. True = finished without error.
  /// A task that outlives its limit keeps running in the background.
  static Future<bool> bounded(
    String name,
    Future<void> Function() run,
    Duration limit, {
    void Function(String message)? log,
  }) async {
    final say = log ?? ((m) => debugPrint('AppStartup: $m'));
    try {
      await run().timeout(limit);
      return true;
    } on TimeoutException {
      say('$name: no answer in ${limit.inSeconds}s, going on without it');
      return false;
    } catch (e) {
      say('$name: failed — $e');
      return false;
    }
  }

  /// The tasks that must be done (or given up on) before the first screen.
  /// Offline: nothing is attempted, so the first screen is not delayed.
  Future<void> runBeforeApp() async {
    final mine = tasks.where((t) => t.beforeApp).toList();
    if (_connectivity.isOffline) {
      _log('offline: skipping ${mine.map((t) => t.name).join(', ')}');
      _pending.addAll(mine);
      return;
    }
    await Future.wait([
      for (final t in mine)
        () async {
          final ok = await bounded(t.name, t.run, t.limit, log: _log);
          if (!ok) _pending.add(t);
        }(),
    ]);
    _scheduleRetry();
  }

  /// Starts the tasks that run after the first screen. Never waited for.
  void runAfterApp() {
    final mine = tasks.where((t) => !t.beforeApp).toList();
    if (_connectivity.isOffline) {
      _pending.addAll(mine);
      return;
    }
    for (final t in mine) {
      unawaited(() async {
        final ok = await bounded(t.name, t.run, t.limit, log: _log);
        if (!ok && !_disposed) {
          _pending.add(t);
          _scheduleRetry();
        }
      }());
    }
  }

  /// Runs what was skipped or failed when the phone is back online.
  void catchUpWhenOnline() {
    if (_listening) return;
    _listening = true;
    _connectivity.status.addListener(_statusChanged);
    // The state may already be online with leftovers from slow tasks.
    _scheduleRetry();
  }

  void _statusChanged() {
    if (_connectivity.status.value == ConnectionStatus.online) {
      _retryTimer?.cancel();
      unawaited(_runPending());
    }
  }

  void _scheduleRetry() {
    if (_disposed || _pending.isEmpty || _retryTimer?.isActive == true) return;
    if (_retries >= retryDelays.length) return;
    _retryTimer = Timer(retryDelays[_retries], () {
      _retries++;
      if (!_connectivity.isOffline) unawaited(_runPending());
    });
  }

  Future<void> _runPending() async {
    if (_catchingUp || _pending.isEmpty || _disposed) return;
    _catchingUp = true;
    try {
      final todo = List<StartupTask>.of(_pending);
      _pending.clear();
      _log('back online: running ${todo.map((t) => t.name).join(', ')}');
      await Future.wait([
        for (final t in todo)
          () async {
            final ok = await bounded(t.name, t.run, catchUpLimit, log: _log);
            if (!ok) _pending.add(t);
          }(),
      ]);
    } finally {
      _catchingUp = false;
    }
    if (_pending.isNotEmpty) {
      if (!_connectivity.isOffline) _scheduleRetry();
    } else {
      _retries = 0;
    }
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    if (_listening) _connectivity.status.removeListener(_statusChanged);
    _listening = false;
  }
}
