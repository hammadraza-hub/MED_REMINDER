/// All the words of the CSV report in one place. M17 step 3.
///
/// The defaults are English. The Report Builder (step 5) fills this from the
/// 5 app languages, so the builder itself never needs to change for a
/// language.
class ReportCsvLabels {
  const ReportCsvLabels({
    this.title = 'MedRemind health report',
    this.profile = 'Profile',
    this.dateRange = 'Date range',
    this.generatedAt = 'Generated at',
    this.disclaimerLabel = 'Disclaimer',
    this.disclaimer =
        'This report is made from information entered in the app. It is not '
        'a medical diagnosis. Please discuss it with your doctor.',
    this.adherenceSummary = 'Adherence summary',
    this.adherenceByDay = 'Adherence by day',
    this.adherenceByMedication = 'Adherence by medication',
    this.missedReasons = 'Missed and skipped doses by reason',
    this.vitals = 'Vitals (daily summary)',
    this.sideEffects = 'Side effects',
    this.date = 'Date',
    this.dateTime = 'Date and time',
    this.medication = 'Medication',
    this.taken = 'Taken',
    this.missed = 'Missed',
    this.skipped = 'Skipped',
    this.pending = 'Pending',
    this.adherencePercent = 'Adherence %',
    this.reason = 'Reason',
    this.count = 'Count',
    this.type = 'Type',
    this.readings = 'Readings',
    this.average = 'Average',
    this.min = 'Min',
    this.max = 'Max',
    this.unit = 'Unit',
    this.symptom = 'Symptom',
    this.severity = 'Severity (1-5)',
    this.notes = 'Notes',
    this.reasonForgot = 'Forgot',
    this.reasonSideEffect = 'Side effect',
    this.reasonRanOut = 'Ran out',
    this.reasonOther = 'Other',
    this.reasonUnspecified = 'No reason given',
    this.vitalBloodPressure = 'Blood pressure',
    this.vitalGlucose = 'Glucose',
    this.vitalWeight = 'Weight',
    this.vitalHeartRate = 'Heart rate',
    this.noData = 'No data in this range',
    this.notAvailable = 'Not available (no access, or it could not be loaded)',
    this.truncatedNote = 'Only the newest entries are shown (limit reached)',
  });

  final String title;
  final String profile;
  final String dateRange;
  final String generatedAt;
  final String disclaimerLabel;
  final String disclaimer;

  final String adherenceSummary;
  final String adherenceByDay;
  final String adherenceByMedication;
  final String missedReasons;
  final String vitals;
  final String sideEffects;

  final String date;
  final String dateTime;
  final String medication;
  final String taken;
  final String missed;
  final String skipped;
  final String pending;
  final String adherencePercent;
  final String reason;
  final String count;
  final String type;
  final String readings;
  final String average;
  final String min;
  final String max;
  final String unit;
  final String symptom;
  final String severity;
  final String notes;

  final String reasonForgot;
  final String reasonSideEffect;
  final String reasonRanOut;
  final String reasonOther;
  final String reasonUnspecified;

  final String vitalBloodPressure;
  final String vitalGlucose;
  final String vitalWeight;
  final String vitalHeartRate;

  final String noData;
  final String notAvailable;
  final String truncatedNote;
}
