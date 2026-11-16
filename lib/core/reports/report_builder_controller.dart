import 'package:flutter/foundation.dart';

import 'report_csv_builder.dart';
import 'report_data_source.dart';
import 'report_models.dart';
import 'report_options.dart';
import 'report_range.dart';

/// Where the Report Builder screen is. M17 step 5.
enum ReportBuilderPhase {
  /// The form (range, sections) is shown.
  editing,

  /// Reading the data.
  loading,

  /// Making the PDF and CSV.
  building,

  /// A report was made.
  ready,

  /// The range has nothing to report.
  empty,

  /// More doses than a report can safely hold.
  tooLarge,

  /// Something went wrong (network, permission...).
  failed,
}

/// The finished files.
class ReportFiles {
  const ReportFiles({required this.pdf, required this.csv});

  final Uint8List pdf;
  final ReportCsv csv;
}

/// ============================================================
/// REPORT BUILDER CONTROLLER — M17 step 5
///
/// All the logic of the Report Builder screen, without any widget: the chosen
/// range and sections, the checks on them, and the state machine of
/// Generate. Loading and building are injected, so it is unit-testable.
/// ============================================================
class ReportBuilderController extends ChangeNotifier {
  ReportBuilderController({
    required this.loadData,
    required this.buildFiles,
    DateTime Function()? clock,
    ReportRange? initialRange,
    ReportOptions initialOptions = const ReportOptions({
      ReportSection.adherence,
      ReportSection.vitals,
    }),
  }) : _clock = clock ?? DateTime.now,
       _options = initialOptions {
    final start = initialRange;
    if (start != null &&
        ReportRange.validate(start.from, start.to, now: _clock()).isEmpty) {
      _from = start.from;
      _to = start.to;
    } else {
      final def = ReportRange.lastDays(7, now: _clock());
      _from = def.from;
      _to = def.to;
    }
  }

  /// Reads everything for a range.
  final Future<ReportData> Function(ReportRange range, ReportOptions options)
  loadData;

  /// Makes the PDF and CSV from the data (runs in a background isolate in the
  /// app).
  final Future<ReportFiles> Function(ReportData data) buildFiles;

  final DateTime Function() _clock;

  late DateTime _from;
  late DateTime _to;
  ReportOptions _options;

  ReportBuilderPhase _phase = ReportBuilderPhase.editing;
  ReportData? _data;
  ReportFiles? _files;
  Object? _error;
  bool _disposed = false;

  // ------------------------------------------------------------
  // what the form shows
  // ------------------------------------------------------------

  ReportBuilderPhase get phase => _phase;
  ReportOptions get options => _options;
  DateTime get from => _from;
  DateTime get to => _to;

  /// Problems with the chosen dates (empty = fine).
  Set<ReportRangeError> get rangeErrors =>
      ReportRange.validate(_from, _to, now: _clock());

  bool get rangeIsValid => rangeErrors.isEmpty;

  /// The range, or null when the dates are not valid.
  ReportRange? get range =>
      rangeIsValid ? ReportRange.custom(_from, _to) : null;

  /// Number of days chosen (also for an invalid range, as long as from <= to).
  int get dayCount {
    final f = ReportRange.dayOf(_from);
    final t = ReportRange.dayOf(_to);
    if (f.isAfter(t)) return 0;
    return ReportRange.custom(_from, _to).dayCount;
  }

  /// 7, 30 or 90 when the range is exactly "the last N days"; null = custom.
  int? get activePreset {
    for (final n in presets) {
      final p = ReportRange.lastDays(n, now: _clock());
      if (p.from == ReportRange.dayOf(_from) &&
          p.to == ReportRange.dayOf(_to)) {
        return n;
      }
    }
    return null;
  }

  static const List<int> presets = [7, 30, 90];

  /// Above this many days the screen warns that it may take a moment.
  static const int slowRangeDays = 90;

  bool get isLargeRange => dayCount > slowRangeDays;

  bool get canGenerate =>
      rangeIsValid &&
      _options.isValid &&
      (_phase == ReportBuilderPhase.editing ||
          _phase == ReportBuilderPhase.failed ||
          _phase == ReportBuilderPhase.empty ||
          _phase == ReportBuilderPhase.tooLarge);

  bool get isBusy =>
      _phase == ReportBuilderPhase.loading ||
      _phase == ReportBuilderPhase.building;

  ReportData? get data => _data;
  ReportFiles? get files => _files;
  Object? get error => _error;

  // ------------------------------------------------------------
  // changing the form
  // ------------------------------------------------------------

  void selectPreset(int days) {
    if (isBusy) return;
    final r = ReportRange.lastDays(days, now: _clock());
    _from = r.from;
    _to = r.to;
    _backToEditing();
  }

  /// A custom range. Invalid dates are kept (so the screen can show what is
  /// wrong) but cannot be generated.
  void setCustomRange(DateTime from, DateTime to) {
    if (isBusy) return;
    _from = ReportRange.dayOf(from);
    _to = ReportRange.dayOf(to);
    _backToEditing();
  }

  void toggleSection(ReportSection s) {
    if (isBusy) return;
    _options = _options.toggled(s);
    _backToEditing();
  }

  /// "Change range or options" on a result card.
  void edit() {
    if (isBusy) return;
    _phase = ReportBuilderPhase.editing;
    _data = null;
    _files = null;
    _error = null;
    _notify();
  }

  void _backToEditing() {
    if (_phase != ReportBuilderPhase.editing) {
      _phase = ReportBuilderPhase.editing;
      _data = null;
      _files = null;
      _error = null;
    }
    _notify();
  }

  // ------------------------------------------------------------
  // Generate
  // ------------------------------------------------------------

  /// Reads the data and makes the files. Does nothing when a report is already
  /// being made (double tap) or the form is not valid.
  Future<void> generate() async {
    if (!canGenerate) return;
    final r = range!;
    final o = _options;

    _phase = ReportBuilderPhase.loading;
    _data = null;
    _files = null;
    _error = null;
    _notify();

    try {
      final data = await loadData(r, o);
      if (_disposed) return;

      if (data.isEmpty) {
        _data = data;
        _phase = ReportBuilderPhase.empty;
        _notify();
        return;
      }

      _phase = ReportBuilderPhase.building;
      _notify();

      final files = await buildFiles(data);
      if (_disposed) return;

      _data = data;
      _files = files;
      _phase = ReportBuilderPhase.ready;
      _notify();
    } on ReportTooLargeException catch (e) {
      if (_disposed) return;
      _error = e;
      _phase = ReportBuilderPhase.tooLarge;
      _notify();
    } catch (e) {
      if (_disposed) return;
      _error = e;
      _phase = ReportBuilderPhase.failed;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
