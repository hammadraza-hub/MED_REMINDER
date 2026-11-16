import '../../core/ai/chat_controller.dart';
import '../../l10n/app_localizations.dart';

/// Fills the chat's fixed sentences from the app's language. M18 step 6.
class ChatTextsL10n {
  ChatTextsL10n._();

  static ChatTexts of(AppLocalizations l10n) => ChatTexts(
    emergency: l10n.aiSafetyEmergency,
    doseChange: l10n.aiSafetyDoseChange,
    diagnosis: l10n.aiSafetyDiagnosis,
    replyBlocked: l10n.aiReplyBlocked,
    disclaimer: l10n.aiDisclaimer,
    aiUnavailable: l10n.aiChatUnavailable,
    labelUnavailable: l10n.aiChatLabelUnavailable,
    labelNotFound: (name) => l10n.aiChatLabelNotFound(name),
  );
}
