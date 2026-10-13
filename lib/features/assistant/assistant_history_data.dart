// ============================================================
// ASSISTANT CHAT HISTORY DATA
//
// Chat History Screen ke labels aur past thread list.
// HTML design ke exact values yahan se aate hain.
//
// TODO Backend:
// Threads Firestore se aayenge (userId + memberId scoped);
// abhi dummy list hai.
// ============================================================

/// Ek past conversation thread — title, preview aur date.
class AssistantChatThread {
  const AssistantChatThread({
    required this.title,
    required this.preview,
    required this.dateLabel,
  });

  /// Thread ka headline (first question se bana title).
  final String title;

  /// Pehle message ka chhota preview.
  final String preview;

  /// Right side date label ("Today", "Yesterday", "Mon, 15 Sep").
  final String dateLabel;
}

/// Screen ke saare static labels + seed thread list.
class AssistantHistoryData {
  const AssistantHistoryData._();

  static const String screenTitle = 'Chat History';
  static const String newChatLabel = '+ Start New Chat';
  static const String sectionLabel = 'Past conversations';
  static const String footerHint = 'Tap a conversation to continue it';
  static const String secureNote =
      'Conversations stored securely on your device';

  /// TODO Backend:
  /// User ki Firestore chat history se load hoga.
  static const List<AssistantChatThread> threads = [
    AssistantChatThread(
      title: 'Metformin side effects & timing',
      preview: 'You asked about nausea after doses...',
      dateLabel: 'Today',
    ),
    AssistantChatThread(
      title: 'Missed doses this week',
      preview: '12 of 14 doses taken — 1 missed...',
      dateLabel: 'Yesterday',
    ),
    AssistantChatThread(
      title: 'Vitamin interactions',
      preview: 'Whether Vitamin D3 interacts with Metformin...',
      dateLabel: 'Mon, 15 Sep',
    ),
    AssistantChatThread(
      title: 'Refill planning',
      preview: 'When to order the next Metformin refill...',
      dateLabel: 'Fri, 12 Sep',
    ),
  ];
}
