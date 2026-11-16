import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/ai/ai_chat_backend.dart';
import '../../core/ai/chat_controller.dart';
import '../../core/ai/chat_models.dart';
import '../../core/ai/fda_label_client.dart';
import '../../core/ai/label_question_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../core/services/fda_label_service.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/ai_context_wiring.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/medication_repository.dart';
import 'assistant_history_screen.dart';
import 'chat_texts_l10n.dart';

/// ============================================================
/// AI ASSISTANT CHAT — M18 step 6
///
/// Home → "AI Assist" → (consent) → this screen.
///
/// How a question is answered is decided by [ChatController]:
///   1. emergency / dose change / diagnosis -> fixed safe message
///   2. side effects / uses / warnings of one of the user's medicines ->
///      the official FDA label, with its source (no AI needed)
///   3. anything else -> the AI backend (not available on the Spark plan)
/// Every message is saved to the user's chat history (users/{uid}/chatThreads).
/// ============================================================
class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key, this.threadId, this.controller});

  /// Opens this saved thread instead of an empty chat.
  final String? threadId;

  /// For tests: a controller with fake parts.
  @visibleForTesting
  final ChatController? controller;

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  late final ChatController _c;
  late final bool _ownsController;

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _c = widget.controller ?? _defaultController();
    _c.addListener(_onChanged);
    _c.init();
    final id = widget.threadId;
    if (id != null) _c.openThread(id);
  }

  static ChatController _defaultController() {
    String? memberId() {
      final id = ProfileController.instance.memberId;
      return (id == null || id.isEmpty) ? null : id;
    }

    return ChatController(
      store: ChatRepository.instance,
      backend: const UnavailableAiBackend(),
      profileId: memberId,
      loadMeds: () async {
        final id = memberId();
        if (id == null) return const [];
        final meds = await MedicationRepository.instance
            .watchActiveMedications(id)
            .first;
        return [for (final m in meds) ChatMed(name: m.name, rxcui: m.rxcui)];
      },
      lookupLabel: ({rxcui, name}) =>
          FdaLabelService.instance.lookup(rxcui: rxcui, name: name),
      loadContext: () async {
        final id = memberId();
        if (id == null) return '';
        return (await buildAiContextBuilder(id).build()).toPromptText();
      },
    );
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    if (_ownsController) _c.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_c.takeSaveWarning()) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.aiChatSaveFailed)));
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final texts = ChatTextsL10n.of(AppLocalizations.of(context));
    _input.clear();
    await _c.send(text, texts);
  }

  Future<void> _openHistory() async {
    final choice = await Navigator.of(context).push<AssistantHistoryChoice>(
      MaterialPageRoute(builder: (_) => const AssistantHistoryScreen()),
    );
    if (choice == null || !mounted) return;
    if (choice.threadId == null) {
      _c.newChat();
    } else {
      await _c.openThread(choice.threadId!);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.permissionsHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildStream()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.permissionsHeader,
        boxShadow: [
          BoxShadow(
            color: AppColors.reportCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 20,
                    color: AppColors.reportVitalsTile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiChatTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface,
                        ),
                      ),
                      Text(
                        l10n.aiChatStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.assistantOnlineText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('chat-new'),
                  tooltip: l10n.aiChatNewChat,
                  onPressed: _c.isReplying ? null : _c.newChat,
                  icon: const Icon(
                    Icons.add_comment_outlined,
                    size: 22,
                    color: AppColors.surface,
                  ),
                ),
                IconButton(
                  key: const Key('chat-history'),
                  tooltip: l10n.aiHistoryTitle,
                  onPressed: _openHistory,
                  icon: const Icon(
                    Icons.history,
                    size: 22,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStream() {
    final l10n = AppLocalizations.of(context);

    if (_c.isLoadingThread) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = <Widget>[];

    if (_c.loadFailed) {
      items.add(_notice(l10n.aiChatLoadFailed, Icons.error_outline));
      items.add(const SizedBox(height: 12));
    }

    if (_c.isEmpty && !_c.loadFailed) {
      items.add(_notice(l10n.aiChatEmptyHint, Icons.medication_outlined));
      items.add(const SizedBox(height: 12));
    }

    for (var i = 0; i < _c.messages.length; i++) {
      if (i > 0) items.add(const SizedBox(height: 14));
      items.add(_buildMessage(_c.messages[i]));
    }

    if (_c.isReplying) {
      items.add(const SizedBox(height: 14));
      items.add(_buildTyping());
    }

    if (_c.isEmpty && _suggestions(l10n).isNotEmpty) {
      items.add(const SizedBox(height: 16));
      items.add(_buildSuggestions(l10n));
    }

    items.add(const SizedBox(height: 14));
    items.add(_buildCaution(l10n));

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: items,
    );
  }

  Widget _notice(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.permissionsSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- messages ----

  String _time(DateTime t) =>
      DateFormat.jm(AppLocalizations.of(context).localeName).format(t);

  Widget _buildMessage(ChatMessage m) {
    final user = m.isUser;
    return Align(
      alignment: user
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Column(
          crossAxisAlignment: user
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: user ? AppColors.permissionsGreen : AppColors.surface,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(16),
                  topEnd: const Radius.circular(16),
                  bottomStart: Radius.circular(user ? 16 : 4),
                  bottomEnd: Radius.circular(user ? 4 : 16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.permissionsCardShadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: SelectableText(
                m.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: user ? FontWeight.w600 : FontWeight.w400,
                  color: user ? AppColors.surface : AppColors.reportPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _time(m.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: const _TypingDots(color: AppColors.permissionsSecondary),
      ),
    );
  }

  // ---- suggestions ----

  /// Questions built from the user's first medicine (they are answered from
  /// its official label).
  List<String> _suggestions(AppLocalizations l10n) {
    if (_c.meds.isEmpty) return const [];
    final raw = FdaQuery.genericName(_c.meds.first.name);
    if (raw == null) return const [];
    final name = '${raw[0].toUpperCase()}${raw.substring(1)}';
    return [
      l10n.aiChatAskSideEffects(name),
      l10n.aiChatAskUsedFor(name),
      l10n.aiChatAskWarnings(name),
    ];
  }

  Widget _buildSuggestions(AppLocalizations l10n) {
    final questions = _suggestions(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.tips_and_updates,
              size: 16,
              color: AppColors.permissionsSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.aiChatSuggested.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.66,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in questions)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _send(q),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.permissionsCardShadow,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    q,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.permissionsSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaution(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user,
            size: 18,
            color: AppColors.assistantPendingText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.aiChatCaution,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: AppColors.assistantNoteText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInputArea() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.reportConfigShadow,
            blurRadius: 20,
            offset: Offset(0, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_c.isFull)
                _buildFullBanner(l10n)
              else
                Row(
                  children: [
                    Expanded(child: _buildField(l10n)),
                    const SizedBox(width: 8),
                    _buildSendButton(),
                  ],
                ),
              const SizedBox(height: 6),
              Text(
                l10n.aiChatFooter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullBanner(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.aiChatFull,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.permissionsSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          key: const Key('chat-full-new'),
          onPressed: _c.newChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.permissionsGreen,
            foregroundColor: AppColors.surface,
          ),
          child: Text(l10n.aiChatNewChat),
        ),
      ],
    );
  }

  Widget _buildField(AppLocalizations l10n) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: 48,
      child: TextField(
        key: const Key('chat-input'),
        controller: _input,
        textInputAction: TextInputAction.send,
        onSubmitted: _send,
        maxLength: ChatLimits.maxTextLength,
        buildCounter: (
          context, {
          required currentLength,
          required isFocused,
          required maxLength,
        }) => null,
        cursorColor: AppColors.permissionsSecondary,
        style: const TextStyle(fontSize: 14, color: AppColors.reportPrimary),
        decoration: InputDecoration(
          hintText: l10n.aiChatInputHint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.permissionsSecondary.withValues(alpha: 0.7),
          ),
          filled: true,
          fillColor: AppColors.permissionsChipFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      key: const Key('chat-send'),
      onTap: () => _send(_input.text),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _c.isReplying
              ? AppColors.permissionsSecondary
              : AppColors.permissionsGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send, size: 22, color: AppColors.surface),
      ),
    );
  }
}

/// Three pulsing dots while an answer is being made.
class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + index * 0.2) % 1.0;
            final wave = (phase * 2 - 1).abs();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Opacity(
                opacity: 0.4 + (1 - wave) * 0.6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
