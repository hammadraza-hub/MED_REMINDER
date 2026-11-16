import 'package:flutter/material.dart';

import '../../core/ai/ai_consent.dart';
import '../../core/services/ai_consent_service.dart';
import 'ai_consent_screen.dart';
import 'assistant_chat_screen.dart';

/// The only way into the AI assistant. M18 step 1.
///
/// Reads the saved consent first (fails closed). With consent the chat opens;
/// without it the consent screen is shown, and the chat opens only if the user
/// agrees.
Future<void> openAssistant(
  BuildContext context, {
  AiConsentController? consent,
  WidgetBuilder? chatBuilder,
}) async {
  final controller = consent ?? AiConsentService.instance;
  final navigator = Navigator.of(context);

  final allowed = await controller.ensure();

  var agreed = allowed;
  if (!allowed) {
    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => AiConsentScreen(controller: controller),
      ),
    );
    agreed = result == true;
  }

  if (!agreed) return;
  await navigator.push(
    MaterialPageRoute(
      builder: chatBuilder ?? (_) => const AssistantChatScreen(),
    ),
  );
}
