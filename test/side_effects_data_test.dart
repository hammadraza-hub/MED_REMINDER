import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/features/meds/side_effects_data.dart';

SymptomEntry sym(
  String id,
  DateTime at, {
  String name = 'Nausea',
  int severity = 3,
  String? med,
  String? notes,
}) => SymptomEntry(
  id: id,
  symptom: name,
  severity: severity,
  medicationId: med,
  occurredAt: at,
  notes: notes,
);

void main() {
  const metformin = (name: 'Metformin', strength: '500mg');

  test('empty input -> empty list', () {
    expect(SideEffectsData.fromSymptoms(const [], {}), isEmpty);
  });

  test('entries are sorted newest first', () {
    final out = SideEffectsData.fromSymptoms([
      sym('a', DateTime(2026, 11, 10)),
      sym('b', DateTime(2026, 11, 14)),
      sym('c', DateTime(2026, 11, 12)),
    ], {});
    expect(out.map((e) => e.id), ['b', 'c', 'a']);
  });

  test('a linked medication is resolved to its name and strength', () {
    final e = SideEffectsData.fromSymptoms(
      [sym('a', DateTime(2026, 11, 14), med: 'm1', notes: 'after lunch')],
      {'m1': metformin},
    ).single;
    expect(e.medicationId, 'm1');
    expect(e.medicationName, 'Metformin');
    expect(e.medicationStrength, '500mg');
    expect(e.medicationLabel, 'Metformin 500mg');
    expect(e.note, 'after lunch');
  });

  test(
    'no link, or a medication that no longer exists, gives an empty label',
    () {
      final out = SideEffectsData.fromSymptoms(
        [
          sym('a', DateTime(2026, 11, 14)),
          sym('b', DateTime(2026, 11, 13), med: 'deleted'),
        ],
        {'m1': metformin},
      );
      expect(out[0].medicationLabel, isEmpty);
      expect(out[1].medicationLabel, isEmpty);
      expect(out[1].medicationId, 'deleted', reason: 'the link itself is kept');
    },
  );

  test('a medication without strength has no trailing space', () {
    final e = SideEffectsData.fromSymptoms(
      [sym('a', DateTime(2026, 11, 14), med: 'm2')],
      {'m2': (name: 'Vitamin D', strength: '')},
    ).single;
    expect(e.medicationLabel, 'Vitamin D');
  });

  test('entries without an id are skipped, severity is kept in 1..5', () {
    final out = SideEffectsData.fromSymptoms([
      SymptomEntry(
        symptom: 'x',
        severity: 3,
        occurredAt: DateTime(2026, 11, 14),
      ),
      sym('a', DateTime(2026, 11, 14), severity: 9),
      sym('b', DateTime(2026, 11, 14), severity: 0),
    ], {});
    expect(out.length, 2);
    expect(out.firstWhere((e) => e.id == 'a').severity, 5);
    expect(out.firstWhere((e) => e.id == 'b').severity, 1);
  });

  test('severity levels', () {
    SideEffectEntry at(int sev) => SideEffectsData.fromSymptoms([
      sym('a', DateTime(2026, 11, 14), severity: sev),
    ], {}).single;
    expect(at(1).level, SideEffectSeverityLevel.mild);
    expect(at(2).level, SideEffectSeverityLevel.mild);
    expect(at(3).level, SideEffectSeverityLevel.moderate);
    expect(at(4).level, SideEffectSeverityLevel.severe);
    expect(at(5).severityLabel, 'Severe (5/5)');
  });

  test('countThisMonth counts only the current month', () {
    final entries = SideEffectsData.fromSymptoms([
      sym('a', DateTime(2026, 11, 1)),
      sym('b', DateTime(2026, 11, 30, 23, 59)),
      sym('c', DateTime(2026, 10, 31, 23, 59)),
      sym('d', DateTime(2025, 11, 14)),
    ], {});
    expect(
      SideEffectsData.countThisMonth(entries, now: DateTime(2026, 11, 14)),
      2,
    );
    expect(
      SideEffectsData.countThisMonth(const [], now: DateTime(2026, 11, 14)),
      0,
    );
  });
}
