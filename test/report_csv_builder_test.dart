import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/adherence_calculator.dart';
import 'package:med_remind_app/core/reports/report_csv_builder.dart';
import 'package:med_remind_app/core/reports/report_csv_labels.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/core/reports/report_options.dart';
import 'package:med_remind_app/core/reports/report_range.dart';
import 'package:med_remind_app/core/vitals/symptom_entry.dart';
import 'package:med_remind_app/core/vitals/vital_summary.dart';
import 'package:med_remind_app/core/vitals/vital_types.dart';

final now = DateTime(2026, 11, 14, 9, 5);
final range = ReportRange.lastDays(7, now: now);

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

const taken = ReportDoseStatus.taken;
const missed = ReportDoseStatus.missed;

ReportData report({
  List<ReportDose> doses = const [],
  ReportOptions options = const ReportOptions.adherenceOnly(),
  Map<VitalKind, List<VitalDaily>>? vitals,
  List<SymptomEntry>? symptoms,
  Set<ReportSection> unavailable = const {},
  Set<ReportSection> truncated = const {},
  String? name = 'Sarah',
}) => ReportData(
  range: range,
  generatedAt: now,
  options: options,
  profileName: name,
  adherence: options.adherence
      ? AdherenceCalculator.summarize(doses, range)
      : null,
  vitals: vitals,
  symptoms: symptoms,
  unavailable: unavailable,
  truncated: truncated,
);

/// Reads the CSV back with the same library, as a spreadsheet would.
List<List<String>> parse(ReportCsv c) => [
  for (final r in csv.decode(c.text)) [for (final v in r) '$v'],
];

List<String>? find(List<List<String>> rows, String first) {
  for (final r in rows) {
    if (r.isNotEmpty && r.first == first) return r;
  }
  return null;
}

const all = ReportOptions({
  ReportSection.adherence,
  ReportSection.vitals,
  ReportSection.sideEffects,
});

