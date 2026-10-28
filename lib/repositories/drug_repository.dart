import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/drug.dart';

/// Drug Repository — provides autocomplete + lookup for medications.
///
/// M4 — Drug Catalog & Label Scan
///
/// Phase A (Spark plan — current):
///   • Loads drugs from bundled JSON asset (assets/data/drugs.json)
///   • Prefix search on name + synonyms (in-memory, instant)
///   • Lookup by RxCUI
///   • Search by drug class (for allergy matching)
///
/// Phase B (Blaze plan — future):
///   • Will query Firestore drugs/{rxcui} (populated by syncRxnorm Cloud Function)
///   • Direct API calls to RxNav REST (https://rxnav.nlm.nih.gov/REST/) for full info
class DrugRepository {
  static DrugRepository? _instance;
  static DrugRepository get instance => _instance ??= DrugRepository._();

  DrugRepository._();

  final List<Drug> _drugs = [];
  bool _loaded = false;

  /// Loads drugs from bundled JSON asset (one-time, cached in memory).
  Future<void> _loadFromAsset() async {
    if (_loaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/drugs.json');
      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      _drugs.clear();
      _drugs.addAll(
        jsonList.map((e) => Drug.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      // Asset not found or malformed JSON — continue with empty list.
      // (drugs.json will be created in Step 3)
      _drugs.clear();
    } finally {
      _loaded = true; // Don't retry on every call
    }
  }

  /// Search drugs by prefix (autocomplete).
  ///
  /// Returns up to [limit] matches (default 15).
  /// Matches on name, nameLower, or any synonym.
  ///
  /// Usage in UI:
  ///   final results = await DrugRepository.instance.searchDrugs('metf');
  ///   → returns [Metformin 500 MG, Metformin 850 MG, Metformin 1000 MG, ...]
  Future<List<Drug>> searchDrugs(String prefix, {int limit = 15}) async {
    await _loadFromAsset();
    if (prefix.trim().isEmpty) return [];

    final q = prefix.toLowerCase();
    final results = <Drug>[];

    for (final drug in _drugs) {
      if (drug.matchesPrefix(q)) {
        results.add(drug);
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Get a specific drug by its RxCUI.
  /// Returns null if not found.
  Future<Drug?> getDrugByRxcui(String rxcui) async {
    await _loadFromAsset();
    for (final drug in _drugs) {
      if (drug.rxcui == rxcui) return drug;
    }
    return null;
  }

  /// Search drugs by drug class (e.g., "Penicillins", "Sulfonamides").
  ///
  /// Used by Add Allergy screen to suggest class-level allergies.
  /// If user searches "penicil", returns all drugs in Penicillins class.
  Future<List<Drug>> searchByClass(String className, {int limit = 15}) async {
    await _loadFromAsset();
    if (className.trim().isEmpty) return [];

    final c = className.toLowerCase();
    final results = <Drug>[];

    for (final drug in _drugs) {
      if (drug.isInClass(c)) {
        results.add(drug);
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Get all drugs (mostly for testing / debugging).
  Future<List<Drug>> getAllDrugs() async {
    await _loadFromAsset();
    return List.unmodifiable(_drugs);
  }

  /// Total number of loaded drugs.
  Future<int> get drugCount async {
    await _loadFromAsset();
    return _drugs.length;
  }

  /// Reload drugs from asset (rarely needed — for debugging/admin).
  Future<void> reload() async {
    _loaded = false;
    await _loadFromAsset();
  }
}
