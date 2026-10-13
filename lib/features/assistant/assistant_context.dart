import '../../core/medications/local_medication_repository.dart';
import '../../core/medications/local_medication_schedule_repository.dart';
import '../../core/medications/medication_repository.dart';
import '../../core/medications/medication_schedule_repository.dart';
import '../../core/profile/profile_controller.dart';
import '../home/home_data.dart';
import '../home/vitals_data.dart';
import '../meds/inventory_data.dart';

/// ============================================================
/// ASSISTANT CONTEXT
///
/// PURPOSE:
/// AI ko user ke REAL app data ka compact summary deta hai, taake
/// jab user refill, dose time ya apni medications ke baare mein
/// poochhe to jawab dummy guess ki jagah asli data se aaye.
///
/// DATA SOURCES:
/// • Selected family member (ProfileController)
/// • Active medications + schedules (Drift repositories — real)
/// • Refill / inventory (InventoryData)
/// • Today's doses (HomeData)
/// • Latest vitals (VitalsData)
///
/// TODO Backend:
/// Jab Firebase lagega to yahan Firestore queries aayengi; baaki
/// AI layer (AiService) untouched rahegi.
/// ============================================================
class AssistantContext {
  AssistantContext._();

  static final MedicationRepository _medications =
      LocalMedicationRepository();
  static final MedicationScheduleRepository _schedules =
      LocalMedicationScheduleRepository();

  /// Poora context string build karta hai (AI ke system prompt ke liye).
  static Future<String> build() async {
    final buffer = StringBuffer();
    final memberId = ProfileController.instance.memberId;
    final memberName = ProfileController.instance.displayName;

    buffer.writeln('Family member: '
        '${memberName.trim().isEmpty ? 'unknown' : memberName}');
    buffer.writeln('Date: ${DateTime.now().toIso8601String().split('T').first}');
    buffer.writeln();

    await _writeMedications(buffer, memberId);
    _writeRefills(buffer);
    _writeTodayDoses(buffer);
    _writeVitals(buffer);

    return buffer.toString().trim();
  }

  // ================= MEDICATIONS + SCHEDULES (real) =================

  static Future<void> _writeMedications(StringBuffer buffer, String? memberId) async {
    if (memberId == null || memberId.isEmpty) {
      buffer.writeln('Medications: none (no member selected).');
      buffer.writeln();
      return;
    }

    List<MedicationProfile> meds = const [];
    try {
      await _medications.seedInitialMedicationsIfNeeded(memberId);
      meds = await _medications.getActiveMedications(memberId);
    } catch (_) {
      // Read fail ho to context khaali chhod do (AI general jawab dega).
    }

    if (meds.isEmpty) {
      buffer.writeln('Medications: none recorded.');
      buffer.writeln();
      return;
    }

    buffer.writeln('Medications & their dose times:');
    for (final med in meds) {
      final form = med.medicineForm?.trim();
      final formPart = (form == null || form.isEmpty) ? '' : ' [$form]';

      List<String> times = const [];
      try {
        final schedules = await _schedules.getSchedulesForMedication(med.id);
        times = schedules
            .where((s) => s.isEnabled && s.memberId == memberId)
            .map((s) => _formatTime(s.timeOfDay))
            .toList()
          ..sort();
      } catch (_) {
        times = const [];
      }

      final timePart =
          times.isEmpty ? 'no schedule set' : 'doses at ${times.join(', ')}';
      final instructions = med.instructions?.trim();
      final instrPart = (instructions == null || instructions.isEmpty)
          ? ''
          : ' — instructions: $instructions';

      buffer.writeln(
        '- ${med.name} ${med.displayStrength}$formPart: $timePart$instrPart',
      );
    }
    buffer.writeln();
  }

  // ================= REFILL / INVENTORY =================

  static void _writeRefills(StringBuffer buffer) {
    final List<InventoryItem> items;
    try {
      items = InventoryData.inventory();
    } catch (_) {
      return;
    }

    if (items.isEmpty) return;

    buffer.writeln('Refill / remaining supply:');
    for (final item in items) {
      buffer.writeln(
        '- ${item.displayName}: ${item.remainingQuantity} ${item.unitLabel}(s) '
        'left, ~${item.estimatedDaysRemaining} days remaining '
        '(${item.isLowStock ? 'LOW STOCK' : 'OK'})',
      );
    }
    buffer.writeln();
  }

  // ================= TODAY'S DOSES =================

  static void _writeTodayDoses(StringBuffer buffer) {
    final List<Dose> doses;
    try {
      doses = HomeData.todayDoses();
    } catch (_) {
      return;
    }

    if (doses.isEmpty) return;

    buffer.writeln("Today's doses:");
    for (final dose in doses) {
      buffer.writeln(
        '- ${dose.name} ${dose.doseAmount} at ${dose.time} — '
        '${_doseStatusLabel(dose.status)}',
      );
    }
    buffer.writeln();
  }

  // ================= VITALS =================

  static void _writeVitals(StringBuffer buffer) {
    final List<VitalMetric> metrics;
    try {
      metrics = VitalsData.metrics();
    } catch (_) {
      return;
    }

    if (metrics.isEmpty) return;

    buffer.writeln('Latest vitals:');
    for (final metric in metrics) {
      buffer.writeln('- ${metric.title}: ${metric.value} ${metric.unit}');
    }
  }

  // ================= HELPERS =================

  /// "HH:mm" → "8:00 PM" (readable) ; invalid ho to raw lauta deta hai.
  static String _formatTime(String timeOfDay) {
    final parts = timeOfDay.split(':');
    if (parts.length < 2) return timeOfDay;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return timeOfDay;

    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$hour12:$mm $period';
  }

  static String _doseStatusLabel(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return 'taken';
      case DoseStatus.pending:
        return 'pending';
      case DoseStatus.upcoming:
        return 'upcoming';
      case DoseStatus.skipped:
        return 'skipped';
    }
  }
}
