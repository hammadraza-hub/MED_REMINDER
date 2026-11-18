import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/repositories/dose_repository.dart';

void main() {
  final now = DateTime.utc(2026, 11, 18, 12);
  bool sweep(String? status, DateTime? deadline) =>
      DoseRepository.isOverdueForSweep(
        status: status,
        missDeadline: deadline,
        now: now,
      );

  test('pending and past the deadline: swept', () {
    expect(sweep('pending', now.subtract(const Duration(minutes: 1))), isTrue);
  });
  test('deadline exactly now is not overdue', () {
    expect(sweep('pending', now), isFalse);
  });
  test('deadline in the future (a snoozed dose): not swept', () {
    expect(sweep('pending', now.add(const Duration(minutes: 10))), isFalse);
  });
  test('finished doses are never touched', () {
    final past = now.subtract(const Duration(days: 3));
    for (final s in ['taken', 'skipped', 'missed', 'snoozed']) {
      expect(sweep(s, past), isFalse, reason: s);
    }
  });
  test('missing status or deadline: not swept', () {
    expect(sweep(null, now.subtract(const Duration(days: 1))), isFalse);
    expect(sweep('pending', null), isFalse);
  });
  test('the limit is 200 per run', () {
    expect(DoseRepository.sweepLimit, 200);
  });
}
