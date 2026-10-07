import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'report_preview_data.dart';

/// ============================================================
/// REPORT PREVIEW SCREEN (Export → PDF Preview)
///
/// PURPOSE:
/// Custom export configure karna (date range, data types,
/// profile) aur generate karke paginated PDF preview dekhna.
///
/// FLOW (requirement):
/// Adherence Detail → Export → [CONFIG FORM]
///   • Date range picker
///   • Checkboxes: Adherence / Vitals / Side effects
///   • Profile selector
///   • Generate Report (dummy 1.2s delay)
/// → [PDF PREVIEW] (Prev/Next pages, share sheet).
/// "Regenerate with different options" wapas config par.
///
/// NOTE:
/// Design mein bottom bar hai (Reports tab active) —
/// shared AppBottomNavigation use hota hai.
///
/// TODO Backend:
/// Range/profile/options ke hisaab se dossier generate,
/// share (physician contacts / encrypted device save)
/// Firestore + Cloud Functions se.
/// ============================================================
class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({super.key});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  int _currentPage = 1;

  /// true = config form, false = generated PDF preview.
  bool _isConfiguring = true;
  bool _isGenerating = false;

  /// Generate ke baad chhoti success state ("Report Generated!").
  bool _showGenerated = false;

  // ---- Export options (config form state) ----
  DateTimeRange _dateRange = DateTimeRange(
    start: ReportPreviewData.exportRangeStart,
    end: ReportPreviewData.exportRangeEnd,
  );
  String _profileName = ReportPreviewData.defaultProfile;
  final Set<ReportExportOption> _selectedOptions = {
    ReportExportOption.adherence,
    ReportExportOption.vitals,
  };

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Range label HTML jaisa: "11–17 Sep 2026".
  String get _dateRangeLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime start = _dateRange.start;
    final DateTime end = _dateRange.end;

    if (start.year == end.year && start.month == end.month) {
      return '${start.day}–${end.day} ${months[end.month - 1]} ${end.year}';
    }
    if (start.year == end.year) {
      return '${start.day} ${months[start.month - 1]}'
          ' – ${end.day} ${months[end.month - 1]} ${end.year}';
    }
    return '${start.day} ${months[start.month - 1]} ${start.year}'
        ' – ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  /// Single date label HTML jaisa: "11 Sep 2026".
  String _formatDateShort(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Selected range ke total din ("7 Days Total" pill).
  int get _totalDays => _dateRange.end.difference(_dateRange.start).inDays + 1;

  /// Active quick-range chip — null = custom range.
  ReportRangePreset? get _activePreset {
    for (final ReportRangePreset preset in ReportPreviewData.rangePresets) {
      if (preset.days == null) continue;
      if (_totalDays == preset.days &&
          _dateRange.end == ReportPreviewData.exportRangeEnd) {
        return preset;
      }
    }
    return null;
  }

  /// Chip tap → naya range; Custom → date picker.
  void _applyPreset(ReportRangePreset preset) {
    if (preset.days == null) {
      _pickDateRange();
      return;
    }

    final DateTime end = ReportPreviewData.exportRangeEnd;
    setState(() {
      _dateRange = DateTimeRange(
        start: end.subtract(Duration(days: preset.days! - 1)),
        end: end,
      );
    });
  }

  // ============================================================
  // PAGINATION (HTML JS: sirf indicator + button states)
  // ============================================================

  void _goToPrevPage() {
    if (_currentPage <= 1) return;
    setState(() => _currentPage--);
  }

  void _goToNextPage() {
    if (_currentPage >= ReportPreviewData.totalPages) return;
    setState(() => _currentPage++);
  }

  // ============================================================
  // GENERATE (requirement: select options → generate)
  // ============================================================

  void _generateReport() {
    if (_selectedOptions.isEmpty || _isGenerating) return;
    setState(() => _isGenerating = true);

    // TODO Backend:
    // Selected range + profile + data types se naya dossier
    // generate karna hai (Firestore/Cloud Function), phir preview.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _showGenerated = true;
      });

      // HTML jaisa chhota success feedback, phir preview.
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          _showGenerated = false;
          _isConfiguring = false;
        });

        if (_scrollController.hasClients) _scrollController.jumpTo(0);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Report generated')));
      });
    });
  }

  /// "Regenerate with different options" → wapas config form.
  void _regenerate() {
    setState(() => _isConfiguring = true);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  // ============================================================
  // DATE RANGE PICKER
  // ============================================================

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: _dateRange,
    );

    if (picked != null) setState(() => _dateRange = picked);
  }

  // ============================================================
  // DATA TYPE CHECKBOXES
  // ============================================================

  void _toggleOption(ReportExportOption option) {
    setState(() {
      if (!_selectedOptions.remove(option)) {
        _selectedOptions.add(option);
      }
    });
  }

  // ============================================================
  // SHARE
  // ============================================================

  Future<void> _openShareSheet() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.permissionsHeader.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (context) => _buildShareSheet(),
    );
  }

  /// Sheet ka koi bhi action (tile/row/Share Now) — pop + snackbar.
  void _completeShare(String action) {
    Navigator.of(context).pop();

    // TODO Backend:
    // Email/Print/Files/AirDrop, CSV/Documents export aur
    // Share Now — platform share API + file export backend se.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$action — pending backend')));
  }

  // ============================================================
  // BOTTOM NAVIGATION (Reports tab active = index 3)
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  //
  // AnnotatedRegion:
  // Status bar style sirf ISI screen par scoped hai.
  // ============================================================

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
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: _buildContent(),
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    // HTML mein "MedRemind" wordmark sm (640px+) breakpoint par hi dikhta hai.
    final bool showWordmark = MediaQuery.sizeOf(context).width >= 640;

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
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),

              const SizedBox(width: 2),

              Expanded(
                child: Text(
                  _isConfiguring ? 'Build Report' : 'Report Preview',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (showWordmark)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    'MedRemind',
                    style: TextStyle(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  // ============================================================
  // CONTENT (config form OR generated preview)
  // ============================================================

  Widget _buildContent() {
    if (_isConfiguring) return _buildConfigContent();
    return _buildPreviewContent();
  }

  // ============================================================
  // CONFIG FORM
  // (requirement: date range, checkboxes, profile, generate)
  // ============================================================

  Widget _buildConfigContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileSection(),

        const SizedBox(height: 16),

        _buildDateRangeSection(),

        const SizedBox(height: 16),

        _buildDataSection(),

        const SizedBox(height: 20),

        _buildPdfStatusCard(),

        const SizedBox(height: 20),

        _buildGenerateButton(),
      ],
    );
  }

  // ============================================================
  // PREVIEW CONTENT
  // ============================================================

  Widget _buildPreviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // 1. PAGE NAVIGATION (Prev / indicator / Next)
        // ======================================================

        _buildPageNavigator(),

        const SizedBox(height: 8),

        // ======================================================
        // 2. DOCUMENT PREVIEW (clinical sheet)
        // ======================================================
        _buildDocumentCard(),

        const SizedBox(height: 4),

        // ======================================================
        // 3. REGENERATE LINK
        // ======================================================
        _buildRegenerateButton(),

        const SizedBox(height: 8),

        // ======================================================
        // 4. SHARE REPORT
        // ======================================================
        _buildShareSection(),
      ],
    );
  }

  // ============================================================
  // PROFILE SECTION (card → profile picker sheet)
  // ============================================================

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildFieldLabel('PROFILE'),
        ),

        const SizedBox(height: 6),

        _buildProfileCard(),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ReportPreviewData.profileHelp,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              color: AppColors.permissionsSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: const BoxDecoration(
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
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: _openProfilePicker,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppAvatar(
                    size: 36,
                    ringColor: AppColors.reportChipHigh.withValues(alpha: 0.4),
                    ringWidth: 1,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileName.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.reportPrimary,
                          ),
                        ),
                        Text(
                          ReportPreviewData.profileCaptionFor(_profileName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: AppColors.permissionsSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.permissionsSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Profile card tap → profile chooser bottom sheet.
  Future<void> _openProfilePicker() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              const Text(
                'Select Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsHeader,
                ),
              ),

              const SizedBox(height: 8),

              for (final String name in ReportPreviewData.exportProfiles)
                ListTile(
                  dense: true,
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.reportPrimary,
                    ),
                  ),
                  trailing: name == _profileName
                      ? const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: AppColors.permissionsGreen,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (name != _profileName) {
                      setState(() => _profileName = name);
                    }
                  },
                ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.66,
        color: AppColors.permissionsSecondary,
      ),
    );
  }

  // ============================================================
  // DATE RANGE SECTION (quick chips + From/To cards)
  // ============================================================

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              _buildFieldLabel('DATE RANGE'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.permissionsBadgeBackground.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                ),
                child: Text(
                  '$_totalDays ${ReportPreviewData.daysTotalSuffix}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.permissionsGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ReportPreviewData.rangePresets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _buildRangeChip(ReportPreviewData.rangePresets[index]),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildDateCard(
                label: ReportPreviewData.fromLabel,
                value: _formatDateShort(_dateRange.start),
                icon: Icons.calendar_today_outlined,
                onTap: _pickDateRange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDateCard(
                label: ReportPreviewData.toLabel,
                value: _formatDateShort(_dateRange.end),
                icon: Icons.calendar_month_outlined,
                onTap: _pickDateRange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeChip(ReportRangePreset preset) {
    final bool isActive = preset.days != null
        ? _activePreset == preset
        : _activePreset == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _applyPreset(preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.reportConfigShadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          preset.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.surface
                : AppColors.permissionsSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.reportConfigShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
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

  // ============================================================
  // DATA TO INCLUDE (icon tiles + custom checkboxes)
  // ============================================================

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              _buildFieldLabel('DATA TO INCLUDE'),
              const Spacer(),
              Text(
                '${_selectedOptions.length} '
                '${ReportPreviewData.selectedSuffix}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
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
          ),
          child: Column(
            children: [
              for (int i = 0; i < ReportExportOption.values.length; i++) ...[
                if (i > 0) _buildOptionDivider(),
                _buildOptionRow(ReportExportOption.values[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: AppColors.permissionsInactiveFill,
    );
  }

  // ---- Checkbox row (data type) ----

  Widget _buildOptionRow(ReportExportOption option) {
    final bool isSelected = _selectedOptions.contains(option);

    return Semantics(
      checked: isSelected,
      label: option.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _toggleOption(option);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // ---- Icon tile ----
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _optionTileColor(option),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(
                  option.icon,
                  size: 20,
                  color: _optionIconColor(option),
                ),
              ),

              const SizedBox(width: 12),

              // ---- Label + description ----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportPrimary,
                      ),
                    ),
                    Text(
                      option.description,
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

              // ---- Custom checkbox (HTML design jaisa) ----
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.permissionsGreen
                      : AppColors.permissionsInactiveFill,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: isSelected ? AppColors.surface : AppColors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon tile ka background (HTML ke pastel tints).
  Color _optionTileColor(ReportExportOption option) {
    return switch (option) {
      ReportExportOption.adherence =>
        AppColors.permissionsBadgeBackground.withValues(alpha: 0.3),
      ReportExportOption.vitals => AppColors.reportVitalsTile.withValues(
        alpha: 0.4,
      ),
      ReportExportOption.sideEffects => AppColors.reportSurfaceContainer,
    };
  }

  /// Icon ka color per option.
  Color _optionIconColor(ReportExportOption option) {
    return switch (option) {
      ReportExportOption.adherence => AppColors.permissionsGreen,
      ReportExportOption.vitals => AppColors.permissionsSecondary,
      ReportExportOption.sideEffects => AppColors.permissionsSecondary,
    };
  }

  // ============================================================
  // PDF STATUS CARD (gradient strip + Ready pill)
  // ============================================================

  Widget _buildPdfStatusCard() {
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
                  ReportPreviewData.pdfCardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.reportPrimary,
                  ),
                ),
                Text(
                  ReportPreviewData.pdfCardSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: AppColors.permissionsSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.permissionsBadgeBackground,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Text(
              ReportPreviewData.pdfReadyLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.permissionsGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENERATE BUTTON
  // ============================================================

  Widget _buildGenerateButton() {
    final bool isBusy = _isGenerating || _showGenerated;
    final bool canGenerate = _selectedOptions.isNotEmpty && !isBusy;

    // HTML states: idle = tertiary-container green,
    // success = secondary blue, empty = chip fill (disabled).
    final Color bgColor = _showGenerated
        ? AppColors.permissionsSecondary
        : _selectedOptions.isEmpty
        ? AppColors.permissionsChipFill
        : AppColors.permissionsGreen;
    final Color fgColor = _selectedOptions.isEmpty && !_showGenerated
        ? AppColors.permissionsSecondary
        : AppColors.surface;

    late final Widget buttonChild;
    if (_isGenerating) {
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.surface,
            ),
          ),
          SizedBox(width: 10),
          Flexible(child: Text(ReportPreviewData.compilingLabel)),
        ],
      );
    } else if (_showGenerated) {
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 20),
          SizedBox(width: 8),
          Flexible(child: Text(ReportPreviewData.generatedLabel)),
        ],
      );
    } else {
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 22),
          SizedBox(width: 10),
          Flexible(child: Text('Generate Report')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: canGenerate ? _generateReport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: bgColor,
              disabledForegroundColor: fgColor,
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
            child: buttonChild,
          ),
        ),

        if (_selectedOptions.isEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            'Select at least one data type.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.permissionsErrorText,
            ),
          ),
        ],

        const SizedBox(height: 10),

        // ---- AES note (HTML CTA ke neeche) ----
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 14, color: AppColors.permissionsSecondary),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                ReportPreviewData.lockNote,
                textAlign: TextAlign.center,
                style: TextStyle(
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

  // ============================================================
  // PAGE NAVIGATOR
  // ============================================================

  Widget _buildPageNavigator() {
    final bool canGoPrev = _currentPage > 1;
    final bool canGoNext = _currentPage < ReportPreviewData.totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---- PREV ----
          Opacity(
            opacity: canGoPrev ? 1 : 0.4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canGoPrev ? _goToPrevPage : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: AppColors.permissionsSecondary,
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Prev',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.permissionsSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- PAGE INDICATOR PILL ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.permissionsInactiveFill,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 14,
                  color: AppColors.permissionsHeader,
                ),
                const SizedBox(width: 6),
                Text(
                  'PAGE $_currentPage OF ${ReportPreviewData.totalPages}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.permissionsHeader,
                  ),
                ),
              ],
            ),
          ),

          // ---- NEXT ----
          Opacity(
            opacity: canGoNext ? 1 : 0.4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canGoNext ? _goToNextPage : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.permissionsGreen,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.permissionsGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENT CARD (skeuomorphic clinical sheet)
  // ============================================================

  Widget _buildDocumentCard() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.reportCardShadow,
            blurRadius: 30,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        // NOTE: HTML ka bottom-right watermark emblem intentionally
        // REMOVE kiya — translucent footer ke peeche AES ke paas
        // chupke se show ho raha tha.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildReportBranding(),

                  _buildDivider(),

                  // ---- Selected data types ke hisaab se sections ----
                  if (_selectedOptions.contains(
                    ReportExportOption.adherence,
                  )) ...[
                    _buildComplianceMetric(),
                    _buildWeekCalendar(),
                  ],

                  if (_selectedOptions.contains(ReportExportOption.vitals))
                    _buildVitalsPanel(),

                  if (_selectedOptions.contains(ReportExportOption.sideEffects))
                    _buildSideEffectsPanel(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildPdfFooter(),
          ],
        ),
      ),
    );
  }

  // ---- Report branding / header ----

  Widget _buildReportBranding() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                ReportPreviewData.clinicalLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.permissionsSecondary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                ReportPreviewData.reportTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: AppColors.permissionsHeader,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _profileName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.reportPrimary,
                      ),
                    ),
                    const TextSpan(
                      text: ' · ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.permissionsSecondary,
                      ),
                    ),
                    TextSpan(
                      text: _dateRangeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.permissionsSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.reportSurfaceContainer,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            size: 22,
            color: AppColors.permissionsHeader,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.reportSurfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
    );
  }

  // ---- Summary compliance metric ----

  Widget _buildComplianceMetric() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      ReportPreviewData.adherenceLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.permissionsGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      ReportPreviewData.dosesConfirmed,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.permissionsSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ---- "Target met" chip ----
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.permissionsBadgeBackground,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: AppColors.reportTargetText,
                    ),
                    SizedBox(width: 4),
                    Text(
                      ReportPreviewData.targetChipLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportTargetText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ---- Adherence progress gauge ----
          Container(
            width: double.infinity,
            height: 10,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.permissionsInactiveFill,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ReportPreviewData.adherencePercent / 100,
                child: Container(
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.permissionsGreen,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Mini week compliance calendar ----

  Widget _buildWeekCalendar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                ReportPreviewData.dailySectionLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.66,
                  color: AppColors.permissionsHeader,
                ),
              ),
              const Text(
                ReportPreviewData.weekLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ReportPreviewData.weekDays.map(_buildWeekDay).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDay(ReportDay day) {
    Color circleBackground;
    IconData statusIcon;
    Color iconColor;

    switch (day.status) {
      case ReportDayStatus.taken:
        circleBackground = AppColors.permissionsGreen;
        statusIcon = Icons.check_rounded;
        iconColor = AppColors.surface;
      case ReportDayStatus.missed:
        circleBackground = AppColors.permissionsErrorContainer;
        statusIcon = Icons.priority_high_rounded;
        iconColor = AppColors.permissionsErrorText;
      case ReportDayStatus.pending:
        circleBackground = AppColors.permissionsInactiveFill;
        statusIcon = Icons.horizontal_rule_rounded;
        iconColor = AppColors.permissionsSecondary;
    }

    final bool isMissed = day.status == ReportDayStatus.missed;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 4),
        Text(
          day.letter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isMissed
                ? AppColors.permissionsErrorIcon
                : AppColors.permissionsSecondary,
          ),
        ),
      ],
    );
  }

  // ---- Logged vitals panel ----

  Widget _buildVitalsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 16,
                color: AppColors.permissionsSecondary,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  ReportPreviewData.vitalsLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.permissionsHeader,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          for (int i = 0; i < ReportPreviewData.vitals.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildVitalRow(ReportPreviewData.vitals[i]),
          ],

          const SizedBox(height: 10),

          const Text(
            ReportPreviewData.syncNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.permissionsSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalRow(ReportVitalRow vital) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            vital.label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.permissionsSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: vital.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.permissionsHeader,
                  ),
                ),
                TextSpan(
                  text: ' ${vital.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.permissionsSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Reported side effects panel ----

  Widget _buildSideEffectsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                size: 16,
                color: AppColors.permissionsSecondary,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  ReportPreviewData.sideEffectsLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.permissionsHeader,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          for (int i = 0; i < ReportPreviewData.sideEffects.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildSideEffectRow(ReportPreviewData.sideEffects[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSideEffectRow(ReportSideEffectRow row) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.medication,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.permissionsHeader,
                  ),
                ),
                Text(
                  row.effect,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.permissionsSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _severityBackground(row.severity),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
            child: Text(
              row.severity.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _severityTextColor(row.severity),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityBackground(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.low:
        return AppColors.successBackground;
      case ReportSeverity.medium:
        return AppColors.pendingBackground;
      case ReportSeverity.high:
        return AppColors.permissionsErrorContainer;
    }
  }

  Color _severityTextColor(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.low:
        return AppColors.success;
      case ReportSeverity.medium:
        return AppColors.statusPendingText;
      case ReportSeverity.high:
        return AppColors.permissionsErrorText;
    }
  }

  // ---- PDF stamp & footer ----

  Widget _buildPdfFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill.withValues(alpha: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---- Verified badge (narrow screens par ellipsis) ----
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 13,
                  color: AppColors.permissionsSecondary,
                ),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    ReportPreviewData.verifiedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.permissionsSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Page number ----
          Text(
            'Page $_currentPage / ${ReportPreviewData.totalPages}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.permissionsSecondary,
            ),
          ),

          // ---- Encryption ----
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 13,
                color: AppColors.permissionsSecondary,
              ),
              const SizedBox(width: 4),
              const Text(
                ReportPreviewData.aesLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.permissionsSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REGENERATE LINK (wapas config form)
  // ============================================================

  Widget _buildRegenerateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: TextButton(
          onPressed: _regenerate,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sync_rounded,
                size: 16,
                color: AppColors.permissionsGreen,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  ReportPreviewData.regenerateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.permissionsGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARE SECTION
  // ============================================================

  Widget _buildShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _openShareSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.permissionsGreen,
              foregroundColor: AppColors.surface,
              elevation: 6,
              shadowColor: AppColors.reportShareShadow,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ios_share_rounded, size: 20),
                SizedBox(width: 10),
                Text(ReportPreviewData.shareButtonLabel),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          ReportPreviewData.shareCaption,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.permissionsSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARE SHEET (share options bottom sheet)
  // ============================================================

  Widget _buildShareSheet() {
    final String firstName = _profileName.split(' ').first;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shareSheetShadow,
            blurRadius: 40,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- 1. Handle bar ----
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.shareBorder,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ---- 2. Title ----
              const Text(
                ReportPreviewData.shareSheetTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.25,
                  color: AppColors.permissionsHeader,
                ),
              ),

              const SizedBox(height: 2),

              // ---- 3. Subtitle ----
              Text(
                ReportPreviewData.shareSheetSubtitle(firstName),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.shareSecondaryText,
                ),
              ),

              const SizedBox(height: 20),

              // ---- 4. Share options grid (4 tiles) ----
              Row(
                children: [
                  for (
                    int i = 0;
                    i < ReportPreviewData.shareTiles.length;
                    i++
                  ) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _buildShareTile(ReportPreviewData.shareTiles[i]),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // ---- 5. Divider ----
              Container(height: 1, color: AppColors.shareDivider),

              const SizedBox(height: 16),

              // ---- 6. Secondary actions ----
              for (
                int i = 0;
                i < ReportPreviewData.shareRowActions.length;
                i++
              ) ...[
                if (i > 0) const SizedBox(height: 8),
                _buildShareActionRow(ReportPreviewData.shareRowActions[i]),
              ],

              const SizedBox(height: 16),

              // ---- 7. Share Now ----
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () =>
                      _completeShare(ReportPreviewData.shareNowLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shareActionGreen,
                    foregroundColor: AppColors.surface,
                    elevation: 4,
                    shadowColor: AppColors.shareButtonShadow,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ios_share_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(ReportPreviewData.shareNowLabel),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ---- 8. Cancel (underlined) ----
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    ReportPreviewData.cancelLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      color: AppColors.shareSecondaryText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ---- 9. Home indicator ----
              Center(
                child: Container(
                  width: 128,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.shareBorder,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Grid tile (Email / Print / Save to Files / AirDrop) ----

  Widget _buildShareTile(ReportShareTile tile) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _completeShare(tile.label);
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.shareTileFill,
              border: Border.all(color: AppColors.shareBorder),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.permissionsCardShadow,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(tile.icon, size: 24, color: AppColors.shareActionGreen),
          ),
          const SizedBox(height: 6),
          Text(
            tile.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.shareSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Secondary row (Save as CSV / Save to Documents) ----

  Widget _buildShareActionRow(ReportShareRowAction action) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _completeShare(action.label);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.shareTileFill,
          border: Border.all(
            color: AppColors.shareBorder.withValues(alpha: 0.8),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Icon(
                action.icon,
                size: 16,
                color: AppColors.shareActionGreen,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                action.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.shareActionGreen,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.shareSecondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
