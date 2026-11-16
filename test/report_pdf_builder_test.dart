import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/adherence_calculator.dart';
import 'package:med_remind_app/core/reports/report_csv_labels.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/core/reports/report_options.dart';
import 'package:med_remind_app/core/reports/report_pdf_builder.dart';
import 'package:med_remind_app/core/reports/report_pdf_fonts.dart';
import 'package:med_remind_app/core/reports/report_pdf_labels.dart';
import 'package:med_remind_app/core/reports/report_range.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/core/vitals/vital_summary.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';

final now = DateTime(2026, 11, 14, 9, 5);

ByteData font(String asset) =>
    ByteData.sublistView(File(asset).readAsBytesSync());

ReportPdfFonts loadFonts() => ReportPdfFonts(
  regular: font(ReportPdfFonts.regularAsset),
  bold: font(ReportPdfFonts.boldAsset),
  devanagari: font(ReportPdfFonts.devanagariAsset),
  arabic: font(ReportPdfFonts.arabicAsset),
);

ReportDose dose(
  String id,
  DateTime at,
  ReportDoseStatus status, {
  String med = 'm1',
  String name = 'Metformin',
  String? strength = '500mg',
  ReportMissReason reason = ReportMissReason.unspecified,
}) => ReportDose(
  id: id,
  medicationId: med,
  medName: name,
  strength: strength,
  scheduledAt: at,
  status: status,
  reason: reason,
);

const all = ReportOptions({
  ReportSection.adherence,
  ReportSection.vitals,
  ReportSection.sideEffects,
});

/// A realistic report over [days] days.
ReportData sample(
  int days, {
  String name = 'Sarah Johnson',
  ReportOptions options = all,
  String medName = 'Metformin',
  String symptomText = 'Nausea',
  String notes = 'After dinner',
  int symptomCount = 3,
  Set<ReportSection> unavailable = const {},
  Set<ReportSection> truncated = const {},
}) {
  final range = ReportRange.lastDays(days, now: now);
  final doses = <ReportDose>[];
  for (var i = 0; i < days; i++) {
    final day = range.days[i];
    doses.add(
      dose(
        'a$i',
        DateTime(day.year, day.month, day.day, 8),
        i % 7 == 3 ? ReportDoseStatus.missed : ReportDoseStatus.taken,
        name: medName,
        reason: i % 7 == 3
            ? ReportMissReason.forgot
            : ReportMissReason.unspecified,
      ),
    );
    if (i % 5 == 0) {
      doses.add(
        dose(
          'b$i',
          DateTime(day.year, day.month, day.day, 20),
          ReportDoseStatus.skipped,
          med: 'm2',
          name: 'Aspirin',
          strength: '',
          reason: ReportMissReason.sideEffect,
        ),
      );
    }
  }

  Map<VitalKind, List<VitalDaily>> vitals() {
    VitalDaily d(DateTime day, double base, {bool bp = false}) => VitalDaily(
      dayKey: ReportRange.dayKey(day),
      count: 2,
      avg: base,
      min: base - 4,
      max: base + 5,
      avg2: bp ? base - 40 : null,
      min2: bp ? base - 46 : null,
      max2: bp ? base - 34 : null,
    );
    final step = days > 31 ? 3 : 1;
    return {
      VitalKind.bloodPressure: [
        for (var i = 0; i < days; i += step)
          d(range.days[i], 118 + (i % 9).toDouble(), bp: true),
      ],
      VitalKind.glucose: [
        for (var i = 0; i < days; i += step)
          d(range.days[i], 95 + (i % 13).toDouble()),
      ],
      VitalKind.weight: [d(range.days[days ~/ 2], 72.46)],
      VitalKind.heartRate: const [],
    };
  }

  return ReportData(
    range: range,
    generatedAt: now,
    options: options,
    profileName: name,
    adherence: options.adherence
        ? AdherenceCalculator.summarize(doses, range)
        : null,
    vitals: options.vitals && !unavailable.contains(ReportSection.vitals)
        ? vitals()
        : null,
    symptoms:
        options.sideEffects && !unavailable.contains(ReportSection.sideEffects)
        ? [
            for (var i = 0; i < symptomCount; i++)
              SymptomEntry(
                symptom: '$symptomText $i',
                severity: 1 + i % 5,
                occurredAt: range.to.subtract(Duration(hours: i * 5)),
                notes: notes,
              ),
          ]
        : null,
    unavailable: unavailable,
    truncated: truncated,
  );
}

int pageCount(Uint8List pdf) =>
    RegExp(r'/Type\s*/Page\b(?!s)')
        .allMatches(String.fromCharCodes(pdf))
        .length;

