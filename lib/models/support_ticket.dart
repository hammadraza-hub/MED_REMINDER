/// ============================================================
/// SUPPORT TICKET — M13 step 5
///
/// A request written to `supportTickets/{id}` from the Help screen.
/// The limits below mirror `validTicketCreate()` in firestore.rules —
/// keep them in sync.
///
/// Pure logic (no Firebase imports) so it is easy to unit test.
/// ============================================================

library;

/// Result of checking the form before sending.
enum TicketValidation {
  ok,
  subjectEmpty,
  subjectTooLong,
  bodyEmpty,
  bodyTooLong,
}

class SupportTicket {
  const SupportTicket({
    required this.uid,
    required this.subject,
    required this.body,
    required this.appVersion,
    required this.device,
    this.locale,
  });

  static const int maxSubject = 120;
  static const int maxBody = 2000;
  static const int maxAppVersion = 40;
  static const int maxDevice = 120;

  final String uid;
  final String subject;
  final String body;
  final String appVersion;
  final String device;
  final String? locale;

  /// Checks the user-typed fields (whitespace is trimmed first).
  static TicketValidation validate(String subject, String body) {
    final s = subject.trim();
    final b = body.trim();
    if (s.isEmpty) return TicketValidation.subjectEmpty;
    if (s.length > maxSubject) return TicketValidation.subjectTooLong;
    if (b.isEmpty) return TicketValidation.bodyEmpty;
    if (b.length > maxBody) return TicketValidation.bodyTooLong;
    return TicketValidation.ok;
  }

  /// Builds a ticket from raw form values: trims text and clamps the
  /// auto-collected fields to the rule limits so they can never make the
  /// write fail.
  factory SupportTicket.fromForm({
    required String uid,
    required String subject,
    required String body,
    required String appVersion,
    required String device,
    String? locale,
  }) {
    String clamp(String v, int max) => v.length > max ? v.substring(0, max) : v;
    return SupportTicket(
      uid: uid,
      subject: subject.trim(),
      body: body.trim(),
      appVersion: clamp(appVersion, maxAppVersion),
      device: clamp(device, maxDevice),
      locale: (locale != null && locale.isNotEmpty && locale.length <= 10)
          ? locale
          : null,
    );
  }

  /// Firestore fields (the repository adds `createdAt` as server time).
  Map<String, Object> toMap() => <String, Object>{
        'uid': uid,
        'subject': subject,
        'body': body,
        'appVersion': appVersion,
        'device': device,
        'locale': ?locale,
        'status': 'open',
      };
}
