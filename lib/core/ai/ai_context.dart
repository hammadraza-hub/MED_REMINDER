import '../reports/adherence_calculator.dart';
import '../reports/report_models.dart';
import '../reports/report_range.dart';
import '../../models/allergy.dart';
import '../../models/medication.dart';
import 'ai_text_scrubber.dart';

/// ============================================================
/// AI CONTEXT — M18 step 2
///
/// The small, privacy-safe summary of a person's medicine data that the AI
/// assistant may see: active medicines with their schedules, adherence of the
/// last 30 days, allergies.
///
/// PRIVACY BY CONSTRUCTION: there is no field here for a name, date of birth,
/// email, phone number or any other contact detail, so they cannot be sent by
/// mistake. Free text (medicine names, instructions, allergy notes) is also
/// cleaned by [AiTextScrubber].
/// ============================================================

class AiContextMed {
  const AiContextMed({
    required this.name,
    this.strength,
    this.form,
    required this.schedule,
    this.instructions,
  });

  final String name;
  final String? strength;
  final String? form;

  /// "Daily at 08:00, 20:00" or "As needed (PRN)".
  final String schedule;
  final String? instructions;
}

class AiContextMedAdherence {
  const AiContextMedAdherence({required this.name, required this.counts});

  final String name;
  final AdherenceCounts counts;
}

class AiContextAllergy {
  const AiContextAllergy({
    required this.name,
    required this.severity,
    this.note,
  });

  final String name;
  final String severity;
  final String? note;
}

class AiContext {
  const AiContext({
    required this.date,
    this.medications,
    this.adherenceTotal,
    this.adherenceByMed = const [],
    this.allergies,
    this.adherenceDays = AiContextBuilder.adherenceDays,
  });

  /// Today (a date, never a birth date).
  final DateTime date;

  /// null = could not be loaded (the AI is told so and must not guess).
  final List<AiContextMed>? medications;
  final AdherenceCounts? adherenceTotal;
  final List<AiContextMedAdherence> adherenceByMed;
  final List<AiContextAllergy>? allergies;
  final int adherenceDays;

  /// The text given to the AI (as part of its prompt).
  String toPromptText() {
    final b = StringBuffer();
    b.writeln('Date: ${ReportRange.dayKey(date)}');
    b.writeln();

    // Medications
    final meds = medications;
    if (meds == null) {
      b.writeln('Medicines: unavailable right now.');
    } else if (meds.isEmpty) {
      b.writeln('Medicines: none recorded.');
    } else {
      b.writeln('Active medicines:');
      for (final m in meds) {
        final parts = [
          m.name,
          if (m.strength != null) m.strength!,
          if (m.form != null) '[${m.form}]',
        ].join(' ');
        final note = m.instructions == null
            ? ''
            : ' — instructions: ${m.instructions}';
        b.writeln('- $parts: ${m.schedule}$note');
      }
    }
    b.writeln();

    // Adherence
    final total = adherenceTotal;
    if (total == null) {
      b.writeln('Adherence (last $adherenceDays days): unavailable right now.');
    } else if (!total.hasData) {
      b.writeln('Adherence (last $adherenceDays days): no doses recorded.');
    } else {
      final pct = total.decided == 0 ? 'n/a' : '${total.percent}%';
      b.writeln(
        'Adherence (last $adherenceDays days): $pct — '
        '${total.taken} taken, ${total.missed} missed, '
        '${total.skipped} skipped, ${total.pending} pending.',
      );
      for (final m in adherenceByMed) {
        final c = m.counts;
        final p = c.decided == 0 ? 'n/a' : '${c.percent}%';
        b.writeln(
          '- ${m.name}: $p (${c.taken} taken, ${c.missed} missed, '
          '${c.skipped} skipped)',
        );
      }
    }
    b.writeln();

    // Allergies
    final al = allergies;
    if (al == null) {
      b.writeln('Allergies: unavailable right now.');
    } else if (al.isEmpty) {
      b.writeln('Allergies: none recorded.');
    } else {
      b.writeln('Allergies:');
      for (final a in al) {
        final note = a.note == null ? '' : ' — ${a.note}';
        b.writeln('- ${a.name} (${a.severity})$note');
      }
    }

    return b.toString().trimRight();
  }
}

/// Builds an [AiContext] from injected data readers (so it is unit-testable).
class AiContextBuilder {
  AiContextBuilder({
    required this.fetchMedications,
    required this.fetchAllergies,
    required this.fetchDoses,
  });

  final Future<List<Medication>> Function() fetchMedications;
  final Future<List<Allergy>> Function() fetchAllergies;

  /// Doses of the range, already in the report shape (the same mapping the
  /// reports use, so the numbers match Adherence Detail and the PDF).
  final Future<List<ReportDose>> Function(ReportRange range) fetchDoses;

  static const int adherenceDays = 30;
  static const int maxMedications = 30;
  static const int maxAllergies = 20;
  static const int maxNameLength = 80;
  static const int maxTextLength = 120;

  Future<AiContext> build({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final range = ReportRange.lastDays(adherenceDays, now: today);

    List<AiContextMed>? meds;
    try {
      final all = await fetchMedications();
      meds = [
        for (final m
            in all
                .where((m) => m.status == MedicationStatus.active)
                .take(maxMedications))
          _med(m),
      ];
    } catch (_) {
      meds = null;
    }

    AdherenceCounts? total;
    var byMed = <AiContextMedAdherence>[];
    try {
      final doses = await fetchDoses(range);
      final summary = AdherenceCalculator.summarize(doses, range);
      total = summary.total;
      byMed = [
        for (final m in summary.perMedication.take(maxMedications))
          AiContextMedAdherence(
            name:
                AiTextScrubber.clean(m.displayName, maxLength: maxNameLength) ??
                '',
            counts: m.counts,
          ),
      ];
    } catch (_) {
      total = null;
    }

    List<AiContextAllergy>? allergies;
    try {
      final all = await fetchAllergies();
      allergies = [
        for (final a in all.take(maxAllergies))
          AiContextAllergy(
            name:
                AiTextScrubber.clean(a.name, maxLength: maxNameLength) ??
                'unknown',
            severity: a.severity,
            note: AiTextScrubber.clean(a.description, maxLength: maxTextLength),
          ),
      ];
    } catch (_) {
      allergies = null;
    }

    return AiContext(
      date: today,
      medications: meds,
      adherenceTotal: total,
      adherenceByMed: byMed,
      allergies: allergies,
    );
  }

  AiContextMed _med(Medication m) {
    // Built by the app (not typed by the user), so it is not scrubbed: a
    // cyclical schedule contains a start date that must stay readable.
    final scheduleText = m.schedule.description;
    return AiContextMed(
      name: AiTextScrubber.clean(m.name, maxLength: maxNameLength) ?? 'unknown',
      strength: AiTextScrubber.clean(m.strength, maxLength: 40),
      form: AiTextScrubber.clean(m.form, maxLength: 40),
      schedule: scheduleText,
      instructions: AiTextScrubber.clean(
        m.instructions,
        maxLength: maxTextLength,
      ),
    );
  }
}
