import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/services/connectivity_service.dart';

void main() {
  group('fromResults', () {
    test('any real connection is online', () {
      for (final r in [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
        ConnectivityResult.bluetooth,
        ConnectivityResult.other,
      ]) {
        expect(
          ConnectivityService.fromResults([r]),
          ConnectionStatus.online,
          reason: r.name,
        );
      }
      expect(
        ConnectivityService.fromResults([
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        ConnectionStatus.online,
      );
    });

    test('none or an empty list is offline', () {
      expect(
        ConnectivityService.fromResults([ConnectivityResult.none]),
        ConnectionStatus.offline,
      );
      expect(ConnectivityService.fromResults([]), ConnectionStatus.offline);
    });
  });

  group('ConnectivityService', () {
    late StreamController<List<ConnectivityResult>> changes;

    setUp(() {
      changes = StreamController<List<ConnectivityResult>>.broadcast();
    });

    tearDown(() async {
      await changes.close();
    });

    ConnectivityService make(List<ConnectivityResult> first) =>
        ConnectivityService(check: () async => first, changes: changes.stream);

    test('starts as unknown, then reads the first state', () async {
      final s = make([ConnectivityResult.wifi]);
      expect(s.status.value, ConnectionStatus.unknown);
      await s.start();
      expect(s.status.value, ConnectionStatus.online);
      expect(s.isOffline, isFalse);
      await s.dispose();
    });

    test('offline at the start', () async {
      final s = make([ConnectivityResult.none]);
      await s.start();
      expect(s.status.value, ConnectionStatus.offline);
      expect(s.isOffline, isTrue);
      await s.dispose();
    });

    test('follows changes: offline, then back online', () async {
      final s = make([ConnectivityResult.wifi]);
      await s.start();
      final seen = <ConnectionStatus>[];
      s.status.addListener(() => seen.add(s.status.value));

      changes.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      changes.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);

      expect(seen, [ConnectionStatus.offline, ConnectionStatus.online]);
      await s.dispose();
    });

    test('a change that arrives during the first read wins over it', () async {
      final gate = Completer<List<ConnectivityResult>>();
      final s = ConnectivityService(
        check: () => gate.future,
        changes: changes.stream,
      );
      final started = s.start();
      changes.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(s.status.value, ConnectionStatus.offline);

      // the (older) read finishes later and says "online": it must not
      // overwrite the newer "offline"
      gate.complete([ConnectivityResult.wifi]);
      await started;
      expect(s.status.value, ConnectionStatus.offline);
      await s.dispose();
    });

    test('a failed first read stays unknown (no wrong banner)', () async {
      final s = ConnectivityService(
        check: () async => throw Exception('plugin'),
        changes: changes.stream,
      );
      await s.start();
      expect(s.status.value, ConnectionStatus.unknown);
      // but later changes still work
      changes.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(s.status.value, ConnectionStatus.offline);
      await s.dispose();
    });

    test('start twice listens once', () async {
      var reads = 0;
      final s = ConnectivityService(
        check: () async {
          reads++;
          return [ConnectivityResult.wifi];
        },
        changes: changes.stream,
      );
      await s.start();
      await s.start();
      expect(reads, 1);
      expect(changes.hasListener, isTrue);
      await s.dispose();
    });

    test('dispose stops listening', () async {
      final s = make([ConnectivityResult.wifi]);
      await s.start();
      expect(changes.hasListener, isTrue);
      await s.dispose();
      expect(changes.hasListener, isFalse);
    });

    test('a stream error does not break the service', () async {
      final s = make([ConnectivityResult.wifi]);
      await s.start();
      changes.addError(Exception('boom'));
      await Future<void>.delayed(Duration.zero);
      changes.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(s.status.value, ConnectionStatus.offline);
      await s.dispose();
    });
  });
}
