import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../vitals/vital_summary.dart';
import '../vitals/vital_types.dart';
import 'report_csv_labels.dart';
import 'report_format.dart';
import 'report_models.dart';
import 'report_options.dart';
import 'report_pdf_fonts.dart';
import 'report_pdf_labels.dart';
import 'report_range.dart';

/// ============================================================
/// REPORT PDF BUILDER — M17 step 4
///
/// Builds the doctor-visit report as a PDF, on the phone (no server). Pure
/// Dart: the fonts come in as bytes, so it runs in a unit test and, in step 6,
/// can run in a background isolate for big reports.
///
/// Every number comes from [ReportData], which comes from
/// `AdherenceCalculator`, the same calculation as the app screens.
/// ============================================================
class ReportPdfBuilder {
  ReportPdfBuilder._();

  // palette
  static const _ink = PdfColor.fromInt(0xFF0F2D3A);
  static const _muted = PdfColor.fromInt(0xFF5C7280);
  static const _line = PdfColor.fromInt(0xFFD5DEE3);
  static const _soft = PdfColor.fromInt(0xFFF1F6F8);
  static const _green = PdfColor.fromInt(0xFF1E9E6A);
  static const _red = PdfColor.fromInt(0xFFD64545);
  static const _amber = PdfColor.fromInt(0xFFE0A02B);
  static const _blue = PdfColor.fromInt(0xFF8FB3D9);
  static const _noDose = PdfColor.fromInt(0xFFE3E9EC);
  static const _brand = PdfColor.fromInt(0xFF00566E);

  /// Vitals get a day-by-day table only up to this many days; a long range
  /// shows the chart and the totals.
  static const int vitalsTableMaxDays = 31;

  /// Day-number labels under the day strip only up to this many days.
  static const int dayLabelsMaxDays = 31;

  /// [rtl] is true for a right-to-left language (Arabic).
  static Future<Uint8List> build(
    ReportData data, {
    required ReportPdfFonts fonts,
    ReportCsvLabels labels = const ReportCsvLabels(),
    ReportPdfLabels pdfLabels = const ReportPdfLabels(),
    bool rtl = false,
  }) async {
    final regular = pw.Font.ttf(fonts.regular);
    final bold = pw.Font.ttf(fonts.bold);
    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [pw.Font.ttf(fonts.devanagari), pw.Font.ttf(fonts.arabic)],
    );

    final doc = pw.Document(
      theme: theme,
      title:
          '${labels.title} ${ReportRange.dayKey(data.range.from)} - '
          '${ReportRange.dayKey(data.range.to)}',
      author: 'MedRemind',
      creator: 'MedRemind',
      subject: pdfLabels.subtitle,
    );

