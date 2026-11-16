// The part of the AI assistant that writes answers with a language model.
// M18 step 6.
//
// On the Spark plan there is no server, and an AI key must never be inside
// the app, so today the only implementation is [UnavailableAiBackend]. After
// the move to Blaze a `CloudFunctionAiBackend` (calling the `aiChat`
// function) is added and the screens do not change.

/// One earlier message, given to the model for context.
class AiChatTurn {
  const AiChatTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

sealed class AiBackendResult {
  const AiBackendResult();
}

/// The model's answer (still checked by `AiReplyChecker` before it is shown).
class AiBackendReply extends AiBackendResult {
  const AiBackendReply(this.text);
  final String text;
}

/// No model is available (not built yet, offline, over the daily limit...).
class AiBackendUnavailable extends AiBackendResult {
  const AiBackendUnavailable();
}

abstract class AiChatBackend {
  /// False when [send] can only answer "unavailable"; the chat then skips
  /// building the context.
  bool get isAvailable;

  Future<AiBackendResult> send({
    required String message,
    required List<AiChatTurn> history,
    required String context,
  });
}

/// Spark plan: there is no AI server yet.
class UnavailableAiBackend implements AiChatBackend {
  const UnavailableAiBackend();

  @override
  bool get isAvailable => false;

  @override
  Future<AiBackendResult> send({
    required String message,
    required List<AiChatTurn> history,
    required String context,
  }) async => const AiBackendUnavailable();
}
