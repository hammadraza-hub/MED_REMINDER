import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../vitals/vital_summary.dart';
import '../vitals/vital_types.dart';
import 'report_csv_labels.dart';
import 'report_format.dart';
import 'report_models.dart';
import 'report_options.dart';
import 'report_range.dart';

/// A finished CSV report.
class ReportCsv {
  const ReportCsv({
    required this.fileName,
    required this.text,
    required this.bytes,
  });

  /// e.g. `medremind-report_2026-11-08_2026-11-14.csv`. No profile name in it
  /// (personal data must not travel in a file name).
  final String fileName;

  /// The CSV without the byte order mark.
  final String text;

  /// UTF-8 WITH a byte order mark, so Excel shows Hindi / Arabic correctly.
  final Uint8List bytes;
}

/// ============================================================
/// REPORT CSV BUILDER — M17 step 3
///
/// One file, sections one after the other (each with a title row, a blank row
/// between them), built from [ReportData]:
///   header · adherence summary · by day · by medication · missed reasons ·
///   vitals · side effects
///
/// Conventions (so any spreadsheet in any country reads it the same way):
/// * dates `yyyy-MM-dd`, times `yyyy-MM-dd HH:mm`, local time;
/// * numbers always with a `.` decimal point and no thousands separator;
/// * a percentage cell is EMPTY when no dose had an outcome (not "0");
/// * text typed by a person (notes, medicine names) that starts with
///   `= + - @` is prefixed with `'` so a spreadsheet never runs it as a
///   formula (CSV injection);
/// * lines end with CRLF.
/// ============================================================
class ReportCsvBuilder {
  ReportCsvBuilder._();

  static const List<int> _bom = [0xEF, 0xBB, 0xBF];

  static ReportCsv build(
    ReportData data, {
    ReportCsvLabels labels = const ReportCsvLabels(),
  }) {
    final rows = <List<String>>[];

    void blank() => rows.add(const []);
    void title(String t) => rows.add([t]);

    // ---------------- header ----------------
    title(labels.title);
    final name = data.profileName?.trim() ?? '';
    if (name.isNotEmpty) rows.add([labels.profile, _text(name)]);
    rows.add([
      labels.dateRange,
      ReportRange.dayKey(data.range.from),
      ReportRange.dayKey(data.range.to),
    ]);
    rows.add([labels.generatedAt, ReportFormat.dateTime(data.generatedAt)]);
    rows.add([labels.disclaimerLabel, labels.disclaimer]);

    // ---------------- adherence ----------------
    final a = data.adherence;
    if (data.options.adherence && a != null) {
      blank();
      title(labels.adherenceSummary);
      if (!a.total.hasData) {
        rows.add([labels.noData]);
      } else {
        rows.add(_countsHeader(labels, first: null));
        rows.add(_countsRow(null, a.total));

        blank();
        title(labels.adherenceByDay);
        rows.add(_countsHeader(labels, first: labels.date));
        for (final d in a.perDay) {
          rows.add(_countsRow(d.dayKey, d.counts));
        }

        blank();
        title(labels.adherenceByMedication);
        rows.add(_countsHeader(labels, first: labels.medication));
        for (final m in a.perMedication) {
          rows.add(_countsRow(_text(m.displayName), m.counts));
        }

        if (a.reasons.isNotEmpty) {
          blank();
          title(labels.missedReasons);
          rows.add([labels.reason, labels.count]);
          for (final r in a.reasons) {
            rows.add([_reasonLabel(labels, r.reason), '${r.count}']);
          }
        }
      }
    }

    // ---------------- vitals ----------------
    if (data.options.vitals) {
      blank();
      title(labels.vitals);
      if (data.unavailable.contains(ReportSection.vitals)) {
        rows.add([labels.notAvailable]);
      } else {
        final v = data.vitals ?? const {};
        if (v.values.every((l) => l.isEmpty)) {
          rows.add([labels.noData]);
        } else {
          rows.add([
            labels.date,
            labels.type,
            labels.readings,
            labels.average,
            labels.min,
            labels.max,
            labels.unit,
          ]);
          for (final kind in VitalKind.values) {
            for (final d in v[kind] ?? const <VitalDaily>[]) {
              rows.add(_vitalRow(labels, kind, d));
            }
          }
        }
        if (data.truncated.contains(ReportSection.vitals)) {
          rows.add([labels.truncatedNote]);
        }
      }
    }

    // ---------------- side effects ----------------
    if (data.options.sideEffects) {
      blank();
      title(labels.sideEffects);
      if (data.unavailable.contains(ReportSection.sideEffects)) {
        rows.add([labels.notAvailable]);
      } else {
        final s = data.symptoms ?? const [];
        if (s.isEmpty) {
          rows.add([labels.noData]);
        } else {
          rows.add([
            labels.dateTime,
            labels.symptom,
            labels.severity,
            labels.notes,
          ]);
          for (final e in s) {
            rows.add([
              ReportFormat.dateTime(e.occurredAt),
              _text(e.symptom),
              '${e.severity}',
              _text(e.notes ?? ''),
            ]);
          }
        }
        if (data.truncated.contains(ReportSection.sideEffects)) {
          rows.add([labels.truncatedNote]);
        }
      }
    }

    final text = csv.encode(rows);
    return ReportCsv(
      fileName: fileNameFor(data.range),
      text: text,
      bytes: Uint8List.fromList([..._bom, ...utf8.encode(text)]),
    );
  }

