import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/adherence_calculator.dart';
import 'package:med_remind_app/core/reports/report_builder_controller.dart';
import 'package:med_remind_app/core/reports/report_csv_builder.dart';
import 'package:med_remind_app/core/reports/report_data_source.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/core/reports/report_options.dart';
import 'package:med_remind_app/core/reports/report_range.dart';

final now = DateTime(2026, 11, 14, 10, 0);

ReportData dataWith(ReportRange r, {bool empty = false}) => ReportData(
  range: r,
  generatedAt: now,
  options: const ReportOptions.adherenceOnly(),
  adherence: AdherenceCalculator.summarize(
    empty
        ? const []
        : [
            ReportDose(
              id: 'a',
              medicationId: 'm',
              medName: 'Metformin',
              scheduledAt: r.from,
              status: ReportDoseStatus.taken,
            ),
          ],
    r,
  ),
);

ReportFiles files() => ReportFiles(
  pdf: Uint8List.fromList([1, 2, 3]),
  csv: ReportCsv(fileName: 'x.csv', text: 'x', bytes: Uint8List.fromList([1])),
);

class Harness {
  Harness({this.empty = false, this.failLoad, this.failBuild, this.gate}) {
    c = ReportBuilderController(
      clock: () => now,
      loadData: (r, o) async {
        loads++;
        lastRange = r;
        lastOptions = o;
        if (gate != null) await gate!.future;
        if (failLoad != null) throw failLoad!;
        return dataWith(r, empty: empty);
      },
      buildFiles: (d) async {
        builds++;
        if (failBuild != null) throw failBuild!;
        return files();
      },
    );
  }

  final bool empty;
  final Object? failLoad;
  final Object? failBuild;
  final Completer<void>? gate;
  late final ReportBuilderController c;
  int loads = 0, builds = 0;
  ReportRange? lastRange;
  ReportOptions? lastOptions;
}

