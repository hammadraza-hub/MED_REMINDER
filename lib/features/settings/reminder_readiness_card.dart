import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/reminders/reminder_readiness.dart';
import '../../core/services/reminder_permission_service.dart';
import '../../l10n/app_localizations.dart';

/// "Make reminders reliable" (M22): a card that shows only while the phone is
/// stopping, or may stop, dose reminders, and opens a guided sheet that asks
/// for each permission with the system's own prompt or settings page.
///
/// With [autoPrompt] the sheet opens by itself once per app start when
/// reminders are blocked or at risk, so the person does not have to find the
/// phone settings.
class ReminderReadinessCard extends StatefulWidget {
  const ReminderReadinessCard({
    super.key,
    this.autoPrompt = false,
    this.service,
  });

  final bool autoPrompt;

  /// Test seam (null = the real service).
  final Future<ReminderReadiness> Function()? service;

  @override
  State<ReminderReadinessCard> createState() => _ReminderReadinessCardState();
}

class _ReminderReadinessCardState extends State<ReminderReadinessCard>
    with WidgetsBindingObserver {
  /// One automatic prompt per app start.
  static bool _prompted = false;

  ReminderReadiness? _readiness;

  Future<ReminderReadiness> _check() =>
      (widget.service ?? ReminderPermissionService.instance.check)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh(first: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from a system settings page: look again.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh({bool first = false}) async {
    final r = await _check();
    if (!mounted) return;
    setState(() => _readiness = r);
    if (first && widget.autoPrompt && !_prompted && r.atRisk) {
      _prompted = true;
      // After the first frame so the sheet has a context to sit on.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open();
      });
    }
  }

  Future<void> _open() async {
    await showReminderSetupSheet(context, check: widget.service);
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final r = _readiness;
    // Nothing to show when all is fine (the autostart tip lives in the sheet).
    if (r == null || r.allGood) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final blocked = r.blocked;
    return Container(
      key: const Key('reminder-readiness-card'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: blocked ? AppColors.error : AppColors.formAccent,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            blocked ? Icons.notifications_off_rounded : Icons.alarm_off_rounded,
            color: blocked ? AppColors.error : AppColors.formAccent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reminderSetupCardTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.reminderSetupCardBody,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const Key('reminder-readiness-fix'),
            onPressed: _open,
            child: Text(l10n.reminderSetupCardButton),
          ),
        ],
      ),
    );
  }
}

/// The guided sheet: one row per step with a button that opens the system's
/// prompt or settings page. It re-checks when the person comes back.
Future<void> showReminderSetupSheet(
  BuildContext context, {
  Future<ReminderReadiness> Function()? check,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReminderSetupSheet(check: check),
  );
}

class ReminderSetupSheet extends StatefulWidget {
  const ReminderSetupSheet({super.key, this.check, this.run});

  final Future<ReminderReadiness> Function()? check;

  /// Test seam for the system call of one step.
  final Future<void> Function(ReminderStep step)? run;

  @override
  State<ReminderSetupSheet> createState() => _ReminderSetupSheetState();
}

class _ReminderSetupSheetState extends State<ReminderSetupSheet>
    with WidgetsBindingObserver {
  ReminderReadiness? _r;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final r =
        await (widget.check ?? ReminderPermissionService.instance.check)();
    if (!mounted) return;
    setState(() => _r = r);
  }

  Future<void> _do(ReminderStep step) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await (widget.run ?? ReminderPermissionService.instance.run)(step);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _refresh();
    // New permission: set the alarms again now, not at the next app start.
    if (widget.run == null) {
      await ReminderPermissionService.instance.afterChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = _r;
    final steps = <(ReminderStep, bool, String, String)>[
      if (r != null) ...[
        (
          ReminderStep.notifications,
          r.notifications,
          l10n.reminderStepNotifications,
          l10n.reminderStepNotificationsDesc,
        ),
        (
          ReminderStep.exactAlarms,
          r.exactAlarms,
          l10n.reminderStepExact,
          l10n.reminderStepExactDesc,
        ),
        (
          ReminderStep.battery,
          r.batteryUnrestricted,
          l10n.reminderStepBattery,
          l10n.reminderStepBatteryDesc,
        ),
        if (r.needsAutostartTip)
          (
            ReminderStep.autostart,
            false,
            l10n.reminderStepAutostart,
            l10n.reminderStepAutostartDesc,
          ),
      ],
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            key: const Key('reminder-setup-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.reminderSetupTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.reminderSetupIntro,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              if (r == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                for (final s in steps) _row(l10n, s.$1, s.$2, s.$3, s.$4),
                if (r.allGood && !r.needsAutostartTip)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.reminderSetupAllDone,
                      key: const Key('reminder-setup-done'),
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  r != null && r.allGood
                      ? l10n.reminderSetupClose
                      : l10n.reminderSetupLater,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    AppLocalizations l10n,
    ReminderStep step,
    bool done,
    String title,
    String desc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        key: Key('reminder-step-${step.name}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: done ? AppColors.formAccent : AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            Text(
              l10n.reminderStepDone,
              style: const TextStyle(
                color: AppColors.formAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            OutlinedButton(
              key: Key('reminder-allow-${step.name}'),
              onPressed: _busy ? null : () => _do(step),
              child: Text(l10n.reminderStepAllow),
            ),
        ],
      ),
    );
  }
}
