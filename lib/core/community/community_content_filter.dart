/// A basic text check before a post, comment or bio is sent. M19 step 6.
///
/// It only helps on the phone: anybody who bypasses the app is not stopped by
/// it, and a word list can be wrong both ways. Real protection is reports,
/// blocks and moderators (step 7).
enum CommunityVerdict {
  /// Nothing found.
  ok,

  /// Medicine advice that can hurt ("stop taking your insulin"). The user is
  /// warned and may still post.
  medicalWarning,

  /// The text may be about hurting oneself. The user gets a caring message
  /// with a way to find help, and may still post.
  selfHarm,

  /// An e-mail address or a web link (private details). Not posted.
  contact,

  /// Abuse or hate. Not posted.
  abusive,
}

class CommunityContentFilter {
  CommunityContentFilter._();

  /// The most serious finding in [text] ([CommunityVerdict.ok] if none).
  /// Order: abusive, contact, selfHarm, medicalWarning.
  static CommunityVerdict check(String text) {
    final lower = text.toLowerCase();
    final tokens = _tokens(lower);

    if (_hasAbuse(lower, tokens)) return CommunityVerdict.abusive;
    if (_email.hasMatch(text) || _link.hasMatch(text)) {
      return CommunityVerdict.contact;
    }
    if (_selfHarm.any((r) => r.hasMatch(lower)) ||
        _selfHarmWords.any(lower.contains)) {
      return CommunityVerdict.selfHarm;
    }
    if (_medical.any((r) => r.hasMatch(lower))) {
      return CommunityVerdict.medicalWarning;
    }
    return CommunityVerdict.ok;
  }

  /// True when abuse is found (used for names and bios too).
  static bool isAbusive(String text) {
    final lower = text.toLowerCase();
    return _hasAbuse(lower, _tokens(lower));
  }

  // ---------------------------------------------------------------- abuse

