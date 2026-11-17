import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/core/async_state.dart';

void main() {
  group('AsyncState basics', () {
    test('ofList: empty list is empty, otherwise data', () {
      expect(AsyncState.ofList<int>([]), isA<AsyncEmpty<List<int>>>());
      final s = AsyncState.ofList<int>([1, 2]);
      expect(s, isA<AsyncData<List<int>>>());
      expect(s.valueOrNull, [1, 2]);
    });

    test('getters', () {
      const loading = AsyncState<int>.loading();
      const data = AsyncState<int>.data(3);
      const empty = AsyncState<int>.empty();
      final fail = AsyncState<int>.failure(const AppException.network('x'));
      expect(loading.isLoading, isTrue);
      expect(data.hasData, isTrue);
      expect(empty.isEmpty, isTrue);
      expect(fail.isFailure, isTrue);
      expect(data.valueOrNull, 3);
      expect(loading.valueOrNull, isNull);
      expect(fail.errorOrNull!.type, AppExceptionType.network);
      expect(data.errorOrNull, isNull);
    });

    test('when calls exactly the callback of the state', () {
      String name(AsyncState<int> s) => s.when(
        loading: () => 'loading',
        data: (v) => 'data $v',
        empty: () => 'empty',
        failure: (e) => 'failure ${e.type.name}',
      );
      expect(name(const AsyncState.loading()), 'loading');
      expect(name(const AsyncState.data(7)), 'data 7');
      expect(name(const AsyncState.empty()), 'empty');
      expect(
        name(const AsyncState.failure(AppException.server('x'))),
        'failure server',
      );
    });
  });

  group('AsyncState.guard', () {
    test('a value becomes data', () async {
      final s = await AsyncState.guard<int>(() async => 5);
      expect(s.valueOrNull, 5);
    });

    test('empty list, set, map and null become empty', () async {
      expect(
        await AsyncState.guard<List<int>>(() async => []),
        isA<AsyncEmpty<List<int>>>(),
      );
      expect(
        await AsyncState.guard<Set<int>>(() async => {}),
        isA<AsyncEmpty<Set<int>>>(),
      );
      expect(
        await AsyncState.guard<Map<String, int>>(() async => {}),
        isA<AsyncEmpty<Map<String, int>>>(),
      );
      expect(
        await AsyncState.guard<int?>(() async => null),
        isA<AsyncEmpty<int?>>(),
      );
      // zero and an empty string are real values
      expect((await AsyncState.guard<int>(() async => 0)).hasData, isTrue);
    });

    test('a custom isEmpty decides', () async {
      final s = await AsyncState.guard<int>(
        () async => 0,
        isEmpty: (v) => v == 0,
      );
      expect(s.isEmpty, isTrue);
    });

    test('errors are mapped to an AppException', () async {
      final fs = await AsyncState.guard<int>(
        () => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );
      expect(fs.errorOrNull!.type, AppExceptionType.permission);

      final net = await AsyncState.guard<int>(
        () => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      );
      expect(net.errorOrNull!.type, AppExceptionType.network);

      final other = await AsyncState.guard<int>(() => throw StateError('x'));
      expect(other.errorOrNull!.type, AppExceptionType.unknown);
    });
  });

  group('AppException.fromAny additions (M20 step 1)', () {
    test('a timeout is a network problem', () {
      final e = AppException.fromAny(TimeoutException('slow'));
      expect(e.type, AppExceptionType.network);
    });

    test(
      'a dropped connection (SocketException by name) is a network problem',
      () {
        final e = AppException.fromAny(SocketException());
        expect(e.type, AppExceptionType.network);
      },
    );

    test('an expired sign-in token is a permission problem with its code', () {
      for (final code in [
        'user-token-expired',
        'invalid-user-token',
        'user-token-revoked',
      ]) {
        final e = AppException.fromAny(FirebaseAuthException(code: code));
        expect(e.type, AppExceptionType.permission, reason: code);
        expect(e.code, code);
      }
    });

    test('an AppException passes through unchanged', () {
      const original = AppException.notFound('gone');
      expect(identical(AppException.fromAny(original), original), isTrue);
    });
  });

  group('fromSnapshot', () {
    test('waiting without data is loading', () {
      expect(
        AsyncState.fromSnapshot<int>(const AsyncSnapshot.waiting()).isLoading,
        isTrue,
      );
    });

    test('data, empty data and error', () {
      expect(
        AsyncState.fromSnapshot<int>(
          const AsyncSnapshot.withData(ConnectionState.active, [1]),
        ).hasData,
        isTrue,
      );
      expect(
        AsyncState.fromSnapshot<int>(
          const AsyncSnapshot.withData(ConnectionState.active, <int>[]),
        ).isEmpty,
        isTrue,
      );
      final err = AsyncState.fromSnapshot<int>(
        AsyncSnapshot.withError(
          ConnectionState.active,
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
      );
      expect(err.errorOrNull!.type, AppExceptionType.network);
    });
  });

  group('AsyncController', () {
    test('first load: loading, then data', () async {
      final c = AsyncController<List<int>>();
      expect(c.state.isLoading, isTrue);
      final done = Completer<List<int>>();
      final f = c.load(() => done.future);
      expect(c.state.isLoading, isTrue);
      done.complete([1]);
      await f;
      expect(c.state.valueOrNull, [1]);
      c.dispose();
    });

    test('empty result and failed first load', () async {
      final c = AsyncController<List<int>>();
      await c.load(() async => []);
      expect(c.state.isEmpty, isTrue);
      await c.load(() async => throw StateError('x'));
      // the first screen state was empty (no data), so the error shows
      expect(c.state.isFailure, isTrue);
      c.dispose();
    });

    test('retry after a failure goes through loading to data', () async {
      final c = AsyncController<int>();
      await c.load(() async => throw StateError('x'));
      expect(c.state.isFailure, isTrue);
      final states = <String>[];
      c.addListener(() => states.add(c.state.runtimeType.toString()));
      await c.load(() async => 4);
      expect(c.state.valueOrNull, 4);
      expect(states.first, contains('AsyncLoading'));
      c.dispose();
    });

    test('a reload keeps the data on screen (no spinner)', () async {
      final c = AsyncController<int>();
      await c.load(() async => 1);
      final seen = <bool>[];
      c.addListener(() => seen.add(c.state.isLoading));
      final done = Completer<int>();
      final f = c.load(() => done.future);
      expect(c.state.valueOrNull, 1);
      done.complete(2);
      await f;
      expect(c.state.valueOrNull, 2);
      expect(seen.contains(true), isFalse);
      c.dispose();
    });

    test('a failed reload keeps the old data and reports the error', () async {
      final c = AsyncController<int>();
      await c.load(() async => 1);
      await c.load(
        () => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      );
      expect(c.state.valueOrNull, 1);
      expect(c.lastReloadError!.type, AppExceptionType.network);
      await c.load(() async => 3);
      expect(c.lastReloadError, isNull);
      expect(c.state.valueOrNull, 3);
      c.dispose();
    });

    test('an older slow load cannot overwrite a newer one', () async {
      final c = AsyncController<int>();
      final slow = Completer<int>();
      final first = c.load(() => slow.future);
      await c.load(() async => 2);
      slow.complete(1);
      await first;
      expect(c.state.valueOrNull, 2);
      c.dispose();
    });

    test('setData and a custom isEmpty', () {
      final c = AsyncController<int>(isEmpty: (v) => v == 0);
      c.setData(0);
      expect(c.state.isEmpty, isTrue);
      c.setData(5);
      expect(c.state.valueOrNull, 5);
      c.dispose();
    });
  });
}

/// Stand-in for dart:io's SocketException (the mapper matches its type name,
/// so the app does not have to import dart:io).
class SocketException implements Exception {}
