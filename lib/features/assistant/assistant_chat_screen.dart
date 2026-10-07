import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import 'assistant_chat_data.dart';

/// ============================================================
/// MED ASSISTANT CHAT THREAD
///
/// PURPOSE:
/// Conversational Q&A — user apne medications aur logged data
/// ke baare mein sawaal poochhe (message thread + input + send).
///
/// FLOW:
/// Home → Quick Access "AI Assist" → [CHAT THREAD]
///   • Seed thread: greeting, missed-dose answer + insight card
///   • Suggested chip tap → sawaal auto-send
///   • Type + send → user bubble + 450ms dummy AI reply
/// History button → Chat History List (pending screen).
///
/// NOTE:
/// Design mein bottom nav NAHI hai — input area bottom par
/// sticky hai, back button se pop hota hai.
///
/// TODO Backend:
/// AI reply (logged data + model), voice input aur chat history
/// backend par depend karte hain.
/// ============================================================
class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final List<AssistantMessage> _messages =
      List.of(AssistantChatData.seedMessages);

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Ek reply pending — double-send (chip/enter) rokne ke liye.
  bool _isReplying = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND + DUMMY AI REPLY
  // ============================================================

  void _sendText(String raw) {
    final String text = raw.trim();
    if (text.isEmpty || _isReplying) return;

    _inputController.clear();
    setState(() {
      _isReplying = true;
      _messages.add(
        AssistantMessage(
          role: AssistantMessageRole.user,
          text: text,
          time: 'Just now',
        ),
      );
    });
    _scrollToBottom();

    // TODO Backend:
    // User ke sawaal ka asli AI answer (logged data + model) yahan aayega.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _isReplying = false;
        _messages.add(
          const AssistantMessage(
            role: AssistantMessageRole.assistant,
            text: AssistantChatData.dynamicReply,
            time: 'Just now',
            boldSegment: AssistantChatData.dynamicReplyBold,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---- Pending destinations (screens abhi nahi bane) ----

  void _openChatHistory() {
    // TODO Backend: Chat History List screen aayegi.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Chat History — coming next')),
      );
  }

  void _onVoiceInput() {
    // TODO Backend: speech-to-text integration.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Voice input — coming next')),
      );
  }

  // ============================================================
  // BUILD — header + chat stream + sticky input
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
            Expanded(child: _buildChatStream()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER (back + bot badge + title/status + history + avatar)
  // ============================================================

  Widget _buildHeader() {
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
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 24,
                  ),
                ),

                // ---- Bot badge ----
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

                // ---- Title + online status ----
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AssistantChatData.screenTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface,
                        ),
                      ),
                      Row(
                        children: [
                          // HTML ka pulse dot (abhi static).
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.assistantLiveGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              AssistantChatData.statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.assistantOnlineText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---- History ----
                IconButton(
                  onPressed: _openChatHistory,
                  icon: const Icon(
                    Icons.history,
                    size: 22,
                    color: AppColors.surface,
                  ),
                ),

                const SizedBox(width: 4),

                // ---- Profile avatar ----
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.reportPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 18,
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

  // ============================================================
  // CHAT STREAM (divider + messages + suggested + caution)
  // ============================================================

  Widget _buildChatStream() {
    final List<Widget> items = <Widget>[
      Center(child: _buildDateDividerPill()),
      const SizedBox(height: 16),
    ];

    for (int i = 0; i < _messages.length; i++) {
      if (i > 0) items.add(const SizedBox(height: 16));
      items.add(_buildMessageItem(_messages[i]));
    }

    items.add(const SizedBox(height: 16));
    items.add(_buildSuggestedSection());
    items.add(const SizedBox(height: 12));
    items.add(_buildCautionBanner());

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: items,
    );
  }

  Widget _buildDateDividerPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(999)),
        boxShadow: [
          BoxShadow(color: AppColors.permissionsCardShadow, blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.assistantInsightTile,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AssistantChatData.todayLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.permissionsSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(AssistantMessage message) {
    return message.role == AssistantMessageRole.user
        ? _buildUserMessage(message)
        : _buildAssistantMessage(message);
  }

  // ---- Assistant bubble (avatar + timestamp + optional insight) ----

  Widget _buildAssistantMessage(AssistantMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.permissionsCardShadow,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 16,
                    color: AppColors.permissionsSecondary,
                  ),
                ),

                const SizedBox(width: 4),

                Flexible(child: _buildAssistantBubble(message)),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(left: 36, top: 4),
              child: Text(
                message.time,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ),

            if (message.insight != null) ...[
              const SizedBox(height: 8),
              _buildInsightCard(message.insight!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(AssistantMessage message) {
    final bool hasStats = message.stats != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageText(
            message,
            headline: hasStats,
          ),

          if (message.stats != null) ...[
            const SizedBox(height: 10),

            // ---- Status pills ----
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final AssistantStatPill pill in message.stats!.pills)
                  _buildPill(pill),
              ],
            ),

            const SizedBox(height: 10),

            // ---- Nested clinical note ----
            _buildNoteBox(message.stats!),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageText(
    AssistantMessage message, {
    required bool headline,
  }) {
    final TextStyle style = headline
        ? const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: AppColors.reportPrimary,
          )
        : const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.reportPrimary,
          );

    final String? bold = message.boldSegment;
    if (bold == null || !message.text.contains(bold)) {
      return Text(message.text, style: style);
    }

    final int index = message.text.indexOf(bold);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: message.text.substring(0, index)),
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: message.text.substring(index + bold.length)),
        ],
      ),
    );
  }

  Widget _buildPill(AssistantStatPill pill) {
    final Color bg;
    final Color fg;
    switch (pill.kind) {
      case AssistantPillKind.taken:
        bg = AppColors.permissionsGreen;
        fg = AppColors.surface;
      case AssistantPillKind.pending:
        bg = AppColors.reportVitalsTile;
        fg = AppColors.assistantPendingText;
      case AssistantPillKind.missed:
        bg = AppColors.permissionsErrorContainer;
        fg = AppColors.permissionsErrorIcon;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pill.kind == AssistantPillKind.pending)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            )
          else
            Icon(
              pill.kind == AssistantPillKind.taken
                  ? Icons.check
                  : Icons.close,
              size: 14,
              color: fg,
            ),
          const SizedBox(width: 4),
          Text(
            pill.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox(AssistantStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.assistantNoteText,
          ),
          children: [
            TextSpan(text: stats.noteLead),
            TextSpan(
              text: stats.noteHighlight,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.reportPrimary,
              ),
            ),
            TextSpan(text: stats.noteTail),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(AssistantInsight insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.assistantInsightTile.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(
              Icons.monitor_heart,
              size: 22,
              color: AppColors.permissionsSecondary,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.reportPrimary,
                  ),
                ),
                Text(
                  insight.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.permissionsSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          RepaintBoundary(
            child: CustomPaint(
              size: const Size(64, 32),
              painter: const _SparklinePainter(
                color: AppColors.assistantLiveGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- User bubble (right aligned) ----

  Widget _buildUserMessage(AssistantMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.permissionsGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.permissionsCardShadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: AppColors.surface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 4),
              child: Text(
                message.time,
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

  // ---- Suggested queries ----

  Widget _buildSuggestedSection() {
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
              AssistantChatData.suggestedLabel.toUpperCase(),
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

        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AssistantChatData.prompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _buildPromptChip(AssistantChatData.prompts[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(AssistantPrompt prompt) {
    final Color iconColor = switch (prompt.kind) {
      AssistantPromptKind.sideEffects => AppColors.permissionsSecondary,
      AssistantPromptKind.streak => AppColors.assistantLiveGreen,
      AssistantPromptKind.nextDose => AppColors.reportPrimary,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _sendText(prompt.kind.prompt);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(prompt.kind.icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              prompt.kind.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Clinical caution banner ----

  Widget _buildCautionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user,
            size: 18,
            color: AppColors.assistantPendingText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AssistantChatData.cautionText,
              textAlign: TextAlign.center,
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
  // STICKY INPUT AREA (field + mic + send + disclaimer)
  // ============================================================

  Widget _buildInputArea() {
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
              Row(
                children: [
                  Expanded(child: _buildInputField()),
                  const SizedBox(width: 8),
                  _buildSendButton(),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                AssistantChatData.disclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsSecondary
                      .withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      borderSide: BorderSide.none,
    );

    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          TextField(
            controller: _inputController,
            textInputAction: TextInputAction.send,
            onSubmitted: _sendText,
            cursorColor: AppColors.permissionsSecondary,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.reportPrimary,
            ),
            decoration: InputDecoration(
              hintText: AssistantChatData.inputHint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.permissionsSecondary.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: AppColors.permissionsChipFill,
              contentPadding: const EdgeInsets.only(
                left: 20,
                right: 44,
                top: 14,
                bottom: 14,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),

          // ---- Mic (inside field) ----
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onVoiceInput,
                child: const Icon(
                  Icons.mic,
                  size: 20,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: () {
        _sendText(_inputController.text);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.permissionsGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.reportGenerateShadow,
              blurRadius: 24,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: const Icon(
          Icons.send,
          size: 22,
          color: AppColors.surface,
        ),
      ),
    );
  }
}

/// ============================================================
/// SPARKLINE PAINTER
/// HTML SVG polyline (viewBox 0 0 64 32) ke exact points.
/// ============================================================
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color});

  final Color color;

  static const List<Offset> _points = [
    Offset(2, 24),
    Offset(14, 18),
    Offset(26, 20),
    Offset(38, 10),
    Offset(50, 14),
    Offset(62, 4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    for (int i = 0; i < _points.length; i++) {
      final Offset p = _points[i];
      final double dx = p.dx / 64 * size.width;
      final double dy = p.dy / 32 * size.height;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