void main() {
  group('range and presets', () {
    test('starts on the last 7 days with adherence and vitals', () {
      final h = Harness();
      expect(h.c.activePreset, 7);
      expect(h.c.dayCount, 7);
      expect(h.c.rangeIsValid, isTrue);
      expect(h.c.options.adherence, isTrue);
      expect(h.c.options.vitals, isTrue);
      expect(h.c.options.sideEffects, isFalse);
      expect(h.c.phase, ReportBuilderPhase.editing);
    });

    test('presets 30 and 90', () {
      final h = Harness();
      h.c.selectPreset(30);
      expect(h.c.activePreset, 30);
      expect(h.c.dayCount, 30);
      h.c.selectPreset(90);
      expect(h.c.activePreset, 90);
      expect(h.c.isLargeRange, isFalse);
    });

    test('a custom range clears the preset', () {
      final h = Harness();
      h.c.setCustomRange(DateTime(2026, 11, 1), DateTime(2026, 11, 10));
      expect(h.c.activePreset, isNull);
      expect(h.c.dayCount, 10);
      expect(h.c.rangeIsValid, isTrue);
    });

    test('a custom range that equals a preset selects that preset', () {
      final h = Harness();
      h.c.setCustomRange(DateTime(2026, 10, 16), DateTime(2026, 11, 14));
      expect(h.c.activePreset, 30);
    });

    test('365 days is allowed and is flagged as a long range', () {
      final h = Harness();
      h.c.setCustomRange(DateTime(2025, 11, 15), DateTime(2026, 11, 14));
      expect(h.c.dayCount, 365);
      expect(h.c.rangeIsValid, isTrue);
      expect(h.c.isLargeRange, isTrue);
    });

    test('366 days is refused', () {
      final h = Harness();
      h.c.setCustomRange(DateTime(2025, 11, 14), DateTime(2026, 11, 14));
      expect(h.c.rangeErrors, {ReportRangeError.tooLong});
      expect(h.c.canGenerate, isFalse);
      expect(h.c.range, isNull);
    });

    test('from after to is refused', () {
      final h = Harness();
      h.c.setCustomRange(DateTime(2026, 11, 10), DateTime(2026, 11, 5));
      expect(h.c.rangeErrors, {ReportRangeError.fromAfterTo});
      expect(h.c.dayCount, 0);
      expect(h.c.canGenerate, isFalse);
    });

    test('a range ending in the future is refused', () {
      final h = Harness();
      h.c.setCustomRange(DateTime(2026, 11, 10), DateTime(2026, 11, 20));
      expect(h.c.rangeErrors, {ReportRangeError.inFuture});
      expect(h.c.canGenerate, isFalse);
    });

    test('an invalid range can be fixed with a preset', () {
      final h = Harness();
      h.c.setCustomRange(DateTime(2026, 11, 10), DateTime(2026, 11, 5));
      h.c.selectPreset(7);
      expect(h.c.rangeIsValid, isTrue);
      expect(h.c.canGenerate, isTrue);
    });

    test(
      'a valid initial range is used, an invalid one falls back to 7 days',
      () {
        final ok = ReportBuilderController(
          clock: () => now,
          initialRange: ReportRange.custom(
            DateTime(2026, 10, 1),
            DateTime(2026, 10, 31),
          ),
          loadData: (r, o) async => dataWith(r),
          buildFiles: (d) async => files(),
        );
        expect(ok.dayCount, 31);

        final bad = ReportBuilderController(
          clock: () => now,
          initialRange: ReportRange.custom(
            DateTime(2026, 11, 1),
            DateTime(2026, 12, 31),
          ),
          loadData: (r, o) async => dataWith(r),
          buildFiles: (d) async => files(),
        );
        expect(bad.activePreset, 7);
      },
    );
  });

  group('sections', () {
    test('toggling adds and removes', () {
      final h = Harness();
      h.c.toggleSection(ReportSection.sideEffects);
      expect(h.c.options.sideEffects, isTrue);
      h.c.toggleSection(ReportSection.sideEffects);
      expect(h.c.options.sideEffects, isFalse);
    });

    test('with no section chosen nothing can be generated', () {
      final h = Harness();
      h.c.toggleSection(ReportSection.adherence);
      h.c.toggleSection(ReportSection.vitals);
      expect(h.c.options.isValid, isFalse);
      expect(h.c.canGenerate, isFalse);
    });
  });

  group('generate', () {
    test('loads the data, builds the files and ends ready', () async {
      final h = Harness();
      final phases = <ReportBuilderPhase>[];
      h.c.addListener(() => phases.add(h.c.phase));
      await h.c.generate();

      expect(phases, [
        ReportBuilderPhase.loading,
        ReportBuilderPhase.building,
        ReportBuilderPhase.ready,
      ]);
      expect(h.loads, 1);
      expect(h.builds, 1);
      expect(h.c.data, isNotNull);
      expect(h.c.files!.pdf, [1, 2, 3]);
      expect(h.lastRange!.dayCount, 7);
      expect(h.lastOptions!.adherence, isTrue);
    });

    test('an empty range ends empty and builds nothing', () async {
      final h = Harness(empty: true);
      await h.c.generate();
      expect(h.c.phase, ReportBuilderPhase.empty);
      expect(h.builds, 0);
      expect(h.c.files, isNull);
      expect(h.c.canGenerate, isTrue); // a longer range can be tried
    });

    test('too many records is its own state', () async {
      final h = Harness(failLoad: ReportTooLargeException(20000));
      await h.c.generate();
      expect(h.c.phase, ReportBuilderPhase.tooLarge);
      expect(h.c.error, isA<ReportTooLargeException>());
      expect(h.builds, 0);
    });

    test('a load error ends failed and can be retried', () async {
      final h = Harness(failLoad: Exception('offline'));
      await h.c.generate();
      expect(h.c.phase, ReportBuilderPhase.failed);
      expect(h.c.canGenerate, isTrue);
      await h.c.generate();
      expect(h.loads, 2);
    });

    test('a build error ends failed', () async {
      final h = Harness(failBuild: Exception('boom'));
      await h.c.generate();
      expect(h.c.phase, ReportBuilderPhase.failed);
      expect(h.c.files, isNull);
    });

    test('a second tap while busy does nothing', () async {
      final gate = Completer<void>();
      final h = Harness(gate: gate);
      final first = h.c.generate();
      expect(h.c.phase, ReportBuilderPhase.loading);
      expect(h.c.canGenerate, isFalse);
      await h.c.generate(); // ignored
      expect(h.loads, 1);
      gate.complete();
      await first;
      expect(h.loads, 1);
      expect(h.c.phase, ReportBuilderPhase.ready);
    });

    test('the form cannot be changed while busy', () async {
      final gate = Completer<void>();
      final h = Harness(gate: gate);
      final run = h.c.generate();
      h.c.selectPreset(90);
      h.c.toggleSection(ReportSection.sideEffects);
      expect(h.c.activePreset, 7);
      expect(h.c.options.sideEffects, isFalse);
      gate.complete();
      await run;
    });

    test('an invalid form does not start anything', () async {
      final h = Harness();
      h.c.setCustomRange(DateTime(2026, 11, 10), DateTime(2026, 11, 5));
      await h.c.generate();
      expect(h.loads, 0);
      expect(h.c.phase, ReportBuilderPhase.editing);
    });

    test('changing the form after a result goes back to editing', () async {
      final h = Harness();
      await h.c.generate();
      expect(h.c.phase, ReportBuilderPhase.ready);
      h.c.selectPreset(30);
      expect(h.c.phase, ReportBuilderPhase.editing);
      expect(h.c.data, isNull);
      expect(h.c.files, isNull);
    });

    test('edit() returns to the form and keeps the choices', () async {
      final h = Harness();
      h.c.selectPreset(30);
      await h.c.generate();
      h.c.edit();
      expect(h.c.phase, ReportBuilderPhase.editing);
      expect(h.c.activePreset, 30);
    });

    test('disposing while loading does not throw', () async {
      final gate = Completer<void>();
      final h = Harness(gate: gate);
      final run = h.c.generate();
      h.c.dispose();
      gate.complete();
      await run;
    });
  });
}
