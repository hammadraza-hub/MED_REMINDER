import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../widgets/app_avatar.dart';
import 'add_allergy_screen.dart';
import 'allergies_data.dart';

/// ============================================================
/// ALLERGIES — allergen list + Add/Edit sheet
///
/// DATA:
/// UI → AllergiesData (in-memory, backend-ready)
///
/// TODO Local Storage / Backend:
/// Firestore allergies collection:
/// { id, memberId, name, category, severity, symptoms, addedAt }
///
/// MEMBER ISOLATION:
/// ProfileController.memberId se records filter hote hain.
///
/// ACTIONS:
/// • Tap + / "Add"        → Add sheet (save → list refresh)
/// • Tap any allergy card → Edit sheet (update/remove)
/// • New medications isi list ke against auto-checked (future engine)
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
/// ============================================================
class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  List<AllergyRecord> _records = [];

  @override
  void initState() {
    super.initState();

    _loadRecords();
  }

  // ============================================================
  // DATA
  // ============================================================

  void _loadRecords() {
    final memberId = ProfileController.instance.memberId;

    setState(() {
      _records = AllergiesData.recordsFor(memberId);
    });
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _openSheet({AllergyRecord? record}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.allergyScrim,
      builder: (sheetContext) {
        return _AllergyFormSheet(
          memberId: ProfileController.instance.memberId,
          record: record,
        );
      },
    );

    // Save/remove ke baad list refresh.
    if (saved == true && mounted) {
      _loadRecords();
    }
  }

  /// Add Allergy — dedicated full screen (design: Add Allergy page).
  Future<void> _addAllergy() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddAllergyScreen()),
    );

    if (saved == true && mounted) {
      _loadRecords();
    }
  }

  // ============================================================
  // SEVERITY / CATEGORY PRESENTATION
  // ============================================================

  Color _severityColor(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.high:
        return AppColors.permissionsErrorIcon;
      case AllergySeverity.moderate:
        return AppColors.allergyModerateDot;
      case AllergySeverity.mild:
        return AppColors.permissionsGreenDark;
    }
  }

  Color _severityPillBackground(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.high:
        return AppColors.permissionsErrorContainer.withValues(alpha: 0.40);
      case AllergySeverity.moderate:
        return AppColors.reportVitalsTile.withValues(alpha: 0.40);
      case AllergySeverity.mild:
        return AppColors.permissionsBadgeBackground.withValues(alpha: 0.40);
    }
  }

  IconData _categoryIcon(AllergyCategory category) {
    switch (category) {
      case AllergyCategory.medication:
        return Icons.medication_rounded;
      case AllergyCategory.food:
        return Icons.local_dining_rounded;
      case AllergyCategory.environmental:
        return Icons.grass_rounded;
      case AllergyCategory.other:
        return Icons.warning_amber_rounded;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DARK HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.permissionsHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
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

              const SizedBox(width: 4),

              const Expanded(
                child: Text(
                  'Allergies',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppAvatar(
                size: 33,
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
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCountRow(),

          const SizedBox(height: 14),

          _buildSafetyStrip(),

          const SizedBox(height: 14),

          if (_records.isEmpty)
            _buildEmptyState()
          else
            ..._records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAllergyCard(record),
              ),
            ),

          const SizedBox(height: 4),

          _buildGuardCard(),

          const SizedBox(height: 16),

          _buildAddButton(),

          const SizedBox(height: 16),

          _buildFooterNotes(),
        ],
      ),
    );
  }

  // ============================================================
  // COUNT ROW — dot + count + Add button
  // ============================================================

  Widget _buildCountRow() {
    final count = _records.length;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.permissionsSecondary,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            '$count ${count == 1 ? 'allergy' : 'allergies'} on file',
            style: const TextStyle(
              color: AppColors.permissionsSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        GestureDetector(
          onTap: () {
            _addAllergy();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.formAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: AppColors.surface),
                SizedBox(width: 4),
                Text(
                  'Add',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAFETY STRIP
  // ============================================================

  Widget _buildSafetyStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.permissionsBadgeBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 16,
              color: AppColors.permissionsGreenDark,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'New medications are automatically checked against this list.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALLERGY CARD
  // ============================================================

  Widget _buildAllergyCard(AllergyRecord record) {
    final severityColor = _severityColor(record.severity);

    return GestureDetector(
      onTap: () {
        _openSheet(record: record);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.permissionsCardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconBox(record, severityColor),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              record.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.reportPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          _buildSeverityPill(record),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Text(
                        record.severitySummary,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),

                const SizedBox(width: 6),

                Text(
                  'Added ${_formatDate(record.addedAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.permissionsSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(AllergyRecord record, Color severityColor) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(record.category),
              size: 22,
              color: AppColors.reportPrimary,
            ),
          ),

          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: severityColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityPill(AllergyRecord record) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _severityPillBackground(record.severity),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        record.severityName.toUpperCase(),
        style: TextStyle(
          color: _severityColor(record.severity),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // GUARD CARD — non-drug allergies
  // ============================================================

  Widget _buildGuardCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.permissionsSecondary,
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have non-drug allergies?',
                  style: TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'You can also track food, environmental, and other '
                  'sensitivities here.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        _addAllergy();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.formAccent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shareButtonShadow,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 20,
              color: AppColors.surface,
            ),
            SizedBox(width: 8),
            Text(
              'Add New Allergy',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER NOTES
  // ============================================================

  Widget _buildFooterNotes() {
    return Column(
      children: [
        const Text(
          'Tap an allergy to edit or remove it',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 12,
              color: AppColors.fieldHint,
            ),

            const SizedBox(width: 4),

            Text(
              'Allergy data encrypted on device',
              style: TextStyle(color: AppColors.fieldHint, fontSize: 10.5),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.shield_outlined,
            color: AppColors.fieldHint,
            size: 44,
          ),

          SizedBox(height: 10),

          Text(
            'No allergies on file',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE HELPER — design: "01 Sep 2026"
  // ============================================================

  String _formatDate(DateTime date) {
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

    final day = date.day.toString().padLeft(2, '0');

    return '$day ${months[date.month - 1]} ${date.year}';
  }
}

/// ============================================================
/// ADD / EDIT ALLERGY SHEET
///
/// Save  → AllergiesData.add/update → pop(true)
/// Remove→ AllergiesData.removeRecord → pop(true)
/// Close → pop(null)
/// ============================================================
class _AllergyFormSheet extends StatefulWidget {
  const _AllergyFormSheet({required this.memberId, this.record});

  final String? memberId;
  final AllergyRecord? record;

  @override
  State<_AllergyFormSheet> createState() => _AllergyFormSheetState();
}

class _AllergyFormSheetState extends State<_AllergyFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _symptomsController;

  late AllergySeverity _severity;
  late AllergyCategory _category;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _nameController = TextEditingController(text: record?.name ?? '');
    _symptomsController = TextEditingController(text: record?.symptoms ?? '');

    _severity = record?.severity ?? AllergySeverity.moderate;
    _category = record?.category ?? AllergyCategory.medication;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symptomsController.dispose();

    super.dispose();
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter an allergen name.');
      return;
    }

    final symptoms = _symptomsController.text.trim();

    final record = widget.record;

    if (record == null) {
      AllergiesData.addRecord(
        memberId: widget.memberId,
        name: name,
        category: _category,
        severity: _severity,
        symptoms: symptoms,
      );
    } else {
      AllergiesData.updateRecord(
        memberId: widget.memberId,
        id: record.id,
        name: name,
        category: _category,
        severity: _severity,
        symptoms: symptoms,
      );
    }

    Navigator.of(context).pop(true);
  }

  void _remove() {
    final record = widget.record;

    if (record == null) {
      return;
    }

    AllergiesData.removeRecord(memberId: widget.memberId, id: record.id);

    Navigator.of(context).pop(true);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHandle(),

                const SizedBox(height: 10),

                _buildSheetHeader(),

                const SizedBox(height: 18),

                _fieldLabel('Allergen Name'),

                _buildNameField(),

                const SizedBox(height: 18),

                _fieldLabel('Reaction Severity'),

                _buildSeveritySelector(),

                const SizedBox(height: 18),

                _fieldLabel('Observed Symptoms'),

                _buildSymptomsField(),

                const SizedBox(height: 22),

                _buildSaveButton(),

                if (_isEditing) ...[
                  const SizedBox(height: 10),
                  _buildRemoveButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.shareBorder,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Allergy' : 'Add Allergy',
                style: const TextStyle(
                  color: AppColors.reportPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'New medications will be checked against this entry.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.reportSurfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.permissionsHeader,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'e.g. Penicillin, Peanuts, Latex',
          hintStyle: TextStyle(
            color: AppColors.fieldHint,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSeveritySelector() {
    final severities = AllergySeverity.values;

    return Row(
      children: [
        for (var i = 0; i < severities.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildSeverityButton(severities[i])),
        ],
      ],
    );
  }

  Widget _buildSeverityButton(AllergySeverity severity) {
    final selected = _severity == severity;

    return GestureDetector(
      onTap: () {
        setState(() => _severity = severity);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.formAccent
              : AppColors.permissionsChipFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _severityName(severity),
          style: TextStyle(
            color: selected
                ? AppColors.surface
                : AppColors.permissionsSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _severityName(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.high:
        return 'High';
    }
  }

  Widget _buildSymptomsField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _symptomsController,
        maxLines: null,
        minLines: 3,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText: 'e.g. rash, swelling, difficulty breathing',
          hintStyle: TextStyle(color: AppColors.fieldHint, fontSize: 14),
          contentPadding: EdgeInsets.all(14),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.formAccent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shareButtonShadow,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.surface,
            ),
            const SizedBox(width: 8),
            Text(
              _isEditing ? 'Save Changes' : 'Save Allergy Record',
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveButton() {
    return Center(
      child: GestureDetector(
        onTap: _remove,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Remove this allergy',
            style: TextStyle(
              color: AppColors.permissionsErrorIcon,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
