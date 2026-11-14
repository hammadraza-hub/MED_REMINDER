import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/core/vitals/vital_models.dart';
import 'package:med_remind_app/core/vitals/vital_summary.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/core/vitals/vital_units.dart';

final _now = DateTime.utc(2026, 11, 14, 12);

VitalReading sync(
  String ext, {
  VitalKind kind = VitalKind.glucose,
  double value = 95,
  VitalSource source = VitalSource.healthKit,
  DateTime? at,
  double? value2,
}) => VitalReading(
  kind: kind,
  value: value,
  value2: value2,
  measuredAt: at ?? DateTime.utc(2026, 11, 14, 8),
  source: source,
  externalId: ext,
);

void main() {
  group('VitalReading map round trip', () {
    test('toCreateMap writes canonical fields only', () {
      final r = VitalReading(
        kind: VitalKind.bloodPressure,
        value: 120,
        value2: 80,
        pulse: 72,
        measuredAt: DateTime.utc(2026, 11, 14, 8),
        note: '  after walk  ',
      );
      final m = r.toCreateMap();
      expect(m['type'], 'bloodPressure');
      expect(m['value'], 120);
      expect(m['value2'], 80);
      expect(m['pulse'], 72);
      expect(m['unit'], 'mmHg');
      expect(m['source'], 'manual');
      expect(m['note'], 'after walk');
      expect(m.containsKey('externalId'), isFalse);
      expect(m.containsKey('createdBy'), isFalse); // repository adds it
      expect(m.containsKey('createdAt'), isFalse);
    });

    test('optional fields are left out when empty', () {
      final m = VitalReading(
        kind: VitalKind.weight,
        value: 72.4,
        measuredAt: DateTime.utc(2026),
        note: '   ',
      ).toCreateMap();
      expect(m.keys.toSet(), {'type', 'value', 'unit', 'measuredAt', 'source'});
    });

    test('sync reading keeps its externalId, manual never does', () {
      expect(sync('abc').toCreateMap()['externalId'], 'abc');
      final manual = VitalReading(
        kind: VitalKind.weight,
        value: 70,
        measuredAt: DateTime.utc(2026),
        externalId: 'leak',
      );
      expect(manual.toCreateMap().containsKey('externalId'), isFalse);
    });

    test('fromMap reads ints and doubles, source and ids', () {
      final r = VitalReading.fromMap('doc1', {
        'type': 'glucose',
        'value': 95,
        'unit': 'mg/dL',
        'measuredAt': DateTime.utc(2026, 11, 14, 8),
        'source': 'health_connect',
        'externalId': 'rec1',
        'createdBy': 'u1',
      })!;
      expect(r.id, 'doc1');
      expect(r.kind, VitalKind.glucose);
      expect(r.value, 95.0);
      expect(r.source, VitalSource.healthConnect);
      expect(r.externalId, 'rec1');
      expect(r.createdBy, 'u1');
    });

    test('unreadable documents give null instead of throwing', () {
      expect(VitalReading.fromMap('x', {'type': 'oxygen', 'value': 1, 'measuredAt': DateTime.utc(2026)}), isNull);
      expect(VitalReading.fromMap('x', {'type': 'weight', 'value': 'a', 'measuredAt': DateTime.utc(2026)}), isNull);
      expect(VitalReading.fromMap('x', {'type': 'weight', 'value': 70}), isNull);
      expect(VitalReading.fromMap('x', {}), isNull);
    });

    test('unknown source falls back to manual', () {
      final r = VitalReading.fromMap('x', {
        'type': 'weight', 'value': 70, 'measuredAt': DateTime.utc(2026), 'source': 'fitbit',
      })!;
      expect(r.source, VitalSource.manual);
    });
  });

  group('VitalSyncPlanner', () {
    test('new readings get the deterministic id and are written', () {
      final plan = VitalSyncPlanner.plan([sync('A1'), sync('A2')], {}, now: _now);
      expect(plan.toWrite.map((r) => r.id), ['healthkit_A1', 'healthkit_A2']);
      expect(plan.skippedExisting, 0);
      expect(plan.rejected, isEmpty);
    });

    test('ids that already exist are skipped (rules forbid rewriting them)', () {
      final plan = VitalSyncPlanner.plan(
        [sync('A1'), sync('A2')],
        {'healthkit_A1'},
        now: _now,
      );
      expect(plan.toWrite.map((r) => r.id), ['healthkit_A2']);
      expect(plan.skippedExisting, 1);
    });

    test('syncing the same data twice writes nothing the second time', () {
      final batch = [sync('A1'), sync('A2'), sync('A3')];
      final first = VitalSyncPlanner.plan(batch, {}, now: _now);
      final stored = {for (final r in first.toWrite) r.id!};
      final second = VitalSyncPlanner.plan(batch, stored, now: _now);
      expect(first.toWrite.length, 3);
      expect(second.toWrite, isEmpty);
      expect(second.skippedExisting, 3);
    });

    test('the same reading twice inside one batch is written once', () {
      final plan = VitalSyncPlanner.plan([sync('A1'), sync('A1')], {}, now: _now);
      expect(plan.toWrite.length, 1);
      expect(plan.duplicatesInBatch, 1);
    });

    test('the same external id from two sources is two different readings', () {
      final plan = VitalSyncPlanner.plan([
        sync('1'),
        sync('1', source: VitalSource.healthConnect),
      ], {}, now: _now);
      expect(plan.toWrite.length, 2);
    });

    test('invalid values are rejected with a reason, valid ones still go through', () {
      final plan = VitalSyncPlanner.plan([
        sync('ok'),
        sync('bad', value: 5000),
        sync('bp', kind: VitalKind.bloodPressure, value: 120), // diastolic missing
        sync('future', at: _now.add(const Duration(days: 1))),
      ], {}, now: _now);
      expect(plan.toWrite.map((r) => r.id), ['healthkit_ok']);
      expect(plan.rejected.length, 3);
      expect(plan.rejected.first.reason, contains('outOfRange'));
    });

    test('manual readings and missing external ids are rejected', () {
      final manual = VitalReading(kind: VitalKind.weight, value: 70, measuredAt: _now);
      final noExt = VitalReading(
        kind: VitalKind.weight,
        value: 70,
        measuredAt: _now,
        source: VitalSource.healthKit,
      );
      final plan = VitalSyncPlanner.plan([manual, noExt], {}, now: _now);
      expect(plan.toWrite, isEmpty);
      expect(plan.rejected.length, 2);
    });

    test('affected days list every (kind, local day) that changed once', () {
      final a = DateTime(2026, 11, 14, 8);
      final b = DateTime(2026, 11, 14, 20);
      final c = DateTime(2026, 11, 13, 9);
      final plan = VitalSyncPlanner.plan([
        sync('1', at: a),
        sync('2', at: b),
        sync('3', at: c),
        sync('4', kind: VitalKind.weight, value: 70, at: a),
      ], {}, now: DateTime(2026, 11, 15));
      expect(plan.affectedDays, {
        'glucose|2026-11-14',
        'glucose|2026-11-13',
        'weight|2026-11-14',
      });
    });

    test('skipped readings do not mark their day as affected', () {
      final plan = VitalSyncPlanner.plan(
        [sync('1')],
        {'healthkit_1'},
        now: _now,
      );
      expect(plan.affectedDays, isEmpty);
    });

    test('ids match VitalUnits.documentId', () {
      final plan = VitalSyncPlanner.plan([sync('a/b')], {}, now: _now);
      expect(plan.toWrite.single.id,
          VitalUnits.documentId(VitalSource.healthKit, 'a/b'));
    });
  });

  group('VitalAnalysis.dayBounds', () {
    test('covers one local calendar day', () {
      final b = VitalAnalysis.dayBounds('2026-11-14')!;
      expect(b.start, DateTime(2026, 11, 14));
      expect(b.end, DateTime(2026, 11, 15));
    });

    test('month and year rollover', () {
      expect(VitalAnalysis.dayBounds('2026-11-30')!.end, DateTime(2026, 12, 1));
      expect(VitalAnalysis.dayBounds('2026-12-31')!.end, DateTime(2027, 1, 1));
    });

    test('malformed keys give null', () {
      expect(VitalAnalysis.dayBounds('2026-1-1'), isNull);
      expect(VitalAnalysis.dayBounds('nonsense'), isNull);
      expect(VitalAnalysis.dayBounds(''), isNull);
    });
  });

  group('SymptomEntry', () {
    test('toCreateMap trims and leaves out empty optionals', () {
      final m = SymptomEntry(
        symptom: '  Nausea ',
        severity: 3,
        occurredAt: DateTime.utc(2026, 11, 14),
        notes: '   ',
        medicationId: '',
      ).toCreateMap();
      expect(m['symptom'], 'Nausea');
      expect(m['severity'], 3);
      expect(m.containsKey('notes'), isFalse);
      expect(m.containsKey('medicationId'), isFalse);
      expect(m.containsKey('createdBy'), isFalse);
    });

    test('medication link and notes are kept', () {
      final m = SymptomEntry(
        symptom: 'Dizzy',
        severity: 2,
        occurredAt: DateTime.utc(2026),
        medicationId: 'med1',
        notes: 'after dose',
      ).toCreateMap();
      expect(m['medicationId'], 'med1');
      expect(m['notes'], 'after dose');
    });

    test('fromMap round trip and unreadable documents', () {
      final e = SymptomEntry.fromMap('s1', {
        'symptom': 'Nausea',
        'severity': 4,
        'occurredAt': DateTime.utc(2026, 11, 14),
        'medicationId': 'med1',
        'createdBy': 'u1',
      })!;
      expect(e.id, 's1');
      expect(e.severity, 4);
      expect(e.medicationId, 'med1');
      expect(SymptomEntry.fromMap('x', {'symptom': 'a', 'severity': 'high', 'occurredAt': DateTime.utc(2026)}), isNull);
      expect(SymptomEntry.fromMap('x', {'severity': 3, 'occurredAt': DateTime.utc(2026)}), isNull);
      expect(SymptomEntry.fromMap('x', {}), isNull);
    });
  });
}
