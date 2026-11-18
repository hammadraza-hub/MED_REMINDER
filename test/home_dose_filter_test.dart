import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_time.dart';
import 'package:med_remind_app/features/home/home_dose_filter.dart';
import 'package:med_remind_app/models/dose.dart';

Dose d(String id, DoseStatus status) {
  final at = DateTime(2026, 11, 18, 8);
  return Dose(
    id: id,
    profileId: 'p',
    medicationId: 'm',
    medName: 'M',
    doseLabel: 'x',
    scheduledAt: at,
    missDeadline: at.add(const Duration(minutes: 30)),
    status: status,
    createdAt: at,
  );
}

void main() {
  final all = [
    d('m_1', DoseStatus.pending),
    d('m_2', DoseStatus.taken),
    d('m_3', DoseStatus.missed),
    d('m_4', DoseStatus.skipped),
    d('m_5', DoseStatus.snoozed),
    d('m_prn_6', DoseStatus.taken),
  ];

  List<String> ids(HomeFilter f) =>
      HomeDoseFilter.apply(all, f).map((e) => e.id).toList();

  test('all: every scheduled dose, never an as-needed one', () {
    expect(ids(HomeFilter.all), ['m_1', 'm_2', 'm_3', 'm_4', 'm_5']);
  });

  test('pending: pending, snoozed and missed (still to do)', () {
    expect(ids(HomeFilter.pending), ['m_1', 'm_3', 'm_5']);
  });

  test('taken: only taken, not the as-needed one', () {
    expect(ids(HomeFilter.taken), ['m_2']);
  });

  test('skipped doses show under All only', () {
    expect(ids(HomeFilter.pending).contains('m_4'), isFalse);
    expect(ids(HomeFilter.taken).contains('m_4'), isFalse);
    expect(ids(HomeFilter.all).contains('m_4'), isTrue);
  });

  test('empty list stays empty', () {
    for (final f in HomeFilter.values) {
      expect(HomeDoseFilter.apply(const [], f), isEmpty);
    }
  });

  group('dose time', () {
    final morning = DateTime(2026, 11, 18, 8, 30);
    final noon = DateTime(2026, 11, 18, 12, 0);
    final midnight = DateTime(2026, 11, 18, 0, 5);
    final evening = DateTime(2026, 11, 18, 20, 5);

    Future<MaterialLocalizations> loc(String code) =>
        GlobalMaterialLocalizations.delegate.load(Locale(code));

    test('English 12-hour', () async {
      final l = await loc('en');
      String f(DateTime t) => formatDoseTimeWith(l, t, use24Hour: false);
      expect(f(morning), '8:30 AM');
      expect(f(noon), '12:00 PM');
      expect(f(midnight), '12:05 AM');
      expect(f(evening), '8:05 PM');
    });

    test('24-hour setting', () async {
      final l = await loc('en');
      String f(DateTime t) => formatDoseTimeWith(l, t, use24Hour: true);
      expect(f(morning), '08:30');
      expect(f(evening), '20:05');
      expect(f(midnight), '00:05');
    });

    test('other languages follow their own convention', () async {
      final ar = await loc('ar');
      expect(formatDoseTimeWith(ar, evening, use24Hour: false), '8:05 م');
      expect(formatDoseTimeWith(ar, morning, use24Hour: false), '8:30 ص');
      // Spanish and French write the clock their own way (24 h style).
      final es = await loc('es');
      expect(formatDoseTimeWith(es, evening, use24Hour: false), '20:05');
      final fr = await loc('fr');
      expect(formatDoseTimeWith(fr, morning, use24Hour: false), '08:30');
    });
  });
}
