import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AsyncSnapshot;

import 'app_exception.dart';

/// One value for "what should this screen show right now". M20 step 1.
///
/// Every screen that reads data from a repository ends up in exactly one of
/// four states, so the screen only needs one `switch` (or [when]) and never
/// forgets one of them:
///
///  * [AsyncLoading]  — nothing to show yet: show a skeleton or spinner
///  * [AsyncData]     — there is data to show
///  * [AsyncEmpty]    — the read worked, but there is nothing in the list:
///                      show the empty state ("No medications yet")
///  * [AsyncFailure]  — the read failed: show the error and, when it makes
///                      sense ([AppException.type]), a retry button
///
/// (The failure class is not called `AsyncError` because `dart:async`
/// already has a class of that name.)
sealed class AsyncState<T> {
  const AsyncState();

  const factory AsyncState.loading() = AsyncLoading<T>;
  const factory AsyncState.data(T value) = AsyncData<T>;
  const factory AsyncState.empty() = AsyncEmpty<T>;
  const factory AsyncState.failure(AppException error) = AsyncFailure<T>;

  /// A list read: [AsyncEmpty] when the list is empty, otherwise [AsyncData].
  static AsyncState<List<E>> ofList<E>(List<E> list) =>
      list.isEmpty ? AsyncEmpty<List<E>>() : AsyncData<List<E>>(list);

  /// Runs [run] and turns the outcome into a state: the value (or
  /// [AsyncEmpty] when [isEmpty] says so; by default an empty list, set, map
  /// or null counts as empty), or a [AsyncFailure] with the error mapped by
  /// [AppException.fromAny].
  static Future<AsyncState<T>> guard<T>(
    Future<T> Function() run, {
    bool Function(T value)? isEmpty,
  }) async {
    try {
      final value = await run();
      final empty = isEmpty != null ? isEmpty(value) : _looksEmpty(value);
      return empty ? AsyncEmpty<T>() : AsyncData<T>(value);
    } catch (e) {
      return AsyncFailure<T>(AppException.fromAny(e));
    }
  }

  /// A `StreamBuilder` snapshot of a list as a state. Data that is already
  /// there wins over a later error or a reconnect (the screen keeps showing
  /// what it has).
  static AsyncState<List<E>> fromSnapshot<E>(AsyncSnapshot<List<E>> s) {
    if (s.hasData) return ofList<E>(s.data!);
    if (s.hasError) {
      return AsyncFailure<List<E>>(AppException.fromAny(s.error!));
    }
    return const AsyncLoading();
  }

  static bool _looksEmpty(Object? v) {
    if (v == null) return true;
    if (v is Iterable) return v.isEmpty;
    if (v is Map) return v.isEmpty;
    return false;
  }

  bool get isLoading => this is AsyncLoading<T>;
  bool get isEmpty => this is AsyncEmpty<T>;
  bool get isFailure => this is AsyncFailure<T>;
  bool get hasData => this is AsyncData<T>;

  /// The data, or null in every other state.
  T? get valueOrNull => switch (this) {
    AsyncData<T>(:final value) => value,
    _ => null,
  };

  /// The error, or null in every other state.
  AppException? get errorOrNull => switch (this) {
    AsyncFailure<T>(:final error) => error,
    _ => null,
  };

  /// One callback per state; the screen cannot forget one.
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function() empty,
    required R Function(AppException error) failure,
  }) => switch (this) {
    AsyncLoading<T>() => loading(),
    AsyncData<T>(:final value) => data(value),
    AsyncEmpty<T>() => empty(),
    AsyncFailure<T>(:final error) => failure(error),
  };
}

final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

final class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.value);

  final T value;
}

final class AsyncEmpty<T> extends AsyncState<T> {
  const AsyncEmpty();
}

final class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure(this.error);

  final AppException error;
}

/// Holds the [AsyncState] of one read, for screens that load once and on
/// "try again" / pull-to-refresh.
///
/// While reloading, data that is already shown stays on screen (no flash of a
/// spinner), and a failed reload keeps the old data and only reports the
/// error through [lastReloadError]. The first load shows [AsyncLoading].
class AsyncController<T> extends ChangeNotifier {
  AsyncController({this.isEmpty});

  /// Decides which values count as empty (default: empty list / map / null).
  final bool Function(T value)? isEmpty;

  AsyncState<T> _state = const AsyncLoading();
  AppException? _lastReloadError;
  int _generation = 0;
  bool _disposed = false;

  AsyncState<T> get state => _state;

  /// The error of the latest reload that failed while data was on screen.
  AppException? get lastReloadError => _lastReloadError;

  /// Reads again. A reload that is still running when a newer one starts is
  /// ignored when it finishes.
  Future<void> load(Future<T> Function() run) async {
    final gen = ++_generation;
    _lastReloadError = null;
    if (!_state.hasData) {
      _state = const AsyncLoading();
      _notify();
    }
    final next = await AsyncState.guard<T>(run, isEmpty: isEmpty);
    if (gen != _generation || _disposed) return;
    if (next is AsyncFailure<T> && _state.hasData) {
      _lastReloadError = next.error;
    } else {
      _state = next;
    }
    _notify();
  }

  /// Puts a value straight in (for example after a local change).
  void setData(T value) {
    _generation++;
    _lastReloadError = null;
    final empty = isEmpty != null
        ? isEmpty!(value)
        : AsyncState._looksEmpty(value);
    _state = empty ? AsyncEmpty<T>() : AsyncData<T>(value);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
