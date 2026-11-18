import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/core/services/reminder_action_queue.dart';
import 'package:med_remind_app/models/dose.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTarget implements DoseActionTarget {
  final calls = <String>[];
  Object? failWith;

  @override
  Future<void> logDose({
    required String profileId,
    required String doseId,
    required DoseStatus status,
    required String loggedBy,
    MissedDoseReason? reasonCode,
  }) async {
    if (failWith != null) throw failWith!;
    calls.add(
      '${status.value}:$profileId:$doseId:$loggedBy:${reasonCode?.value}',
    );
  }

  @override
  Future<void> snoozeDose({
    required String profileId,
    required String doseId,
    required Duration snoozeDuration,
  }) async {
    if (failWith != null) throw failWith!;
    calls.add('snooze:$profileId:$doseId:${snoozeDuration.inMinutes}');
  }
}

Future<List<Map<String, dynamic>>> stored() async {
  final prefs = await SharedPreferences.getInstance();
  return [
    for (final raw in prefs.getStringList('reminder_actions_v1') ?? <String>[])
      jsonDecode(raw) as Map<String, dynamic>,
  ];
}

void main() {
  late FakeTarget fake;
  final queue = ReminderActionQueue.instance;
  String? uid = 'u1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = FakeTarget();
    uid = 'u1';
    queue.target = fake;
    queue.uidProvider = () => uid;
  });

  Future<void> enqueue(String action, {String dose = 'd1', int? snooze}) =>
      queue.enqueue(
        doseId: dose,
        profileId: 'p1',
        action: action,
        snoozeMinutes: snooze,
      );

  test('taken is replayed as a taken log by the signed-in user', () async {
    await enqueue('taken');
    await queue.replay();
    expect(fake.calls, ['taken:p1:d1:u1:null']);
    expect(await stored(), isEmpty);
  });

  test('skipped is replayed with the reason "forgot"', () async {
    await enqueue('skipped');
    await queue.replay();
    expect(fake.calls, ['skipped:p1:d1:u1:forgot']);
  });

  test('snooze uses the stored minutes, default 10', () async {
    await enqueue('snooze', snooze: 15);
    await enqueue('snooze', dose: 'd2');
    await queue.replay();
    expect(fake.calls, ['snooze:p1:d1:15', 'snooze:p1:d2:10']);
  });

  test('actions replay in the order they were tapped', () async {
    await enqueue('snooze', snooze: 10);
    await enqueue('taken');
    await queue.replay();
    expect(fake.calls.first.startsWith('snooze'), isTrue);
    expect(fake.calls.last.startsWith('taken'), isTrue);
  });

  test('signed out: the queue is kept and replays after sign-in', () async {
    uid = null;
    await enqueue('taken');
    await queue.replay();
    expect(fake.calls, isEmpty);
    expect((await stored()).length, 1);
    uid = 'u1';
    await queue.replay();
    expect(fake.calls.length, 1);
    expect(await stored(), isEmpty);
  });

  test('replaying twice does not apply an action twice', () async {
    await enqueue('taken');
    await queue.replay();
    await queue.replay();
    expect(fake.calls.length, 1);
  });

  test('network failure keeps the action and counts the attempt', () async {
    fake.failWith = const AppException.network('offline');
    await enqueue('taken');
    await queue.replay();
    final left = await stored();
    expect(left.length, 1);
    expect(left.first['attempts'], 1);
    fake.failWith = null;
    await queue.replay();
    expect(fake.calls.length, 1);
    expect(await stored(), isEmpty);
  });

  test('a dose that no longer exists (notFound) is dropped', () async {
    fake.failWith = const AppException.notFound('gone');
    await enqueue('taken');
    await queue.replay();
    expect(await stored(), isEmpty);
  });

  test('validation errors are dropped, not retried for ever', () async {
    fake.failWith = const AppException.validation('bad');
    await enqueue('taken');
    await queue.replay();
    expect(await stored(), isEmpty);
  });

  test('gives up after 10 failed attempts', () async {
    fake.failWith = const AppException.network('offline');
    await enqueue('taken');
    for (var i = 0; i < 9; i++) {
      await queue.replay();
      expect((await stored()).length, 1, reason: 'attempt ${i + 1}');
    }
    await queue.replay(); // the 10th
    expect(await stored(), isEmpty);
  });

  test('one failing action does not block the others', () async {
    await enqueue('taken', dose: 'bad');
    await enqueue('taken', dose: 'good');
    final failing = _SelectiveTarget(fake);
    queue.target = failing;
    await queue.replay();
    expect(fake.calls.length, 1);
    expect((await stored()).single['doseId'], 'bad');
  });

  test('unknown actions and corrupt entries are dropped', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminder_actions_v1', [
      'not json',
      jsonEncode({'doseId': 'd', 'profileId': 'p', 'action': 'dance'}),
    ]);
    await queue.replay();
    expect(await stored(), isEmpty);
    expect(fake.calls, isEmpty);
  });

  test('an empty queue does nothing', () async {
    await queue.replay();
    expect(fake.calls, isEmpty);
  });
}

class _SelectiveTarget implements DoseActionTarget {
  _SelectiveTarget(this.inner);
  final FakeTarget inner;

  @override
  Future<void> logDose({
    required String profileId,
    required String doseId,
    required DoseStatus status,
    required String loggedBy,
    MissedDoseReason? reasonCode,
  }) {
    if (doseId == 'bad') throw const AppException.network('offline');
    return inner.logDose(
      profileId: profileId,
      doseId: doseId,
      status: status,
      loggedBy: loggedBy,
      reasonCode: reasonCode,
    );
  }

  @override
  Future<void> snoozeDose({
    required String profileId,
    required String doseId,
    required Duration snoozeDuration,
  }) => inner.snoozeDose(
    profileId: profileId,
    doseId: doseId,
    snoozeDuration: snoozeDuration,
  );
}
