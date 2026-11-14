import '../../core/vitals/symptom_entry.dart';

/// ============================================================
/// SIDE EFFECTS DATA
///
/// M15 step 6: backed by `profiles/{memberId}/symptoms/{id}` (see
/// FirebaseSymptomRepository). This file only maps stored [SymptomEntry]s to
/// the entries the Side Effects screen draws; there is no in-memory or demo
/// data any more.
/// ============================================================

enum SideEffectSeverityLevel { mild, moderate, severe }

class SideEffectEntry {
  const SideEffectEntry({
    required this.id,
    required this.symptom,
    required this.medicationName,
    required this.medicationStrength,
    required this.severity,
    required this.recordedAt,
    this.note,
    this.medicationId,
  });

  final String id;

  /// Medication this symptom is linked to (null = not linked to any).
  final String? medicationId;

  /// "Metformin 500mg", or empty when no medication is linked / known.
  String get medicationLabel => '$medicationName $medicationStrength'.trim();

  /// Example: Nausea, Headache, Dizziness
  final String symptom;

  /// Linked medication — abhi name/strength text.
  /// TODO Backend: medicationId reference (Firestore).
  final String medicationName;
  final String medicationStrength;

  /// 1..5
  final int severity;

  final DateTime recordedAt;
  final String? note;

  // ================= COMPUTED =================

  /// 1-2 → Mild | 3 → Moderate | 4-5 → Severe
  SideEffectSeverityLevel get level {
    if (severity <= 2) {
      return SideEffectSeverityLevel.mild;
    }

    if (severity == 3) {
      return SideEffectSeverityLevel.moderate;
    }

    return SideEffectSeverityLevel.severe;
  }

  String get severityName {
    switch (level) {
      case SideEffectSeverityLevel.mild:
        return 'Mild';
      case SideEffectSeverityLevel.moderate:
        return 'Moderate';
      case SideEffectSeverityLevel.severe:
        return 'Severe';
    }
  }

  /// Example: "Moderate (3/5)"
  String get severityLabel => '$severityName ($severity/5)';
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
/// A medication's display name and strength, for labelling symptoms.
typedef MedicationLabel = ({String name, String strength});

class SideEffectsData {
  SideEffectsData._();

  /// Maps stored symptoms to screen entries, newest first. [medicationsById]
  /// resolves `medicationId` to a name and strength; an id that cannot be
  /// resolved (deleted medication) is kept as an entry without a label.
  static List<SideEffectEntry> fromSymptoms(
    Iterable<SymptomEntry> symptoms,
    Map<String, MedicationLabel> medicationsById,
  ) {
    final out = <SideEffectEntry>[];
    for (final e in symptoms) {
      final id = e.id;
      if (id == null) continue;

      final med = e.medicationId == null
          ? null
          : medicationsById[e.medicationId];
      out.add(
        SideEffectEntry(
          id: id,
          symptom: e.symptom,
          medicationId: e.medicationId,
          medicationName: med?.name ?? '',
          medicationStrength: med?.strength ?? '',
          severity: e.severity.clamp(1, 5),
          recordedAt: e.occurredAt,
          note: e.notes,
        ),
      );
    }
    out.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return out;
  }

  /// Entries recorded in the month of [now] (local time).
  static int countThisMonth(List<SideEffectEntry> entries, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return entries.where((e) {
      final d = e.recordedAt.toLocal();
      return d.year == n.year && d.month == n.month;
    }).length;
  }
}
