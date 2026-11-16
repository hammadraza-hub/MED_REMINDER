/// The extra words of the PDF (the table and section words are shared with
/// the CSV, see `ReportCsvLabels`). Defaults are English; the Report Builder
/// fills these from the 5 app languages. M17 step 4.
class ReportPdfLabels {
  const ReportPdfLabels({
    this.subtitle = 'Medication adherence report',
    this.overallAdherence = 'Overall adherence',
    this.decidedDoses = 'doses with an outcome',
    this.dayOverview = 'Day by day',
    this.legendAllTaken = 'All taken',
    this.legendMissed = 'Missed',
    this.legendSkipped = 'Skipped',
    this.legendPending = 'Pending',
    this.legendNoDoses = 'No doses',
    this.latestToEarliest = 'Newest first',
    this.page = 'Page {page} of {pages}',
  });

  final String subtitle;
  final String overallAdherence;
  final String decidedDoses;
  final String dayOverview;
  final String legendAllTaken;
  final String legendMissed;
  final String legendSkipped;
  final String legendPending;
  final String legendNoDoses;
  final String latestToEarliest;

  /// Contains `{page}` and `{pages}`.
  final String page;

  String pageLabel(int page, int pages) =>
      this.page.replaceAll('{page}', '$page').replaceAll('{pages}', '$pages');
}
