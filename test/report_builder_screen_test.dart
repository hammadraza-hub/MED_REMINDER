import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/adherence_calculator.dart';
import 'package:med_remind_app/core/reports/report_builder_controller.dart';
import 'package:med_remind_app/core/reports/report_csv_builder.dart';
import 'package:med_remind_app/core/reports/report_data_source.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/core/reports/report_options.dart';
import 'package:med_remind_app/core/reports/report_range.dart';
import 'package:med_remind_app/core/reports/report_sharer.dart';
import 'package:med_remind_app/features/reports/report_pdf_viewer_screen.dart';
import 'package:med_remind_app/features/reports/report_preview_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

ReportBuilderController make({
  ReportRange? initialRange,
  bool empty = false,
  Object? failLoad,
  Completer<void>? gate,
}) {
  return ReportBuilderController(
    initialRange: initialRange,
    loadData: (r, o) async {
      if (gate != null) await gate.future;
      if (failLoad != null) throw failLoad;
      final doses = empty
          ? <ReportDose>[]
          : [
              for (var i = 0; i < 3; i++)
                ReportDose(
                  id: 't$i',
                  medicationId: 'm',
                  medName: 'Metformin',
                  scheduledAt: r.from,
                  status: ReportDoseStatus.taken,
                ),
              ReportDose(
                id: 'x',
                medicationId: 'm',
                medName: 'Metformin',
                scheduledAt: r.from,
                status: ReportDoseStatus.missed,
              ),
            ];
      return ReportData(
        range: r,
        generatedAt: DateTime.now(),
        options: o,
        adherence: AdherenceCalculator.summarize(doses, r),
      );
    },
    buildFiles: (d) async => ReportFiles(
      pdf: Uint8List(2048),
      csv: ReportCsv(fileName: 'a.csv', text: '', bytes: Uint8List(512)),
    ),
  );
}

Future<void> pump(
  WidgetTester t,
  ReportBuilderController c, {
  ReportSharer? sharer,
  bool pro = true,
}) async {
  t.view.physicalSize = const Size(800, 2200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: ReportPreviewScreen(
        controller: c,
        sharer: sharer,
        proCheck: () async => pro,
      ),
    ),
  );
  await t.pump();
}

