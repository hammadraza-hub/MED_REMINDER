import 'package:flutter/foundation.dart';

import 'ai_chat_backend.dart';
import 'ai_reply_checker.dart';
import 'ai_safety_guard.dart';
import 'chat_models.dart';
import 'fda_label.dart';
import 'label_question_router.dart';

/// Where chats are kept (Firestore in the app: `ChatRepository`).
abstract class ChatStore {
  Future<String> createThread({
    required String profileId,
    required String firstQuestion,
  });

  Future<void> addMessage({
    required String threadId,
    required ChatRole role,
    required String text,
  });

  Future<List<ChatMessage>> loadMessages(String threadId);

  Future<List<ChatThread>> listThreads(String profileId);

  Future<void> deleteThread(String threadId);
}

/// The fixed sentences the chat itself writes (translated by the screen).
class ChatTexts {
  const ChatTexts({
    required this.emergency,
    required this.doseChange,
    required this.diagnosis,
    required this.replyBlocked,
    required this.disclaimer,
    required this.aiUnavailable,
    required this.labelUnavailable,
    required this.labelNotFound,
  });

  final String emergency;
  final String doseChange;
  final String diagnosis;
  final String replyBlocked;
  final String disclaimer;
  final String aiUnavailable;
  final String labelUnavailable;
  final String Function(String medName) labelNotFound;
}

