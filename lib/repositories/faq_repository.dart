import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/faq_item.dart';

/// Reads the FAQ from `config/faq` (M13 step 4) so it can be edited from the
/// Firebase console without an app release.
///
/// Never throws: any failure (offline, missing document, permission) returns
/// an empty list and the Help screen keeps showing the FAQ bundled in the app.
class FaqRepository {
  FaqRepository._();
  static final FaqRepository instance = FaqRepository._();

  static const Duration _timeout = Duration(seconds: 8);

  /// Last successful server FAQ per language, kept for this app session so
  /// reopening Help shows it instantly (no flash of the bundled FAQ).
  final Map<String, List<FaqItem>> _cache = {};

  /// Cached server FAQ for [languageCode], or null if none loaded yet.
  List<FaqItem>? cached(String languageCode) => _cache[languageCode];

  Future<List<FaqItem>> getFaq(String languageCode) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('config')
          .doc('faq')
          .get()
          .timeout(_timeout);
      if (!snap.exists) {
        debugPrint('FaqRepository: config/faq does not exist → bundled FAQ');
        return const [];
      }
      final data = snap.data();
      final raw = data?['items'];
      final items = FaqItem.parseDoc(data, languageCode);
      debugPrint(
        'FaqRepository: config/faq found — '
        'items field: ${raw is List ? 'array of ${raw.length}' : raw.runtimeType}, '
        'usable items ($languageCode): ${items.length}',
      );
      if (items.isNotEmpty) _cache[languageCode] = items;
      return items;
    } catch (e) {
      debugPrint('FaqRepository: could not load FAQ, using bundled — $e');
      return const [];
    }
  }
}
