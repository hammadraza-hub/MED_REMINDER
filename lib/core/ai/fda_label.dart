// FDA drug label data for the AI assistant. M18 step 5.
//
// openFDA (https://open.fda.gov) publishes the official US drug labels. The
// assistant may quote them, with a source, when it explains what a medicine
// is for, its warnings, side effects and interactions.
//
// The dosage section is deliberately NOT included: the assistant never
// advises on doses (see AiPromptRules, rule 1).

/// The label sections the assistant may use.
enum FdaLabelSection {
  boxedWarning('Boxed warning', ['boxed_warning']),
  indications('What it is used for', ['indications_and_usage']),
  contraindications('Do not use if', ['contraindications']),
  warnings('Warnings', ['warnings_and_cautions', 'warnings']),
  adverseReactions('Side effects', ['adverse_reactions']),
  interactions('Interactions', ['drug_interactions']),
  storage('Storage', ['storage_and_handling', 'how_supplied']);

  const FdaLabelSection(this.title, this.fieldKeys);

  /// Readable heading.
  final String title;

  /// openFDA fields, tried in this order (labels differ).
  final List<String> fieldKeys;

  static FdaLabelSection? byName(String name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// Makes a label field readable and short.
class FdaTextCleaner {
  FdaTextCleaner._();

  static const int defaultMaxChars = 700;

  static String clean(String raw, {int maxChars = defaultMaxChars}) {
    var s = raw;

    // Bullets and odd symbols -> plain text.
    s = s.replaceAll(RegExp('[•●▪·�]'), '- ');

    // "1 INDICATIONS AND USAGE ", "5 WARNINGS AND PRECAUTIONS N/A " at the start.
    s = s.replaceFirst(
      RegExp(
        r'^\s*\d+(\.\d+)*\s+[A-Z][A-Z &/,\-]{3,}?(?=\s+[A-Z][a-z]|\s+N/A|\s*$|\s+-)',
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'\bN/A\b'), '');

    // Cross references: "(5.1)", "( 5.1 , 5.2 )", "[see Warnings (5.1)]".
    // A "[see ...]" note that ends with a section number, with or without
    // its closing bracket (some labels forget it).
    s = s.replaceAll(
      RegExp(
        r'\[\s*see [^\]\[]*?\(\s*\d+(\.\d+)*(\s*,\s*\d+(\.\d+)*)*\s*\)\s*\]?',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'\[\s*see [^\]]*\]', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\(\s*\d+(\.\d+)*(\s*,\s*\d+(\.\d+)*)*\s*\)'), '');

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAllMapped(RegExp(r'\s+([.,;:])'), (m) => m[1]!);

    if (s.length <= maxChars) return s;
    return _truncate(s, maxChars);
  }

  /// Cuts at the end of a sentence if one is near the limit, else at a word.
  static String _truncate(String s, int maxChars) {
    final head = s.substring(0, maxChars);
    final lastStop = head.lastIndexOf(RegExp(r'[.!?](\s|$)'));
    if (lastStop >= maxChars * 0.5) {
      return head.substring(0, lastStop + 1);
    }
    final lastSpace = head.lastIndexOf(' ');
    final cut = lastSpace > 0 ? head.substring(0, lastSpace) : head;
    return '${cut.trimRight()}…';
  }
}

/// One drug label, reduced to what the assistant may use.
class FdaLabel {
  const FdaLabel({
    required this.setId,
    this.brandName,
    this.genericName,
    this.effectiveDate,
    required this.sections,
  });

  /// The label's id (links to DailyMed).
  final String setId;
  final String? brandName;
  final String? genericName;
  final DateTime? effectiveDate;

  /// Cleaned text per section; only sections the label has.
  final Map<FdaLabelSection, String> sections;

  String? get displayName => genericName ?? brandName;

  /// Public page of the label (DailyMed, US National Library of Medicine).
  String get sourceUrl =>
      'https://dailymed.nlm.nih.gov/dailymed/lookup.cfm?setid=$setId';

  /// "FDA drug label (openFDA) · Metformin · label date 2026-09-09".
  String get citation {
    final parts = ['FDA drug label (openFDA)'];
    final name = displayName;
    if (name != null) parts.add(name);
    final d = effectiveDate;
    if (d != null) parts.add('label date ${_day(d)}');
    return parts.join(' · ');
  }

  /// A block for the AI prompt / the chat: the chosen sections and the source.
  /// [only] limits it to some sections (all of them when null).
  String toPromptText({Set<FdaLabelSection>? only}) {
    final b = StringBuffer()..writeln('$citation:');
    for (final s in FdaLabelSection.values) {
      if (only != null && !only.contains(s)) continue;
      final text = sections[s];
      if (text == null || text.isEmpty) continue;
      b.writeln('- ${s.title}: $text');
    }
    b.write('Source: $sourceUrl');
    return b.toString();
  }

  Map<String, dynamic> toJson() => {
    'setId': setId,
    'brandName': brandName,
    'genericName': genericName,
    'effectiveDate': effectiveDate?.toIso8601String(),
    'sections': {for (final e in sections.entries) e.key.name: e.value},
  };

  factory FdaLabel.fromJson(Map<String, dynamic> json) {
    final sections = <FdaLabelSection, String>{};
    final raw = json['sections'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final s = FdaLabelSection.byName('${e.key}');
        if (s != null && e.value is String) sections[s] = e.value as String;
      }
    }
    return FdaLabel(
      setId: (json['setId'] as String?) ?? '',
      brandName: json['brandName'] as String?,
      genericName: json['genericName'] as String?,
      effectiveDate: DateTime.tryParse('${json['effectiveDate'] ?? ''}'),
      sections: sections,
    );
  }

  /// Builds a label from one openFDA `results[]` entry; null when it has
  /// nothing the assistant may use.
  static FdaLabel? fromOpenFda(
    Map<String, dynamic> result, {
    int maxChars = FdaTextCleaner.defaultMaxChars,
  }) {
    final sections = <FdaLabelSection, String>{};
    for (final s in FdaLabelSection.values) {
      for (final key in s.fieldKeys) {
        final text = _firstText(result[key]);
        if (text == null) continue;
        final cleaned = FdaTextCleaner.clean(text, maxChars: maxChars);
        if (cleaned.isNotEmpty) {
          sections[s] = cleaned;
          break;
        }
      }
    }
    if (sections.isEmpty) return null;

    final openfda = result['openfda'];
    String? first(String key) {
      if (openfda is! Map) return null;
      final v = openfda[key];
      if (v is List && v.isNotEmpty && v.first is String) {
        return _titleCase(v.first as String);
      }
      return null;
    }

    return FdaLabel(
      setId: (result['set_id'] as String?) ?? '',
      brandName: first('brand_name'),
      genericName: first('generic_name'),
      effectiveDate: _parseDate(result['effective_time']),
      sections: sections,
    );
  }

  static String? _firstText(Object? field) {
    if (field is List) {
      for (final v in field) {
        if (v is String && v.trim().isNotEmpty) return v;
      }
    } else if (field is String && field.trim().isNotEmpty) {
      return field;
    }
    return null;
  }

  /// openFDA dates look like "20260909".
  static DateTime? _parseDate(Object? raw) {
    final s = '$raw';
    if (s.length != 8) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(4, 6));
    final d = int.tryParse(s.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static String _titleCase(String s) {
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// The answer of a lookup. It never throws.
sealed class FdaLookupResult {
  const FdaLookupResult();
}

/// A label was found.
class FdaLabelFound extends FdaLookupResult {
  const FdaLabelFound(this.label);
  final FdaLabel label;
}

/// openFDA has no label for this medicine.
class FdaLabelNotFound extends FdaLookupResult {
  const FdaLabelNotFound();
}

/// The label could not be loaded now (offline, timeout, rate limit...).
class FdaLabelUnavailable extends FdaLookupResult {
  const FdaLabelUnavailable(this.reason);
  final String reason;
}
