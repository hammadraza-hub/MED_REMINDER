import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/export/export_collector.dart';
import 'package:med_remind_app/core/export/export_data_source.dart';
import 'package:med_remind_app/core/export/firestore_value_converter.dart';

class FakeSource implements ExportDataSource {
  FakeSource({
    this.user = const {'email': 'a@b.c'},
    this.profiles = const [],
    this.collections = const {},
    this.failing = const {},
    this.truncatedPaths = const {},
  });

  final Map<String, dynamic> user;
  final List<RawDoc> profiles;
  final Map<String, List<RawDoc>> collections;
  final Set<String> failing;
  final Set<String> truncatedPaths;
  final List<String> reads = [];

  @override
  Future<Map<String, dynamic>> getUser(String uid) async => user;

  @override
  Future<List<RawDoc>> listOwnedProfiles(String uid) async => profiles;

  @override
  Future<ReadResult> readCollection(String path, {int maxDocs = 0}) async {
    reads.add(path);
    if (failing.contains(path)) throw Exception('permission-denied');
    return ReadResult(
      collections[path] ?? const [],
      truncated: truncatedPaths.contains(path),
    );
  }
}

void main() {
  group('FirestoreValueConverter', () {
    test('Timestamp becomes UTC DateTime', () {
      final v = FirestoreValueConverter.convert(
        Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3)),
      );
      expect(v, DateTime.utc(2026, 1, 2, 3));
      expect((v as DateTime).isUtc, isTrue);
    });

    test('GeoPoint becomes a map', () {
      expect(FirestoreValueConverter.convert(const GeoPoint(1.5, -2.5)), {
        'latitude': 1.5,
        'longitude': -2.5,
      });
    });

    test('Blob becomes base64', () {
      expect(
        FirestoreValueConverter.convert(Blob(Uint8List.fromList([1, 2, 3]))),
        'AQID',
      );
    });

    test('recurses into maps and lists, keeps plain values', () {
      final out = FirestoreValueConverter.convertMap({
        'a': 1,
        's': 'x',
        'n': null,
        'list': [
          Timestamp.fromDate(DateTime.utc(2026)),
          {'t': Timestamp.fromDate(DateTime.utc(2027))},
        ],
      });
      expect(out['a'], 1);
      expect(out['s'], 'x');
      expect(out['n'], isNull);
      expect((out['list'] as List)[0], DateTime.utc(2026));
      expect(((out['list'] as List)[1] as Map)['t'], DateTime.utc(2027));
    });
  });

  group('ExportCollector', () {
    final owned = [
      const RawDoc(id: 'p1', data: {'name': 'Self'}),
    ];

    test('reads every profile collection and sets paths', () async {
      final src = FakeSource(
        profiles: owned,
        collections: {
          'profiles/p1/doses': [
            const RawDoc(id: 'd1', data: {'status': 'taken'}),
          ],
        },
      );
      final bundle = await ExportCollector(src).collect(
        uid: 'u1',
        appVersion: '1.0.0+1',
        now: DateTime.utc(2026, 11, 13),
      );
      expect(bundle.userId, 'u1');
      expect(bundle.userData['email'], 'a@b.c');
      expect(bundle.profiles.length, 1);
      final doses = bundle.profiles.first.collections['doses']!;
      expect(doses.single.path, 'doses/d1');
      expect(doses.single.data['status'], 'taken');
      for (final c in ExportCollector.profileCollections) {
        expect(src.reads, contains('profiles/p1/$c'));
        expect(bundle.profiles.first.collections.containsKey(c), isTrue);
      }
      expect(bundle.notes, isEmpty);
    });

    test('reads nested inventoryEvents per medication', () async {
      final src = FakeSource(
        profiles: owned,
        collections: {
          'profiles/p1/medications': [
            const RawDoc(id: 'm1', data: {'name': 'Aspirin'}),
            const RawDoc(id: 'm2', data: {'name': 'Iron'}),
          ],
          'profiles/p1/medications/m1/inventoryEvents': [
            const RawDoc(id: 'e1', data: {'delta': -1}),
          ],
        },
      );
      final bundle = await ExportCollector(
        src,
      ).collect(uid: 'u1', appVersion: 'v');
      final ev = bundle.profiles.first.collections['inventoryEvents']!;
      expect(ev.length, 1);
      expect(ev.single.path, 'medications/m1/inventoryEvents/e1');
      expect(src.reads, contains('profiles/p1/medications/m2/inventoryEvents'));
    });

    test('an unreadable collection becomes a note, export continues', () async {
      final src = FakeSource(
        profiles: owned,
        collections: {
          'profiles/p1/doses': [const RawDoc(id: 'd1', data: {})],
        },
        failing: {'profiles/p1/vitals'},
      );
      final bundle = await ExportCollector(
        src,
      ).collect(uid: 'u1', appVersion: 'v');
      expect(bundle.profiles.first.collections['vitals'], isEmpty);
      expect(bundle.profiles.first.collections['doses'], hasLength(1));
      expect(bundle.notes.single, contains('vitals'));
      expect(bundle.notes.single, contains('could not be read'));
    });

    test('truncation is noted', () async {
      final src = FakeSource(
        profiles: owned,
        truncatedPaths: {'profiles/p1/doses'},
      );
      final bundle = await ExportCollector(
        src,
        maxDocsPerCollection: 5,
      ).collect(uid: 'u1', appVersion: 'v');
      expect(bundle.notes.single, contains('first 5 records'));
    });

    test('no owned profiles -> empty profile list', () async {
      final bundle = await ExportCollector(
        FakeSource(),
      ).collect(uid: 'u1', appVersion: 'v');
      expect(bundle.profiles, isEmpty);
    });

    test('progress callback reports steps', () async {
      final steps = <String>[];
      await ExportCollector(FakeSource(profiles: owned)).collect(
        uid: 'u1',
        appVersion: 'v',
        onProgress: steps.add,
      );
      expect(steps.first, 'account');
      expect(steps, contains('p1/doses'));
    });

    test('user document failure propagates', () async {
      final src = _BadUser();
      expect(
        () => ExportCollector(src).collect(uid: 'u1', appVersion: 'v'),
        throwsException,
      );
    });
  });
}

class _BadUser extends FakeSource {
  @override
  Future<Map<String, dynamic>> getUser(String uid) async =>
      throw Exception('offline');
}
