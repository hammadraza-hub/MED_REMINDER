/// ============================================================
/// HELP & SUPPORT DATA — backend-ready
///
/// PURPOSE:
/// Settings → Help & Support screen ka static config (FAQ list,
/// support contact channels, app version).
///
/// IMPORTANT:
/// Display text yahan nahi rakhte — woh AppLocalizations (ARB) se
/// stable id ke through aata hai, taake language change effect ho.
///
/// Backend: actual support ticket submission backend phase mein
/// wire hoga; UI structure waisa hi rahega.
/// ============================================================
library;

class HelpSupportData {
  HelpSupportData._();

  /// FAQ items — stable localization ids (order = screen order).
  static const List<String> faqIds = [
    'doseTime',
    'reminder',
    'caregiverAlerts',
    'addMember',
  ];

  /// Support email (contact channels).
  static const String supportEmail = 'support@medremind.app';

  /// Support request email subject.
  static const String ticketSubject = 'MedRemind Support Request (v1.2.0)';
}