void main() {
  testWidgets('shows the form and generates a report', (t) async {
    final c = make();
    await pump(t, c);
    expect(find.text('Generate Report'), findsWidgets);
    await t.tap(find.text('Generate Report').last);
    await t.pump();
    await t.pump();
    expect(c.phase, ReportBuilderPhase.ready);
    expect(find.byKey(const Key('report-percent')), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.byKey(const Key('report-file-info')), findsOneWidget);
  });

  testWidgets('empty range shows the no-data message', (t) async {
    final c = make(empty: true);
    await pump(t, c);
    await t.tap(find.text('Generate Report').last);
    await t.pump();
    await t.pump();
    expect(c.phase, ReportBuilderPhase.empty);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
  });

  testWidgets('failure offers Try again', (t) async {
    final c = make(failLoad: Exception('offline'));
    await pump(t, c);
    await t.tap(find.text('Generate Report').last);
    await t.pump();
    await t.pump();
    expect(c.phase, ReportBuilderPhase.failed);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('too many records shows its message', (t) async {
    final c = make(failLoad: ReportTooLargeException(20000));
    await pump(t, c);
    await t.tap(find.text('Generate Report').last);
    await t.pump();
    await t.pump();
    expect(find.byIcon(Icons.unfold_more_double_outlined), findsOneWidget);
  });

  testWidgets('Generate is disabled with no section chosen', (t) async {
    final c = make();
    await pump(t, c);
    c.toggleSection(ReportSection.adherence);
    c.toggleSection(ReportSection.vitals);
    await t.pump();
    expect(c.canGenerate, isFalse);
    final button = t.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('presets change the range', (t) async {
    final c = make();
    await pump(t, c);
    await t.tap(find.text('Last 30 days'));
    await t.pump();
    expect(c.dayCount, 30);
    expect(c.activePreset, 30);
  });

  testWidgets('change options returns to the form', (t) async {
    final c = make();
    await pump(t, c);
    await t.tap(find.text('Generate Report').last);
    await t.pump();
    await t.pump();
    await t.tap(find.text('Change range or options'));
    await t.pump();
    expect(c.phase, ReportBuilderPhase.editing);
    expect(find.byKey(const Key('report-percent')), findsNothing);
  });

  testWidgets('range is accepted as initialRange type', (t) async {
    expect(
      ReportRange.custom(DateTime(2026, 1, 1), DateTime(2026, 1, 7)).dayCount,
      7,
    );
  });

  group('sharing', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('rpt_screen'));
    tearDown(() => dir.deleteSync(recursive: true));

    Future<ReportBuilderController> ready(
      WidgetTester t,
      ReportSharer sharer,
    ) async {
      final c = make();
      await pump(t, c, sharer: sharer);
      await t.tap(find.text('Generate Report').last);
      await t.pump();
      await t.pump();
      return c;
    }

    testWidgets('Share PDF and Share CSV call the share sheet', (t) async {
      final calls = <String>[];
      final sharer = ReportSharer(
        tempDir: () async => dir,
        share: (path, mime, subject) async =>
            calls.add('$mime ${path.replaceAll(r'\', '/').split('/').last}'),
      );
      await ready(t, sharer);
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('report-share-pdf')));
        for (var i = 0; i < 100 && calls.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        await t.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await t.pump();
        await t.tap(find.byKey(const Key('report-share-csv')));
        for (var i = 0; i < 100 && calls.length < 2; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await t.pump();
      expect(calls, ['application/pdf a.pdf', 'text/csv a.csv']);
      expect(dir.listSync(), isEmpty);
    });

    testWidgets('a share error shows a message', (t) async {
      final sharer = ReportSharer(
        tempDir: () async => dir,
        share: (p, m, s) async => throw Exception('no app'),
      );
      await ready(t, sharer);
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('report-share-pdf')));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await t.pump();
      expect(
        find.text('Could not share the file. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Preview PDF opens the viewer', (t) async {
      final sharer = ReportSharer(
        tempDir: () async => dir,
        share: (p, m, s) async {},
      );
      await ready(t, sharer);
      await t.tap(find.byKey(const Key('report-preview')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(ReportPdfViewerScreen), findsOneWidget);
    });
  });

  group('pro gate (Free = last 7 days)', () {
    testWidgets('Free: 30 days opens the upgrade dialog, range unchanged', (
      t,
    ) async {
      final c = make();
      await pump(t, c, pro: false);
      await t.pump();
      expect(find.byKey(const Key('report-pro-lock')), findsWidgets);
      await t.tap(find.text('Last 30 days'));
      await t.pumpAndSettle();
      expect(find.text('Longer reports are a Pro feature'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(c.dayCount, 7);
      expect(c.activePreset, 7);
    });

    testWidgets('Free: Last 7 days still works', (t) async {
      final c = make();
      await pump(t, c, pro: false);
      await t.tap(find.text('Last 7 days'));
      await t.pumpAndSettle();
      expect(find.text('Longer reports are a Pro feature'), findsNothing);
    });

    testWidgets('Free: a longer range from another screen cannot Generate', (
      t,
    ) async {
      final c = make(
        initialRange: ReportRange.custom(
          DateTime.now().subtract(const Duration(days: 29)),
          DateTime.now(),
        ),
      );
      await pump(t, c, pro: false);
      await t.tap(find.text('Generate Report').last);
      await t.pumpAndSettle();
      expect(find.text('Longer reports are a Pro feature'), findsOneWidget);
      expect(c.phase, ReportBuilderPhase.editing);
    });

    testWidgets('Pro: 30 days works and no lock icons show', (t) async {
      final c = make();
      await pump(t, c, pro: true);
      await t.pump();
      expect(find.byKey(const Key('report-pro-lock')), findsNothing);
      await t.tap(find.text('Last 30 days'));
      await t.pumpAndSettle();
      expect(c.dayCount, 30);
    });

    testWidgets('a failing Pro check is treated as Free', (t) async {
      final c = make();
      t.view.physicalSize = const Size(800, 2200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ReportPreviewScreen(
            controller: c,
            proCheck: () async => throw Exception('offline'),
          ),
        ),
      );
      await t.pump();
      await t.tap(find.text('Last 30 days'));
      await t.pumpAndSettle();
      expect(find.text('Longer reports are a Pro feature'), findsOneWidget);
      expect(c.dayCount, 7);
    });
  });
}
