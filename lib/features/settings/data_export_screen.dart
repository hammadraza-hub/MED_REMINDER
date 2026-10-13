import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'data_export_data.dart';

/// ============================================================
/// DATA EXPORT SCREEN
///
/// PURPOSE:
/// Poora personal data export request karna (portability / GDPR-style)
/// — Reports feature se independent.
///
/// NAVIGATION:
/// Settings → Data Export row se khulti hai. Detail screen hone ki
/// wajah se shared AppBottomNavigation reuse hoti hai (Settings tab).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// Asli ZIP archive generate karke email bhejna backend phase mein
/// wire hoga; yahan UI + local state hai.
/// ============================================================
class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================

  bool _requesting = false;
  bool _requested = false;

  /// Aakhri export ka formatted timestamp (null = never).
  String? _lastExportAt;

  late final AnimationController _pulseController;

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

  void _requestExport() {
    if (_requesting || _requested) return;

    setState(() => _requesting = true);

    // TODO Backend: export request queue karna + email bhejna.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      final now = DateTime.now();
      final material = MaterialLocalizations.of(context);
      final date = material.formatShortDate(now);
      final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(now));

      setState(() {
        _requesting = false;
        _requested = true;
        _lastExportAt = '$date, $time';
      });
    });
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
                        _buildHeroCard(),
                        const SizedBox(height: 16),
                        _buildIncludedCard(),
                        const SizedBox(height: 16),
                        _buildFormatNote(),
                        const SizedBox(height: 12),
                        _buildActionArea(),
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
                  AppLocalizations.of(context).dataExportTitle,
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
  // HERO OVERVIEW CARD
  // ============================================================

  Widget _buildHeroCard() {
    final l10n = AppLocalizations.of(context);

    return _card(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.formAccentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.download_rounded,
              size: 34,
              color: AppColors.formAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.dataExportHeroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.permissionsHeader,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dataExportHeroSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.permissionsChipFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: AppColors.permissionsSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.dataExportBadge,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
  // WHAT'S INCLUDED CARD
  // ============================================================

  Widget _buildIncludedCard() {
    final l10n = AppLocalizations.of(context);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dataExportIncludedTitle.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.permissionsChipFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.dataExportModules,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < DataExportData.includedModules.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildModuleRow(l10n, DataExportData.includedModules[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleRow(AppLocalizations l10n, String id) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.shareTileFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.permissionsBadgeBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.permissionsGreenDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _moduleLabel(l10n, id),
              style: const TextStyle(
                color: AppColors.permissionsHeader,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _moduleLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'profiles' => l10n.dataExportIncludedProfiles,
      'doses' => l10n.dataExportIncludedDoses,
      'vitals' => l10n.dataExportIncludedVitals,
      _ => l10n.dataExportIncludedPrescribers,
    };
  }

  // ============================================================
  // FORMAT NOTE STRIP
  // ============================================================

  Widget _buildFormatNote() {
    final l10n = AppLocalizations.of(context);
    final name = ProfileController.instance.displayName;
    final email = '${name.toLowerCase().replaceAll(RegExp(r'\s+'), '.')}'
        '@email.com';

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.reportVitalsTile,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.permissionsSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dataExportFormatNote(l10n.dataExportFormats),
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dataExportSentTo(email),
                  style: TextStyle(
                    color: AppColors.permissionsSecondary.withValues(
                      alpha: 0.8,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
  // ACTION AREA — CTA + success card + status
  // ============================================================

  Widget _buildActionArea() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRequestButton(l10n),
        if (_requested) ...[
          const SizedBox(height: 12),
          _buildSuccessCard(l10n),
        ],
        const SizedBox(height: 14),
        _buildStatusFooter(l10n),
      ],
    );
  }

  Widget _buildRequestButton(AppLocalizations l10n) {
    final label = _requested
        ? l10n.dataExportSubmitted
        : (_requesting ? l10n.dataExportGenerating : l10n.dataExportRequest);

    return GestureDetector(
      onTap: _requested ? null : _requestExport,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _requested
              ? AppColors.permissionsGreenDark
              : AppColors.formAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shareButtonShadow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_requesting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                ),
              )
            else
              Icon(
                _requested ? Icons.done_all_rounded : Icons.download_rounded,
                size: 20,
                color: AppColors.surface,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(AppLocalizations l10n) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.permissionsBadgeBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 18,
              color: AppColors.permissionsGreenDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dataExportSuccessTitle,
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.dataExportSuccessMessage,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.3, end: 1).animate(
                        _pulseController,
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.formAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.dataExportQueued,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter(AppLocalizations l10n) {
    final lastExport = _lastExportAt == null
        ? l10n.dataExportLastExportNever
        : l10n.dataExportLastExportNow(_lastExportAt!);

    return Column(
      children: [
        Text(
          lastExport,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.permissionsSecondary,
            fontSize: 11,
            fontWeight: _lastExportAt == null
                ? FontWeight.w500
                : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.dataExportRetentionId(DataExportData.retentionId),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.permissionsSecondary.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
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
