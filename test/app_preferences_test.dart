import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/models/app_preferences.dart';

void main() {
  const defaults = AppPreferences(
    language: 'en',
    textSizeIndex: 2,
    highContrast: false,
    simplifiedMode: true,
    voiceInput: true,
  );

  group('fromSettingsMap', () {
    test('reads valid values', () {
      final p = AppPreferences.fromSettingsMap({
        'language': 'hi',
        'textSizeIndex': 3,
        'highContrast': true,
        'simplifiedMode': false,
        'voiceInput': false,
        'doseEnabled': true, // notification key is ignored
      });
      expect(p.language, 'hi');
      expect(p.textSizeIndex, 3);
      expect(p.highContrast, true);
      expect(p.simplifiedMode, false);
      expect(p.voiceInput, false);
    });

    test('null map / missing keys -> not set', () {
      expect(AppPreferences.fromSettingsMap(null).isEmpty, isTrue);
      expect(AppPreferences.fromSettingsMap({}).isEmpty, isTrue);
      expect(
        AppPreferences.fromSettingsMap({'doseEnabled': true}).isEmpty,
        isTrue,
      );
    });

    test('wrong types are ignored, never thrown', () {
      final p = AppPreferences.fromSettingsMap({
        'language': 5,
        'textSizeIndex': 'big',
        'highContrast': 'yes',
        'simplifiedMode': 1,
        'voiceInput': null,
      });
      expect(p.isEmpty, isTrue);
    });

    test('blank language is not set; double index is truncated', () {
      final p = AppPreferences.fromSettingsMap(
        {'language': '  ', 'textSizeIndex': 2.0},
      );
      expect(p.language, isNull);
      expect(p.textSizeIndex, 2);
    });
  });

  group('toFieldUpdates', () {
    test('uses dotted paths and only set fields', () {
      const p = AppPreferences(language: 'es', voiceInput: false);
      expect(p.toFieldUpdates(), {
        'settings.language': 'es',
        'settings.voiceInput': false,
      });
    });

    test('empty -> no updates', () {
      expect(const AppPreferences().toFieldUpdates(), isEmpty);
    });
  });

  group('changedFrom', () {
    test('only differing fields', () {
      const base = AppPreferences(language: 'en', textSizeIndex: 2);
      const now = AppPreferences(language: 'hi', textSizeIndex: 2);
      final c = now.changedFrom(base);
      expect(c.language, 'hi');
      expect(c.textSizeIndex, isNull);
    });

    test('no change -> empty', () {
      expect(defaults.changedFrom(defaults).isEmpty, isTrue);
    });
  });

  group('overlay', () {
    test('remote values win, local fills gaps', () {
      const local = AppPreferences(language: 'en', textSizeIndex: 1);
      const remote = AppPreferences(language: 'ar');
      final o = local.overlay(remote);
      expect(o.language, 'ar');
      expect(o.textSizeIndex, 1);
    });
  });

  group('seedFor (first-sync seeding)', () {
    test('seeds customised local values the server lacks', () {
      const local = AppPreferences(
        language: 'hi',
        textSizeIndex: 3,
        highContrast: false,
        simplifiedMode: true,
        voiceInput: true,
      );
      final seed = local.seedFor(
        remote: const AppPreferences(),
        defaults: defaults,
      );
      expect(seed.language, 'hi');
      expect(seed.textSizeIndex, 3);
      // equal to defaults -> never seeded
      expect(seed.highContrast, isNull);
      expect(seed.simplifiedMode, isNull);
      expect(seed.voiceInput, isNull);
    });

    test('never overwrites what the server already has', () {
      const local = AppPreferences(language: 'hi', textSizeIndex: 3);
      final seed = local.seedFor(
        remote: const AppPreferences(language: 'es', textSizeIndex: 0),
        defaults: defaults,
      );
      expect(seed.isEmpty, isTrue);
    });

    test('fresh device (all defaults) seeds nothing', () {
      final seed = defaults.seedFor(
        remote: const AppPreferences(),
        defaults: defaults,
      );
      expect(seed.isEmpty, isTrue);
    });
  });
}
