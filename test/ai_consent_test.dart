import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/ai/ai_consent.dart';

class FakeStore implements AiConsentStore {
  DateTime? at;
  Object? failRead;
  Object? failWrite;
  int reads = 0;

  @override
  Future<DateTime?> read() async {
    reads++;
    if (failRead != null) throw failRead!;
    return at;
  }

  @override
  Future<void> grant() async {
    if (failWrite != null) throw failWrite!;
    at = DateTime(2026, 11, 16);
  }

  @override
  Future<void> withdraw() async {
    if (failWrite != null) throw failWrite!;
    at = null;
  }
}

void main() {
  test('starts unknown and not given', () {
    final c = AiConsentController(FakeStore());
    expect(c.status.value, AiConsentStatus.unknown);
    expect(c.isGiven, isFalse);
  });

  test('no saved consent -> notGiven', () async {
    final c = AiConsentController(FakeStore());
    expect(await c.refresh(), AiConsentStatus.notGiven);
    expect(await c.ensure(), isFalse);
  });

  test('saved consent -> given', () async {
    final s = FakeStore()..at = DateTime(2026, 11, 1);
    final c = AiConsentController(s);
    expect(await c.ensure(), isTrue);
    expect(c.isGiven, isTrue);
  });

  test('a read error fails closed', () async {
    final s = FakeStore()
      ..at = DateTime(2026, 11, 1)
      ..failRead = Exception('offline');
    final c = AiConsentController(s);
    expect(await c.ensure(), isFalse);
    expect(c.status.value, AiConsentStatus.notGiven);
  });

  test(
    'ensure reads again every time (another account may have signed in)',
    () async {
      final s = FakeStore()..at = DateTime(2026, 11, 1);
      final c = AiConsentController(s);
      expect(await c.ensure(), isTrue);
      s.at = null; // a different account now
      expect(await c.ensure(), isFalse);
      expect(s.reads, 2);
    },
  );

  test('grant saves and flips the status', () async {
    final s = FakeStore();
    final c = AiConsentController(s);
    await c.grant();
    expect(s.at, isNotNull);
    expect(c.isGiven, isTrue);
  });

  test('withdraw clears and flips the status', () async {
    final s = FakeStore()..at = DateTime(2026, 11, 1);
    final c = AiConsentController(s);
    await c.refresh();
    await c.withdraw();
    expect(s.at, isNull);
    expect(c.status.value, AiConsentStatus.notGiven);
  });

  test('a failed grant throws and keeps the status', () async {
    final s = FakeStore()..failWrite = Exception('denied');
    final c = AiConsentController(s);
    await expectLater(c.grant(), throwsException);
    expect(c.isGiven, isFalse);
  });

  test('a failed withdraw throws and keeps consent', () async {
    final s = FakeStore()
      ..at = DateTime(2026, 11, 1)
      ..failWrite = Exception('denied');
    final c = AiConsentController(s);
    await c.refresh();
    await expectLater(c.withdraw(), throwsException);
    expect(c.isGiven, isTrue);
  });

  test('reset forgets the status', () async {
    final s = FakeStore()..at = DateTime(2026, 11, 1);
    final c = AiConsentController(s);
    await c.refresh();
    c.reset();
    expect(c.status.value, AiConsentStatus.unknown);
  });
}
