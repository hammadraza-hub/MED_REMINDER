/// What Free and Pro users may put in a report. M17 step 7.
///
/// Free: the last 7 days. Pro: any range up to [ReportRange.maxDays].
/// Reports are made on the phone, so this is an app-side rule only (there is
/// no server call to protect on the Spark plan).
class ReportProRule {
  const ReportProRule._();

  /// Longest range a Free user may report.
  static const int freeMaxDays = 7;

  /// True when a range of [dayCount] days needs Pro.
  static bool needsPro(int dayCount) => dayCount > freeMaxDays;
}
