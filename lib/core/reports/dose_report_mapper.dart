import '../../models/dose.dart';
import 'report_models.dart';

/// ============================================================
/// DOSE -> REPORT DOSE — M17 step 2
///
/// Turns the app's [Dose] into the report's plain [ReportDose] with the SAME
/// rules the Adherence Detail screen applies, so the numbers match:
/// * taken / skipped / missed stay as they are;
/// * a pending dose whose miss deadline has passed counts as MISSED;
/// * a pending dose still inside its window, and any snoozed dose, stays
///   pending (it is not part of the percentage).
/// ============================================================
class DoseReportMapper {
  DoseReportMapper._();

  static ReportDose fromDose(
    Dose dose, {
    required DateTime now,
    String? strength,
  }) {
    return ReportDose(
      id: dose.id,
      medicationId: dose.medicationId,
      medName: dose.medName,
      strength: strength,
      scheduledAt: dose.scheduledAt,
      status: statusOf(dose, now),
      reason: reasonOf(dose.reasonCode),
    );
  }

  static ReportDoseStatus statusOf(Dose dose, DateTime now) {
    switch (dose.status) {
      case DoseStatus.taken:
        return ReportDoseStatus.taken;
      case DoseStatus.skipped:
        return ReportDoseStatus.skipped;
      case DoseStatus.missed:
        return ReportDoseStatus.missed;
      case DoseStatus.snoozed:
        return ReportDoseStatus.pending;
      case DoseStatus.pending:
        return now.isAfter(dose.missDeadline)
            ? ReportDoseStatus.missed
            : ReportDoseStatus.pending;
    }
  }

  static ReportMissReason reasonOf(MissedDoseReason? r) {
    switch (r) {
      case MissedDoseReason.forgot:
        return ReportMissReason.forgot;
      case MissedDoseReason.sideEffect:
        return ReportMissReason.sideEffect;
      case MissedDoseReason.ranOut:
        return ReportMissReason.ranOut;
      case MissedDoseReason.other:
        return ReportMissReason.other;
      case null:
        return ReportMissReason.unspecified;
    }
  }
}
