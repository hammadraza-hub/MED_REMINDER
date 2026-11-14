import 'dart:convert';

/// ============================================================
/// EXPORT BUILDER — M14 step 1
///
/// Pure logic that turns a user's data into export files (JSON for
/// everything, CSV per collection). No Firebase / Flutter imports and no
/// file or network access, so it is fully unit-testable. Later steps feed it
/// data read from Firestore and zip/share the resulting files.
///
/// Input values must already be plain Dart types. `DateTime` is written as an
/// ISO-8601 UTC string; anything unknown falls back to `toString()` so a
/// surprise type can never break the export.
///
/// Output layout:
///   export-info.txt                         what is included, counts
///   user.json                               users/{uid}
///   profiles/{profileId}/profile.json       the profile document
///   profiles/{profileId}/{collection}.json  every document, as a JSON array
///   profiles/{profileId}/{collection}.csv   same data as a table
/// ============================================================

/// One Firestore document, relative to its profile
/// (e.g. `medications/abc` or `medications/abc/inventoryEvents/ev1`).
class ExportDoc {
  const ExportDoc({required this.path, required this.data});

  final String path;
  final Map<String, dynamic> data;

  String get id => path.split('/').last;
}

/// A profile the user owns plus its collections.
class ExportProfile {
  const ExportProfile({
    required this.profileId,
    required this.data,
    required this.collections,
  });

  final String profileId;

  /// The `profiles/{profileId}` document itself.
  final Map<String, dynamic> data;

  /// Collection name (e.g. `doses`, `inventoryEvents`) -> its documents.
  final Map<String, List<ExportDoc>> collections;
}

/// Everything to export.
class ExportBundle {
  const ExportBundle({
    required this.generatedAt,
    required this.appVersion,
    required this.userId,
    required this.userData,
    required this.profiles,
    this.notes = const [],
  });

  final DateTime generatedAt;
  final String appVersion;
  final String userId;

  /// The `users/{uid}` document.
  final Map<String, dynamic> userData;

  final List<ExportProfile> profiles;

  /// Extra lines for export-info.txt (e.g. "doses: could not be read").
  final List<String> notes;
}

/// One output file (text).
class ExportFile {
  const ExportFile({required this.name, required this.content});

  /// Path inside the ZIP, always with forward slashes.
  final String name;
  final String content;
}

class ExportBuilder {
  ExportBuilder._();

  /// Builds all export files for [bundle].
  static List<ExportFile> build(ExportBundle bundle) {
    final files = <ExportFile>[
      ExportFile(name: 'export-info.txt', content: _info(bundle)),
      ExportFile(name: 'user.json', content: toJson(bundle.userData)),
    ];

    final usedFolders = <String>{};
    for (final profile in bundle.profiles) {
      final folder = _uniqueFolder(safeName(profile.profileId), usedFolders);
      final base = 'profiles/$folder';

      files.add(
        ExportFile(name: '$base/profile.json', content: toJson(profile.data)),
      );

      final names = profile.collections.keys.toList()..sort();
      final usedNames = <String>{};
      for (final collection in names) {
        final docs = profile.collections[collection] ?? const <ExportDoc>[];
        final file = _uniqueFolder(safeName(collection), usedNames);
        files.add(
          ExportFile(
            name: '$base/$file.json',
            content: toJson([
              for (final d in docs) {'_path': d.path, ...d.data},
            ]),
          ),
        );
        files.add(ExportFile(name: '$base/$file.csv', content: toCsv(docs)));
      }
    }
    return files;
  }

  // ------------------------------------------------------------
  // JSON
  // ------------------------------------------------------------

  /// Pretty JSON with sorted keys (deterministic output).
  static String toJson(Object? value) {
    return const JsonEncoder.withIndent('  ').convert(_normalize(value));
  }

