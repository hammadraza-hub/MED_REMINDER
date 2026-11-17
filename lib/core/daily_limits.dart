import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Things a person may only do so many times a day. M21 step 6.
///
/// Spark has no Cloud Function to count and refuse, so the counting is done by
/// the Firestore RULES: every limited action must be written in the SAME batch
/// as `users/{uid}/limits/{day}` with that day's counter raised by exactly one,
/// and the rules refuse a counter above the limit. The numbers below must match
/// `firestore.rules` (`bumpedOnce(...)` and `validLimitBump()`).
///
/// A scripted client that skips the counter is refused too: without the
/// counter write the action rule fails. What the rules cannot stop is a person
/// opening many accounts; that needs App Check and, on Blaze, server checks.
enum DailyLimitKind {
  posts(20),
  comments(100),
  reports(20),
  tickets(5);

  const DailyLimitKind(this.max);

  /// Most actions of this kind per day (UTC day).
  final int max;

  /// The field of the counter document.
  String get field => name;
}

/// The day's limit for [kind] is used up.
class DailyLimitException implements Exception {
  const DailyLimitException(this.kind);

  final DailyLimitKind kind;

  @override
  String toString() => 'DailyLimitException(${kind.name})';
}

class DailyLimits {
  DailyLimits._();

  static const Duration _look = Duration(seconds: 3);

  /// Number of the UTC day, the id of the counter document. The rules compute
  /// the same number from the server time.
  static int dayNumber(DateTime now) =>
      now.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  static DocumentReference<Map<String, dynamic>> counter(
    FirebaseFirestore db,
    String uid, {
    DateTime? now,
  }) => db
      .collection('users')
      .doc(uid)
      .collection('limits')
      .doc('${dayNumber(now ?? DateTime.now())}');

  /// Adds the counter bump to [batch]. Call this for every limited action.
  static void bump(
    WriteBatch batch,
    FirebaseFirestore db,
    String uid,
    DailyLimitKind kind, {
    DateTime? now,
  }) {
    batch.set(counter(db, uid, now: now), {
      kind.field: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Throws [DailyLimitException] when today's counter already shows the
  /// limit. Only to give a clear message BEFORE the write: the rules decide.
  /// Offline or slow: no answer, no check (the write then queues or fails).
  static Future<void> assertRoom(
    FirebaseFirestore db,
    String uid,
    DailyLimitKind kind, {
    DateTime? now,
  }) async {
    try {
      final snap = await counter(db, uid, now: now).get().timeout(_look);
      final used = (snap.data()?[kind.field] as num?)?.toInt() ?? 0;
      if (used >= kind.max) throw DailyLimitException(kind);
    } on DailyLimitException {
      rethrow;
    } catch (_) {
      // Unknown: let the write try.
    }
  }

  /// Whether [used] actions of [kind] leave room for one more (pure, tested).
  static bool hasRoom(DailyLimitKind kind, int used) => used < kind.max;
}