    final ctx = _Ctx(data, labels, pdfLabels);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 40),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        maxPages: 400,
        footer: (c) => _footer(ctx, c),
        build: (c) => [
          _titleBlock(ctx),
          pw.SizedBox(height: 14),
          if (data.options.adherence && data.adherence != null)
            ..._adherence(ctx, data.adherence!),
          if (data.options.vitals) ..._vitals(ctx),
          if (data.options.sideEffects) ..._sideEffects(ctx),
        ],
      ),
    );

    return doc.save();
  }

  // ------------------------------------------------------------
  // title + footer
  // ------------------------------------------------------------

  static pw.Widget _titleBlock(_Ctx x) {
    final d = x.data;
    final name = d.profileName?.trim() ?? '';
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MedRemind',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            x.labels.title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 19,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            x.pdf.subtitle,
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
          pw.SizedBox(height: 10),
          if (name.isNotEmpty) _kv(x.labels.profile, name),
          _kv(
            x.labels.dateRange,
            '${ReportRange.dayKey(d.range.from)}  –  '
            '${ReportRange.dayKey(d.range.to)}  (${d.range.dayCount})',
          ),
          _kv(x.labels.generatedAt, ReportFormat.dateTime(d.generatedAt)),
        ],
      ),
    );
  }

  static pw.Widget _kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 82,
          child: pw.Text(
            k,
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            v,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  static pw.Widget _footer(_Ctx x, pw.Context c) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            x.labels.disclaimer,
            style: const pw.TextStyle(color: _muted, fontSize: 7.5),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Text(
          x.pdf.pageLabel(c.pageNumber, c.pagesCount),
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
      ],
    ),
  );

  // ------------------------------------------------------------
  // adherence
  // ------------------------------------------------------------

  static List<pw.Widget> _adherence(_Ctx x, AdherenceBreakdown a) {
    final l = x.labels;
    final out = <pw.Widget>[_sectionTitle(l.adherenceSummary)];

    if (!a.total.hasData) {
      out.add(_note(l.noData));
      return out;
    }

    // headline
    final t = a.total;
    out.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _soft,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  t.decided == 0 ? '–' : '${t.percent}%',
                  style: pw.TextStyle(
                    fontSize: 34,
                    fontWeight: pw.FontWeight.bold,
                    color: _green,
                  ),
                ),
                pw.Text(
                  x.pdf.overallAdherence,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
                pw.Text(
                  '${t.decided} ${x.pdf.decidedDoses}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
              ],
            ),
            pw.SizedBox(width: 22),
            pw.Expanded(
              child: pw.Row(
                children: [
                  _stat(l.taken, t.taken, _green),
                  _stat(l.missed, t.missed, _red),
                  _stat(l.skipped, t.skipped, _amber),
                  _stat(l.pending, t.pending, _blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // day strip
    out.add(_subTitle(x.pdf.dayOverview));
    out.add(_dayStrip(x, a.perDay));
    out.add(pw.SizedBox(height: 6));
    out.add(_legend(x));

    // by medication
    out.add(_subTitle(l.adherenceByMedication));
    out.add(
      pw.TableHelper.fromTextArray(
        headers: [
          l.medication,
          l.taken,
          l.missed,
          l.skipped,
          l.pending,
          l.adherencePercent,
        ],
        data: [
          for (final m in a.perMedication)
            [
              m.displayName,
              '${m.counts.taken}',
              '${m.counts.missed}',
              '${m.counts.skipped}',
              '${m.counts.pending}',
              m.counts.decided == 0 ? '' : '${m.counts.percent}%',
            ],
        ],
        headerStyle: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
        cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
        headerDecoration: const pw.BoxDecoration(color: _soft),
        cellAlignments: {for (var i = 1; i <= 5; i++) i: pw.Alignment.center},
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1.5),
          5: const pw.FlexColumnWidth(1.7),
        },
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: 0.4),
          bottom: pw.BorderSide(color: _line, width: 0.4),
        ),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      ),
    );

    // reasons
    if (a.reasons.isNotEmpty) {
      out.add(_subTitle(l.missedReasons));
      out.add(
        pw.TableHelper.fromTextArray(
          headers: [l.reason, l.count],
          data: [
            for (final r in a.reasons)
              [_reasonLabel(l, r.reason), '${r.count}'],
          ],
          headerStyle: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
          headerDecoration: const pw.BoxDecoration(color: _soft),
          cellAlignments: {1: pw.Alignment.center},
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.4),
            bottom: pw.BorderSide(color: _line, width: 0.4),
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
        ),
      );
    }
    out.add(pw.SizedBox(height: 10));
    return out;
  }

  static pw.Widget _stat(String label, int n, PdfColor color) => pw.Expanded(
    child: pw.Column(
      children: [
        pw.Text(
          '$n',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ],
    ),
  );

  static PdfColor _dayColor(AdherenceCounts c) {
    if (!c.hasData) return _noDose;
    if (c.missed > 0) return _red;
    if (c.skipped > 0) return _amber;
    if (c.taken > 0 && c.pending == 0) return _green;
    if (c.taken > 0) return _green;
    return _blue;
  }

  static pw.Widget _dayStrip(_Ctx x, List<DailyAdherence> days) {
    final labelled = days.length <= dayLabelsMaxDays;
    final size = labelled ? 14.0 : (days.length > 200 ? 5.0 : 8.0);
    return pw.Wrap(
      spacing: labelled ? 4 : 1.5,
      runSpacing: labelled ? 4 : 1.5,
      children: [
        for (final d in days)
          pw.Container(
            width: size,
            height: size,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _dayColor(d.counts),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: labelled
                ? pw.Text(
                    '${d.day.day}',
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      color: d.counts.hasData ? PdfColors.white : _muted,
                    ),
                  )
                : null,
          ),
      ],
    );
  }

  static pw.Widget _legend(_Ctx x) {
    pw.Widget item(PdfColor c, String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(right: 12),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(width: 7, height: 7, color: c),
          pw.SizedBox(width: 3),
          pw.Text(t, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
        ],
      ),
    );
    return pw.Wrap(
      children: [
        item(_green, x.pdf.legendAllTaken),
        item(_red, x.pdf.legendMissed),
        item(_amber, x.pdf.legendSkipped),
        item(_blue, x.pdf.legendPending),
        item(_noDose, x.pdf.legendNoDoses),
      ],
    );
  }

  // ------------------------------------------------------------
  // vitals
  // ------------------------------------------------------------

  static List<pw.Widget> _vitals(_Ctx x) {
    final l = x.labels;
    final d = x.data;
    final out = <pw.Widget>[_sectionTitle(l.vitals)];

    if (d.unavailable.contains(ReportSection.vitals)) {
      out.add(_note(l.notAvailable));
      return out;
    }
    final v = d.vitals ?? const <VitalKind, List<VitalDaily>>{};
    if (v.values.every((e) => e.isEmpty)) {
      out.add(_note(l.noData));
      return out;
    }

    for (final kind in VitalKind.values) {
      final days = v[kind] ?? const <VitalDaily>[];
      if (days.isEmpty) continue;
      out.add(_subTitle('${_vitalName(l, kind)} (${kind.canonicalUnit})'));
      out.add(_vitalTotals(x, kind, days));
      out.add(pw.SizedBox(height: 6));
      out.add(_vitalChart(x, kind, days));
      if (d.range.dayCount <= vitalsTableMaxDays) {
        out.add(pw.SizedBox(height: 6));
        out.add(_vitalTable(x, kind, days));
      }
    }
    if (d.truncated.contains(ReportSection.vitals)) {
      out.add(_note(l.truncatedNote));
    }
    out.add(pw.SizedBox(height: 10));
    return out;
  }

  static pw.Widget _vitalTotals(_Ctx x, VitalKind kind, List<VitalDaily> days) {
    final l = x.labels;
    final bp = kind == VitalKind.bloodPressure;
    final count = days.fold<int>(0, (s, e) => s + e.count);
    // weighted average of the per-day averages
    double wavg(double Function(VitalDaily) f) =>
        days.fold<double>(0, (s, e) => s + f(e) * e.count) / count;
    double mn(double Function(VitalDaily) f) =>
        days.map(f).reduce((a, b) => a < b ? a : b);
    double mx(double Function(VitalDaily) f) =>
        days.map(f).reduce((a, b) => a > b ? a : b);

    String pair(double a, double? b) => bp && b != null
        ? '${ReportFormat.dec(a)}/${ReportFormat.dec(b)}'
        : ReportFormat.dec(a);

    final avg2 = bp && days.every((e) => e.avg2 != null)
        ? wavg((e) => e.avg2!)
        : null;
    final min2 = bp && days.every((e) => e.min2 != null)
        ? mn((e) => e.min2!)
        : null;
    final max2 = bp && days.every((e) => e.max2 != null)
        ? mx((e) => e.max2!)
        : null;

    pw.Widget cell(String k, String v) => pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(k, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
          pw.Text(
            v,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          cell(l.readings, '$count'),
          cell(l.average, pair(wavg((e) => e.avg), avg2)),
          cell(l.min, pair(mn((e) => e.min), min2)),
          cell(l.max, pair(mx((e) => e.max), max2)),
        ],
      ),
    );
  }

  static pw.Widget _vitalChart(_Ctx x, VitalKind kind, List<VitalDaily> days) {
    final range = x.data.range;
    final origin = range.from;
    int idx(VitalDaily d) {
      final b = VitalAnalysis.dayBounds(d.dayKey);
      if (b == null) return 0;
      return DateTime.utc(
        b.start.year,
        b.start.month,
        b.start.day,
      ).difference(DateTime.utc(origin.year, origin.month, origin.day)).inDays;
    }

    final series = <(PdfColor, List<pw.PointChartValue>)>[
      (
        _brand,
        [for (final d in days) pw.PointChartValue(idx(d).toDouble(), d.avg)],
      ),
      if (kind == VitalKind.bloodPressure && days.every((d) => d.avg2 != null))
        (
          _red,
          [
            for (final d in days)
              pw.PointChartValue(idx(d).toDouble(), d.avg2!),
          ],
        ),
    ];

    final ys = [
      for (final s in series)
        for (final p in s.$2) p.y,
    ];
    var lo = ys.reduce((a, b) => a < b ? a : b);
    var hi = ys.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.1;
    lo = (lo - pad);
    hi = (hi + pad);
    final yTicks = [for (var i = 0; i <= 3; i++) lo + (hi - lo) * i / 3];

    final last = (range.dayCount - 1).clamp(1, 100000);
    final xTicks = <double>[0, last / 2, last.toDouble()];
    String xLabel(num v) {
      final day = DateTime(origin.year, origin.month, origin.day + v.round());
      return ReportFormat.shortDay(ReportRange.dayKey(day));
    }

    return pw.SizedBox(
      height: 110,
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis(
            xTicks,
            format: (v) => xLabel(v),
            textStyle: const pw.TextStyle(fontSize: 7, color: _muted),
            marginStart: 6,
            marginEnd: 6,
          ),
          yAxis: pw.FixedAxis(
            yTicks,
            format: (v) => ReportFormat.dec(double.parse(v.toStringAsFixed(1))),
            textStyle: const pw.TextStyle(fontSize: 7, color: _muted),
            divisions: true,
          ),
        ),
        datasets: [
          for (final s in series)
            pw.LineDataSet(
              data: s.$2,
              color: s.$1,
              lineWidth: 1.2,
              drawPoints: true,
              pointSize: 2.2,
              drawSurface: false,
            ),
        ],
      ),
    );
  }

  static pw.Widget _vitalTable(_Ctx x, VitalKind kind, List<VitalDaily> days) {
    final l = x.labels;
    final bp = kind == VitalKind.bloodPressure;
    String pair(double a, double? b) => bp && b != null
        ? '${ReportFormat.dec(a)}/${ReportFormat.dec(b)}'
        : ReportFormat.dec(a);
    return pw.TableHelper.fromTextArray(
      headers: [l.date, l.readings, l.average, l.min, l.max],
      data: [
        for (final d in days)
          [
            d.dayKey,
            '${d.count}',
            pair(d.avg, d.avg2),
            pair(d.min, d.min2),
            pair(d.max, d.max2),
          ],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8.5, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: _soft),
      cellAlignments: {for (var i = 1; i <= 4; i++) i: pw.Alignment.center},
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.4),
        bottom: pw.BorderSide(color: _line, width: 0.4),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    );
  }

  // ------------------------------------------------------------
  // side effects
  // ------------------------------------------------------------

  static List<pw.Widget> _sideEffects(_Ctx x) {
    final l = x.labels;
    final d = x.data;
    final out = <pw.Widget>[_sectionTitle(l.sideEffects)];

    if (d.unavailable.contains(ReportSection.sideEffects)) {
      out.add(_note(l.notAvailable));
      return out;
    }
    final s = d.symptoms ?? const [];
    if (s.isEmpty) {
      out.add(_note(l.noData));
    } else {
      out.add(
        pw.TableHelper.fromTextArray(
          headers: [l.dateTime, l.symptom, l.severity, l.notes],
          data: [
            for (final e in s)
              [
                ReportFormat.dateTime(e.occurredAt),
                e.symptom,
                '${e.severity}',
                e.notes ?? '',
              ],
          ],
          headerStyle: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
          headerDecoration: const pw.BoxDecoration(color: _soft),
          cellAlignments: {2: pw.Alignment.center},
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(3.2),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.4),
            bottom: pw.BorderSide(color: _line, width: 0.4),
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
        ),
      );
    }
    if (d.truncated.contains(ReportSection.sideEffects)) {
      out.add(_note(l.truncatedNote));
    }
    return out;
  }

  // ------------------------------------------------------------
  // small pieces
  // ------------------------------------------------------------

  static pw.Widget _sectionTitle(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 6, bottom: 6),
    child: pw.Text(
      t,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _brand,
      ),
    ),
  );

  static pw.Widget _subTitle(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 5),
    child: pw.Text(
      t,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
  );

  static pw.Widget _note(String t) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Text(t, style: const pw.TextStyle(fontSize: 9, color: _muted)),
  );

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
}

class _Ctx {
  _Ctx(this.data, this.labels, this.pdf);

  final ReportData data;
  final ReportCsvLabels labels;
  final ReportPdfLabels pdf;
}