  static String fileNameFor(ReportRange range) =>
      'medremind-report_${ReportRange.dayKey(range.from)}_'
      '${ReportRange.dayKey(range.to)}.csv';

  // ------------------------------------------------------------
  // rows
  // ------------------------------------------------------------

  static List<String> _countsHeader(
    ReportCsvLabels l, {
    required String? first,
  }) => [?first, l.taken, l.missed, l.skipped, l.pending, l.adherencePercent];

  static List<String> _countsRow(String? first, AdherenceCounts c) => [
    ?first,
    '${c.taken}',
    '${c.missed}',
    '${c.skipped}',
    '${c.pending}',
    c.decided == 0 ? '' : '${c.percent}',
  ];

  static List<String> _vitalRow(
    ReportCsvLabels l,
    VitalKind kind,
    VitalDaily d,
  ) {
    final bp = kind == VitalKind.bloodPressure;
    String pair(double a, double? b) => bp && b != null
        ? '${ReportFormat.dec(a)}/${ReportFormat.dec(b)}'
        : ReportFormat.dec(a);
    return [
      d.dayKey,
      _vitalName(l, kind),
      '${d.count}',
      pair(d.avg, d.avg2),
      pair(d.min, d.min2),
      pair(d.max, d.max2),
      kind.canonicalUnit,
    ];
  }

  static String _vitalName(ReportCsvLabels l, VitalKind k) {
    switch (k) {
      case VitalKind.bloodPressure:
        return l.vitalBloodPressure;
      case VitalKind.glucose:
        return l.vitalGlucose;
      case VitalKind.weight:
        return l.vitalWeight;
      case VitalKind.heartRate:
        return l.vitalHeartRate;
    }
  }

  static String _reasonLabel(ReportCsvLabels l, ReportMissReason r) {
    switch (r) {
      case ReportMissReason.forgot:
        return l.reasonForgot;
      case ReportMissReason.sideEffect:
        return l.reasonSideEffect;
      case ReportMissReason.ranOut:
        return l.reasonRanOut;
      case ReportMissReason.other:
        return l.reasonOther;
      case ReportMissReason.unspecified:
        return l.reasonUnspecified;
    }
  }

  // ------------------------------------------------------------
  // cell formatting
  // ------------------------------------------------------------

  /// Text typed by a person. A leading `= + - @` (or tab / carriage return)
  /// would be run as a formula by a spreadsheet, so it gets a `'` in front.
  static String _text(String s) {
    if (s.isEmpty) return s;
    const risky = {'=', '+', '-', '@', '\t', '\r'};
    return risky.contains(s[0]) ? "'$s" : s;
  }
}
