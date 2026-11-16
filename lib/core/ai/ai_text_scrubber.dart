/// Cleans free text before it can go into the AI context. M18 step 2.
///
/// People type anything into a medicine's "instructions" or an allergy note:
/// "ask Dr Ahmed, 0300-1234567", "born 12/03/1990", an email, a link. None of
/// that may reach the AI. This removes it and shortens the text.
///
/// It is a safety net on top of the real protection (the context model simply
/// has no name / date of birth / email / phone fields).
class AiTextScrubber {
  AiTextScrubber._();

  static const String removed = '[removed]';

  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );

  static final RegExp _url = RegExp(
    r'(https?://|www\.)\S+',
    caseSensitive: false,
  );

  /// "born 12/03/1990", "DOB: 1990-03-12", "date of birth 12 March 1990".
  static final RegExp _birth = RegExp(
    r'\b(born|dob|d\.o\.b\.?|date\s+of\s+birth)\b[:\s\-]*[^,;\n]{0,24}',
    caseSensitive: false,
  );

  /// A phone number: 7 or more digits, with optional + ( ) - . and spaces
  /// between them.
  static final RegExp _phone = RegExp(r'\+?\d[\d\s().\-]{5,}\d');

  /// Any run of 6+ digits left over (ids, card numbers, ...).
  static final RegExp _digits = RegExp(r'\d{6,}');

  /// Removes personal details from [input], collapses spaces and cuts it to
  /// [maxLength] characters. Returns null for null / empty / blank input.
  static String? clean(String? input, {int maxLength = 120}) {
    if (input == null) return null;
    var s = input;

    s = s.replaceAll(_email, removed);
    s = s.replaceAll(_url, removed);
    s = s.replaceAll(_birth, removed);
    s = s.replaceAllMapped(_phone, (m) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '').length;
      // "10-20 mg" or "2 to 3" are not phone numbers.
      return digits >= 7 ? removed : m.group(0)!;
    });
    s = s.replaceAll(_digits, removed);

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty) return null;

    if (s.length > maxLength) {
      s = '${s.substring(0, maxLength - 1).trimRight()}…';
    }
    return s;
  }
}
