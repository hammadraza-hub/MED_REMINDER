import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_engine.dart';
import 'package:med_remind_app/models/dose.dart';

Dose dose(String id, DateTime at) => Dose(
  id: id,
  profileId: 'p',
  medicationId: 'm',
  medName: 'M',
  doseLabel: 'x',
  scheduledAt: at,
  missDeadline: at.add(const Duration(minutes: 30)),
  createdAt: at,
);

void main() {
  final base = DateTime.utc(2026, 11, 18, 8);
  final all = [
    for (var i = 0; i < 5; i++) dose('m_$i', base.add(Duration(days: i))),
  ];

  test('nothing exists: everything is written', () {
    expect(DoseEngine.onlyMissing(all, {}).length, 5);
  });

  test('existing ids are never written again (a taken dose stays)', () {
    final r = DoseEngine.onlyMissing(all, {'m_0', 'm_2'});
    expect(r.map((d) => d.id), ['m_1', 'm_3', 'm_4']);
  });

  test('everything exists: nothing to write', () {
    expect(DoseEngine.onlyMissing(all, all.map((d) => d.id).toSet()), isEmpty);
  });

  test('notBefore keeps only the future (schedule change)', () {
    final r = DoseEngine.onlyMissing(
      all,
      {},
      notBefore: base.add(const Duration(days: 2)),
    );
    expect(r.map((d) => d.id), ['m_2', 'm_3', 'm_4']); // at == notBefore stays
  });

  test('top-up after 14 days: only the new day is missing', () {
    final window1 = all.sublist(0, 4);
    final r = DoseEngine.onlyMissing(all, window1.map((d) => d.id).toSet());
    expect(r.map((d) => d.id), ['m_4']);
  });
}
