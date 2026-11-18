import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/dose_zone.dart';

void main() {
  setUpAll(DoseZone.ensureData);

  Future<String?> phone(String? name) async => name;

  group('DoseZone.forProfile', () {
    test('a real IANA name is used', () async {
      final z = await DoseZone.forProfile('America/New_York');
      expect(z.name, 'America/New_York');
    });

    test('an old abbreviation ("PKT", "EST") is not a zone: the phone zone is used', () async {
      for (final old in ['PKT', 'EST', 'GMT+5', 'garbage']) {
        final z = await DoseZone.forProfile(
          old,
          phone: () => phone('Asia/Karachi'),
        );
        expect(z.name, 'Asia/Karachi', reason: old);
      }
    });

    test('missing, empty or blank: the phone zone', () async {
      for (final none in [null, '', '   ']) {
        final z = await DoseZone.forProfile(
          none,
          phone: () => phone('Europe/London'),
        );
        expect(z.name, 'Europe/London');
      }
    });

    test('the profile zone wins over the phone zone', () async {
      final z = await DoseZone.forProfile(
        'Australia/Sydney',
        phone: () => phone('Asia/Karachi'),
      );
      expect(z.name, 'Australia/Sydney');
    });

    test('nothing usable at all: UTC (never an exception)', () async {
      final a = await DoseZone.forProfile('PKT', phone: () => phone(null));
      final b = await DoseZone.forProfile(null, phone: () => phone('nonsense'));
      for (final z in [a, b]) {
        expect(z.name, anyOf('UTC', 'Etc/UTC'));
        expect(z.currentTimeZone.offset, Duration.zero);
      }
    });

    test('a failing phone lookup is survived', () async {
      final z = await DoseZone.forProfile(
        null,
        phone: () async => throw StateError('no plugin'),
      );
      expect(z.currentTimeZone.offset, Duration.zero);
    });
  });

  group('the phone zone', () {
    test(
      'cannot be read in a plain test (no plugin): null, not an exception',
      () async {
        expect(await DoseZone.phoneZoneName(), isNull);
        expect(await DoseZone.phoneZoneNameOrUtc(), 'UTC');
      },
    );
  });
}
