import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'help_support_data.dart';

/// ============================================================
/// HELP & SUPPORT SCREEN
///
/// PURPOSE:
/// Support resources — FAQ search + accordion, contact channels
/// (email / support request) aur app version info.
///
/// NAVIGATION:
/// Settings → Help & Support row se khulti hai. Detail screen hone ki
/// wajah se shared AppBottomNavigation reuse hoti hai (Settings tab).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// Ticket submission + support chat backend phase mein wire honge;
/// abhi email action par snackbar dikhta hai.
/// ============================================================
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================

  final _searchController = TextEditingController();

  late final AnimationController _pulseDotController;

  /// Query ke hisab se search string.
  String _query = '';

  /// Khule FAQ items ke indices (default: aakhri item khula hua).
  final Set<int> _expanded = {HelpSupportData.faqIds.length - 1};

  /// Feedback diya gaya hai ya nahi.
  bool _feedbackGiven = false;

  @override
  void initState() {
    super.initState();

    _pulseDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _pulseDotController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim().toLowerCase();
    if (value == _query) return;
    setState(() => _query = value);
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _toggleFaq(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onEmailTap(AppLocalizations l10n) {
    // TODO Backend: url_launcher ke mailto: URI se email app open karna.
    _showMessage(l10n.helpSupportEmailClipped(HelpSupportData.supportEmail));
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchBar(l10n),
                        const SizedBox(height: 16),
                        _buildBanner(l10n),
                        const SizedBox(height: 16),
                        _buildFaqCard(l10n),
                        const SizedBox(height: 16),
                        _buildContactCard(l10n),
                        const SizedBox(height: 16),
                        _buildFeedbackPill(l10n),
                        const SizedBox(height: 16),
                        _buildFooter(l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 4,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).helpSupportTitle,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppAvatar(
                size: 32,
                ringColor: AppColors.surface,
                ringWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar(AppLocalizations l10n) {
    final hasQuery = _searchController.text.isNotEmpty;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.permissionsSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: AppColors.reportPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: l10n.helpSupportSearchHint,
                hintStyle: const TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.permissionsSecondary,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPFUL BANNER
  // ============================================================

  Widget _buildBanner(AppLocalizations l10n) {
    return _card(
      color: AppColors.reportSurfaceContainer,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 22,
              color: AppColors.formAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.helpSupportBannerTitle,
                  style: const TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.helpSupportBannerSubtitle,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FAQ ACCORDION CARD
  // ============================================================

  List<int> _visibleFaqIndices(AppLocalizations l10n) {
    if (_query.isEmpty) {
      return [for (var i = 0; i < HelpSupportData.faqIds.length; i++) i];
    }

    return [
      for (var i = 0; i < HelpSupportData.faqIds.length; i++)
        if (_faqQuestion(l10n, i).toLowerCase().contains(_query) ||
            _faqAnswer(l10n, i).toLowerCase().contains(_query))
          i,
    ];
  }

  Widget _buildFaqCard(AppLocalizations l10n) {
    final visible = _visibleFaqIndices(l10n);

    return _card(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.helpSupportFaqHeader.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.reportPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Text(
                  l10n.helpSupportFaqCount(HelpSupportData.faqIds.length),
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Text(
                l10n.helpSupportNoResults,
                style: const TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const _FaqDivider(),
              _buildFaqItem(l10n, visible[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildFaqItem(AppLocalizations l10n, int index) {
    final isOpen = _expanded.contains(index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _toggleFaq(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _faqQuestion(l10n, index),
                    style: const TextStyle(
                      color: AppColors.reportPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isOpen
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: isOpen
                      ? AppColors.formAccent
                      : AppColors.permissionsSecondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isOpen
              ? Container(
                  width: double.infinity,
                  color: AppColors.permissionsChipFill,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Text(
                    _faqAnswer(l10n, index),
                    style: const TextStyle(
                      color: AppColors.permissionsSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  String _faqQuestion(AppLocalizations l10n, int index) {
    return switch (HelpSupportData.faqIds[index]) {
      'doseTime' => l10n.faqQ1,
      'reminder' => l10n.faqQ2,
      'caregiverAlerts' => l10n.faqQ3,
      _ => l10n.faqQ4,
    };
  }

  String _faqAnswer(AppLocalizations l10n, int index) {
    return switch (HelpSupportData.faqIds[index]) {
      'doseTime' => l10n.faqA1,
      'reminder' => l10n.faqA2,
      'caregiverAlerts' => l10n.faqA3,
      _ => l10n.faqA4,
    };
  }

  // ============================================================
  // CONTACT CHANNELS CARD
  // ============================================================

  Widget _buildContactCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.helpSupportStillNeedHelp.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.reportSurfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(controller: _pulseDotController),
                    const SizedBox(width: 6),
                    Text(
                      l10n.helpSupportLiveOnline,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChannelRow(
            icon: Icons.mail_outline_rounded,
            iconColor: AppColors.formAccent,
            title: l10n.helpSupportEmailSupport,
            subtitle: HelpSupportData.supportEmail,
            trailing: GestureDetector(
              onTap: () => _onEmailTap(l10n),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.formAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.helpSupportEmailAction,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.reportSurfaceContainer,
            ),
          ),
          _buildChannelRow(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.reportPrimary,
            title: l10n.helpSupportSubmitRequest,
            subtitle: l10n.helpSupportResponseTime,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.permissionsSecondary,
            ),
            onTap: () => _onEmailTap(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.reportSurfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  // ============================================================
  // FEEDBACK PILL
  // ============================================================

  Widget _buildFeedbackPill(AppLocalizations l10n) {
    return _card(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            size: 18,
            color: AppColors.permissionsSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.helpSupportHelpful,
              style: const TextStyle(
                color: AppColors.reportPrimary,
                fontSize: 13,
              ),
            ),
          ),
          if (_feedbackGiven)
            Flexible(
              child: Text(
                l10n.helpSupportFeedbackThanks,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...[
            _feedbackPill(l10n.helpSupportYes),
            const SizedBox(width: 8),
            _feedbackPill(l10n.helpSupportNo),
          ],
        ],
      ),
    );
  }

  Widget _feedbackPill(String label) {
    return GestureDetector(
      onTap: () => setState(() => _feedbackGiven = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.reportSurfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.permissionsSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VERSION FOOTER
  // ============================================================

  Widget _buildFooter(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.helpSupportVersion,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.permissionsSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.helpSupportCompliance,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.permissionsSecondary.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED HELPERS
  // ============================================================

  Widget _card({
    required Widget child,
    Color color = AppColors.surface,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// FAQ list ke beech ki hairline divider.
class _FaqDivider extends StatelessWidget {
  const _FaqDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.reportSurfaceContainer);
  }
}

/// Pulsing live dot.
class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.formAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
