import 'package:flutter/material.dart';

/// ============================================================
/// ASSISTANT CHAT DATA
///
/// Med Assistant Chat Thread ke labels, seed thread aur
/// suggested prompts. HTML design ke exact values yahan se aate hain.
///
/// TODO Backend:
/// Seed thread, AI replies aur chat history Firestore se aayenge;
/// abhi dummy thread + canned reply hai.
/// ============================================================

/// Chat message ka role.
enum AssistantMessageRole { assistant, user }

/// Dose status pill ka kind (TAKEN / PENDING / MISSED).
enum AssistantPillKind { taken, pending, missed }

/// Suggested query chip ka kind (icon color mapping screen par).
enum AssistantPromptKind { sideEffects, streak, nextDose }

/// Ek chat message — seed thread ya runtime user/assistant reply.
class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.text,
    required this.time,
    this.boldSegment,
    this.stats,
    this.insight,
  });

  final AssistantMessageRole role;
  final String text;
  final String time;

  /// HTML `<strong>` jaisa bold phrase (dynamic assistant reply).
  final String? boldSegment;

  /// Assistant bubble ke andar pills + note block.
  final AssistantStats? stats;

  /// Message ke neeche sparkline insight card.
  final AssistantInsight? insight;
}

/// Stats block: status pills + nested clinical note.
class AssistantStats {
  const AssistantStats({
    required this.pills,
    required this.noteLead,
    required this.noteHighlight,
    required this.noteTail,
  });

  final List<AssistantStatPill> pills;
  final String noteLead;
  final String noteHighlight;
  final String noteTail;
}

/// Ek status pill — label HTML jaisa uppercase ("12 TAKEN").
class AssistantStatPill {
  const AssistantStatPill({required this.label, required this.kind});

  final String label;
  final AssistantPillKind kind;
}

/// Quick insight card (title + subtitle; sparkline screen par).
class AssistantInsight {
  const AssistantInsight({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

/// Suggested query chip.
class AssistantPrompt {
  const AssistantPrompt(this.kind);

  final AssistantPromptKind kind;
}

extension AssistantPromptLabels on AssistantPromptKind {
  String get label => switch (this) {
        AssistantPromptKind.sideEffects => 'Metformin side effects?',
        AssistantPromptKind.streak => 'Show my streak',
        AssistantPromptKind.nextDose => 'When is my next dose?',
      };

  /// Chip tap par input se send hone wala poora sawaal.
  String get prompt => switch (this) {
        AssistantPromptKind.sideEffects => 'What are Metformin side effects?',
        AssistantPromptKind.streak => 'Show my adherence streak',
        AssistantPromptKind.nextDose => 'When is my next dose scheduled?',
      };

  IconData get icon => switch (this) {
        AssistantPromptKind.sideEffects => Icons.medication,
        AssistantPromptKind.streak => Icons.local_fire_department,
        AssistantPromptKind.nextDose => Icons.schedule,
      };
}

/// Screen ke saare static labels.
class AssistantChatData {
  const AssistantChatData._();

  static const String screenTitle = 'Med Assistant Chat Thread';
  static const String statusText = 'Online · Answers from your own data';
  static const String todayLabel = 'Today';
  static const String suggestedLabel = 'Suggested queries';
  static const String cautionText =
      'Answers drawn directly from your logged logs & schedules.';
  static const String disclaimer =
      'Not professional medical advice. Always consult your physician.';
  static const String inputHint = 'Ask about your medicine or log...';

  static const List<AssistantPrompt> prompts = [
    AssistantPrompt(AssistantPromptKind.sideEffects),
    AssistantPrompt(AssistantPromptKind.streak),
    AssistantPrompt(AssistantPromptKind.nextDose),
  ];
}
