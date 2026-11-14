import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';
import 'package:med_remind_app/core/vitals/vital_units.dart';

void main() {
  group('glucose', () {
    test('mg/dL stays as is (rounded to whole number for display)', () {
      expect(VitalUnits.glucoseToDisplay(95, GlucoseUnit.mgPerDl), 95);
      expect(VitalUnits.glucoseToDisplay(95.4, GlucoseUnit.mgPerDl), 95);
    });

    test('mg/dL -> mmol/L', () {
      expect(VitalUnits.glucoseToDisplay(99, GlucoseUnit.mmolPerL), 5.5);
      expect(VitalUnits.glucoseToDisplay(180, GlucoseUnit.mmolPerL), 10.0);
    });

    test('mmol/L -> canonical mg/dL', () {
      expect(VitalUnits.glucoseToCanonical(5.5, GlucoseUnit.mmolPerL), 99.1);
      expect(VitalUnits.glucoseToCanonical(7.0, GlucoseUnit.mmolPerL), 126.1);
      expect(VitalUnits.glucoseToCanonical(95, GlucoseUnit.mgPerDl), 95);
    });

    test(
      'typing a mmol/L value and showing it again gives the same number',
      () {
        for (final mmol in [3.9, 4.4, 5.5, 6.1, 7.8, 10.0, 13.9, 22.2]) {
          final stored = VitalUnits.glucoseToCanonical(
            mmol,
            GlucoseUnit.mmolPerL,
          );
          expect(
            VitalUnits.glucoseToDisplay(stored, GlucoseUnit.mmolPerL),
            mmol,
            reason: '$mmol mmol/L -> $stored mg/dL',
          );
        }
      },
    );
  });

  group('weight', () {
    test('kg -> lb', () {
      expect(VitalUnits.weightToDisplay(70, WeightUnit.lb), 154.3);
      expect(VitalUnits.weightToDisplay(72.4, WeightUnit.kg), 72.4);
    });

    test('lb -> canonical kg', () {
      expect(VitalUnits.weightToCanonical(154.3, WeightUnit.lb), 69.99);
      expect(VitalUnits.weightToCanonical(72.4, WeightUnit.kg), 72.4);
    });

    test('typing a lb value and showing it again gives the same number', () {
      for (final lb in [100.0, 132.5, 154.3, 180.0, 220.4, 301.0]) {
        final stored = VitalUnits.weightToCanonical(lb, WeightUnit.lb);
        expect(
          VitalUnits.weightToDisplay(stored, WeightUnit.lb),
          lb,
          reason: '$lb lb -> $stored kg',
        );
      }
    });
  });

  test('unit labels', () {
    expect(VitalUnits.glucoseUnitLabel(GlucoseUnit.mmolPerL), 'mmol/L');
    expect(VitalUnits.glucoseUnitLabel(GlucoseUnit.mgPerDl), 'mg/dL');
    expect(VitalUnits.weightUnitLabel(WeightUnit.lb), 'lb');
    expect(VitalUnits.weightUnitLabel(WeightUnit.kg), 'kg');
  });

  group('document ids', () {
    test('manual readings get no fixed id (Firestore makes one)', () {
      expect(VitalUnits.documentId(VitalSource.manual, null), isNull);
      expect(VitalUnits.documentId(VitalSource.manual, 'abc'), isNull);
    });

    test('synced readings use {source}_{externalId}', () {
      expect(
        VitalUnits.documentId(VitalSource.healthKit, 'ABC-123_x'),
        'healthkit_ABC-123_x',
      );
      expect(
        VitalUnits.documentId(VitalSource.healthConnect, 'rec42'),
        'health_connect_rec42',
      );
    });

    test('the same reading always gives the same id (no duplicates)', () {
      final a = VitalUnits.documentId(VitalSource.healthKit, '9F3A-77');
      final b = VitalUnits.documentId(VitalSource.healthKit, '9F3A-77');
      expect(a, b);
    });

    test('the same external id from two sources does not collide', () {
      expect(
        VitalUnits.documentId(VitalSource.healthKit, '1'),
        isNot(VitalUnits.documentId(VitalSource.healthConnect, '1')),
      );
    });

    test('characters that are illegal in a Firestore id are escaped', () {
      final id = VitalUnits.documentId(VitalSource.healthKit, 'a/b.c')!;
      expect(id.contains('/'), isFalse);
      expect(id.contains('.'), isFalse);
      expect(id, 'healthkit_a~2f;b~2e;c');
    });

    test(
      'different external ids never share an id, even with odd characters',
      () {
        final ids = {
          for (final e in ['a/b', 'a_b', 'a~b', 'a~2f;b', 'a b', 'a.b', 'A/B'])
            VitalUnits.documentId(VitalSource.healthKit, e),
        };
        expect(ids.length, 7);
      },
    );

    test('unicode external ids stay valid and distinct', () {
      final a = VitalUnits.documentId(VitalSource.healthConnect, 'دوا');
      final b = VitalUnits.documentId(VitalSource.healthConnect, 'दवा');
      expect(a, isNot(b));
      expect(a!.contains('/'), isFalse);
    });

    test('a sync reading without an external id is a programming error', () {
      expect(
        () => VitalUnits.documentId(VitalSource.healthKit, null),
        throwsArgumentError,
      );
      expect(
        () => VitalUnits.documentId(VitalSource.healthKit, '  '),
        throwsArgumentError,
      );
    });
  });
}
