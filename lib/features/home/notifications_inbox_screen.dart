import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/doctors/appointment_validator.dart';
import '../../core/doctors/appointment_models.dart';
import '../../core/dose_time.dart';
import '../../core/inventory/inventory_repository.dart';
import '../../core/notification_feed.dart';
import '../../core/services/appointment_reminders.dart';
import '../../core/vitals/symptom_entry.dart';
import '../../models/dose.dart';
import '../../l10n/app_localizations.dart';
import '../meds/appointment_screen.dart';
import '../meds/inventory_screen.dart';
import '../meds/side_effects_screen.dart';
import '../settings/reminder_readiness_card.dart';
import 'notification_sources.dart';

/// The screen behind the bell on Home. Two chips:
///  * **App**: missed doses, doses someone else logged, reminders that may not
///    ring, appointments in the next 48 hours;
///  * **Medicine**: stock (out / running low) and side effects of the last 7
///    days.
/// The list is computed from the profile's data ([NotificationFeed]); pull
/// down to refresh.
class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({
    super.key,
    required this.profileId,
    this.sources,
    this.initial = FeedCategory.app,
  });

  final String profileId;

  /// Test seam (null = Firestore).
  final NotificationSources? sources;

  final FeedCategory initial;

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  late FeedCategory _category = widget.initial;
  late final NotificationSources _sources =
      widget.sources ?? NotificationSources.firestore();

  List<FeedItem> _items = const [];
  bool _loading = true;
  int _failed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    var failed = 0;

    // A closure, so a source that throws before it returns a Future (for
    // example Firebase not ready) is caught too.
    Future<T> guard<T>(Future<T> Function() f, T fallback) async {
      try {
        return await f();
      } catch (_) {
        failed++;
        return fallback;
      }
    }

    final id = widget.profileId;
    final dosesF = guard<List<Dose>>(() => _sources.todayDoses(id), const []);
    final stockF = guard<List<InventoryItem>>(
      () => _sources.inventory(id),
      const [],
    );
    final symptomsF = guard<List<SymptomEntry>>(
      () => _sources.symptoms(id, now.subtract(NotificationFeed.symptomWindow)),
      const [],
    );
    final apptsF = guard<List<Appointment>>(
      () => _sources.appointments(id, now),
      const [],
    );
    final riskF = guard<bool>(() => _sources.remindersAtRisk(), false);
    await Future.wait<Object>([dosesF, stockF, symptomsF, apptsF, riskF]);
    if (!mounted) return;

    final doses = await dosesF;
    final stock = await stockF;
    final symptoms = await symptomsF;
    final appts = await apptsF;
    final risk = await riskF;
    final names = <String, String>{
      for (final i in stock) i.medicationId: i.medicineName,
    };

    setState(() {
      _items = NotificationFeed.build(
        now: now,
        myUid: _sources.myUid,
        todayDoses: doses,
        inventory: stock,
        symptoms: symptoms,
        appointments: appts,
        remindersAtRisk: risk,
        medicineNames: names,
      );
      _failed = failed;
      _loading = false;
    });
  }

  // ------------------------------------------------------------ taps

  Future<void> _open(FeedItem item) async {
    switch (item.kind) {
      case FeedKind.missedDose:
      case FeedKind.caregiverTaken:
      case FeedKind.caregiverSkipped:
        // The dose cards live on Home.
        Navigator.of(context).maybePop();
        return;
      case FeedKind.remindersAtRisk:
        await showReminderSetupSheet(context);
      case FeedKind.upcomingAppointment:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
      case FeedKind.outOfStock:
      case FeedKind.lowStock:
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const InventoryScreen()));
      case FeedKind.sideEffect:
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SideEffectsScreen()));
    }
    if (mounted) await _load();
  }

  // ------------------------------------------------------------ text

  String _when(BuildContext context, DateTime at) {
    final l = at.toLocal();
    final now = DateTime.now();
    final time = formatDoseTime(context, at);
    if (l.year == now.year && l.month == now.month && l.day == now.day) {
      return time;
    }
    return '${MaterialLocalizations.of(context).formatMediumDate(l)}, $time';
  }

  (String, String) _text(AppLocalizations l10n, FeedItem i) {
    final time = formatDoseTime(context, i.at);
    switch (i.kind) {
      case FeedKind.missedDose:
        return (
          l10n.inboxMissedDose(i.subject),
          l10n.inboxMissedDoseBody(time),
        );
      case FeedKind.caregiverTaken:
        return (l10n.inboxCaregiverTaken(i.subject), l10n.inboxLoggedAt(time));
      case FeedKind.caregiverSkipped:
        return (
          l10n.inboxCaregiverSkipped(i.subject),
          l10n.inboxLoggedAt(time),
        );
      case FeedKind.remindersAtRisk:
        return (l10n.reminderSetupCardTitle, l10n.reminderSetupCardBody);
      case FeedKind.upcomingAppointment:
        final type =
            AppointmentType.fromCode(i.subject) ?? AppointmentType.other;
        return (
          l10n.inboxAppointmentTitle(AppointmentTexts.typeLabel(l10n, type)),
          '',
        );
      case FeedKind.outOfStock:
        return (l10n.inboxOutOfStock(i.subject), l10n.inboxOutOfStockBody);
      case FeedKind.lowStock:
        return (
          l10n.inboxLowStock(i.subject),
          l10n.inboxLowStockBody(i.number ?? 0),
        );
      case FeedKind.sideEffect:
        final sev = i.number ?? 0;
        return (
          l10n.inboxSideEffect(i.subject),
          i.detail == null
              ? l10n.inboxSideEffectBody(sev)
              : l10n.inboxSideEffectBodyWithMed(sev, i.detail!),
        );
    }
  }

  /// The small grey time line, or none when it would only repeat the text
  /// above it ("It was due at 11:56 AM.") or mean nothing ("now").
  String? _timeLine(AppLocalizations l10n, FeedItem i) {
    if (i.kind == FeedKind.remindersAtRisk) return null;
    final when = _when(context, i.at);
    final body = _text(l10n, i).$2;
    return body.contains(formatDoseTime(context, i.at)) && when.length < 12
        ? null
        : when;
  }

  IconData _icon(FeedKind k) => switch (k) {
    FeedKind.missedDose => Icons.alarm_off_rounded,
    FeedKind.caregiverTaken => Icons.check_circle_outline_rounded,
    FeedKind.caregiverSkipped => Icons.skip_next_rounded,
    FeedKind.remindersAtRisk => Icons.notifications_off_rounded,
    FeedKind.upcomingAppointment => Icons.event_rounded,
    FeedKind.outOfStock => Icons.production_quantity_limits_rounded,
    FeedKind.lowStock => Icons.inventory_2_outlined,
    FeedKind.sideEffect => Icons.healing_rounded,
  };

  Color _color(FeedLevel l) => switch (l) {
    FeedLevel.urgent => AppColors.error,
    FeedLevel.warning => AppColors.accentOrange,
    FeedLevel.info => AppColors.formAccent,
  };

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = NotificationFeed.of(_items, FeedCategory.app);
    final medicine = NotificationFeed.of(_items, FeedCategory.medicine);
    final shown = _category == FeedCategory.app ? app : medicine;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.headerDark,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 16, 14),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('inbox-back'),
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.surface,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.inboxTitle,
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              // On a tablet or a landscape phone the content stays a
              // readable column instead of stretching edge to edge.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          // Two equal halves of the screen width.
                          Expanded(
                            child: _InboxChip(
                              key: const Key('inbox-chip-app'),
                              label: l10n.inboxChipApp,
                              count: app.length,
                              selected: _category == FeedCategory.app,
                              onTap: () =>
                                  setState(() => _category = FeedCategory.app),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InboxChip(
                              key: const Key('inbox-chip-medicine'),
                              label: l10n.inboxChipMedicine,
                              count: medicine.length,
                              selected: _category == FeedCategory.medicine,
                              onTap: () => setState(
                                () => _category = FeedCategory.medicine,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _loading && _items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: CircularProgressIndicator()),
                                ],
                              )
                            : ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  32,
                                ),
                                children: [
                                  if (_failed > 0)
                                    Container(
                                      key: const Key('inbox-partial'),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.accentOrange,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.inboxPartial,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (shown.isEmpty)
                                    _Empty(
                                      text: _category == FeedCategory.app
                                          ? l10n.inboxEmptyApp
                                          : l10n.inboxEmptyMedicine,
                                    )
                                  else
                                    for (final item in shown)
                                      _FeedTile(
                                        key: ValueKey<String>(item.id),
                                        icon: _icon(item.kind),
                                        color: _color(item.level),
                                        title: _text(l10n, item).$1,
                                        body: _text(l10n, item).$2,
                                        time: _timeLine(l10n, item),
                                        onTap: () => _open(item),
                                      ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxChip extends StatelessWidget {
  const _InboxChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label ($count)',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? AppColors.formAccent : AppColors.surface,
        shape: StadiumBorder(
          side: const BorderSide(color: AppColors.formAccent),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // Shrinks (never overflows) with a long label or very large text.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.surface
                            : AppColors.formAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.surface
                              : AppColors.formAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: selected
                                ? AppColors.formAccent
                                : AppColors.surface,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
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
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (time != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          time!,
                          style: const TextStyle(
                            color: AppColors.fieldHint,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
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

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 52,
            color: AppColors.fieldHint,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            key: const Key('inbox-empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
