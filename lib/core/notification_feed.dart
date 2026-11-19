import '../models/dose.dart';
import 'inventory/inventory_repository.dart';
import 'doctors/appointment_models.dart';
import 'vitals/symptom_entry.dart';

/// The two chips of the Notifications screen.
enum FeedCategory {
  /// The app itself: missed doses, what others logged, reminders that may not
  /// ring, appointments coming up.
  app,

  /// The medicines: stock (inventory) and side effects.
  medicine,
}

enum FeedKind {
  missedDose,
  caregiverTaken,
  caregiverSkipped,
  remindersAtRisk,
  upcomingAppointment,
  outOfStock,
  lowStock,
  sideEffect,
}

/// How much attention an item needs.
enum FeedLevel { info, warning, urgent }

/// One line of the Notifications screen. It holds DATA, not text: the screen
/// writes the words in the app language.
class FeedItem {
  const FeedItem({
    required this.id,
    required this.category,
    required this.kind,
    required this.level,
    required this.at,
    this.subject = '',
    this.detail,
    this.number,
  });

  final String id;
  final FeedCategory category;
  final FeedKind kind;
  final FeedLevel level;

  /// When it happened, or will happen (an appointment).
  final DateTime at;

  /// The medicine, symptom or appointment type.
  final String subject;

  /// A second name: the medicine a side effect was linked to.
  final String? detail;

  /// Days of supply left, side-effect severity ...
  final int? number;
}

/// Builds the Notifications list from data the app already reads. Pure: no
/// Firestore, no clock of its own (there is no server on the Spark plan, so the
/// list is computed, not stored).
class NotificationFeed {
  NotificationFeed._();

  static const Duration appointmentWindow = Duration(hours: 48);
  static const Duration symptomWindow = Duration(days: 7);
  static const int maxItems = 60;

  static List<FeedItem> build({
    required DateTime now,
    String? myUid,
    Iterable<Dose> todayDoses = const [],
    Iterable<InventoryItem> inventory = const [],
    Iterable<SymptomEntry> symptoms = const [],
    Iterable<Appointment> appointments = const [],
    Map<String, String> medicineNames = const {},
    bool remindersAtRisk = false,
  }) {
    final items = <FeedItem>[];
    final at = now.toUtc();

    // ----- App: doses
    for (final d in todayDoses) {
      if (d.isPrn) continue;
      final late =
          (d.status == DoseStatus.pending || d.status == DoseStatus.snoozed) &&
          d.missDeadline.toUtc().isBefore(at);
      if (d.status == DoseStatus.missed || late) {
        items.add(
          FeedItem(
            id: 'missed_${d.id}',
            category: FeedCategory.app,
            kind: FeedKind.missedDose,
            level: FeedLevel.urgent,
            at: d.scheduledAt,
            subject: d.medName,
          ),
        );
      } else if ((d.status == DoseStatus.taken ||
              d.status == DoseStatus.skipped) &&
          d.loggedBy != null &&
          d.loggedBy!.isNotEmpty &&
          d.loggedBy != myUid) {
        items.add(
          FeedItem(
            id: 'by_other_${d.id}',
            category: FeedCategory.app,
            kind: d.status == DoseStatus.taken
                ? FeedKind.caregiverTaken
                : FeedKind.caregiverSkipped,
            level: FeedLevel.info,
            at: d.loggedAt ?? d.scheduledAt,
            subject: d.medName,
          ),
        );
      }
    }

    // ----- App: reminders that may not ring
    if (remindersAtRisk) {
      items.add(
        FeedItem(
          id: 'reminders_at_risk',
          category: FeedCategory.app,
          kind: FeedKind.remindersAtRisk,
          level: FeedLevel.warning,
          at: now,
        ),
      );
    }

    // ----- App: appointments in the next 48 hours
    for (final a in appointments) {
      final starts = a.startsAt.toUtc();
      if (starts.isBefore(at) || starts.isAfter(at.add(appointmentWindow))) {
        continue;
      }
      items.add(
        FeedItem(
          id: 'appt_${a.id}',
          category: FeedCategory.app,
          kind: FeedKind.upcomingAppointment,
          level: starts.difference(at) <= const Duration(hours: 24)
              ? FeedLevel.warning
              : FeedLevel.info,
          at: a.startsAt,
          subject: a.type.code,
        ),
      );
    }

    // ----- Medicine: stock
    for (final i in inventory) {
      // A medicine whose stock is not tracked has quantity 0 by default: that
      // is "unknown", not "out of stock".
      final tracked =
          i.unitsPerDay != null ||
          i.packageQuantity != null ||
          i.lastAdjustedAt != null;
      if (!tracked) continue;
      if (i.remainingQuantity <= 0) {
        items.add(
          FeedItem(
            id: 'out_${i.medicationId}',
            category: FeedCategory.medicine,
            kind: FeedKind.outOfStock,
            level: FeedLevel.urgent,
            at: i.lastAdjustedAt ?? now,
            subject: i.medicineName,
          ),
        );
      } else if (i.isLowStock) {
        items.add(
          FeedItem(
            id: 'low_${i.medicationId}',
            category: FeedCategory.medicine,
            kind: FeedKind.lowStock,
            level: FeedLevel.warning,
            at: i.lastAdjustedAt ?? now,
            subject: i.medicineName,
            number: i.daysOfSupply,
          ),
        );
      }
    }

    // ----- Medicine: side effects of the last 7 days
    final since = at.subtract(symptomWindow);
    for (final s in symptoms) {
      if (s.occurredAt.toUtc().isBefore(since)) continue;
      items.add(
        FeedItem(
          id: 'se_${s.id ?? s.occurredAt.millisecondsSinceEpoch}',
          category: FeedCategory.medicine,
          kind: FeedKind.sideEffect,
          level: s.severity >= 4 ? FeedLevel.urgent : FeedLevel.info,
          at: s.occurredAt,
          subject: s.symptom,
          detail: s.medicationId == null ? null : medicineNames[s.medicationId],
          number: s.severity,
        ),
      );
    }

    // Most urgent first; inside a level, the closest to now first.
    items.sort((a, b) {
      final l = b.level.index - a.level.index;
      if (l != 0) return l;
      final da = a.at.toUtc().difference(at).abs();
      final db = b.at.toUtc().difference(at).abs();
      final t = da.compareTo(db);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
    return items.length > maxItems ? items.sublist(0, maxItems) : items;
  }

  /// Items of one chip.
  static List<FeedItem> of(List<FeedItem> items, FeedCategory category) => [
    for (final i in items)
      if (i.category == category) i,
  ];

  /// Does anything need attention (a warning or an urgent item)?
  static bool needsAttention(Iterable<FeedItem> items) =>
      items.any((i) => i.level != FeedLevel.info);
}
