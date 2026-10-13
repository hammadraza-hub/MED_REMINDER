import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import 'payment_success_data.dart';
import 'upgrade_data.dart';

/// ============================================================
/// PAYMENT SUCCESS (CONFIRMATION) SCREEN
///
/// PURPOSE:
/// Purchase confirm karna — success hero, order summary, receipt
/// info aur "Start Using Pro" CTA. Dashboard (now unlocked) par
/// wapas bhejta hai.
///
/// NAVIGATION:
/// Upgrade (paywall) → "Start free trial" se khulti hai. "Start
/// Using Pro" par dashboard (index 0) khul jaata hai.
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// RevenueCat / StoreKit / Play Billing receipt data + real order
/// id wire honge.
/// ============================================================
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.planId,
    this.isAnnual = true,
  });

  /// Purchased plan id ('solo' / 'family').
  final String planId;

  /// Annual billing ya monthly.
  final bool isAnnual;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================

  late final AnimationController _confettiController;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    final rng = math.Random(7);
    _particles = List.generate(42, (_) => _ConfettiParticle.random(rng));

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _onStartPro() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MedRemindShell(initialIndex: 0)),
      (route) => false,
    );
  }

  void _onViewReceipt() {
    // TODO Backend: receipt PDF open/share.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).comingSoon(
              AppLocalizations.of(context).paymentViewFullReceipt,
            ),
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
                        _buildHeroCard(l10n),
                        const SizedBox(height: 16),
                        _buildOrderSummaryCard(l10n),
                        const SizedBox(height: 16),
                        _buildReceiptCard(l10n),
                        const SizedBox(height: 20),
                        _buildStartButton(l10n),
                        const SizedBox(height: 12),
                        _buildUnlockNote(l10n),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.formAccent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.permissionsBadgeBackground,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.paymentTitle,
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
  // SUCCESS HERO CARD
  // ============================================================

  Widget _buildHeroCard(AppLocalizations l10n) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.shareTileFill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.formAccent,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: AppColors.formAccent,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.permissionsHeader,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: AppColors.subscriptionGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.paymentProNowTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  l10n.paymentWelcome(
                    _planName(l10n),
                    PaymentSuccessData.userName,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.shareSecondaryText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.shareTileFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulsingDot(),
                    const SizedBox(width: 6),
                    Text(
                      l10n.paymentPlanActive.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.permissionsHeader,
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
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(
                  progress: _confettiController.value,
                  particles: _particles,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ORDER SUMMARY CARD
  // ============================================================

  Widget _buildOrderSummaryCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.paymentOrderSummary.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.shareTileFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.paymentTrialActive,
                  style: const TextStyle(
                    color: AppColors.shareSecondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            l10n.paymentPlanLabel,
            '${_planName(l10n)} — ${_cadence(l10n)}',
            valueBold: true,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            l10n.paymentFreeTrialLabel,
            l10n.paymentFreeTrialValue(_price(l10n)),
            valueBold: true,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            l10n.paymentNextBillingLabel,
            _nextBillingDate(context),
            valueBold: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECEIPT CARD
  // ============================================================

  Widget _buildReceiptCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.paymentReceipt.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.shareSecondaryText,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            l10n.paymentOrderIdLabel,
            PaymentSuccessData.orderId,
            monospace: true,
          ),
          const SizedBox(height: 10),
          _buildPaymentMethodRow(l10n),
          const SizedBox(height: 10),
          _buildInfoRow(
            l10n.paymentReceiptSentLabel,
            PaymentSuccessData.email,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.shareDivider,
            ),
          ),
          GestureDetector(
            onTap: _onViewReceipt,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.paymentViewFullReceipt}  →',
                    style: const TextStyle(
                      color: AppColors.formAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  PaymentSuccessData.receiptSize,
                  style: const TextStyle(
                    color: AppColors.shareSecondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.paymentPaymentMethodLabel,
          style: const TextStyle(
            color: AppColors.shareSecondaryText,
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Container(
              width: 28,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.permissionsHeader,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.apple,
                size: 14,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              PaymentSuccessData.paymentMethod,
              style: const TextStyle(
                color: AppColors.permissionsHeader,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool valueBold = false,
    bool monospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.shareSecondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.permissionsHeader,
              fontSize: 12,
              fontWeight: valueBold || monospace
                  ? FontWeight.w700
                  : FontWeight.w500,
              fontFamily: monospace ? 'monospace' : null,
              letterSpacing: monospace ? -0.3 : null,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CTA + NOTE
  // ============================================================

  Widget _buildStartButton(AppLocalizations l10n) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _onStartPro,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 6,
          shadowColor: AppColors.reportGenerateShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.paymentStartPro,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockNote(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.star_rounded,
          size: 14,
          color: AppColors.subscriptionGold,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.paymentUnlockNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.shareSecondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _planName(AppLocalizations l10n) {
    return widget.planId == 'family'
        ? l10n.upgradePlanFamilyName
        : l10n.upgradePlanSoloName;
  }

  String _cadence(AppLocalizations l10n) {
    return widget.isAnnual ? l10n.upgradeAnnual : l10n.upgradeMonthly;
  }

  String _price(AppLocalizations l10n) {
    final value = widget.isAnnual
        ? UpgradeData.annualPrice[widget.planId] ?? ''
        : UpgradeData.monthlyPrice[widget.planId] ?? '';
    return widget.isAnnual
        ? l10n.upgradePriceAnnual(value)
        : l10n.upgradePriceMonthly(value);
  }

  String _nextBillingDate(BuildContext context) {
    final date = DateTime.now().add(
      const Duration(days: PaymentSuccessData.trialDays),
    );
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: AppColors.permissionsCardShadow,
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: child,
    );
  }
}

/// ============================================================
/// PULSING DOT
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

/// ============================================================
/// CONFETTI
/// ============================================================

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.color,
    required this.phase,
    required this.drift,
  });

  final double x;
  final double y;
  final double length;
  final double speed;
  final Color color;
  final double phase;
  final double drift;

  static const List<Color> _palette = [
    AppColors.formAccent,
    AppColors.subscriptionGold,
    AppColors.permissionsHeader,
    AppColors.shareSecondaryText,
    AppColors.permissionsBadgeBackground,
  ];

  factory _ConfettiParticle.random(math.Random rng) {
    return _ConfettiParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.45,
      length: rng.nextDouble() * 6 + 4,
      speed: rng.nextDouble() * 0.55 + 0.45,
      color: _palette[rng.nextInt(_palette.length)],
      phase: rng.nextDouble() * math.pi * 2,
      drift: rng.nextDouble() * 0.08 + 0.04,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final fade = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);

    for (final p in particles) {
      final y = (p.y + progress * p.speed) * size.height;
      final x =
          (p.x * size.width) + math.sin(p.phase + progress * math.pi * 4) * 10;

      if (y > size.height + 10) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: fade.clamp(0, 1).toDouble())
        ..strokeWidth = p.length / 1.5
        ..strokeCap = StrokeCap.round;

      final angle = p.phase + progress * math.pi * 6;
      final dx = math.cos(angle) * p.length / 2;
      final dy = math.sin(angle) * p.length / 2;

      canvas.drawLine(Offset(x - dx, y - dy), Offset(x + dx, y + dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
