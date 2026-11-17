import 'community_content_filter.dart';
import 'community_models.dart';

/// Checks a user's input before it is sent, with the same rules as
/// `firestore.rules`, so the screen can show a clear message instead of a
/// "permission denied". M19 step 1.
enum CommunityInputError {
  empty,
  tooShort,
  tooLong,
  badCharacters,
  containsContact,

  /// Abusive wording (see [CommunityContentFilter.isAbusive]).
  inappropriate,
}

class CommunityValidator {
  CommunityValidator._();

  static final RegExp _pseudonym = RegExp(r'^[A-Za-z0-9_.-]+$');

  /// null = fine.
  static CommunityInputError? pseudonym(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return CommunityInputError.empty;
    if (s.length < CommunityLimits.pseudonymMin) {
      return CommunityInputError.tooShort;
    }
    if (s.length > CommunityLimits.pseudonymMax) {
      return CommunityInputError.tooLong;
    }
    if (!_pseudonym.hasMatch(s)) return CommunityInputError.badCharacters;
    if (containsContact(s)) return CommunityInputError.containsContact;
    if (CommunityContentFilter.isAbusive(s)) {
      return CommunityInputError.inappropriate;
    }
    return null;
  }

  static CommunityInputError? bio(String? raw) {
    final s = (raw ?? '').trim();
    if (s.length > CommunityLimits.bioMax) return CommunityInputError.tooLong;
    if (containsContact(s)) return CommunityInputError.containsContact;
    if (CommunityContentFilter.isAbusive(s)) {
      return CommunityInputError.inappropriate;
    }
    return null;
  }

  static final RegExp _email = RegExp(r'[^\s@]+@[^\s@]+');
  static final RegExp _link = RegExp(r'(https?:|www\.)', caseSensitive: false);

  /// True when [text] looks like an email, a web link or a phone number
  /// (7 or more digits, ignoring spaces and dashes). This is a friendly check
  /// on the phone only; the rules cannot do it.
  static bool containsContact(String text) {
    if (_email.hasMatch(text) || _link.hasMatch(text)) return true;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7;
  }

  static CommunityInputError? postBody(String? raw) =>
      _body(raw, CommunityLimits.postBodyMax);

  static CommunityInputError? commentBody(String? raw) =>
      _body(raw, CommunityLimits.commentBodyMax);

  static CommunityInputError? _body(String? raw, int max) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return CommunityInputError.empty;
    if (s.length > max) return CommunityInputError.tooLong;
    return null;
  }
}
