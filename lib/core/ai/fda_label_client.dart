import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'fda_label.dart';

/// Where looked-up labels are kept between app starts.
abstract class FdaLabelCache {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In memory only (tests, and the first layer of the app cache).
class MemoryFdaLabelCache implements FdaLabelCache {
  final Map<String, String> _map = {};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

/// Turns a medicine name into something safe to put in an openFDA query.
class FdaQuery {
  FdaQuery._();

  static const int maxWords = 3;

  static const Set<String> _noise = {
    'mg',
    'mcg',
    'ug',
    'g',
    'ml',
    'iu',
    'unit',
    'units',
    'oral',
    'tablet',
    'tablets',
    'capsule',
    'capsules',
    'syrup',
    'solution',
    'suspension',
    'injection',
    'cream',
    'ointment',
    'gel',
    'drops',
    'extended',
    'release',
    'er',
    'xr',
    'sr',
    'dr',
    'film',
    'coated',
    'chewable',
    'powder',
    'for',
    'topical',
    'ophthalmic',
    'inhaler',
    'spray',
    'patch',
    'and',
    'of',
    'per',
    'hr',
    'hour',
  };

  /// "Metformin 500 MG Oral Tablet" -> "metformin"; null when nothing is left.
  /// Only letters, digits-free words and hyphens survive, so a name can never
  /// add anything to the query ("x\" OR \"y" -> "x or y").
  static String? genericName(String? name) {
    if (name == null) return null;
    final words = name
        .toLowerCase()
        .replaceAll(RegExp(r'\([^)]*\)|\[[^\]]*\]'), ' ')
        .split(RegExp(r'[^a-z\-]+'))
        .map((w) => w.replaceAll(RegExp(r'^-+|-+$'), ''))
        .where((w) => w.length >= 2 && !_noise.contains(w))
        .take(maxWords)
        .toList();
    if (words.isEmpty) return null;
    return words.join(' ');
  }

  /// Salt / ester words that do not make a different ingredient
  /// ("metformin hydrochloride" is still metformin).
  static const Set<String> _salts = {
    'hydrochloride',
    'hcl',
    'sodium',
    'potassium',
    'calcium',
    'magnesium',
    'sulfate',
    'sulphate',
    'maleate',
    'mesylate',
    'tartrate',
    'succinate',
    'acetate',
    'citrate',
    'phosphate',
    'besylate',
    'fumarate',
    'bromide',
    'chloride',
    'nitrate',
    'hydrobromide',
    'dihydrate',
    'monohydrate',
    'anhydrous',
    'trihydrate',
  };

  /// The ingredients of a product name, as a comparable key:
  /// "METFORMIN HYDROCHLORIDE" and "Metformin 500 MG Oral Tablet" are both
  /// "metformin"; "Sitagliptin And Metformin" is "metformin sitagliptin".
  static String? ingredientKey(String? name) {
    final g = genericName(name);
    if (g == null) return null;
    final words = g.split(' ').where((w) => !_salts.contains(w)).toList()
      ..sort();
    return words.isEmpty ? null : words.join(' ');
  }

  /// The openFDA search for a generic name. For a single ingredient,
  /// combination products ("... and ...") are left out, so Metformin does not
  /// return a sitagliptin + metformin label.
  static String searchByName(String generic) {
    final single = !generic.contains(' ');
    return 'openfda.generic_name:"$generic"'
        '${single ? ' AND NOT openfda.generic_name:and' : ''}';
  }

  /// Only digits are valid in an RxNorm id.
  static String? rxcui(String? rxcui) {
    final r = rxcui?.trim();
    if (r == null || r.isEmpty) return null;
    return RegExp(r'^\d{1,12}$').hasMatch(r) ? r : null;
  }
}

/// Looks up a medicine's FDA label on openFDA (free, no key, public).
///
/// Only the medicine's id or name is sent: nothing about the person.
/// Order: by RxNorm id first (exact product), then by generic name (the
/// bundled catalogue often holds ingredient-level ids that openFDA does not
/// index). Found labels are cached for [labelTtl], "no label" for
/// [notFoundTtl]; failures are never cached. Never throws.
class FdaLabelClient {
  FdaLabelClient({
    http.Client? client,
    FdaLabelCache? cache,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 10),
    this.labelTtl = const Duration(days: 7),
    this.notFoundTtl = const Duration(days: 1),
  }) : _client = client ?? http.Client(),
       _cache = cache ?? MemoryFdaLabelCache(),
       _clock = clock ?? DateTime.now;

