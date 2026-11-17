import 'dart:math';

/// Suggests a friendly random pseudonym such as `calm_river42`, so the user
/// does not need to use a real name. M19 step 2.
class CommunityNameSuggester {
  CommunityNameSuggester._();

  static const List<String> _adjectives = [
    'calm',
    'brave',
    'kind',
    'quiet',
    'bright',
    'gentle',
    'steady',
    'sunny',
    'wise',
    'happy',
    'swift',
    'cosy',
  ];

  static const List<String> _nouns = [
    'river',
    'maple',
    'falcon',
    'meadow',
    'harbor',
    'willow',
    'comet',
    'pebble',
    'breeze',
    'lantern',
    'otter',
    'cedar',
  ];

  /// Always 3 to 24 characters from `[a-z0-9_]`, so it passes the rules.
  static String suggest([Random? random]) {
    final r = random ?? Random();
    final a = _adjectives[r.nextInt(_adjectives.length)];
    final n = _nouns[r.nextInt(_nouns.length)];
    final num = r.nextInt(90) + 10;
    return '${a}_$n$num';
  }
}

/// Preset avatars (no photo upload). The key is what is stored.
class CommunityAvatars {
  CommunityAvatars._();

  static const List<String> keys = [
    'a1',
    'a2',
    'a3',
    'a4',
    'a5',
    'a6',
    'a7',
    'a8',
    'a9',
    'a10',
    'a11',
    'a12',
  ];

  static const String fallback = 'a1';

  /// An unknown key (for example from a newer app version) shows [fallback].
  static String safe(String? key) => keys.contains(key) ? key! : fallback;
}
