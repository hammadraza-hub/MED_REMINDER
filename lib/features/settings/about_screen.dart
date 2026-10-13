import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'about_data.dart';

/// ============================================================
/// ABOUT SCREEN
///
/// PURPOSE:
/// App info (version + update status), legal links (Terms, Privacy,
/// Licenses) aur credits.
///
/// NAVIGATION:
/// Settings → About row se khulti hai. Detail screen hone ki wajah se
/// shared AppBottomNavigation reuse hoti hai (Settings tab).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// Legal document content CMS/backend phase mein wire hoga; abhi
/// in-app bottom sheet mein summary dikhti hai.
/// ============================================================
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================

  late final AnimationController _pulseController;

  /// App icon par 3-tap easter egg ke liye tap counter + spin.
  int _iconTaps = 0;
  double _iconTurns = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _onAppIconTap() {
    _iconTaps++;
    if (_iconTaps == 3) {
      _iconTaps = 0;
      setState(() => _iconTurns += 1);
    }
  }

  void _openLegalDoc(String id) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => _LegalDocSheet(id: id),
    );
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
          _buildHeader(l10n),
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
                        _buildAppInfoCard(l10n),
                        const SizedBox(height: 16),
                        _buildLegalCard(l10n),
                        const SizedBox(height: 16),
                        _buildCreditsCard(l10n),
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

  Widget _buildHeader(AppLocalizations l10n) {
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
              Image.asset(
                'assets/images/med_reminder_logo.png',
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.aboutTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  // APP INFO CARD
  // ============================================================

  Widget _buildAppInfoCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        children: [
          GestureDetector(
            onTap: _onAppIconTap,
            child: AnimatedRotation(
              turns: _iconTurns,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.permissionsHeader,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.permissionsHeaderShadow,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/med_reminder_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.aboutAppName,
            style: const TextStyle(
              color: AppColors.permissionsHeader,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.aboutVersion,
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.formAccentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 0.3, end: 1).animate(
                    _pulseController,
                  ),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.formAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.aboutUpToDate,
                  style: const TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
  // LEGAL LINKS CARD
  // ============================================================

  Widget _buildLegalCard(AppLocalizations l10n) {
    final ids = AboutData.legalDocIds;

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < ids.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: AppColors.reportSurfaceContainer,
                margin: const EdgeInsets.only(left: 56),
              ),
            _buildLegalRow(l10n, ids[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildLegalRow(AppLocalizations l10n, String id) {
    return InkWell(
      onTap: () => _openLegalDoc(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.permissionsChipFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _legalIcon(id),
                size: 20,
                color: AppColors.permissionsSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _legalTitle(l10n, id),
                style: const TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.permissionsSecondary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _legalIcon(String id) {
    return switch (id) {
      'terms' => Icons.description_outlined,
      'privacy' => Icons.shield_outlined,
      _ => Icons.code_rounded,
    };
  }

  String _legalTitle(AppLocalizations l10n, String id) {
    return switch (id) {
      'terms' => l10n.aboutTerms,
      'privacy' => l10n.aboutPrivacy,
      _ => l10n.aboutLicenses,
    };
  }

  // ============================================================
  // CREDITS CARD
  // ============================================================

  Widget _buildCreditsCard(AppLocalizations l10n) {
    final ids = AboutData.creditIds;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.aboutCredits.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.favorite_border_rounded,
                size: 16,
                color: AppColors.permissionsSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < ids.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.reportSurfaceContainer,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _creditLabel(l10n, ids[i]),
                    style: const TextStyle(
                      color: AppColors.permissionsSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _creditValue(l10n, ids[i]),
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _creditLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'design' => l10n.aboutCreditsDesign,
      'drugData' => l10n.aboutCreditsDrugData,
      _ => l10n.aboutCreditsIcons,
    };
  }

  String _creditValue(AppLocalizations l10n, String id) {
    return switch (id) {
      'design' => l10n.aboutCreditsDesignValue,
      'drugData' => l10n.aboutCreditsDrugDataValue,
      _ => l10n.aboutCreditsIconsValue,
    };
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        l10n.aboutFooter,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.permissionsSecondary,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ============================================================
  // SHARED HELPER — white card
  // ============================================================

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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

/// ============================================================
/// LEGAL DOCUMENT BOTTOM SHEET
/// ============================================================

class _LegalDocSheet extends StatelessWidget {
  const _LegalDocSheet({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final title = switch (id) {
      'terms' => l10n.aboutTerms,
      'privacy' => l10n.aboutPrivacy,
      _ => l10n.aboutLicenses,
    };

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.reportChipHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.permissionsHeader,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.permissionsChipFill,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.permissionsSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.aboutLegalBody1,
                          style: const TextStyle(
                            color: AppColors.assistantNoteText,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.aboutLegalBody2,
                          style: const TextStyle(
                            color: AppColors.assistantNoteText,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.permissionsChipFill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.aboutLegalComplianceTitle,
                                style: const TextStyle(
                                  color: AppColors.permissionsHeader,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.aboutLegalComplianceValue,
                                style: const TextStyle(
                                  color: AppColors.permissionsSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.formAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.aboutDone,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
