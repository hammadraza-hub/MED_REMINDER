import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/account_deletion_engine.dart';

/// In-memory store. Set of full document paths; listIds returns up to
/// [pageSize] children of a collection path. Records the delete order and can
/// fail on demand.
class FakeStore implements PurgeStore {
  FakeStore(
    Iterable<String> docs, {
    this.owned = const [],
    this.memberOf = const [],
    this.pageSize = 2,
  }) : docs = {...docs};

  final Set<String> docs;
  final List<String> owned;
  final List<String> memberOf;
  final int pageSize;
  final List<String> left = [];
  final List<String> deleteOrder = [];
  String? failOn;
  bool noopDelete = false;

  @override
  Future<List<String>> ownedProfileIds(String uid) async => owned;

  @override
  Future<List<String>> memberProfileIds(String uid) async => memberOf;

  @override
  Future<void> leaveProfile(String profileId, String uid) async {
    if (failOn == 'leave:$profileId') throw Exception('rules denied');
    left.add(profileId);
  }

  @override
  Future<List<String>> listIds(String collectionPath) async {
    final prefix = '$collectionPath/';
    final ids = <String>[];
    for (final d in docs) {
      if (!d.startsWith(prefix)) continue;
      final rest = d.substring(prefix.length);
      if (!rest.contains('/')) ids.add(rest);
    }
    ids.sort();
    return ids.take(pageSize).toList();
  }

  @override
  Future<void> deleteDoc(String docPath) async {
    if (failOn == docPath) throw Exception('network down');
    if (noopDelete) return;
    deleteOrder.add(docPath);
    docs.remove(docPath);
  }
}

void main() {
  final data = [
    'users/u1',
    'users/u1/devices/d1',
    'users/u1/devices/d2',
    'users/u1/devices/d3',
    'profiles/p1',
    'profiles/p1/medications/m1',
    'profiles/p1/medications/m2',
    'profiles/p1/medications/m3',
    'profiles/p1/medications/m1/inventoryEvents/e1',
    'profiles/p1/medications/m1/inventoryEvents/e2',
    'profiles/p1/medications/m1/inventoryEvents/e3',
    'profiles/p1/medications/m3/inventoryEvents/e9',
    'profiles/p1/doses/a',
    'profiles/p1/doses/b',
    'profiles/p1/doses/c',
    'profiles/p1/vitals/v1',
    'profiles/p1/allergies/al1',
    'profiles/p2',
    'profiles/p2/doses/z',
    // someone else's data must never be touched
    'users/other',
    'profiles/pOther',
    'profiles/pOther/doses/x',
  ];

  test('deletes everything owned, pages through large collections', () async {
    final store = FakeStore(data, owned: ['p1', 'p2'], pageSize: 2);
    final summary = await AccountDeletionEngine(store).purge('u1');

    expect(store.docs, {'users/other', 'profiles/pOther', 'profiles/pOther/doses/x'});
    expect(summary.profiles, 2);
    expect(summary.deletedDocs, data.length - 3);
  });

  test('children are deleted before their parents', () async {
    final store = FakeStore(data, owned: ['p1', 'p2']);
    await AccountDeletionEngine(store).purge('u1');
    final order = store.deleteOrder;

    int at(String p) => order.indexOf(p);
    // nested events before the medication
    expect(at('profiles/p1/medications/m1/inventoryEvents/e3'),
        lessThan(at('profiles/p1/medications/m1')));
    // every child before the profile document
    for (final d in data.where((d) => d.startsWith('profiles/p1/'))) {
      expect(at(d), lessThan(at('profiles/p1')), reason: d);
    }
    // profile docs before the user document, which is last
    expect(at('profiles/p1'), lessThan(at('users/u1')));
    expect(at('profiles/p2'), lessThan(at('users/u1')));
    expect(order.last, 'users/u1');
    // devices before the user document
    expect(at('users/u1/devices/d3'), lessThan(at('users/u1')));
  });

  test('works for a user with no profiles', () async {
    final store = FakeStore(['users/u1', 'users/u1/devices/d1']);
    final summary = await AccountDeletionEngine(store).purge('u1');
    expect(store.docs, isEmpty);
    expect(summary.profiles, 0);
  });

  test('a failure stops the purge and keeps the user document', () async {
    final store = FakeStore(data, owned: ['p1', 'p2'])
      ..failOn = 'profiles/p1/doses/b';
    await expectLater(
      AccountDeletionEngine(store).purge('u1'),
      throwsException,
    );
    expect(store.docs, contains('users/u1'));
    expect(store.docs, contains('profiles/p1'));
  });

  test('running again after a failure finishes the job', () async {
    final store = FakeStore(data, owned: ['p1', 'p2'])
      ..failOn = 'profiles/p1/doses/b';
    await expectLater(
      AccountDeletionEngine(store).purge('u1'),
      throwsException,
    );

    store.failOn = null;
    // profiles that were already deleted would no longer be listed as owned
    final owned = ['p1', 'p2']
        .where((p) => store.docs.contains('profiles/$p'))
        .toList();
    final retry = FakeStore(store.docs, owned: owned, pageSize: store.pageSize);
    await AccountDeletionEngine(retry).purge('u1');
    expect(retry.docs, {'users/other', 'profiles/pOther', 'profiles/pOther/doses/x'});
  });

  test('delete that silently does nothing is detected, not looped forever', () async {
    final store = FakeStore(data, owned: ['p1'])..noopDelete = true;
    await expectLater(
      AccountDeletionEngine(store).purge('u1'),
      throwsA(isA<PurgeStalledException>()),
    );
  });

  test('progress callback reports profiles and account', () async {
    final steps = <String>[];
    final store = FakeStore(data, owned: ['p1']);
    await AccountDeletionEngine(store).purge('u1', onProgress: steps.add);
    expect(steps, contains('profile:p1'));
    expect(steps.last, 'account');
  });

  test('leaves profiles owned by others first, never deletes their docs', () async {
    final store = FakeStore(
      [...data, 'profiles/pShared', 'profiles/pShared/doses/q'],
      owned: ['p1', 'p2'],
      memberOf: ['pShared'],
    );
    final summary = await AccountDeletionEngine(store).purge('u1');

    expect(store.left, ['pShared']);
    expect(summary.leftProfiles, 1);
    expect(store.docs, contains('profiles/pShared'));
    expect(store.docs, contains('profiles/pShared/doses/q'));
    expect(store.deleteOrder.where((d) => d.contains('pShared')), isEmpty);
  });

  test('a failed leave stops before anything is deleted', () async {
    final store = FakeStore(data, owned: ['p1'], memberOf: ['pShared'])
      ..failOn = 'leave:pShared';
    await expectLater(
      AccountDeletionEngine(store).purge('u1'),
      throwsException,
    );
    expect(store.deleteOrder, isEmpty);
    expect(store.docs, contains('users/u1'));
  });
}
