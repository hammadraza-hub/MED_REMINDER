/// Second safety layer: checks what the AI answered. M18 step 3.
///
/// Even with good rules a model can slip. If its reply tells the person to
/// change a dose, stop or skip a medicine, or states a diagnosis, the reply is
/// NOT shown; a safe message is shown instead. Every shown reply carries the
/// short "not medical advice" reminder.
class AiReplyChecker {
  AiReplyChecker._();

  static RegExp _r(String p) => RegExp(p, caseSensitive: false, unicode: true);

  /// The AI telling the person what to do with a medicine.
  static final List<RegExp> _doseAdvice = [
    _r(
      r"\b(you (should|can|could|may|might|need to|must|have to)|i (recommend|suggest|advise)( that)? you|"
      r"it('s| is) (safe|fine|okay|ok|alright) (for you )?to|try to|go ahead and|feel free to|"
      r"consider)\s+(stop|quit|discontinue|skip|double|triple|increase|decrease|reduce|"
      r"lower|raise|halve|delay|take (two|2|three|3|more|extra|double|another|less|half)|"
      r"cut)\b",
    ),
    // An order at the start of a sentence: "Increase your dose to ...".
    _r(
      r"(^|[.!?] ?)(increase|double|triple|reduce|lower|decrease|raise|adjust|"
      r"change) (your|the) (dose|dosage)\b",
    ),
    // Only an order at the start of a sentence ("Stop taking it."), not
    // "Please do not stop taking it".
    _r(r"(^|[.!?] ?)(stop|quit|discontinue) taking (your|the|this|it)\b"),
    _r(r"\btake (an )?(extra|additional|another) (dose|pill|tablet|capsule)\b"),
  ];

  /// The AI stating a diagnosis.
  static final List<RegExp> _diagnosisClaim = [
    _r(
      r"\b(you (likely|probably|definitely|certainly|may well) have|"
      r"you (have|are suffering from|are diagnosed with)|"
      r"this (is|looks like|sounds like|seems to be|could be|might be)|"
      r"it('s| is) (likely|probably|possibly))\s+(an? )?([a-z\-]+ ){0,2}"
      r"(infection|cancer|diabetes|allergy|allergic reaction|disease|syndrome|"
      r"disorder|tumou?r|eczema|psoriasis|hypertension|heart attack|stroke|"
      r"pneumonia|arthritis|anemia|anaemia|depression)\b",
    ),
    _r(r"\bthe diagnosis is\b|\bi (can )?diagnose\b"),
  ];

  /// True when [reply] must not be shown.
  static bool isUnsafe(String reply) {
    final text = reply.replaceAll(RegExp(r'\s+'), ' ');
    for (final p in _doseAdvice) {
      if (p.hasMatch(text)) return true;
    }
    for (final p in _diagnosisClaim) {
      if (p.hasMatch(text)) return true;
    }
    return false;
  }

  /// The text to show: [safeFallback] when the reply is unsafe, otherwise the
  /// reply with [disclaimer] added at the end (once).
  static String finalize(
    String reply, {
    required String disclaimer,
    required String safeFallback,
  }) {
    final trimmed = reply.trim();
    if (trimmed.isEmpty || isUnsafe(trimmed)) {
      return '$safeFallback\n\n$disclaimer';
    }
    if (trimmed.contains(disclaimer)) return trimmed;
    return '$trimmed\n\n$disclaimer';
  }
}
