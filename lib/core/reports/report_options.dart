/// What a report contains. M17 step 1.
enum ReportSection { adherence, vitals, sideEffects }

class ReportOptions {
  const ReportOptions(this.sections);

  /// Adherence only: the default of the Report Builder.
  const ReportOptions.adherenceOnly()
    : sections = const {ReportSection.adherence};

  final Set<ReportSection> sections;

  bool get isValid => sections.isNotEmpty;

  bool get adherence => sections.contains(ReportSection.adherence);
  bool get vitals => sections.contains(ReportSection.vitals);
  bool get sideEffects => sections.contains(ReportSection.sideEffects);

  /// Vitals and side effects are health data (they need health access in the
  /// security rules); adherence alone does not.
  bool get needsHealthAccess => vitals || sideEffects;

  ReportOptions toggled(ReportSection s) {
    final next = {...sections};
    if (!next.remove(s)) next.add(s);
    return ReportOptions(next);
  }
}