void main() {
  group('header', () {
    test('title, profile, range, generated time and disclaimer', () {
      final rows = parse(ReportCsvBuilder.build(report()));
      expect(rows[0], ['MedRemind health report']);
      expect(rows[1], ['Profile', 'Sarah']);
      expect(rows[2], ['Date range', '2026-11-08', '2026-11-14']);
      expect(rows[3], ['Generated at', '2026-11-14 09:05']);
      expect(rows[4].first, 'Disclaimer');
      expect(rows[4][1], contains('not a medical diagnosis'));
    });

    test('no profile row when there is no name', () {
      final rows = parse(ReportCsvBuilder.build(report(name: null)));
      expect(find(rows, 'Profile'), isNull);
      expect(rows[1].first, 'Date range');
    });

    test('file name has the dates but never the profile name', () {
      final c = ReportCsvBuilder.build(report(name: 'Sarah Johnson'));
      expect(c.fileName, 'medremind-report_2026-11-08_2026-11-14.csv');
      expect(c.fileName.toLowerCase(), isNot(contains('sarah')));
    });
  });

  group('encoding', () {
    test('bytes start with a UTF-8 byte order mark, text does not', () {
      final c = ReportCsvBuilder.build(report());
      expect(c.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      expect(c.text.startsWith('﻿'), isFalse);
      expect(utf8.decode(c.bytes.sublist(3)), c.text);
    });

    test('lines end with CRLF', () {
      final c = ReportCsvBuilder.build(report());
      expect(c.text, contains('\r\n'));
      expect(RegExp(r'(?<!\r)\n').hasMatch(c.text), isFalse);
    });

    test('Hindi, Arabic and accents survive the round trip', () {
      final c = ReportCsvBuilder.build(
        report(
          name: 'सारा أحمد José',
          options: const ReportOptions({ReportSection.sideEffects}),
          symptoms: [
            SymptomEntry(
              symptom: 'सिरदर्द',
              severity: 2,
              occurredAt: DateTime(2026, 11, 10, 8, 30),
              notes: 'صداع خفيف, après le déjeuner',
            ),
          ],
        ),
      );
      final text = utf8.decode(c.bytes.sublist(3));
      expect(text, contains('सारा أحمد José'));
      final row = parse(c).firstWhere((r) => r.first == '2026-11-10 08:30');
      expect(row, [
        '2026-11-10 08:30',
        'सिरदर्द',
        '2',
        'صداع خفيف, après le déjeuner',
      ]);
    });

    test('commas, quotes and new lines inside a cell are quoted', () {
      final c = ReportCsvBuilder.build(
        report(
          options: const ReportOptions({ReportSection.sideEffects}),
          symptoms: [
            SymptomEntry(
              symptom: 'Pain, "sharp"',
              severity: 4,
              occurredAt: DateTime(2026, 11, 10, 8, 30),
              notes: 'line one\nline two',
            ),
          ],
        ),
      );
      final row = parse(c).firstWhere((r) => r.first == '2026-11-10 08:30');
      expect(row[1], 'Pain, "sharp"');
      expect(row[3], 'line one\nline two');
    });
  });

  group('CSV injection', () {
    test('text that starts like a formula gets a quote in front', () {
      final c = ReportCsvBuilder.build(
        report(
          name: '=cmd()',
          doses: [
            dose(
              'a',
              DateTime(2026, 11, 9, 8),
              taken,
              name: '@SUM(A1)',
              strength: '',
            ),
            dose(
              'b',
              DateTime(2026, 11, 9, 9),
              taken,
              name: '+1+1',
              strength: '',
              med: 'm2',
            ),
          ],
          options: all,
          symptoms: [
            SymptomEntry(
              symptom: '-2+3',
              severity: 1,
              occurredAt: DateTime(2026, 11, 10),
              notes: '=HYPERLINK("http://x","y")',
            ),
          ],
          vitals: const {},
        ),
      );
      final rows = parse(c);
      expect(find(rows, 'Profile')![1], "'=cmd()");
      expect(find(rows, "'@SUM(A1)"), isNotNull);
      expect(find(rows, "'+1+1"), isNotNull);
      final se = rows.firstWhere((r) => r.first == '2026-11-10 00:00');
      expect(se[1], "'-2+3");
      expect(se[3], startsWith("'="));
    });

    test('normal text and numbers are left alone', () {
      final c = ReportCsvBuilder.build(
        report(doses: [dose('a', DateTime(2026, 11, 9, 8), taken)]),
      );
      final rows = parse(c);
      expect(find(rows, 'Metformin 500mg'), isNotNull);
      expect(c.text, isNot(contains("'")));
    });

    test('a negative number in a number cell is not touched', () {
      final c = ReportCsvBuilder.build(
        report(
          options: const ReportOptions({ReportSection.vitals}),
          vitals: {
            VitalKind.weight: [
              const VitalDaily(
                dayKey: '2026-11-10',
                count: 1,
                avg: -1,
                min: -1,
                max: -1,
              ),
            ],
          },
        ),
      );
      final row = parse(c).firstWhere((r) => r.first == '2026-11-10');
      expect(row[3], '-1');
    });
  });

  group('adherence sections', () {
    final doses = [
      dose('a', DateTime(2026, 11, 8, 8), taken),
      dose('b', DateTime(2026, 11, 9, 8), taken),
      dose(
        'c',
        DateTime(2026, 11, 10, 8),
        missed,
        reason: ReportMissReason.forgot,
      ),
      dose(
        'd',
        DateTime(2026, 11, 11, 8),
        ReportDoseStatus.skipped,
        reason: ReportMissReason.sideEffect,
      ),
      dose('e', DateTime(2026, 11, 12, 8), ReportDoseStatus.pending),
    ];

    test('summary row equals the calculator (and so the screen)', () {
      final rows = parse(ReportCsvBuilder.build(report(doses: doses)));
      final i = rows.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Adherence summary',
      );
      expect(rows[i + 1], [
        'Taken',
        'Missed',
        'Skipped',
        'Pending',
        'Adherence %',
      ]);
      expect(rows[i + 2], ['2', '1', '1', '1', '50']);
    });

    test('by day has one row for EVERY day, oldest first', () {
      final rows = parse(ReportCsvBuilder.build(report(doses: doses)));
      final i = rows.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Adherence by day',
      );
      final dayRows = rows.sublist(i + 2, i + 2 + 7);
      expect(dayRows.map((r) => r.first), [
        '2026-11-08',
        '2026-11-09',
        '2026-11-10',
        '2026-11-11',
        '2026-11-12',
        '2026-11-13',
        '2026-11-14',
      ]);
      expect(dayRows[0], ['2026-11-08', '1', '0', '0', '0', '100']);
      // a day without doses: zeros, percent empty (not 0)
      expect(dayRows[5], ['2026-11-13', '0', '0', '0', '0', '']);
      // a day with only a pending dose: percent also empty
      expect(dayRows[4], ['2026-11-12', '0', '0', '0', '1', '']);
    });

    test('by medication shows name and strength', () {
      final rows = parse(ReportCsvBuilder.build(report(doses: doses)));
      final i = rows.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Adherence by medication',
      );
      expect(rows[i + 1].first, 'Medication');
      expect(rows[i + 2], ['Metformin 500mg', '2', '1', '1', '1', '50']);
    });

    test('missed reasons list only reasons that happened', () {
      final rows = parse(ReportCsvBuilder.build(report(doses: doses)));
      final i = rows.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Missed and skipped doses by reason',
      );
      expect(rows[i + 1], ['Reason', 'Count']);
      expect(rows[i + 2], ['Forgot', '1']);
      expect(rows[i + 3], ['Side effect', '1']);
    });

    test('no reasons section when nobody gave a reason to list', () {
      final rows = parse(
        ReportCsvBuilder.build(
          report(doses: [dose('a', DateTime(2026, 11, 9, 8), taken)]),
        ),
      );
      expect(find(rows, 'Missed and skipped doses by reason'), isNull);
    });

    test('no doses in the range says so and skips the detail tables', () {
      final rows = parse(ReportCsvBuilder.build(report()));
      final i = rows.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Adherence summary',
      );
      expect(rows[i + 1], ['No data in this range']);
      expect(find(rows, 'Adherence by day'), isNull);
    });

    test('adherence is left out when it was not asked for', () {
      final rows = parse(
        ReportCsvBuilder.build(
          report(
            options: const ReportOptions({ReportSection.sideEffects}),
            symptoms: const [],
          ),
        ),
      );
      expect(find(rows, 'Adherence summary'), isNull);
    });
  });

  group('vitals section', () {
    test('rows per kind and day, with unit', () {
      final c = ReportCsvBuilder.build(
        report(
          options: const ReportOptions({ReportSection.vitals}),
          vitals: {
            VitalKind.bloodPressure: [
              const VitalDaily(
                dayKey: '2026-11-10',
                count: 2,
                avg: 121.5,
                min: 118,
                max: 125,
                avg2: 79.5,
                min2: 76,
                max2: 82,
              ),
            ],
            VitalKind.glucose: [
              const VitalDaily(
                dayKey: '2026-11-09',
                count: 3,
                avg: 100,
                min: 90,
                max: 110,
              ),
            ],
            VitalKind.weight: [
              const VitalDaily(
                dayKey: '2026-11-11',
                count: 1,
                avg: 72.46,
                min: 72.46,
                max: 72.46,
              ),
            ],
            VitalKind.heartRate: const [],
          },
        ),
      );
      final rows = parse(c);
      final i = rows.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Vitals (daily summary)',
      );
      expect(rows[i + 1], [
        'Date',
        'Type',
        'Readings',
        'Average',
        'Min',
        'Max',
        'Unit',
      ]);
      expect(rows[i + 2], [
        '2026-11-10',
        'Blood pressure',
        '2',
        '121.5/79.5',
        '118/76',
        '125/82',
        'mmHg',
      ]);
      expect(rows[i + 3], [
        '2026-11-09',
        'Glucose',
        '3',
        '100',
        '90',
        '110',
        'mg/dL',
      ]);
      expect(rows[i + 4], [
        '2026-11-11',
        'Weight',
        '1',
        '72.46',
        '72.46',
        '72.46',
        'kg',
      ]);
    });

    test('decimal point is always a dot', () {
      final c = ReportCsvBuilder.build(
        report(
          options: const ReportOptions({ReportSection.vitals}),
          vitals: {
            VitalKind.weight: [
              const VitalDaily(
                dayKey: '2026-11-11',
                count: 1,
                avg: 98.6,
                min: 98.6,
                max: 98.6,
              ),
            ],
          },
        ),
      );
      expect(c.text, contains('98.6'));
      expect(c.text, isNot(contains('98,6')));
    });

    test('unavailable, empty and truncated notes', () {
      final unavailable = parse(
        ReportCsvBuilder.build(
          report(
            options: const ReportOptions({ReportSection.vitals}),
            unavailable: {ReportSection.vitals},
          ),
        ),
      );
      final i = unavailable.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Vitals (daily summary)',
      );
      expect(unavailable[i + 1].first, startsWith('Not available'));

      final empty = parse(
        ReportCsvBuilder.build(
          report(
            options: const ReportOptions({ReportSection.vitals}),
            vitals: {for (final k in VitalKind.values) k: const <VitalDaily>[]},
          ),
        ),
      );
      final j = empty.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Vitals (daily summary)',
      );
      expect(empty[j + 1], ['No data in this range']);

      final cut = parse(
        ReportCsvBuilder.build(
          report(
            options: const ReportOptions({ReportSection.vitals}),
            vitals: {
              VitalKind.glucose: [
                const VitalDaily(
                  dayKey: '2026-11-09',
                  count: 1,
                  avg: 100,
                  min: 100,
                  max: 100,
                ),
              ],
            },
            truncated: {ReportSection.vitals},
          ),
        ),
      );
      expect(cut.last.first, startsWith('Only the newest'));
    });
  });

  group('side effects section', () {
    test('rows are date-time, symptom, severity, notes', () {
      final rows = parse(
        ReportCsvBuilder.build(
          report(
            options: const ReportOptions({ReportSection.sideEffects}),
            symptoms: [
              SymptomEntry(
                symptom: 'Nausea',
                severity: 3,
                occurredAt: DateTime(2026, 11, 12, 21, 7),
                notes: 'after dinner',
              ),
              SymptomEntry(
                symptom: 'Headache',
                severity: 1,
                occurredAt: DateTime(2026, 11, 9, 6, 0),
              ),
            ],
          ),
        ),
      );
      final i = rows.indexWhere(
        (r) => r.isNotEmpty && r.first == 'Side effects',
      );
      expect(rows[i + 1], [
        'Date and time',
        'Symptom',
        'Severity (1-5)',
        'Notes',
      ]);
      expect(rows[i + 2], ['2026-11-12 21:07', 'Nausea', '3', 'after dinner']);
      expect(rows[i + 3], ['2026-11-09 06:00', 'Headache', '1', '']);
    });

    test('unavailable, empty and truncated notes', () {
      List<List<String>> build({
        List<SymptomEntry>? s,
        Set<ReportSection> unavailable = const {},
        Set<ReportSection> truncated = const {},
      }) => parse(
        ReportCsvBuilder.build(
          report(
            options: const ReportOptions({ReportSection.sideEffects}),
            symptoms: s,
            unavailable: unavailable,
            truncated: truncated,
          ),
        ),
      );

      final u = build(unavailable: {ReportSection.sideEffects});
      expect(u.last.first, startsWith('Not available'));
      final e = build(s: const []);
      expect(e.last, ['No data in this range']);
      final t = build(
        s: [
          SymptomEntry(
            symptom: 'X',
            severity: 1,
            occurredAt: DateTime(2026, 11, 10),
          ),
        ],
        truncated: {ReportSection.sideEffects},
      );
      expect(t.last.first, startsWith('Only the newest'));
    });
  });

  group('labels', () {
    test('every word can be replaced (other languages)', () {
      const l = ReportCsvLabels(
        title: 'Informe',
        profile: 'Perfil',
        adherenceSummary: 'Resumen',
        taken: 'Tomadas',
        noData: 'Sin datos',
      );
      final rows = parse(
        ReportCsvBuilder.build(
          report(doses: [dose('a', DateTime(2026, 11, 9, 8), taken)]),
          labels: l,
        ),
      );
      expect(rows[0], ['Informe']);
      expect(rows[1].first, 'Perfil');
      final i = rows.indexWhere((r) => r.isNotEmpty && r.first == 'Resumen');
      expect(rows[i + 1].first, 'Tomadas');
    });
  });

  test('sections are separated by exactly one blank line', () {
    final c = ReportCsvBuilder.build(
      report(
        doses: [dose('a', DateTime(2026, 11, 9, 8), taken)],
        options: all,
        vitals: {for (final k in VitalKind.values) k: const <VitalDaily>[]},
        symptoms: const [],
      ),
    );
    expect(c.text, isNot(contains('\r\n\r\n\r\n')));
    expect('\r\n\r\n'.allMatches(c.text).length, greaterThanOrEqualTo(5));
  });
}
