/// First safety layer of the AI assistant. M18 step 3.
///
/// Looks at what the user typed BEFORE it goes to the AI. Three kinds of
/// question never reach the model; the app answers with a fixed, safe message
/// instead (it also works offline and costs nothing):
///
/// * [AiSafetyCategory.emergency]  — chest pain, overdose, can't breathe,
///   suicidal thoughts... -> "call emergency services".
/// * [AiSafetyCategory.doseChange] — double a dose, skip, stop, take more or
///   less -> "your doctor or pharmacist decides this".
/// * [AiSafetyCategory.diagnosis]  — "what is this rash", "do I have cancer"
///   -> "I can't diagnose; see a doctor".
///
/// Everything else is allowed and goes to the model, whose own system prompt
/// ([AiPromptRules]) repeats the same rules.
///
/// This is a keyword net (English, Spanish, French, Arabic, Hindi and Roman
/// Urdu/Hindi), the first wall, not the only one: the reply is checked again by
/// `AiReplyChecker`, and the 50+ prompt set in `test/data` must be run against
/// the real model once the server exists.
enum AiSafetyCategory { emergency, doseChange, diagnosis }

class AiSafetyGuard {
  AiSafetyGuard._();

  /// The category that must be answered by the app, or null when the question
  /// may go to the AI. Emergencies are checked first.
  static AiSafetyCategory? check(String message) {
    final text = _normalize(message);
    if (text.isEmpty) return null;

    if (_matches(_emergency, text)) return AiSafetyCategory.emergency;
    if (_matches(_doseChange, text)) return AiSafetyCategory.doseChange;
    if (_matches(_diagnosis, text)) return AiSafetyCategory.diagnosis;
    return null;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _matches(List<RegExp> patterns, String text) {
    for (final p in patterns) {
      if (p.hasMatch(text)) return true;
    }
    return false;
  }

  static RegExp _r(String pattern) => RegExp(pattern, unicode: true);

  // ------------------------------------------------------------
  // EMERGENCY
  // ------------------------------------------------------------
  static final List<RegExp> _emergency = [
    // English
    _r(r"chest (pain|tightness|pressure)|pain in (my )?chest"),
    _r(
      r"(can't|cannot|can not|unable to|struggling to|trouble) (breathe|breathing)|"
      r"difficulty breathing|short of breath|shortness of breath",
    ),
    _r(
      r"over ?dos|took too (many|much)|taken too (many|much)|"
      r"swallowed too (many|much)|ate too many (pills|tablets)",
    ),
    _r(
      r"suicid|kill myself|end my life|want to die|hurt myself|self[- ]?harm|"
      r"don't want to live|do not want to live",
    ),
    _r(
      r"unconscious|passed out|fainted|seizure|convulsion|"
      r"stroke|face (is )?drooping|slurred speech",
    ),
    _r(
      r"(severe|heavy|uncontrolled) bleeding|bleeding (a lot|heavily)|"
      r"coughing (up )?blood|vomiting blood",
    ),
    _r(
      r"anaphyla|throat (is )?(closing|swelling)|(face|lips|tongue) "
      r"(is |are )?swelling|swollen (face|lips|tongue)",
    ),
    _r(r"poison"),
    // Spanish
    _r(
      r"dolor (de|en el) pecho|no puedo respirar|me cuesta respirar|"
      r"sobredosis|quiero morir|suicid|me desmay|convulsion|ataque (al corazon|cardiaco)",
    ),
    // French
    _r(
      r"douleur (thoracique|dans la poitrine)|(ne )?peux pas respirer|"
      r"difficult[ée]s? (à|a) respirer|surdose|overdose|envie de mourir|"
      r"me suicider|suicid|[ée]vanou|convulsion|crise cardiaque",
    ),
    // Arabic
    _r(
      r"ألم في الصدر|ألم بالصدر|لا أستطيع التنفس|لا استطيع التنفس|"
      r"صعوبة في التنفس|جرعة زائدة|أريد أن أموت|اريد ان اموت|انتحار|"
      r"فقدت الوعي|إغماء|اغماء|تشنج|نوبة قلبية",
    ),
    // Hindi
    _r(
      r"सीने में दर्द|सांस नहीं|साँस नहीं|सांस लेने में तकलीफ|"
      r"ओवरडोज़?|ज़्यादा दवा खा|ज्यादा दवा खा|मरना चाहता|मरना चाहती|"
      r"आत्महत्या|बेहोश|दौरा पड़|दिल का दौरा",
    ),
    // Roman Urdu / Hindi
    _r(
      r"seene (mein|me|main) dard|chest mein dard|saans? nahi|sans nahi|"
      r"saans (lene )?mein (dikkat|takleef)|overdose|zyada (dawai|dawa|goliyan|goli) "
      r"(kha|khaa|le) ?(li|lee|liya|lia)|marna chahta|marna chahti|khudkushi|"
      r"khud ?kushi|behosh|bayhosh|dil ka daura|daura pad",
    ),
  ];

  // ------------------------------------------------------------
  // DOSE CHANGE (start / stop / skip / more / less)
  // ------------------------------------------------------------
  static final List<RegExp> _doseChange = [
    // English
    _r(
      r"\b(double|triple|halve|quadruple)\b.{0,20}\b(dose|dosage|pill|tablet|medic|meds?|it)\b|\bdouble up\b",
    ),
    _r(
      r"\b(increase|raise|boost|up|lower|reduce|decrease|cut|change|adjust|alter|"
      r"modify)\b.{0,20}\b(the |my |his |her )?(dose|dosage|pills?|tablets?|"
      r"medicine|meds?|medication)\b",
    ),
    _r(
      r"\b(stop|quit|discontinue|come off|go off|give up)\b.{0,6}\b(taking|using)?\b"
      r".{0,6}\b(my|the|this|it|them|his|her)\b.{0,25}"
      r"\b(medic|pills?|tablets?|meds?|insulin|capsules?|dose|antibiotics?|"
      r"metformin|statin)",
    ),
    _r(r"\bstop (taking )?(it|them)\b"),
    _r(
      r"\bskip(ping)?\b.{0,25}\b(dose|doses|pill|pills|tablet|tablets|"
      r"capsule|medic|meds?)",
    ),
    _r(
      r"\btake (two|2|three|3|an? extra|extra|more|double|another|less|half|"
      r"a half|a double|fewer)\b",
    ),
    _r(r"\bhow (much|many) .{0,30}\b(should|can|do) i (take|use|have|give)\b"),
    _r(r"\b(what|which) (dose|dosage)\b.{0,20}\b(should|can|do) i\b"),
    _r(r"\b(more|extra) than (the )?(prescribed|recommended|usual)\b"),
    _r(r"\btaper (off|down)\b|\bwean (off|myself)\b"),
    // Spanish
    _r(
      r"(doble|duplicar|doblar|triplicar).{0,15}dosis|dosis doble|"
      r"(aumentar|subir|bajar|reducir|disminuir|cambiar|ajustar).{0,20}(la |mi )?dosis|"
      r"dejar de tomar|saltar(me)? (la |una |mi )?dosis|"
      r"tomar (dos|tres|mas|más|menos|media)",
    ),
    // French
    _r(
      r"doubler.{0,15}dose|double dose|"
      r"(augmenter|diminuer|r[ée]duire|changer|modifier|ajuster).{0,20}(la |ma )?dose|"
      r"arr[êe]ter (de prendre|mon|ma|mes|le traitement)|"
      r"sauter (une |ma |la )?(dose|prise)|prendre (deux|trois|plus|moins|la moiti[ée])",
    ),
    // Arabic
    _r(
      r"مضاعفة الجرعة|ضاعف الجرعة|زيادة الجرعة|زيادة جرعة|"
      r"(تقليل|تخفيض|إنقاص|انقاص) (من )?الجرعة|"
      r"(أوقف|اوقف|أتوقف|اتوقف|ترك|أترك|اترك) (عن )?(تناول )?(الدواء|الحبوب|العلاج)|"
      r"(تخطي|أتخطى|اتخطى|تفويت) (الجرعة|جرعة)|أخذ حبتين|اخذ حبتين",
    ),
    // Hindi
    _r(
      r"डोज़? दोगुन|खुराक दोगुन|खुराक बढ़ा|खुराक कम|डोज़? बढ़ा|डोज़? कम|"
      r"दवा बंद|दवा छोड़|दवाई बंद|दवाई छोड़|खुराक छोड़|दो गोली|ज़्यादा गोली|ज्यादा गोली|"
      r"आधी गोली",
    ),
    // Roman Urdu / Hindi
    _r(
      r"dose (double|barha|badha|zyada|kam|badal|chhod|chod)|"
      r"(double|dugni|dugna) (dose|dawai|dawa|goli)|"
      r"(dawai|dawa|dawaiyan|goli|goliyan) (band|chhod|chod|kam|zyada|barha|badha|"
      r"badal)|(dawai|dawa|goli) (band|chhod|chod) (kar|kr)|"
      r"aadhi (goli|dawai|dawa)|ek ki jagah (do|2)|do (goli|goliyan)|"
      r"zyada (goli|goliyan|dawai|dawa) (le|lun|lu|len)|dose (skip|miss) kar",
    ),
  ];

  // ------------------------------------------------------------
  // DIAGNOSIS
  // ------------------------------------------------------------
  static final List<RegExp> _diagnosis = [
    // English
    _r(
      r"\bwhat('s| is| are)\b.{0,12}\b(this|that|these|those|the)\b.{0,12}"
      r"\b(rash|lump|mole|spot|spots|bump|bumps|swelling|pain|symptom|symptoms|"
      r"discharge|bruise|sore|growth|itch|itching)\b",
    ),
    _r(r"\bdo i have\b"),
    _r(
      r"\bam i (sick|ill|dying|having|suffering|diabetic|pregnant|infected)\b",
    ),
    _r(
      r"\bis (it|this|that)\b.{0,12}\b(cancer|cancerous|diabetes|an infection|"
      r"infected|serious|a tumou?r|a heart attack|a stroke|an allergy|"
      r"an allergic reaction|contagious|malignant|benign|fatal)\b",
    ),
    _r(r"\bwhat('s| is) wrong with me\b|\bwhat could (this|it) be\b"),
    _r(
      r"\bwhat (disease|illness|condition|infection|disorder|sickness) (do|have|am)\b",
    ),
    _r(r"\bdiagnos(e|is|ing)\b"),
    _r(
      r"\b(why|what) (am i|is my body) (feeling|getting|having)\b.{0,30}\b(pain|dizzy|tired|sick|weak)\b",
    ),
    _r(
      r"\bwhat does (my|this) (blood test|lab result|scan|x-?ray|mri|ecg|report) (mean|show)\b",
    ),
    // Spanish
    _r(
      r"qu[ée] es (esta|este|esa|ese) (erupci[oó]n|bulto|mancha|lunar|dolor|s[ií]ntoma)|"
      r"tengo (c[aá]ncer|diabetes|una infecci[oó]n)|qu[ée] enfermedad tengo|"
      r"qu[ée] me pasa|diagn[oó]stic|es (grave|c[aá]ncer)",
    ),
    // French
    _r(
      r"qu'est-ce que (cette|ce|c'est cette) (éruption|[ée]ruption|bosse|tache|grain de beaut[ée]|douleur)|"
      r"ai-je (un |le )?(cancer|diab[èe]te|une infection)|quelle maladie ai-je|"
      r"diagnostic|qu'est-ce que j'ai|c'est grave",
    ),
    // Arabic
    _r(
      r"ما هذا (الطفح|الورم|الكتلة|الألم|العرض)|ما هو هذا الطفح|"
      r"هل (لدي|عندي|أعاني من|اعاني من) (سرطان|سكري|عدوى|التهاب)|"
      r"شخص (حالتي|مرضي)|ما مرضي|ماذا أعاني|ماذا اعاني|هل هذا (خطير|سرطان)",
    ),
    // Hindi
    _r(
      r"यह (दाने|दाना|चकत्ते|गांठ|गाँठ|निशान|दर्द) क्या|क्या मुझे (कैंसर|डायबिटीज़?|शुगर|संक्रमण)|"
      r"मुझे कौन सी बीमारी|मुझे क्या बीमारी|निदान|क्या यह (गंभीर|कैंसर)",
    ),
    // Roman Urdu / Hindi
    _r(
      r"(ye|yeh|ya) (rash|daane|dane|gaanth|ganth|nishan|dard|lump|mole|sujan|soojan) "
      r"(kya|kia)|mujhe (kya|kia|konsi|kaun si) (bimari|bemari|beemari|disease)|"
      r"kya mujhe .{0,20}(hai|hay|ho gaya|hogaya)|kya (ye|yeh) (cancer|serious|khatarnak)|"
      r"meri (bimari|bemari) kya|tashkhees|tashkis",
    ),
  ];
}