  /// Words are matched as whole words (so "class" or "assistant" never hit),
  /// after undoing common letter swaps ("sh1t", "f**k" -> "f  k" is not
  /// handled on purpose) and long repeats ("fuuuck").
  static List<String> _tokens(String lower) {
    final swapped = lower
        .replaceAll('\$', 's')
        .replaceAll('@', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('5', 's');
    final squeezed = swapped.replaceAllMapped(
      RegExp(r'(.)\1{2,}'),
      (m) => m[1]!,
    );
    return squeezed
        .split(RegExp(r'[^\p{L}\p{M}]+', unicode: true))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  static bool _hasAbuse(String lower, List<String> tokens) {
    final set = tokens.toSet();
    if (_abusiveWords.any(set.contains)) return true;
    return _abusivePhrases.any((r) => r.hasMatch(lower));
  }

  static const Set<String> _abusiveWords = {
    // English
    'fuck', 'fucker', 'fucking', 'motherfucker', 'shit', 'bullshit', 'bitch',
    'bastard', 'asshole', 'dickhead', 'cunt', 'slut', 'whore', 'retard',
    'retarded', 'nigger', 'nigga', 'faggot', 'moron',
    // Roman Urdu / Hindi
    'harami', 'haramzada', 'haramzadi', 'kutta', 'kutte', 'kutti', 'kameena',
    'kamina', 'kamine', 'chutiya', 'chutiye', 'madarchod', 'behenchod',
    'bhenchod', 'bhosdi', 'bhosdike', 'gandu', 'randi', 'lanat',
    // other languages
    'puta', 'puto', 'mierda', 'cabron', 'pendejo', 'merde', 'connard',
    'salope', 'putain', 'enculé',
    // Hindi / Urdu script
    'हरामी', 'कुत्ता', 'कमीना', 'चूतिया', 'मादरचोद', 'भेनचोद', 'रंडी',
    'حرامی', 'کتا', 'کمینہ', 'کتیا',
    // Arabic script
    'كلب', 'حقير', 'عاهرة',
  };

  static final List<RegExp> _abusivePhrases = [
    RegExp(r'\bkill\s+your\s*self\b'),
    RegExp(r'\bkys\b'),
    RegExp(r'\bgo\s+(and\s+)?die\b'),
    RegExp(r'\bhope\s+you\s+die\b'),
    RegExp(r'\bi\s*(will|ll|am\s+going\s+to)\s+kill\s+you\b'),
    RegExp(r'\bmar\s+ja(o)?\b'),
    RegExp(r'\bmarr?\s+jao?\s+tum\b'),
  ];

  // -------------------------------------------------------------- contact

  static final RegExp _email = RegExp(r'[^\s@]+@[^\s@]+\.[^\s@]+');
  static final RegExp _link = RegExp(
    r'(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|io|pk|in|co)\b)',
    caseSensitive: false,
  );

  // ------------------------------------------------------------ self-harm

  static final List<RegExp> _selfHarm = [
    RegExp(r'\bkill\s+(my\s*self|myself)\b'),
    RegExp(
      r'\b(want|wanna|going|plan(ning)?)\s+to\s+(die|end\s+(it|my\s+life))\b',
    ),
    RegExp(r'\bend(ing)?\s+my\s+life\b'),
    RegExp(r'\bhurt(ing)?\s+my\s*self\b'),
    RegExp(r'\bharm(ing)?\s+my\s*self\b'),
    RegExp(r"\b(don'?t|do\s+not|dont)\s+want\s+to\s+(live|be\s+alive)\b"),
    RegExp(r'\bno\s+reason\s+to\s+live\b'),
    RegExp(r'\bsuicid(e|al)\b'),
    RegExp(r'\bself[\s-]*harm\b'),
    RegExp(r'\bkhud\s*kushi\b'),
    RegExp(r'\bmar(na)?\s+chah(ta|ti)\s+(hu|hoon|hun)\b'),
    RegExp(r'\bjeena\s+nahi\s+chah(ta|ti)\b'),
    RegExp(r'\bsuicidio\b'),
    RegExp(r'\bme\s+quiero\s+morir\b'),
    RegExp(r'\bje\s+veux\s+mourir\b'),
  ];

  /// Script words that regex word-boundaries do not handle well.
  static const List<String> _selfHarmWords = [
    'आत्महत्या',
    'खुदकुशी',
    'خودکشی',
    'انتحار',
  ];

  // -------------------------------------------------------------- medical

  static final List<RegExp> _medical = [
    RegExp(
      r'\b(stop|quit|skip|miss)\s+(taking\s+)?(your|ur|the|all)\s+(meds?|medicines?|medications?|insulin|pills?|tablets?)\b',
    ),
    RegExp(r'\bstop\s+taking\s+(it|them|insulin|metformin)\b'),
    RegExp(
      r'\b(double|triple|increase)\s+(up\s+)?(your|the|ur)\s+(dose|dosage)\b',
    ),
    RegExp(
      r'\b(take|taking)\s+(double|twice|more)\s+(the\s+)?(dose|dosage|pills?)\b',
    ),
    RegExp(
      r"\b(don'?t|do\s+not|dont|no\s+need\s+to)\s+(see|visit|ask|call|consult)\s+(a\s+|your\s+|the\s+)?(doctor|pharmacist)\b",
    ),
    RegExp(
      r"\b(you\s+)?(don'?t|do\s+not|dont)\s+need\s+(a\s+|your\s+)?(doctor|medicine|medication|insulin)\b",
    ),
    RegExp(
      r'\binstead\s+of\s+(your\s+|the\s+)?(medicine|medication|insulin|doctor|pills?)\b',
    ),
    RegExp(
      r'\b(cure|cures|cured)\s+(for\s+|your\s+)?(diabetes|cancer|hypertension|high\s+blood\s+pressure)\b',
    ),
    RegExp(r'\bdawai\s+(band|chhod|chor)\b'),
    RegExp(r'\bdoctor\s+(ke\s+bagair|ke\s+baghair|ki\s+zaroorat\s+nahi)\b'),
    RegExp(r'\bdose\s+double\b'),
  ];
}
