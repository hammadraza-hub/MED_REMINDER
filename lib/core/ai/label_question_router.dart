import 'fda_label.dart';
import 'fda_label_client.dart';

/// One of the user's active medicines (what the router needs).
class ChatMed {
  const ChatMed({required this.name, this.rxcui});

  final String name;
  final String? rxcui;
}

/// A question the official FDA label can answer.
class LabelQuestion {
  const LabelQuestion({required this.med, required this.section});

  final ChatMed med;
  final FdaLabelSection section;
}

/// Decides whether a chat question is "what does the FDA label say about
/// one of my medicines": side effects, uses, warnings, interactions...
/// Those are answered from the label (with its source) without any AI, which
/// works on the Spark plan. M18 step 6.
///
/// Keyword based, in English, Spanish, French, Arabic, Hindi and Roman Urdu.
/// A question about the dose is never routed here (the guard stops it
/// before, and the dosage section is not read anyway).
class LabelQuestionRouter {
  LabelQuestionRouter._();

  static LabelQuestion? route(String message, List<ChatMed> meds) {
    final text = message.toLowerCase();
    final section = _section(text);
    if (section == null || meds.isEmpty) return null;

    // The medicine named in the question.
    for (final med in meds) {
      final key = _key(med);
      if (key != null && text.contains(key)) {
        return LabelQuestion(med: med, section: section);
      }
    }

    // "What are the side effects?" with a single medicine on the list.
    if (meds.length == 1) {
      return LabelQuestion(med: meds.first, section: section);
    }
    return null;
  }

  /// First word of the generic name ("Metformin 500 MG" -> "metformin").
  static String? _key(ChatMed med) {
    final g = FdaQuery.genericName(med.name);
    if (g == null) return null;
    final first = g.split(' ').first;
    return first.length >= 3 ? first : null;
  }

  static FdaLabelSection? _section(String t) {
    for (final entry in _rules) {
      for (final p in entry.$2) {
        if (p.hasMatch(t)) return entry.$1;
      }
    }
    return null;
  }

  static RegExp _r(String p) => RegExp(p, unicode: true);

  // Order matters: the first matching section wins.
  static final List<(FdaLabelSection, List<RegExp>)> _rules = [
    (
      FdaLabelSection.boxedWarning,
      [_r(r'boxed warning|black box|advertencia en recuadro')],
    ),
    (
      FdaLabelSection.adverseReactions,
      [
        _r(r'side[- ]?effects?|adverse (reaction|effect)|nuksan|nuqsan'),
        _r(r'efectos? (secundarios?|adversos?)'),
        _r(r'effets? (secondaires?|ind[ée]sirables?)'),
        _r(r'الآثار الجانبية|اعراض جانبية|الاعراض الجانبية|الأعراض الجانبية'),
        _r(r'दुष्प्रभाव|साइड इफेक्ट|साइड इफ़ेक्ट'),
      ],
    ),
    (
      FdaLabelSection.interactions,
      [
        _r(r'interact|take (it )?with|mix (it )?with|together with'),
        _r(r'interacci[oó]n|interacciones'),
        _r(r'interaction|interactions m[ée]dicamenteuses'),
        _r(r'تفاعل'),
        _r(r'परस्पर क्रिया|इंटरेक्शन|साथ लेना'),
      ],
    ),
    (
      FdaLabelSection.contraindications,
      [
        _r(r'contraindicat|who should not|when not to|should not take'),
        _r(r'contraindicaci[oó]n'),
        _r(r'contre-indication'),
        _r(r'موانع الاستعمال|موانع الاستخدام'),
        _r(r'प्रतिनिर्देश|किसे नहीं'),
      ],
    ),
    (
      FdaLabelSection.warnings,
      [
        _r(r'warnings?|precautions?|\bcareful\b|ehtiyat|khatr'),
        _r(r'advertencias?|precauciones'),
        _r(r'avertissements?|pr[ée]cautions'),
        _r(r'تحذيرات|تحذير|احتياطات'),
        _r(r'चेतावनी|सावधानी'),
      ],
    ),
    (
      FdaLabelSection.storage,
      [
        _r(r'\bstor(e|age)\b|how to keep|\bfridge\b|refrigerat'),
        _r(r'almacen|conservar|guardar'),
        _r(r'conservation|conserver|stockage'),
        _r(r'تخزين|حفظ'),
        _r(r'भंडारण|कैसे रखें'),
      ],
    ),
    (
      FdaLabelSection.indications,
      [
        _r(
          r'used for|what is .{1,40} for\b|what does .{1,40} (do|treat)|\buses? of\b|what.s .{1,40} for\b',
        ),
        _r(r'kis (liye|kaam|cheez)|kya kaam'),
        _r(r'para qu[ée] sirve|para qu[ée] se usa'),
        _r(r'[àa] quoi sert|pour quoi'),
        _r(r'ما استخدام|لماذا يستخدم|ما فائدة|ما هو استخدام'),
        _r(r'किस लिए|किसलिए|किस काम'),
      ],
    ),
  ];
}
