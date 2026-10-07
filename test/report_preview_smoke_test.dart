import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/features/reports/report_preview_screen.dart';

void main() {
  testWidgets('build report → generate → preview → share sheet',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReportPreviewScreen()),
    );
    await tester.pumpAndSettle();

    // ---- BUILD REPORT (config) ----
    expect(find.text('Build Report'), findsOneWidget);
    expect(find.text('Generate Report'), findsOneWidget);
    expect(find.text('11 Sep 2026'), findsOneWidget);
    expect(find.text('17 Sep 2026'), findsOneWidget);
    expect(find.text('7 Days Total'), findsOneWidget);
    expect(find.text('2 Selected'), findsOneWidget);

    // Checkbox: side effects ON → 3 Selected
    await tester.ensureVisible(find.text('Side Effects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Side Effects'));
    await tester.pumpAndSettle();
    expect(find.text('3 Selected'), findsOneWidget);
    expect(find.text('Symptoms, severity index & notes'), findsOneWidget);

    // ---- GENERATE ----
    await tester.ensureVisible(find.text('Generate Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Report'));
    await tester.pump();
    expect(find.text('Compiling Summary...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    expect(find.text('Report Generated!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    // ---- PREVIEW ----
    expect(find.text('Report Preview'), findsOneWidget);
    expect(find.text('Medication Adherence Report'), findsOneWidget);
    expect(find.text('REPORTED SIDE EFFECTS'), findsOneWidget);
    expect(find.text('PAGE 1 OF 3'), findsOneWidget);

    // Prev/Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 2 OF 3'), findsOneWidget);

    // Regenerate → config
    await tester.ensureVisible(find.text('Regenerate with different options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regenerate with different options'));
    await tester.pumpAndSettle();
    expect(find.text('Build Report'), findsOneWidget);

    // Generate again → share sheet
    await tester.ensureVisible(find.text('Generate Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Report'));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Share Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share Report'));
    await tester.pumpAndSettle();

    // ---- SHARE SHEET ----
    expect(
      find.text('Adherence Report · Sarah · 3 pages · PDF'),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    expect(find.text('Save to Files'), findsOneWidget);
    expect(find.text('AirDrop'), findsOneWidget);
    expect(find.text('Save as CSV'), findsOneWidget);
    expect(find.text('Save to Documents'), findsOneWidget);
    expect(find.text('Share Now'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Cancel → sheet close
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Share Now'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
