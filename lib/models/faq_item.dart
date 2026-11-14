/// ============================================================
/// FAQ ITEM — M13 step 4
///
/// One FAQ entry, built from the Firestore document `config/faq`:
///
///   items: [
///     { id: 'doseTime', order: 1,
///       q: { en: '...', hi: '...' },     // or a plain string
///       a: { en: '...', hi: '...' } },
///     ...
///   ]
///
/// Pure parsing logic (no Firebase imports) so it is easy to unit test.
/// ============================================================
class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;

  /// Picks the text for [languageCode]: that language, else English.
  /// [value] may be a plain string (same text for every language) or a
  /// `{languageCode: text}` map. Returns null when nothing usable exists.
  static String? _pick(Object? value, String languageCode) {
    if (value is String) {
      final t = value.trim();
      return t.isEmpty ? null : t;
    }
    if (value is Map) {
      for (final key in [languageCode, 'en']) {
        final v = value[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return null;
  }

  /// Parses the `config/faq` document data into a sorted list.
  ///
  /// - Items without a usable question or answer are skipped.
  /// - Sorted by numeric `order` (items without one keep their position,
  ///   after ordered ones).
  /// - A missing/invalid document yields an empty list, never throws; the
  ///   caller then falls back to the FAQ bundled in the app.
  static List<FaqItem> parseDoc(Map<String, dynamic>? data, String languageCode) {
    final raw = data?['items'];
    if (raw is! List) return const [];

    final entries = <({int index, num? order, FaqItem item})>[];
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      if (e is! Map) continue;
      final q = _pick(e['q'], languageCode);
      final a = _pick(e['a'], languageCode);
      if (q == null || a == null) continue;
      final id = e['id'] is String && (e['id'] as String).isNotEmpty
          ? e['id'] as String
          : 'faq_$i';
      entries.add((
        index: i,
        order: e['order'] is num ? e['order'] as num : null,
        item: FaqItem(id: id, question: q, answer: a),
      ));
    }

    entries.sort((x, y) {
      if (x.order != null && y.order != null) {
        final c = x.order!.compareTo(y.order!);
        return c != 0 ? c : x.index.compareTo(y.index);
      }
      if (x.order != null) return -1; // ordered before unordered
      if (y.order != null) return 1;
      return x.index.compareTo(y.index);
    });

    return [for (final e in entries) e.item];
  }
}
