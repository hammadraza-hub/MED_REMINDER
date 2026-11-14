import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/services/health_sync_service.dart';
import 'package:med_remind_app/core/vitals/health_sync_mapper.dart';
import 'package:med_remind_app/core/vitals/vital_models.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/repositories/firebase_vitals_repository.dart';

class FakeSource implements HealthDataSource {
  FakeSource({this.access = HealthAccess.granted, this.samples = const []});

  HealthAccess access;
  List<RawHealthSample> samples;
  Object? readError;
  int accessCalls = 0;
  DateTime? readFrom;
  DateTime? readTo;

  @override
  VitalSource get source => VitalSource.healthConnect;

  @override
  Future<HealthAccess> ensureAccess() async {
    accessCalls++;
    return access;
  }

  @override
  Future<List<RawHealthSample>> read(DateTime from, DateTime to) async {
    if (readError != null) throw readError!;
    readFrom = from;
    readTo = to;
    return samples;
  }
}

class FakeStore implements HealthSyncStateStore {
  final Map<String, DateTime> data = {};

  @override
  Future<DateTime?> lastSync(String memberId) async => data[memberId];

  @override
  Future<void> saveLastSync(String memberId, DateTime at) async {
    data[memberId] = at;
  }
}

final now = DateTime.utc(2026, 11, 14, 12);

RawHealthSample weight(double v, DateTime at, [String? id]) => RawHealthSample(
  kind: HealthSampleKind.weight,
  value: v,
  from: at,
  uuid: id,
);

void main() {
  late FakeSource source;
  late FakeStore store;
  late List<List<VitalReading>> imported;
  var pro = true;
  SyncResult nextResult = const SyncResult(
    written: 1,
    skippedExisting: 0,
    duplicatesInBatch: 0,
    rejected: 0,
  );
  Object? importError;

  HealthSyncService build() => HealthSyncService(
    source: source,
    store: store,
    isPro: () async => pro,
    importer: (memberId, readings) async {
      if (importError != null) throw importError!;
      imported.add(readings);
      return nextResult;
    },
    clock: () => now,
  );

  setUp(() {
    source = FakeSource(samples: [weight(70, now, 'w1')]);
    store = FakeStore();
    imported = [];
    pro = true;
    importError = null;
    nextResult = const SyncResult(
      written: 1,
      skippedExisting: 0,
      duplicatesInBatch: 0,
      rejected: 0,
    );
  });

  test('a non-Pro user is stopped before the platform is touched', () async {
    pro = false;
    final r = await build().syncNow('p1');
    expect(r.outcome, HealthSyncOutcome.notPro);
    expect(source.accessCalls, 0);
    expect(imported, isEmpty);
    expect(store.data, isEmpty);
  });

  test('a failing Pro check counts as not Pro (fails closed)', () async {
    final svc = HealthSyncService(
      source: source,
      store: store,
      isPro: () async => false,
      importer: (m, r) async => nextResult,
      clock: () => now,
    );
    expect((await svc.syncNow('p1')).outcome, HealthSyncOutcome.notPro);
  });

  test(
    'health app missing or permission refused: nothing is imported',
    () async {
      source.access = HealthAccess.unavailable;
      expect(
        (await build().syncNow('p1')).outcome,
        HealthSyncOutcome.unavailable,
      );

      source.access = HealthAccess.denied;
      expect(
        (await build().syncNow('p1')).outcome,
        HealthSyncOutcome.permissionDenied,
      );

      expect(imported, isEmpty);
      expect(store.data, isEmpty);
    },
  );

  test(
    'the first sync reads the last 30 days and saves the sync time',
    () async {
      final r = await build().syncNow('p1');
      expect(r.outcome, HealthSyncOutcome.success);
      expect(r.imported, 1);
      expect(source.readTo, now);
      expect(source.readFrom, now.subtract(const Duration(days: 30)));
      expect(store.data['p1'], now);
      expect(imported.single.single.externalId, 'w1');
      expect(imported.single.single.source, VitalSource.healthConnect);
    },
  );

  test('later syncs start one day before the previous one', () async {
    final last = DateTime.utc(2026, 11, 10, 9);
    store.data['p1'] = last;
    await build().syncNow('p1');
    expect(source.readFrom, last.subtract(const Duration(days: 1)));
  });

  test('sync times are kept per profile', () async {
    await build().syncNow('p1');
    expect(store.data.containsKey('p2'), isFalse);
    await build().syncNow('p2');
    expect(store.data.keys, containsAll(['p1', 'p2']));
  });

  test('the report carries the import counts', () async {
    nextResult = const SyncResult(
      written: 3,
      skippedExisting: 5,
      duplicatesInBatch: 2,
      rejected: 1,
    );
    final r = await build().syncNow('p1');
    expect(r.imported, 3);
    expect(r.skippedExisting, 7);
    expect(r.rejected, 1);
  });

  test(
    'no samples: nothing is written but the sync still counts as done',
    () async {
      source.samples = const [];
      final r = await build().syncNow('p1');
      expect(r.outcome, HealthSyncOutcome.success);
      expect(r.imported, 0);
      expect(imported, isEmpty);
      expect(store.data['p1'], now);
    },
  );

  test(
    'a failed read or import keeps the old sync time so it is retried',
    () async {
      final last = DateTime.utc(2026, 11, 10);
      store.data['p1'] = last;

      source.readError = Exception('health app crashed');
      expect((await build().syncNow('p1')).outcome, HealthSyncOutcome.failed);
      expect(store.data['p1'], last);

      source.readError = null;
      importError = Exception('offline');
      expect((await build().syncNow('p1')).outcome, HealthSyncOutcome.failed);
      expect(store.data['p1'], last);
    },
  );

  test('a sync that is already running is not started twice', () async {
    final svc = build();
    final first = svc.syncNow('p1');
    final second = await svc.syncNow('p1');
    expect(second.outcome, HealthSyncOutcome.failed);
    expect((await first).outcome, HealthSyncOutcome.success);
    expect(imported.length, 1);
  });

  test('a new sync is allowed after the previous one finished', () async {
    final svc = build();
    await svc.syncNow('p1');
    final again = await svc.syncNow('p1');
    expect(again.outcome, HealthSyncOutcome.success);
  });
}