void main() {
  late ReportPdfFonts fonts;
  setUpAll(() => fonts = loadFonts());

  Future<Uint8List> build(ReportData d, {bool rtl = false}) =>
      ReportPdfBuilder.build(d, fonts: fonts, rtl: rtl);

  void maybeWrite(String name, Uint8List bytes) {
    final out = Platform.environment['REPORT_PDF_OUT'];
    if (out == null || out.isEmpty) return;
    Directory(out).createSync(recursive: true);
    File('$out/$name.pdf').writeAsBytesSync(bytes);
  }

  test('a PDF starts with %PDF- and has at least one page', () async {
    final pdf = await build(sample(7));
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
    expect(pageCount(pdf), greaterThanOrEqualTo(1));
    maybeWrite('week_en', pdf);
  });

  test('every font file is a real TrueType file', () {
    for (final a in ReportPdfFonts.allAssets) {
      final b = File(a).readAsBytesSync();
      expect(b.length, greaterThan(100000), reason: a);
      expect(b.sublist(0, 4), [0, 1, 0, 0], reason: a);
    }
  });

  test('empty report (no doses) still builds', () async {
    final range = ReportRange.lastDays(7, now: now);
    final d = ReportData(
      range: range,
      generatedAt: now,
      options: all,
      adherence: AdherenceCalculator.summarize(const [], range),
      vitals: {for (final k in VitalKind.values) k: const <VitalDaily>[]},
      symptoms: const [],
    );
    final pdf = await build(d);
    expect(pageCount(pdf), 1);
    maybeWrite('empty', pdf);
  });

  test('adherence only', () async {
    final pdf = await build(
      sample(30, options: const ReportOptions.adherenceOnly()),
    );
    expect(pageCount(pdf), greaterThanOrEqualTo(1));
  });

  test('90 days with vitals', () async {
    final pdf = await build(sample(90));
    expect(pageCount(pdf), greaterThanOrEqualTo(1));
    maybeWrite('quarter_en', pdf);
  });

  test('a full year (365 days) builds', () async {
    final pdf = await build(sample(365, symptomCount: 40));
    expect(pageCount(pdf), greaterThanOrEqualTo(2));
    expect(pdf.length, lessThan(5 * 1024 * 1024));
    maybeWrite('year_en', pdf);
  });

  test('hundreds of side effects run over several pages', () async {
    final pdf = await build(sample(30, symptomCount: 400));
    expect(pageCount(pdf), greaterThan(4));
  });

  test(
    'sections that are unavailable or truncated build with a note',
    () async {
      final pdf = await build(
        sample(
          14,
          unavailable: {ReportSection.vitals},
          truncated: {ReportSection.sideEffects},
        ),
      );
      expect(pageCount(pdf), greaterThanOrEqualTo(1));
      maybeWrite('unavailable', pdf);
    },
  );

  test(
    'vitals with one reading and with all-equal values do not break the chart',
    () async {
      final range = ReportRange.lastDays(7, now: now);
      final d = ReportData(
        range: range,
        generatedAt: now,
        options: const ReportOptions({ReportSection.vitals}),
        vitals: {
          VitalKind.weight: [
            VitalDaily(
              dayKey: ReportRange.dayKey(range.days[3]),
              count: 1,
              avg: 70,
              min: 70,
              max: 70,
            ),
          ],
          VitalKind.glucose: [
            for (var i = 0; i < 7; i++)
              VitalDaily(
                dayKey: ReportRange.dayKey(range.days[i]),
                count: 1,
                avg: 100,
                min: 100,
                max: 100,
              ),
          ],
          VitalKind.bloodPressure: const [],
          VitalKind.heartRate: const [],
        },
      );
      expect(pageCount(await build(d)), greaterThanOrEqualTo(1));
    },
  );

  test('a single-day report builds', () async {
    final pdf = await build(sample(1));
    expect(pageCount(pdf), greaterThanOrEqualTo(1));
  });

  test('Hindi text in names and notes builds', () async {
    final pdf = await build(
      sample(
        14,
        name: 'सारा जॉनसन',
        medName: 'मेटफॉर्मिन',
        symptomText: 'सिरदर्द',
        notes: 'खाने के बाद, हल्का दर्द',
      ),
    );
    expect(pageCount(pdf), greaterThanOrEqualTo(1));
    maybeWrite('week_hi', pdf);
  });

  test('Arabic text builds, left-to-right and right-to-left', () async {
    final d = sample(
      14,
      name: 'سارة أحمد',
      medName: 'ميتفورمين',
      symptomText: 'صداع',
      notes: 'بعد العشاء',
    );
    expect(pageCount(await build(d)), greaterThanOrEqualTo(1));
    final rtl = await build(d, rtl: true);
    expect(pageCount(rtl), greaterThanOrEqualTo(1));
    maybeWrite('week_ar_rtl', rtl);
  });

  test('translated labels build', () async {
    final pdf = await ReportPdfBuilder.build(
      sample(7),
      fonts: fonts,
      labels: const ReportCsvLabels(
        title: 'Informe de salud',
        profile: 'Perfil',
      ),
      pdfLabels: const ReportPdfLabels(page: 'Página {page} de {pages}'),
    );
    expect(pageCount(pdf), greaterThanOrEqualTo(1));
  });

  test('page label fills in both numbers', () {
    expect(const ReportPdfLabels().pageLabel(2, 5), 'Page 2 of 5');
    expect(
      const ReportPdfLabels(page: '{page}/{pages}').pageLabel(1, 1),
      '1/1',
    );
  });
}