  final http.Client _client;
  final FdaLabelCache _cache;
  final DateTime Function() _clock;
  final Duration timeout;
  final Duration labelTtl;
  final Duration notFoundTtl;

  static const String host = 'api.fda.gov';
  static const String path = '/drug/label.json';

  /// How many labels are read per query; the fullest one is used.
  static const int candidates = 3;

  Future<FdaLookupResult> lookup({String? rxcui, String? name}) async {
    final id = FdaQuery.rxcui(rxcui);
    final generic = FdaQuery.genericName(name);
    if (id == null && generic == null) return const FdaLabelNotFound();

    final key = 'fda:${id ?? ''}:${generic ?? ''}';
    final cached = await _fromCache(key);
    if (cached != null) return cached;

    // (search, ingredient the label must match; null = the id is exact)
    final searches = <(String, String?)>[
      if (id != null) ('openfda.rxcui:"$id"', null),
      if (generic != null)
        (FdaQuery.searchByName(generic), FdaQuery.ingredientKey(generic)),
    ];

    for (final (search, ingredient) in searches) {
      final r = await _query(search, ingredient: ingredient);
      switch (r) {
        case FdaLabelFound():
          await _toCache(key, r);
          return r;
        case FdaLabelUnavailable():
          // No point trying the next query while offline / rate limited.
          return r;
        case FdaLabelNotFound():
          continue;
      }
    }

    const nf = FdaLabelNotFound();
    await _toCache(key, nf);
    return nf;
  }

  Future<FdaLookupResult> _query(String search, {String? ingredient}) async {
    final uri = Uri.https(host, path, {
      'search': search,
      'limit': '$candidates',
    });

    http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      return const FdaLabelUnavailable('timeout');
    } catch (_) {
      return const FdaLabelUnavailable('network');
    }

    if (response.statusCode == 404) return const FdaLabelNotFound();
    if (response.statusCode == 429) {
      return const FdaLabelUnavailable('rate limit');
    }
    if (response.statusCode != 200) {
      return FdaLabelUnavailable('http ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return const FdaLabelUnavailable('bad response');
      final results = decoded['results'];
      if (results is! List || results.isEmpty) return const FdaLabelNotFound();

      FdaLabel? best;
      for (final r in results) {
        if (r is! Map<String, dynamic>) continue;
        final label = FdaLabel.fromOpenFda(r);
        if (label == null) continue;
        // A wrong medicine is worse than none: by name, only the same
        // ingredient(s) count (not "sitagliptin and metformin" for metformin).
        if (ingredient != null &&
            FdaQuery.ingredientKey(label.genericName) != ingredient) {
          continue;
        }
        if (best == null || label.sections.length > best.sections.length) {
          best = label;
        }
      }
      return best == null ? const FdaLabelNotFound() : FdaLabelFound(best);
    } catch (_) {
      return const FdaLabelUnavailable('bad response');
    }
  }

  // ------------------------------------------------------------
  // cache
  // ------------------------------------------------------------

  Future<FdaLookupResult?> _fromCache(String key) async {
    try {
      final raw = await _cache.read(key);
      if (raw == null) return null;
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final at = DateTime.tryParse('${m['at']}');
      if (at == null) return null;
      final age = _clock().difference(at);

      if (m['nf'] == true) {
        return age < notFoundTtl ? const FdaLabelNotFound() : null;
      }
      if (age >= labelTtl) return null;
      final label = m['label'];
      if (label is! Map<String, dynamic>) return null;
      return FdaLabelFound(FdaLabel.fromJson(label));
    } catch (e) {
      debugPrint('FdaLabelClient: cache read failed — $e');
      return null;
    }
  }

  Future<void> _toCache(String key, FdaLookupResult r) async {
    try {
      final at = _clock().toIso8601String();
      final value = switch (r) {
        FdaLabelFound(:final label) => jsonEncode({
          'at': at,
          'label': label.toJson(),
        }),
        FdaLabelNotFound() => jsonEncode({'at': at, 'nf': true}),
        FdaLabelUnavailable() => null,
      };
      if (value != null) await _cache.write(key, value);
    } catch (e) {
      debugPrint('FdaLabelClient: cache write failed — $e');
    }
  }
}
