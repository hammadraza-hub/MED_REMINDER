import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Whether the phone has a network connection at all. M20 step 2.
enum ConnectionStatus {
  /// Not read yet (the first check is still running).
  unknown,

  /// There is a connection (Wi-Fi, mobile data, ethernet, ...).
  online,

  /// No connection at all (airplane mode, no signal, Wi-Fi and data off).
  offline,
}

/// Tells the app when the phone goes offline and comes back, so a banner can
/// say "changes will sync" instead of the user guessing.
///
/// It only knows about the network interface: a Wi-Fi without internet still
/// counts as online. Reads and writes that fail anyway are reported by the
/// screens themselves (`AppErrorText`).
class ConnectivityService {
  /// [check] and [changes] are replaced in tests; by default they come from
  /// the `connectivity_plus` plugin.
  ConnectivityService({
    Future<List<ConnectivityResult>> Function()? check,
    this.changes,
  }) : _check = check ?? (() => Connectivity().checkConnectivity());

  static final ConnectivityService instance = ConnectivityService();

  final Future<List<ConnectivityResult>> Function() _check;

  /// Follows changes (null: the plugin's stream).
  final Stream<List<ConnectivityResult>>? changes;

  final ValueNotifier<ConnectionStatus> status = ValueNotifier(
    ConnectionStatus.unknown,
  );

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _started = false;

  bool get isOffline => status.value == ConnectionStatus.offline;

  /// What a list of results from the plugin means. An empty list or only
  /// `none` is offline; anything else is online.
  static ConnectionStatus fromResults(List<ConnectivityResult> results) {
    final connected = results.any((r) => r != ConnectivityResult.none);
    return connected ? ConnectionStatus.online : ConnectionStatus.offline;
  }

  /// Reads the current state once and then follows changes. Safe to call
  /// again; only the first call does anything.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Follow changes first, so a change during the first read is not lost.
    final stream = changes ?? Connectivity().onConnectivityChanged;
    _sub = stream.listen(
      (results) => status.value = fromResults(results),
      onError: (Object e) =>
          debugPrint('ConnectivityService: change stream failed — $e'),
    );

    try {
      final first = fromResults(await _check());
      // A change that arrived while we were reading is newer than the read.
      if (status.value == ConnectionStatus.unknown) status.value = first;
    } catch (e) {
      // "unknown" shows no banner: better silent than a wrong "offline".
      debugPrint('ConnectivityService: first check failed — $e');
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
    status.dispose();
  }
}
