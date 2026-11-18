import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reminders/reminder_readiness.dart';

ReminderReadiness r({
  bool n = true,
  bool e = true,
  bool b = true,
  String maker = 'google',
  bool shown = false,
}) => ReminderReadiness(
  notifications: n,
  exactAlarms: e,
  batteryUnrestricted: b,
  manufacturer: maker,
  autostartShown: shown,
);

void main() {
  test('everything allowed on a Pixel: nothing to do', () {
    final x = r();
    expect(x.allGood, isTrue);
    expect(x.missing, isEmpty);
    expect(x.next, isNull);
    expect(x.atRisk, isFalse);
  });

  test('steps come in order of importance', () {
    final x = r(n: false, e: false, b: false);
    expect(x.missing, [
      ReminderStep.notifications,
      ReminderStep.exactAlarms,
      ReminderStep.battery,
    ]);
    expect(x.next, ReminderStep.notifications);
    expect(x.blocked, isTrue);
  });

  test('without exact alarms reminders are at risk but not blocked', () {
    final x = r(e: false);
    expect(x.blocked, isFalse);
    expect(x.atRisk, isTrue);
    expect(x.next, ReminderStep.exactAlarms);
  });

  test('battery saving alone is a risk', () {
    expect(r(b: false).missing, [ReminderStep.battery]);
  });

  test('Xiaomi gets the autostart tip once, even when all is allowed', () {
    final x = r(maker: 'xiaomi');
    expect(x.allGood, isTrue, reason: 'a tip is not a state');
    expect(x.missing, [ReminderStep.autostart]);
    expect(r(maker: 'xiaomi', shown: true).missing, isEmpty);
  });

  test('a Pixel never gets the autostart tip', () {
    expect(r(maker: 'google').needsAutostartTip, isFalse);
  });

  test('autostart comes last', () {
    final x = r(b: false, maker: 'samsung');
    expect(x.missing, [ReminderStep.battery, ReminderStep.autostart]);
  });

  test('known aggressive makers are covered', () {
    for (final m in ['xiaomi', 'oppo', 'realme', 'vivo', 'huawei', 'honor']) {
      expect(ReminderReadiness.aggressiveMakers.contains(m), isTrue, reason: m);
    }
  });
}
