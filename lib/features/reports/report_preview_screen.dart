import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../core/reports/report_builder_controller.dart';
import '../../core/reports/report_options.dart';
import '../../core/reports/report_pro_rule.dart';
import '../../core/reports/report_range.dart';
import '../../core/reports/report_sharer.dart';
import '../../core/services/pro_access.dart';
import '../../core/services/report_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../settings/subscription_screen.dart';
import 'report_pdf_viewer_screen.dart';

/// ============================================================
/// REPORT BUILDER — M17 step 5
///
/// Pick a profile's date range and what to include, then Generate: the data is
/// read from Firestore and the PDF + CSV are made on the phone (no server).
/// Preview and sharing of the finished files come in step 6.
///
/// All the logic lives in [ReportBuilderController]; this screen only draws it.
///
/// FLOW: Adherence Detail → Export → this screen (the range chosen there is
/// carried over).
/// ============================================================
class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({
    super.key,
    this.initialRange,
    this.controller,
    this.sharer,
    this.proCheck,
  });

  /// The range of the screen we came from (ignored when it is not valid).
  final ReportRange? initialRange;

  /// For tests: a controller with fake loading.
  @visibleForTesting
  final ReportBuilderController? controller;

  @visibleForTesting
  final ReportSharer? sharer;

  /// For tests: replaces the real "is this user Pro?" check.
  @visibleForTesting
  final Future<bool> Function()? proCheck;

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  late final ReportBuilderController _c;
  late final bool _ownsController;
  final ScrollController _scroll = ScrollController();

  late final ReportSharer _sharer =
      widget.sharer ??
      ReportSharer(
        tempDir: getTemporaryDirectory,
        share: (path, mime, subject) async {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(path, mimeType: mime)],
              subject: subject,
            ),
          );
        },
      );
  bool _sharing = false;

  /// null until the first check has answered.
  bool? _isPro;

  Future<bool> _checkPro() async {
    final check = widget.proCheck ?? ProAccess.gate.isPro;
    bool pro;
    try {
      pro = await check();
    } catch (_) {
      pro = false; // fail closed
    }
    if (mounted) setState(() => _isPro = pro);
    return pro;
  }

  /// True when a report of [days] days may be made; otherwise the upgrade
  /// dialog has been shown.
  Future<bool> _allowDays(int days) async {
    if (!ReportProRule.needsPro(days)) return true;
    if (await _checkPro()) return true;
    if (mounted) await _showProDialog();
    return false;
  }

  Future<void> _showProDialog() {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rptProTitle),
        content: Text(l10n.rptProBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: Text(l10n.proGateSeePlans),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPreset(int days) async {
    if (!await _allowDays(days)) return;
    _c.selectPreset(days);
  }

  AppLocalizations? _l10nAtGenerate;
  bool _rtlAtGenerate = false;

  String? get _memberId {
    final id = ProfileController.instance.memberId;
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _c =
        widget.controller ??
        ReportBuilderController(
          initialRange: widget.initialRange,
          loadData: (range, options) {
            final memberId = _memberId;
            if (memberId == null) {
              throw StateError('No profile selected');
            }
            final name = ProfileController.instance.displayName.trim();
            return ReportService.instance.load(
              memberId: memberId,
              profileName: name.isEmpty ? null : name,
              range: range,
              options: options,
            );
          },
          buildFiles: (data) => ReportService.instance.buildFiles(
            data: data,
            l10n: _l10nAtGenerate!,
            rtl: _rtlAtGenerate,
          ),
        );
    _c.addListener(_onChanged);
    _checkPro();
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    if (_ownsController) _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------
  // actions
  // ------------------------------------------------------------

  Future<void> _generate() async {
    if (!await _allowDays(_c.dayCount)) return;
    if (!mounted) return;
    _l10nAtGenerate = AppLocalizations.of(context);
    _rtlAtGenerate = Directionality.of(context) == TextDirection.rtl;
    await _c.generate();
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _share({required bool pdf}) async {
    final files = _c.files;
    if (files == null || _sharing) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final subject = l10n.rptShareSubject;
      if (pdf) {
        await _sharer.sharePdf(
          files.pdf,
          fileName: ReportSharer.pdfName(files.csv.fileName),
          subject: subject,
        );
      } else {
        await _sharer.shareCsv(
          files.csv.bytes,
          fileName: files.csv.fileName,
          subject: subject,
        );
      }
    } catch (e) {
      debugPrint('share failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.rptShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _openPreview() {
    final files = _c.files;
    if (files == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportPdfViewerScreen(
          pdf: files.pdf,
          onShare: () => _share(pdf: true),
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(
        start: _c.from.isAfter(_c.to) ? _c.to : _c.from,
        end: _c.to,
      ),
    );
    if (picked == null) return;
    final days = ReportRange.custom(picked.start, picked.end).dayCount;
    if (!await _allowDays(days)) return;
    _c.setCustomRange(picked.start, picked.end);
  }

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ------------------------------------------------------------
  // build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.permissionsHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: _c.phase == ReportBuilderPhase.ready
                        ? _buildReady()
                        : _buildForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: 3,
          onTap: _onBottomNavigationTap,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.permissionsHeader,
        boxShadow: [
          BoxShadow(
            color: AppColors.reportHeaderShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  _c.phase == ReportBuilderPhase.ready
                      ? l10n.rptReadyTitle
                      : l10n.rptTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppAvatar(
                size: 32,
                ringColor: AppColors.surface,
                ringWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // the form
  // ------------------------------------------------------------

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(l10n.rptProfile),
        const SizedBox(height: 6),
        _profileCard(),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.rptProfileHelp,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              color: AppColors.permissionsSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _rangeSection(),
        const SizedBox(height: 16),
        _dataSection(),
        const SizedBox(height: 16),
        _summaryCard(),
        const SizedBox(height: 16),
        _phaseMessage(),
        _generateButton(),
      ],
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.66,
        color: AppColors.permissionsSecondary,
      ),
    ),
  );

  BoxDecoration get _cardDecoration => const BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [
      BoxShadow(
        color: AppColors.reportConfigShadow,
        blurRadius: 20,
        offset: Offset(0, 4),
        spreadRadius: -2,
      ),
    ],
  );

  Widget _profileCard() {
    final name = ProfileController.instance.displayName.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          AppAvatar(
            size: 36,
            ringColor: AppColors.reportChipHigh.withValues(alpha: 0.4),
            ringWidth: 1,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? '—' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.reportPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- range ----

  String _date(DateTime d) =>
      DateFormat.yMMMd(AppLocalizations.of(context).localeName).format(d);

  Widget _rangeSection() {
    final l10n = AppLocalizations.of(context);
    final errors = _c.rangeErrors;
    final String? error = errors.contains(ReportRangeError.fromAfterTo)
        ? l10n.rptErrFromAfterTo
        : errors.contains(ReportRangeError.tooLong)
        ? l10n.rptErrTooLong
        : errors.contains(ReportRangeError.inFuture)
        ? l10n.rptErrFuture
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _label(l10n.rptDateRange),
            const Spacer(),
            if (_c.dayCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.permissionsBadgeBackground.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                ),
                child: Text(
                  l10n.rptDaysTotal(_c.dayCount),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.permissionsGreen,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(
                l10n.rptPreset7,
                _c.activePreset == 7,
                () => _selectPreset(7),
              ),
              const SizedBox(width: 8),
              _chip(
                l10n.rptPreset30,
                _c.activePreset == 30,
                () => _selectPreset(30),
                locked: _isPro == false,
              ),
              const SizedBox(width: 8),
              _chip(
                l10n.rptPreset90,
                _c.activePreset == 90,
                () => _selectPreset(90),
                locked: _isPro == false,
              ),
              const SizedBox(width: 8),
              _chip(
                l10n.rptPresetCustom,
                _c.activePreset == null,
                _pickRange,
                locked: _isPro == false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dateCard(
                l10n.rptFrom,
                _date(_c.from),
                Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateCard(
                l10n.rptTo,
                _date(_c.to),
                Icons.calendar_month_outlined,
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.permissionsErrorText,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(
    String label,
    bool active,
    VoidCallback onTap, {
    bool locked = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _c.isBusy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.reportConfigShadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppColors.surface
                    : AppColors.permissionsSecondary,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline_rounded,
                key: const Key('report-pro-lock'),
                size: 14,
                color: active
                    ? AppColors.surface
                    : AppColors.permissionsSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateCard(String label, String value, IconData icon) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _c.isBusy ? null : _pickRange,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: AppColors.permissionsSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.reportPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 18, color: AppColors.permissionsSecondary),
          ],
        ),
      ),
    );
  }

  // ---- sections ----

  String _sectionName(ReportSection s) {
    final l10n = AppLocalizations.of(context);
    switch (s) {
      case ReportSection.adherence:
        return l10n.rptOptAdherence;
      case ReportSection.vitals:
        return l10n.rptOptVitals;
      case ReportSection.sideEffects:
        return l10n.rptOptSideEffects;
    }
  }

  Widget _dataSection() {
    final l10n = AppLocalizations.of(context);
    final info = <ReportSection, (String, IconData, Color, Color)>{
      ReportSection.adherence: (
        l10n.rptOptAdherenceDesc,
        Icons.verified,
        AppColors.permissionsBadgeBackground.withValues(alpha: 0.3),
        AppColors.permissionsGreen,
      ),
      ReportSection.vitals: (
        l10n.rptOptVitalsDesc,
        Icons.monitor_heart,
        AppColors.reportVitalsTile.withValues(alpha: 0.4),
        AppColors.permissionsSecondary,
      ),
      ReportSection.sideEffects: (
        l10n.rptOptSideEffectsDesc,
        Icons.healing_outlined,
        AppColors.reportSurfaceContainer,
        AppColors.permissionsSecondary,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _label(l10n.rptData),
            const Spacer(),
            Text(
              l10n.rptSelectedCount(_c.options.sections.length),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            children: [
              for (final s in ReportSection.values) ...[
                if (s != ReportSection.values.first)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    color: AppColors.permissionsInactiveFill,
                  ),
                _optionRow(s, info[s]!),
              ],
            ],
          ),
        ),
        if (_c.options.needsHealthAccess) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.rptHealthAccessNote,
              style: const TextStyle(
                fontSize: 11,
                height: 1.3,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionRow(ReportSection s, (String, IconData, Color, Color) info) {
    final selected = _c.options.sections.contains(s);
    return Semantics(
      checked: selected,
      label: _sectionName(s),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _c.toggleSection(s),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: info.$3,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(info.$2, size: 20, color: info.$4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sectionName(s),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportPrimary,
                      ),
                    ),
                    Text(
                      info.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: AppColors.permissionsSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.permissionsGreen
                      : AppColors.permissionsInactiveFill,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: selected ? AppColors.surface : AppColors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- summary ----

  Widget _summaryCard() {
    final l10n = AppLocalizations.of(context);
    final names = [
      for (final s in ReportSection.values)
        if (_c.options.sections.contains(s)) _sectionName(s),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.permissionsChipFill,
            AppColors.permissionsInactiveFill.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.permissionsHeader,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              size: 18,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rptSummaryTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.reportPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (_c.dayCount > 0) l10n.rptDaysTotal(_c.dayCount),
                    ...names,
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: AppColors.permissionsSecondary,
                  ),
                ),
                if (_c.isLargeRange) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.rptLargeNote,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: AppColors.permissionsSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- result messages + button ----

  Widget _phaseMessage() {
    final l10n = AppLocalizations.of(context);
    String? title;
    String? body;
    IconData icon = Icons.info_outline_rounded;
    var retry = false;

    switch (_c.phase) {
      case ReportBuilderPhase.empty:
        title = l10n.rptNoDataTitle;
        body = l10n.rptNoDataBody;
        icon = Icons.event_busy_outlined;
      case ReportBuilderPhase.tooLarge:
        title = l10n.rptTooLargeTitle;
        body = l10n.rptTooLargeBody;
        icon = Icons.unfold_more_double_outlined;
      case ReportBuilderPhase.failed:
        title = l10n.rptErrorTitle;
        body = l10n.rptErrorBody;
        icon = Icons.cloud_off_outlined;
        retry = true;
      case ReportBuilderPhase.editing:
      case ReportBuilderPhase.loading:
      case ReportBuilderPhase.building:
      case ReportBuilderPhase.ready:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: AppColors.permissionsSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.reportPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.permissionsSecondary,
                    ),
                  ),
                  if (retry)
                    TextButton(
                      onPressed: _c.canGenerate ? _generate : null,
                      child: Text(l10n.rptTryAgain),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateButton() {
    final l10n = AppLocalizations.of(context);
    final busy = _c.isBusy;
    final noSection = !_c.options.isValid;
    final noProfile = _memberId == null && widget.controller == null;
    final enabled = _c.canGenerate && !noProfile;

    final Widget child = busy
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _c.phase == ReportBuilderPhase.loading
                      ? l10n.rptLoadingData
                      : l10n.rptBuilding,
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description, size: 22),
              const SizedBox(width: 10),
              Flexible(child: Text(l10n.rptGenerate)),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: enabled ? _generate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.permissionsGreen,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: busy
                  ? AppColors.permissionsGreen
                  : AppColors.permissionsChipFill,
              disabledForegroundColor: busy
                  ? AppColors.surface
                  : AppColors.permissionsSecondary,
              elevation: 4,
              shadowColor: AppColors.reportGenerateShadow,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: child,
          ),
        ),
        if (noSection) ...[
          const SizedBox(height: 6),
          Text(
            l10n.rptSelectOne,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.permissionsErrorText,
            ),
          ),
        ],
        if (noProfile) ...[
          const SizedBox(height: 6),
          Text(
            l10n.vitalsErrNoProfile,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.permissionsErrorText,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 14,
              color: AppColors.permissionsSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.rptPrivacyNote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // the finished report (preview and sharing arrive in step 6)
  // ------------------------------------------------------------

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildReady() {
    final l10n = AppLocalizations.of(context);
    final data = _c.data!;
    final files = _c.files!;
    final a = data.adherence;
    final range = data.range;

    Widget stat(String label, int n, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            '$n',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.permissionsSecondary,
            ),
          ),
        ],
      ),
    );

    final notes = <String>[
      for (final s in data.unavailable)
        l10n.rptSectionNotIncluded(_sectionName(s)),
      for (final s in data.truncated) l10n.rptSectionTruncated(_sectionName(s)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.permissionsGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.rptReadyTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_date(range.from)} – ${_date(range.to)} · '
                '${l10n.rptDaysTotal(range.dayCount)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.permissionsSecondary,
                ),
              ),
              if (a != null && a.total.hasData) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      a.total.decided == 0 ? '–' : '${a.total.percent}%',
                      key: const Key('report-percent'),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.permissionsGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${l10n.rptLOverallAdherence}\n'
                          '${a.total.decided} ${l10n.rptLDecidedDoses}',
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: AppColors.permissionsSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    stat(
                      l10n.rptLTaken,
                      a.total.taken,
                      AppColors.permissionsGreen,
                    ),
                    stat(l10n.rptLMissed, a.total.missed, AppColors.error),
                    stat(
                      l10n.rptLSkipped,
                      a.total.skipped,
                      const Color(0xFFE67E22),
                    ),
                    stat(
                      l10n.rptLPending,
                      a.total.pending,
                      AppColors.permissionsSecondary,
                    ),
                  ],
                ),
              ],
              for (final n in notes) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.permissionsSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        n,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: AppColors.permissionsSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Text(
                l10n.rptFileInfo(
                  _size(files.pdf.length),
                  _size(files.csv.bytes.length),
                ),
                key: const Key('report-file-info'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.reportPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _actionButton(
          key: const Key('report-preview'),
          icon: Icons.picture_as_pdf_outlined,
          label: l10n.rptPreviewPdf,
          filled: true,
          onTap: _sharing ? null : _openPreview,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                key: const Key('report-share-pdf'),
                icon: Icons.share_outlined,
                label: l10n.rptSharePdf,
                onTap: _sharing ? null : () => _share(pdf: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionButton(
                key: const Key('report-share-csv'),
                icon: Icons.table_chart_outlined,
                label: l10n.rptShareCsv,
                onTap: _sharing ? null : () => _share(pdf: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _c.edit,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: AppColors.permissionsSecondary),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          child: Text(
            l10n.rptChangeOptions,
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    if (filled) {
      return ElevatedButton(
        key: key,
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.permissionsGreen,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(52),
          shape: shape,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      key: key,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.permissionsGreen,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.permissionsGreen),
        shape: shape,
      ),
      child: child,
    );
  }
}
