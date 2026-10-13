import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_avatar.dart';
import 'compare_plans_data.dart';
import 'upgrade_screen.dart';

/// ============================================================
/// COMPARE PLANS SCREEN
///
/// PURPOSE:
/// Free vs Solo Pro vs Family Pro ka side-by-side feature matrix
/// aur pricing. User plan select karke purchase flow mein jaata hai.
///
/// NAVIGATION:
/// Subscription → "Compare Plans" se khulti hai. Plan select karne
/// par Upgrade (paywall) screen pre-selected plan ke saath khulti
/// hai (Payment Confirmation ke liye TODO).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// RevenueCat / StoreKit / Play Billing ke baad real purchase wire
/// hoga.
/// ============================================================
class ComparePlansScreen extends StatelessWidget {
  const ComparePlansScreen({super.key});

  // ============================================================
  // ACTIONS
  // ============================================================

  void _onSelectPlan(BuildContext context, String planId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UpgradeScreen(initialPlanId: planId),
      ),
    );
  }

  void _onContinueFree(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.compareFreeSelected)));
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
          _buildHeader(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBadges(l10n),
                        const SizedBox(height: 16),
                        _buildMatrix(l10n),
                        const SizedBox(height: 16),
                        _buildTestimonial(l10n),
                        const SizedBox(height: 20),
                        _buildActions(context, l10n),
                        const SizedBox(height: 16),
                        _buildFinePrint(l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
                  l10n.compareTitle,
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
  // TOP BADGES
  // ============================================================

  Widget _buildTopBadges(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.permissionsChipFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: AppColors.formAccent,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.compareGuarantee,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.permissionsSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.reportSurfaceContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PulsingDot(),
              const SizedBox(width: 6),
              Text(
                l10n.compareAnnualSave.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.reportPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE MATRIX
  // ============================================================

  Widget _buildMatrix(AppLocalizations l10n) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMatrixHeader(l10n),
          _buildPricingRow(l10n),
          for (var g = 0; g < ComparePlansData.groups.length; g++) ...[
            _buildGroupHeader(l10n, ComparePlansData.groups[g].id),
            for (var i = 0;
                i < ComparePlansData.groups[g].featureIds.length;
                i++)
              _buildFeatureRow(
                l10n,
                ComparePlansData.groups[g].featureIds[i],
                zebra: i.isOdd,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatrixHeader(AppLocalizations l10n) {
    return Container(
      color: AppColors.permissionsHeader,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.compareColFeatures.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.assistantOnlineText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            _headerCell(
              title: l10n.compareColFree,
              subtitle: l10n.compareFreeSubtitle,
              subtitleColor: AppColors.assistantOnlineText,
            ),
            _headerCell(
              title: l10n.compareColSolo,
              subtitle: l10n.compareSoloSubtitle,
              subtitleColor: AppColors.assistantInsightTile,
              crown: true,
            ),
            _headerCell(
              title: l10n.compareColFamily,
              subtitle: l10n.compareFamilySubtitle,
              subtitleColor: AppColors.assistantInsightTile,
              crown: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell({
    required String title,
    required String subtitle,
    required Color subtitleColor,
    bool crown = false,
  }) {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (crown) ...[
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 14,
                    color: AppColors.subscriptionGold,
                  ),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(AppLocalizations l10n) {
    return Container(
      color: AppColors.permissionsChipFill,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.comparePriceLabel,
                      style: const TextStyle(
                        color: AppColors.permissionsSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.compareBilledYearly,
                      style: const TextStyle(
                        color: AppColors.shareSecondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _priceCell(
              price: ComparePlansData.priceYearly['free'] ?? '',
              cadence: l10n.compareForever,
            ),
            _priceCell(
              price: ComparePlansData.priceYearly['solo'] ?? '',
              cadence: l10n.comparePerYear,
            ),
            _priceCell(
              price: ComparePlansData.priceYearly['family'] ?? '',
              cadence: l10n.comparePerYear,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceCell({
    required String price,
    required String cadence,
  }) {
    return Expanded(
      flex: 3,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.reportPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cadence,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.shareSecondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(AppLocalizations l10n, String id) {
    return Container(
      color: AppColors.permissionsInactiveFill.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            _groupIcon(id),
            size: 15,
            color: AppColors.permissionsSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _groupLabel(l10n, id).toUpperCase(),
              style: const TextStyle(
                color: AppColors.reportPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    AppLocalizations l10n,
    String featureId, {
    required bool zebra,
  }) {
    return Container(
      color: zebra
          ? AppColors.permissionsChipFill.withValues(alpha: 0.4)
          : AppColors.surface,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _featureLabel(l10n, featureId),
                    style: const TextStyle(
                      color: AppColors.reportPrimary,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            _availabilityCell(featureId, 0),
            _availabilityCell(featureId, 1),
            _availabilityCell(featureId, 2),
          ],
        ),
      ),
    );
  }

  Widget _availabilityCell(String featureId, int column) {
    final available = ComparePlansData.isAvailable(featureId, column);

    return Expanded(
      flex: 3,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Icon(
          available ? Icons.check_circle_rounded : Icons.close_rounded,
          size: available ? 20 : 18,
          color: available
              ? AppColors.formAccent
              : AppColors.permissionsErrorIcon,
        ),
      ),
    );
  }

  IconData _groupIcon(String id) {
    return switch (id) {
      'daily' => Icons.schedule_rounded,
      'clinical' => Icons.health_and_safety_rounded,
      _ => Icons.groups_rounded,
    };
  }

  String _groupLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'daily' => l10n.compareGroupDaily,
      'clinical' => l10n.compareGroupClinical,
      _ => l10n.compareGroupFamily,
    };
  }

  String _featureLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'unlimitedMeds' => l10n.compareFeatUnlimitedMeds,
      'adherence' => l10n.compareFeatAdherence,
      'interactions' => l10n.compareFeatInteractions,
      'inventory' => l10n.compareFeatInventory,
      'doctorTools' => l10n.compareFeatDoctorTools,
      'reports' => l10n.compareFeatReports,
      'healthSync' => l10n.compareFeatHealthSync,
      'familyLinking' => l10n.compareFeatFamilyLinking,
      'missedDose' => l10n.compareFeatMissedDose,
      _ => l10n.compareFeatFamilyDashboard,
    };
  }

  // ============================================================
  // TESTIMONIAL
  // ============================================================

  Widget _buildTestimonial(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppAvatar(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (_) => const Padding(
                      padding: EdgeInsets.only(right: 1),
                      child: Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.subscriptionGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.compareQuote,
                  style: const TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.compareQuoteAuthor,
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
  // ACTIONS (CTAs)
  // ============================================================

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildSoloButton(context, l10n),
        const SizedBox(height: 10),
        _buildFamilyButton(context, l10n),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => _onContinueFree(context),
          child: Text(
            l10n.compareContinueFree,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoloButton(BuildContext context, AppLocalizations l10n) {
    final price = l10n.upgradePriceAnnual(
      ComparePlansData.priceYearly['solo'] ?? '',
    );

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () => _onSelectPlan(context, 'solo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 6,
          shadowColor: AppColors.reportGenerateShadow,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 16,
              color: AppColors.subscriptionGold,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.compareChooseSolo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              price,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyButton(BuildContext context, AppLocalizations l10n) {
    final price = l10n.upgradePriceAnnual(
      ComparePlansData.priceYearly['family'] ?? '',
    );

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () => _onSelectPlan(context, 'family'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.formAccent,
          elevation: 4,
          shadowColor: AppColors.permissionsCardShadow,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.family_restroom_rounded,
              size: 20,
              color: AppColors.formAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.compareChooseFamily,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              price,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FINE PRINT
  // ============================================================

  Widget _buildFinePrint(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            l10n.compareFinePrint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _trustItem(Icons.lock_rounded, l10n.compareEncrypted),
              _trustDivider(),
              _trustItem(Icons.replay_rounded, l10n.compareAutoSync),
              _trustDivider(),
              _trustItem(Icons.security_rounded, l10n.compareHipaaReady),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.formAccent),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.shareSecondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _trustDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(color: AppColors.permissionsSecondary, fontSize: 11),
      ),
    );
  }
}

/// ============================================================
/// PULSING DOT — "Annual Save" badge ke liye
/// ============================================================

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.formAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