  static Object? _normalize(Object? v) {
    if (v == null || v is bool || v is String) return v;
    if (v is num) {
      // NaN / Infinity are not valid JSON.
      return (v is double && !v.isFinite) ? null : v;
    }
    if (v is DateTime) return v.toUtc().toIso8601String();
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      final byString = {for (final k in v.keys) k.toString(): v[k]};
      return {for (final k in keys) k: _normalize(byString[k])};
    }
    if (v is Iterable) return [for (final e in v) _normalize(e)];
    return v.toString();
  }

  // ------------------------------------------------------------
  // CSV
  // ------------------------------------------------------------

  /// RFC 4180 CSV: CRLF rows, header first. Columns are `_id`, `_path`, then
  /// the sorted union of all top-level keys. Nested maps/lists become a JSON
  /// string in their cell. Text that would be read as a spreadsheet formula
  /// (starts with = + - @ tab or CR) gets a leading apostrophe.
  static String toCsv(List<ExportDoc> docs) {
    final keys = <String>{};
    for (final d in docs) {
      keys.addAll(d.data.keys);
    }
    final columns = keys.toList()..sort();

    final rows = <String>[
      _csvRow([
        _guard('_id'),
        _guard('_path'),
        for (final c in columns) _guard(c),
      ]),
      for (final d in docs)
        _csvRow([
          _guard(d.id),
          _guard(d.path),
          for (final c in columns) _cell(d.data[c]),
        ]),
    ];
    return '${rows.join('\r\n')}\r\n';
  }

  /// Cell text. Only STRING values are checked for formula-looking text, so
  /// real numbers such as -5 stay numbers.
  static String _cell(Object? v) {
    final n = _normalize(v);
    if (n == null) return '';
    if (n is String) return _guard(n);
    if (n is bool || n is num) return n.toString();
    return jsonEncode(n); // map / list
  }

  /// Neutralises text a spreadsheet could run as a formula.
  static String _guard(String s) {
    if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) return "'$s";
    return s;
  }

  static String _csvRow(List<String> cells) => cells.map(_csvEscape).join(',');

  /// RFC 4180 quoting only (formula guarding is done before, per value).
  static String _csvEscape(String s) {
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ------------------------------------------------------------
  // Names
  // ------------------------------------------------------------

  /// File-system safe name: letters, digits, `_` and `-` only.
  static String safeName(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.isEmpty ? '_' : cleaned;
  }

  /// Avoids two entries ending up with the same name after sanitising.
  static String _uniqueFolder(String name, Set<String> used) {
    var candidate = name;
    var i = 2;
    while (!used.add(candidate)) {
      candidate = '${name}_$i';
      i++;
    }
    return candidate;
  }

  // ------------------------------------------------------------
  // export-info.txt
  // ------------------------------------------------------------

  static String _info(ExportBundle b) {
    final out = StringBuffer()
      ..writeln('MedRemind data export')
      ..writeln('Generated: ${b.generatedAt.toUtc().toIso8601String()}')
      ..writeln('App version: ${b.appVersion}')
      ..writeln('Account id: ${b.userId}')
      ..writeln()
      ..writeln('Files')
      ..writeln('- user.json: your account document')
      ..writeln(
        '- profiles/<id>/profile.json: each profile you own '
        '(${b.profiles.length} profile${b.profiles.length == 1 ? '' : 's'})',
      )
      ..writeln(
        '- profiles/<id>/<collection>.json and .csv: all records of a '
        'collection. In the CSV files, nested values are written as JSON.',
      )
      ..writeln('- Dates and times are in UTC (ISO 8601).')
      ..writeln();

    for (final p in b.profiles) {
      final name = p.data['name'];
      out.writeln('Profile ${p.profileId}${name is String ? ' ($name)' : ''}');
      final names = p.collections.keys.toList()..sort();
      for (final c in names) {
        out.writeln('  $c: ${p.collections[c]?.length ?? 0} record(s)');
      }
    }

    if (b.notes.isNotEmpty) {
      out
        ..writeln()
        ..writeln('Notes');
      for (final n in b.notes) {
        out.writeln('- $n');
      }
    }
    return out.toString();
  }
}
