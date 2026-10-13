import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'compare_plans_screen.dart';
import 'subscription_data.dart';

/// ============================================================
/// SUBSCRIPTION SCREEN
///
/// PURPOSE:
/// Current plan dekhna aur manage karna — renewal date, billing,
/// upgrade/downgrade, compare plans, restore purchase aur cancel.
///
/// NAVIGATION:
/// Settings → Subscription row se khulti hai. Detail screen hone ki
/// wajah se shared AppBottomNavigation reuse hoti hai (Settings tab).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// RevenueCat / App Store / Play Billing integration ke baad yahan se
/// real upgrade/downgrade/restore/cancel actions chalengi.
/// ============================================================
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Cancel subscription?',
            style: TextStyle(
              color: AppColors.permissionsHeader,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Your Pro features will remain active until the end of the '
            'billing period.',
            style: TextStyle(color: AppColors.shareSecondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Keep Plan',
                style: TextStyle(color: AppColors.shareSecondaryText),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.interactionWarningRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      _showMessage(context, 'Cancel Subscription — coming soon');
    }
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(BuildContext context, int index) {
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
          _buildHeader(context),
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
                        _buildCurrentPlanCard(),
                        const SizedBox(height: 16),
                        _buildManagePlanSection(context),
                        const SizedBox(height: 20),
                        _buildCompareButton(context),
                        const SizedBox(height: 10),
                        _buildSecondaryLinks(context),
                        const SizedBox(height: 12),
                        _buildFooter(),
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
        onTap: (index) => _onBottomNavigationTap(context, index),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
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
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 2),
              const Expanded(
                child: Text(
                  'Subscription',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppAvatar(
                size: 36,
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
  // CURRENT PLAN CARD
  // ============================================================

  Widget _buildCurrentPlanCard() {
    final plan = SubscriptionData.currentPlan;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.permissionsHeader,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 28,
                  color: AppColors.subscriptionGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppColors.permissionsHeader,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.status,
                      style: const TextStyle(
                        color: AppColors.shareSecondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (plan.isPro)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.permissionsHeader,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.shareDivider,
            ),
          ),
          _buildInfoRow('Renewal date', plan.renewalDate),
          const SizedBox(height: 10),
          _buildInfoRow('Billing', plan.billing),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.shareSecondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.permissionsHeader,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MANAGE PLAN SECTION
  // ============================================================

  Widget _buildManagePlanSection(BuildContext context) {
    final options = SubscriptionData.manageOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MANAGE PLAN',
            style: TextStyle(
              color: AppColors.permissionsHeader,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        _card(
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.shareDivider,
                    ),
                  ),
                _buildManageRow(context, options[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManageRow(BuildContext context, ManagePlanOption option) {
    return InkWell(
      onTap: () => _showMessage(context, '${option.title} — coming soon'),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.shareTileFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              option.icon,
              size: 18,
              color: option.highlightIcon
                  ? AppColors.formAccent
                  : AppColors.shareSecondaryText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.subtitle,
                  style: const TextStyle(
                    color: AppColors.shareSecondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.shareSecondaryText,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPARE PLANS BUTTON
  // ============================================================

  Widget _buildCompareButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ComparePlansScreen()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 4,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              SubscriptionData.comparePlansLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECONDARY LINKS
  // ============================================================

  Widget _buildSecondaryLinks(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => _showMessage(context, 'Restore Purchase — coming soon'),
          child: const Text(
            'Restore Purchase',
            style: TextStyle(
              color: AppColors.formAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _confirmCancel(context),
          child: const Text(
            'Cancel Subscription',
            style: TextStyle(
              color: AppColors.interactionWarningRed,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lock_rounded,
              size: 13,
              color: AppColors.shareSecondaryText,
            ),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              SubscriptionData.footerNote,
              style: TextStyle(
                color: AppColors.shareSecondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED CARD
  // ============================================================

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.shareBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
