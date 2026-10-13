import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'assistant_chat_screen.dart';
import 'assistant_history_data.dart';

/// ============================================================
/// ASSISTANT CHAT HISTORY
///
/// PURPOSE:
/// User ke past AI conversations ki list — browse aur resume.
///
/// KEY ELEMENTS:
/// - "+ Start New Chat" primary action
/// - Past threads (title + preview + date)
/// - Secure-storage assurance footer
///
/// USER ACTIONS:
/// - New Chat → fresh Chat Thread
/// - Thread tap → conversation resume (open thread)
///
/// NAVIGATION:
/// Home child screen → shared bottom navigation currentIndex = 0
///
/// TODO Backend:
/// Thread list Firestore se load hoga; thread tap par us
/// thread ka message history Chat Thread mein load hoga.
/// ============================================================
class AssistantHistoryScreen extends StatefulWidget {
  const AssistantHistoryScreen({super.key});

  @override
  State<AssistantHistoryScreen> createState() =>
      _AssistantHistoryScreenState();
}

class _AssistantHistoryScreenState extends State<AssistantHistoryScreen> {
  // ================= NAVIGATION =================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  void _startNewChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssistantChatScreen()),
    );
  }

  void _openThread(AssistantChatThread thread) {
    // TODO Backend:
    // thread.id se us conversation ka message history load karke
    // AssistantChatScreen mein seed karna.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssistantChatScreen()),
    );
  }

  // ================= BUILD =================

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
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildBody(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: 0,
          onTap: _onBottomNavigationTap,
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.permissionsHeader,
        boxShadow: [
          BoxShadow(
            color: AppColors.permissionsHeaderShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.surface,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    AssistantHistoryData.screenTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                // TODO Backend / Firebase Storage:
                // Selected member ki persistent profile URL use karna.
                const AppAvatar(size: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BODY =================

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNewChatButton(),
          const SizedBox(height: 12),

          _buildSectionHeading(),
          const SizedBox(height: 12),

          ...AssistantHistoryData.threads.map(
            (thread) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildThreadCard(thread),
            ),
          ),

          const SizedBox(height: 4),
          _buildFooter(),
        ],
      ),
    );
  }

  // ---- New Chat button ----

  Widget _buildNewChatButton() {
    return GestureDetector(
      onTap: _startNewChat,
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.assistantNewChatGreen,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.assistantNewChatShadow,
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20, color: AppColors.surface),
            SizedBox(width: 8),
            Text(
              AssistantHistoryData.newChatLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Section heading ----

  Widget _buildSectionHeading() {
    return Text(
      AssistantHistoryData.sectionLabel.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.permissionsHeader,
      ),
    );
  }

  // ---- Thread card ----

  Widget _buildThreadCard(AssistantChatThread thread) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openThread(thread),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.permissionsCardShadow,
              blurRadius: 20,
              offset: Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            // ---- Chat icon tile ----
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.shareTileFill,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: AppColors.assistantNewChatGreen,
              ),
            ),

            const SizedBox(width: 12),

            // ---- Title + preview ----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.permissionsHeader,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.shareSecondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ---- Date + chevron ----
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  thread.dateLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.shareSecondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.shareSecondaryText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Assurance footer ----

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          AssistantHistoryData.footerHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.shareSecondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 14,
              color: AppColors.shareSecondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              AssistantHistoryData.secureNote,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.shareSecondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