/// ============================================================
/// CHAT CONTROLLER — M18 step 6
///
/// All the logic of the assistant chat, without any widget: what to answer,
/// saving to the history, loading an old chat. Everything it needs is
/// injected, so it is unit-testable.
///
/// How a question is answered (first match wins):
/// 1. emergency / dose change / diagnosis  -> fixed safe message (no AI)
/// 2. "side effects / uses / warnings ... of one of my medicines" -> the official
///    FDA label with its source (no AI, works on Spark)
/// 3. anything else -> the AI backend (today "not available yet")
/// ============================================================
class ChatController extends ChangeNotifier {
  ChatController({
    required this.store,
    required this.backend,
    required this.profileId,
    required this.loadMeds,
    required this.lookupLabel,
    required this.loadContext,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ChatStore store;
  final AiChatBackend backend;
  final String? Function() profileId;
  final Future<List<ChatMed>> Function() loadMeds;
  final Future<FdaLookupResult> Function({String? rxcui, String? name})
  lookupLabel;
  final Future<String> Function() loadContext;
  final DateTime Function() _clock;

  final List<ChatMessage> _messages = [];
  List<ChatMed> _meds = const [];
  String? _threadId;
  bool _replying = false;
  bool _loadingThread = false;
  bool _loadFailed = false;
  bool _saveWarning = false;
  bool _disposed = false;
  int _localId = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatMed> get meds => _meds;
  String? get threadId => _threadId;
  bool get isReplying => _replying;
  bool get isLoadingThread => _loadingThread;
  bool get loadFailed => _loadFailed;

  /// No more messages fit in this thread; a new chat must be started.
  bool get isFull => _messages.length >= ChatLimits.maxMessagesPerThread;

  bool get isEmpty => _messages.isEmpty;

  /// True once after a message could not be saved (the screen tells the user).
  bool takeSaveWarning() {
    final w = _saveWarning;
    _saveWarning = false;
    return w;
  }

  /// Loads the user's medicines (for suggestions and label questions).
  Future<void> init() async {
    try {
      _meds = await loadMeds();
    } catch (_) {
      _meds = const [];
    }
    _notify();
  }

  /// Starts again with an empty chat.
  void newChat() {
    _messages.clear();
    _threadId = null;
    _loadFailed = false;
    _replying = false;
    _notify();
  }

  /// Opens a saved thread.
  Future<void> openThread(String threadId) async {
    _loadingThread = true;
    _loadFailed = false;
    _notify();
    try {
      final loaded = await store.loadMessages(threadId);
      if (_disposed) return;
      _messages
        ..clear()
        ..addAll(loaded);
      _threadId = threadId;
    } catch (_) {
      if (_disposed) return;
      _loadFailed = true;
    }
    _loadingThread = false;
    _notify();
  }

  /// Sends a question and adds the answer. Ignored while an answer is being
  /// made, for empty text, and when the thread is full.
  Future<void> send(String raw, ChatTexts texts) async {
    final text = raw.trim();
    if (text.isEmpty || _replying || _loadingThread || isFull) return;

    final history = [
      for (final m in _messages) AiChatTurn(isUser: m.isUser, text: m.text),
    ];

    _add(ChatRole.user, text);
    _replying = true;
    _notify();

    await _save(ChatRole.user, text);

    final answer = await _answer(text, history, texts);
    if (_disposed) return;

    _add(ChatRole.assistant, answer);
    _replying = false;
    _notify();

    await _save(ChatRole.assistant, answer);
  }

  // ------------------------------------------------------------
  // answering
  // ------------------------------------------------------------

  Future<String> _answer(
    String text,
    List<AiChatTurn> history,
    ChatTexts t,
  ) async {
    // 1. safety
    final blocked = AiSafetyGuard.check(text);
    if (blocked != null) {
      return switch (blocked) {
        AiSafetyCategory.emergency => t.emergency,
        AiSafetyCategory.doseChange => t.doseChange,
        AiSafetyCategory.diagnosis => t.diagnosis,
      };
    }

    // 2. official label
    final q = LabelQuestionRouter.route(text, _meds);
    if (q != null) return _labelAnswer(q, t);

    // 3. the AI
    if (!backend.isAvailable) return '${t.aiUnavailable}\n\n${t.disclaimer}';
    try {
      final result = await backend.send(
        message: text,
        history: history,
        context: await _context(),
      );
      return switch (result) {
        AiBackendReply(:final text) => AiReplyChecker.finalize(
          text,
          disclaimer: t.disclaimer,
          safeFallback: t.replyBlocked,
        ),
        AiBackendUnavailable() => '${t.aiUnavailable}\n\n${t.disclaimer}',
      };
    } catch (_) {
      return '${t.aiUnavailable}\n\n${t.disclaimer}';
    }
  }

  Future<String> _context() async {
    try {
      return await loadContext();
    } catch (_) {
      return '';
    }
  }

  Future<String> _labelAnswer(LabelQuestion q, ChatTexts t) async {
    final name = q.med.name;
    final FdaLookupResult r;
    try {
      r = await lookupLabel(rxcui: q.med.rxcui, name: name);
    } catch (_) {
      return '${t.labelUnavailable}\n\n${t.disclaimer}';
    }

    switch (r) {
      case FdaLabelUnavailable():
        return '${t.labelUnavailable}\n\n${t.disclaimer}';
      case FdaLabelNotFound():
        return '${t.labelNotFound(name)}\n\n${t.disclaimer}';
      case FdaLabelFound(:final label):
        final body = label.sections[q.section];
        if (body == null) {
          return '${t.labelNotFound(name)}\n\n${t.disclaimer}';
        }
        return '${q.section.title} — ${label.displayName ?? name}:\n'
            '$body\n\n'
            '${label.citation}\n'
            '${label.sourceUrl}\n\n'
            '${t.disclaimer}';
    }
  }

  // ------------------------------------------------------------
  // saving
  // ------------------------------------------------------------

  Future<void> _save(ChatRole role, String text) async {
    final pid = profileId();
    if (pid == null || pid.isEmpty) return;
    try {
      var id = _threadId;
      if (id == null) {
        // The thread is started with the first question; its title comes
        // from it. If this fails the chat goes on and is tried again with
        // the next message.
        id = await store.createThread(profileId: pid, firstQuestion: text);
        _threadId = id;
      }
      await store.addMessage(threadId: id, role: role, text: text);
    } catch (_) {
      _saveWarning = true;
      _notify();
    }
  }

  void _add(ChatRole role, String text) {
    _messages.add(
      ChatMessage(
        id: 'local-${_localId++}',
        role: role,
        text: text,
        createdAt: _clock(),
      ),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
