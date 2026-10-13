import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_avatar.dart';
import 'payment_success_screen.dart';
import 'upgrade_data.dart';

/// ============================================================
/// UPGRADE (PAYWALL) SCREEN
///
/// PURPOSE:
/// Free user ko Pro mein convert karna — jab koi gated feature
/// request ho. Feature teaser, plan options (Solo/Family ×
/// monthly/annual), pricing, free-trial CTA aur comparison sheet.
///
/// NAVIGATION:
/// Standalone paywall. Close button se pop hoti hai. Customer yahan
/// Subscription screen ya kisi gated feature se aa sakta hai.
///
/// Actions:
/// - Plan select (radio + badge)
/// - Billing cycle toggle (monthly/annual) → pricing update
/// - "See full comparison" → comparison bottom sheet
/// - "Start free trial" → payment confirmation (TODO)
/// - Restore purchase (TODO)
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// RevenueCat / StoreKit / Play Billing ke baad real purchase,
/// restore aur payment confirmation wire honge.
/// ============================================================
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key, this.initialPlanId});

  /// Compare Plans screen se pre-selected plan id ('solo' / 'family').
  final String? initialPlanId;

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _isAnnual = true;
  late String _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlanId ?? UpgradeData.defaultPlanId;
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openComparison() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => const _ComparisonSheet(),
    );
  }

  void _onRestore() {
    // TODO Backend: StoreKit / Play Billing restorePurchases().
    _showMessage(AppLocalizations.of(context).upgradeRestoreToast);
  }

  void _onStartTrial() {
    // TODO Backend: real purchase → success. Abhi confirmation screen.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          planId: _selectedPlan,
          isAnnual: _isAnnual,
        ),
      ),
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
                        _buildUserCard(l10n),
                        const SizedBox(height: 16),
                        _buildHeroCard(l10n),
                        const SizedBox(height: 16),
                        _buildUnlockCard(l10n),
                        const SizedBox(height: 16),
                        _buildSectionHeader(l10n),
                        const SizedBox(height: 12),
                        _buildBillingToggle(l10n),
                        const SizedBox(height: 12),
                        for (final id in UpgradeData.planIds) ...[
                          _buildPlanCard(l10n, id),
                          if (id != UpgradeData.planIds.last)
                            const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 20),
                        _buildCta(l10n),
                        const SizedBox(height: 8),
                        _buildNothingDue(l10n),
                        const SizedBox(height: 12),
                        _buildSecondaryLinks(l10n),
                        const SizedBox(height: 8),
                        _buildLegalNote(l10n),
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
                  Icons.close_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  l10n.upgradeTitle,
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
  // USER CONTEXT CARD
  // ============================================================

  Widget _buildUserCard(AppLocalizations l10n) {
    return _card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const AppAvatar(size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UpgradeData.demoUserName,
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
                  l10n.upgradePlanStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.permissionsChipFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColors.permissionsSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.upgradeProGated.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
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
  // HERO CARD
  // ============================================================

  Widget _buildHeroCard(AppLocalizations l10n) {
    return _card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.reportPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 26,
              color: AppColors.subscriptionGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.upgradeHeroTitle,
                  style: const TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.upgradeHeroSubtitle,
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 13,
                    height: 1.3,
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
  // UNLOCK / COMPARISON TEASER CARD
  // ============================================================

  Widget _buildUnlockCard(AppLocalizations l10n) {
    final ids = UpgradeData.unlockIds;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.upgradeUnlockHeader.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < ids.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _buildUnlockRow(l10n, ids[i]),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: _openComparison,
            child: Container(
              color: AppColors.permissionsChipFill,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.upgradeSeeComparison,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.formAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockRow(AppLocalizations l10n, String id) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.formAccent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _unlockLabel(l10n, id),
            style: const TextStyle(
              color: AppColors.reportPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _unlockLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'interactions' => l10n.upgradeUnlockInteractions,
      'refills' => l10n.upgradeUnlockRefills,
      'reports' => l10n.upgradeUnlockReports,
      _ => l10n.upgradeUnlockFamily,
    };
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.upgradeChoosePlan.toUpperCase(),
            style: const TextStyle(
              color: AppColors.reportPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.formAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.upgradeFreeTrial,
          style: const TextStyle(
            color: AppColors.permissionsSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BILLING CYCLE TOGGLE
  // ============================================================

  Widget _buildBillingToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBillingOption(
            label: l10n.upgradeMonthly,
            selected: !_isAnnual,
            onTap: () => setState(() => _isAnnual = false),
          ),
          _buildBillingOption(
            label: l10n.upgradeAnnual,
            selected: _isAnnual,
            onTap: () => setState(() => _isAnnual = true),
            trailing: _buildSaveBadge(l10n, selected: _isAnnual),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.reportPrimary : AppColors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.surface
                      : AppColors.permissionsSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveBadge(AppLocalizations l10n, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.surface.withValues(alpha: 0.14)
            : AppColors.reportPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.upgradeSaveBadge.toUpperCase(),
        style: const TextStyle(
          color: AppColors.subscriptionGold,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // PLAN CARD
  // ============================================================

  Widget _buildPlanCard(AppLocalizations l10n, String id) {
    final selected = _selectedPlan == id;
    final isPopular = id == UpgradeData.popularPlanId;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.formAccent
                      : AppColors.transparent,
                  width: 2,
                ),
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
                  _buildRadio(selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _planName(l10n, id),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.reportPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isPopular) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.reportSurfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.upgradePopular.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.reportPrimary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _planSubtitle(l10n, id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.permissionsSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _price(l10n, id),
                        style: const TextStyle(
                          color: AppColors.reportPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_isAnnual) ...[
                        const SizedBox(height: 3),
                        Text(
                          l10n.upgradeWasPrice(_wasPrice(id)),
                          style: const TextStyle(
                            color: AppColors.permissionsSecondary,
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.formAccent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.upgradeSelected.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool selected) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.formAccent
            : AppColors.permissionsInactiveFill,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : AppColors.transparent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  String _planName(AppLocalizations l10n, String id) {
    return id == 'solo' ? l10n.upgradePlanSoloName : l10n.upgradePlanFamilyName;
  }

  String _planSubtitle(AppLocalizations l10n, String id) {
    return id == 'solo'
        ? l10n.upgradePlanSoloSubtitle
        : l10n.upgradePlanFamilySubtitle;
  }

  String _price(AppLocalizations l10n, String id) {
    final value = _isAnnual
        ? UpgradeData.annualPrice[id] ?? ''
        : UpgradeData.monthlyPrice[id] ?? '';
    return _isAnnual
        ? l10n.upgradePriceAnnual(value)
        : l10n.upgradePriceMonthly(value);
  }

  String _wasPrice(String id) {
    return UpgradeData.annualWasPrice[id] ?? '';
  }

  // ============================================================
  // CTA + FOOTERS
  // ============================================================

  Widget _buildCta(AppLocalizations l10n) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _onStartTrial,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 6,
          shadowColor: AppColors.reportGenerateShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 20,
              color: AppColors.subscriptionGold,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.upgradeStartTrial,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNothingDue(AppLocalizations l10n) {
    return Text(
      l10n.upgradeNothingDue,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.permissionsSecondary,
        fontSize: 11,
      ),
    );
  }

  Widget _buildSecondaryLinks(AppLocalizations l10n) {
    return Column(
      children: [
        TextButton(
          onPressed: _openComparison,
          child: Text(
            l10n.upgradeCompareAll,
            style: const TextStyle(
              color: AppColors.formAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: _onRestore,
          child: Text(
            l10n.upgradeRestorePurchase,
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

  Widget _buildLegalNote(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        l10n.upgradeLegalNote,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.permissionsSecondary,
          fontSize: 10,
          height: 1.35,
        ),
      ),
    );
  }

  // ============================================================
  // SHARED — white card
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: AppColors.permissionsCardShadow,
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: _cardDecoration(),
      child: child,
    );
  }
}

/// ============================================================
/// FULL PLAN COMPARISON BOTTOM SHEET
/// ============================================================

class _ComparisonSheet extends StatelessWidget {
  const _ComparisonSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.permissionsHeaderShadow,
                  blurRadius: 32,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 22,
                      color: AppColors.reportPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.upgradeComparisonTitle,
                        style: const TextStyle(
                          color: AppColors.reportPrimary,
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
                          color: AppColors.reportPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final id in UpgradeData.comparisonIds) ...[
                          _buildMatrixRow(l10n, id),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(l10n.comingSoon(l10n.upgradeTitle)),
                          ),
                        );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.formAccent,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.upgradeComparisonContinue,
                      style: const TextStyle(
                        fontSize: 14,
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

  Widget _buildMatrixRow(AppLocalizations l10n, String id) {
    final proExclusive = id != 'reminders';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _featureLabel(l10n, id),
              style: const TextStyle(
                color: AppColors.reportPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _featureValue(l10n, id),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: proExclusive
                  ? AppColors.formAccent
                  : AppColors.permissionsSecondary,
              fontSize: 11,
              fontWeight: proExclusive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _featureLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'reminders' => l10n.upgradeFeatureReminders,
      'interactions' => l10n.upgradeFeatureInteractions,
      'refills' => l10n.upgradeFeatureRefills,
      'reports' => l10n.upgradeFeatureReports,
      _ => l10n.upgradeFeatureFamily,
    };
  }

  String _featureValue(AppLocalizations l10n, String id) {
    return switch (id) {
      'reminders' => l10n.upgradeFeatureRemindersValue,
      'family' => l10n.upgradeValueFamily,
      _ => l10n.upgradeValuePro,
    };
  }
}
