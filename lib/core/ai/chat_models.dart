import 'package:cloud_firestore/cloud_firestore.dart';

/// Limits that the security rules also enforce. M18 step 4.
class ChatLimits {
  ChatLimits._();

  static const int maxTitleLength = 80;
  static const int maxTextLength = 4000;

  /// A thread is read with this many messages at most; the chat screen should
  /// start a new thread after this many.
  static const int maxMessagesPerThread = 200;

  /// The history list shows this many threads at most.
  static const int maxThreads = 50;
}

enum ChatRole {
  user,
  assistant;

  static ChatRole fromString(String? value) =>
      value == 'assistant' ? ChatRole.assistant : ChatRole.user;
}

/// One conversation: users/{uid}/chatThreads/{id}.
class ChatThread {
  const ChatThread({
    required this.id,
    required this.profileId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChatThread.fromMap(String id, Map<String, dynamic> map) {
    final created = _date(map['createdAt']);
    return ChatThread(
      id: id,
      profileId: (map['profileId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      createdAt: created,
      // A just-written server time can still be null on this device.
      updatedAt: _date(map['updatedAt'], fallback: created),
    );
  }
}

/// One message: users/{uid}/chatThreads/{id}/messages/{id}.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  bool get isUser => role == ChatRole.user;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      role: ChatRole.fromString(map['role'] as String?),
      text: (map['text'] as String?) ?? '',
      createdAt: _date(map['createdAt']),
    );
  }
}

DateTime _date(Object? raw, {DateTime? fallback}) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return fallback ?? DateTime.now();
}
