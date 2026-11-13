/// ============================================================
/// APP PREFERENCES — M13 step 3
///
/// Language + accessibility preferences stored in
/// `users/{uid}.settings` so they follow the user across devices:
///
///   settings.language        'en' | 'es' | 'fr' | 'ar' | 'hi'
///   settings.textSizeIndex   0..3
///   settings.highContrast    bool
///   settings.simplifiedMode  bool
///   settings.voiceInput      bool
///
/// A null field means "not set" (on the server: never saved; in a
/// diff: unchanged). Pure data + logic, no Firebase imports.
///
/// NOTE: these live in the same `settings` map as the notification
/// preferences, so they must always be written with dotted field paths
/// (`settings.language`), never by replacing the whole map.
/// ============================================================
class AppPreferences {
  const AppPreferences({
    this.language,
    this.textSizeIndex,
    this.highContrast,
    this.simplifiedMode,
    this.voiceInput,
  });

  final String? language;
  final int? textSizeIndex;
  final bool? highContrast;
  final bool? simplifiedMode;
  final bool? voiceInput;

  bool get isEmpty =>
      language == null &&
      textSizeIndex == null &&
      highContrast == null &&
      simplifiedMode == null &&
      voiceInput == null;

  /// Reads the `settings` map of a user document. Unknown / wrongly typed
  /// values are ignored (treated as "not set"), never thrown on.
  factory AppPreferences.fromSettingsMap(Map<String, dynamic>? m) {
    if (m == null) return const AppPreferences();
    final lang = m['language'];
    final size = m['textSizeIndex'];
    return AppPreferences(
      language: (lang is String && lang.trim().isNotEmpty) ? lang : null,
      textSizeIndex: size is num ? size.toInt() : null,
      highContrast: m['highContrast'] is bool ? m['highContrast'] as bool : null,
      simplifiedMode:
          m['simplifiedMode'] is bool ? m['simplifiedMode'] as bool : null,
      voiceInput: m['voiceInput'] is bool ? m['voiceInput'] as bool : null,
    );
  }

  /// Firestore `update()` payload using dotted paths, so only these
  /// fields are touched and sibling keys (notification settings) survive.
  Map<String, Object> toFieldUpdates() {
    return <String, Object>{
      'settings.language': ?language,
      'settings.textSizeIndex': ?textSizeIndex,
      'settings.highContrast': ?highContrast,
      'settings.simplifiedMode': ?simplifiedMode,
      'settings.voiceInput': ?voiceInput,
    };
  }

  /// Fields of `this` that differ from [base] (others become null).
  /// Used to push only what the user actually changed.
  AppPreferences changedFrom(AppPreferences base) {
    return AppPreferences(
      language: language != base.language ? language : null,
      textSizeIndex: textSizeIndex != base.textSizeIndex ? textSizeIndex : null,
      highContrast: highContrast != base.highContrast ? highContrast : null,
      simplifiedMode:
          simplifiedMode != base.simplifiedMode ? simplifiedMode : null,
      voiceInput: voiceInput != base.voiceInput ? voiceInput : null,
    );
  }

  /// Fields set on [remote] win; otherwise keep this value.
  AppPreferences overlay(AppPreferences remote) {
    return AppPreferences(
      language: remote.language ?? language,
      textSizeIndex: remote.textSizeIndex ?? textSizeIndex,
      highContrast: remote.highContrast ?? highContrast,
      simplifiedMode: remote.simplifiedMode ?? simplifiedMode,
      voiceInput: remote.voiceInput ?? voiceInput,
    );
  }

  /// First-sync seeding: the fields where the server has nothing
  /// ([remote] null) but this (local) value differs from the app default,
  /// i.e. the user really customised it on this device. Defaults are never
  /// seeded, so a fresh device cannot overwrite another device's choice.
  AppPreferences seedFor({
    required AppPreferences remote,
    required AppPreferences defaults,
  }) {
    return AppPreferences(
      language: remote.language == null && language != defaults.language
          ? language
          : null,
      textSizeIndex:
          remote.textSizeIndex == null && textSizeIndex != defaults.textSizeIndex
              ? textSizeIndex
              : null,
      highContrast:
          remote.highContrast == null && highContrast != defaults.highContrast
              ? highContrast
              : null,
      simplifiedMode: remote.simplifiedMode == null &&
              simplifiedMode != defaults.simplifiedMode
          ? simplifiedMode
          : null,
      voiceInput: remote.voiceInput == null && voiceInput != defaults.voiceInput
          ? voiceInput
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.language == language &&
      other.textSizeIndex == textSizeIndex &&
      other.highContrast == highContrast &&
      other.simplifiedMode == simplifiedMode &&
      other.voiceInput == voiceInput;

  @override
  int get hashCode => Object.hash(
        language,
        textSizeIndex,
        highContrast,
        simplifiedMode,
        voiceInput,
      );

  @override
  String toString() =>
      'AppPreferences(language: $language, textSizeIndex: $textSizeIndex, '
      'highContrast: $highContrast, simplifiedMode: $simplifiedMode, '
      'voiceInput: $voiceInput)';
}
