import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../widgets/app_avatar.dart';
import 'add_symptom_screen.dart';
import 'side_effects_data.dart';

/// ============================================================
/// SIDE EFFECTS — recorded symptoms/side effects over time
///
/// DATA:
/// UI → SideEffectsData (in-memory, backend-ready)
///
/// TODO Local Storage / Backend:
/// Firestore side_effects collection:
/// { id, memberId, medicationId, symptom, severity, recordedAt, note }
///
/// MEMBER ISOLATION:
/// ProfileController.memberId se entries filter hoti hain.
///
/// ACTIONS:
/// • Tap +       → Add Symptom screen (save → list refresh)
/// • Tap entry   → View/Edit details (reference UI pending)
/// • Export      → PDF doctor summary (pdf/share package phase)
/// ============================================================
class SideEffectsScreen extends StatefulWidget {
  const SideEffectsScreen({super.key});

  @override
  State<SideEffectsScreen> createState() => _SideEffectsScreenState();
}

class _SideEffectsScreenState extends State<SideEffectsScreen> {
  List<SideEffectEntry> _entries = [];

  @override
  void initState() {
    super.initState();

    _loadEntries();
  }

  // ============================================================
  // DATA
  // ============================================================

  void _loadEntries() {
    final memberId = ProfileController.instance.memberId;

    setState(() {
      _entries = SideEffectsData.entriesFor(memberId);
    });
  }

  int get _entriesThisMonthCount {
    final now = DateTime.now();

    return _entries
        .where(
          (entry) =>
              entry.recordedAt.year == now.year &&
              entry.recordedAt.month == now.month,
        )
        .length;
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _addSymptom() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddSymptomScreen()),
    );

    // Save toast ke baad screen pop(true) karti hai → list refresh.
    if (saved == true && mounted) {
      _loadEntries();
    }
  }

  void _openEntry(SideEffectEntry entry) {
    // TODO: Symptom detail/edit screen — reference UI pending.
    _showMessage('${entry.symptom} details — coming soon');
  }

  void _exportSummary() {
    // TODO: PDF export — pdf + share_plus package phase.
    _showMessage('Export Doctor Summary — coming soon');
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
            child: Center(
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
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
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
                  'Side Effects',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppAvatar(
                size: 35,
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEntriesRow(),

          const SizedBox(height: 14),

          if (_entries.isEmpty)
            _buildEmptyState()
          else
            ..._entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSymptomCard(entry),
              ),
            ),

          const SizedBox(height: 4),

          _buildExportCard(),

          const SizedBox(height: 18),

          _buildFooterNotes(),
        ],
      ),
    );
  }

  // ============================================================
  // ENTRIES ROW — month count + add button
  // ============================================================

  Widget _buildEntriesRow() {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.formAccent,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            '$_entriesThisMonthCount entries this month',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        GestureDetector(
          onTap: _addSymptom,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.formAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.formAccent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: AppColors.surface, size: 26),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SYMPTOM CARD
  // ============================================================

  Widget _buildSymptomCard(SideEffectEntry entry) {
    return GestureDetector(
      onTap: () {
        _openEntry(entry);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeverityIconCircle(entry),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.symptom,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '${entry.medicationName} ${entry.medicationStrength}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _formatEntryDate(entry.recordedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Text(
                  'Severity',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                _buildSeverityDots(entry),

                const SizedBox(width: 8),

                Text(
                  entry.severityLabel,
                  style: TextStyle(
                    color: _severityColor(entry.level),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEVERITY ICON + DOTS
  // ============================================================

  Widget _buildSeverityIconCircle(SideEffectEntry entry) {
    final isSevere = entry.level == SideEffectSeverityLevel.severe;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSevere
            ? AppColors.symptomSevereFill
            : AppColors.symptomIconFill,
      ),
      child: Icon(
        _severityIcon(entry.level),
        size: 22,
        color: _severityIconColor(entry.level),
      ),
    );
  }

  Widget _buildSeverityDots(SideEffectEntry entry) {
    final color = _severityColor(entry.level);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < entry.severity;

        return Container(
          width: 9,
          height: 9,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : AppColors.symptomDotEmpty,
          ),
        );
      }),
    );
  }

  IconData _severityIcon(SideEffectSeverityLevel level) {
    switch (level) {
      case SideEffectSeverityLevel.mild:
        return Icons.sentiment_neutral_rounded;
      case SideEffectSeverityLevel.moderate:
        return Icons.sentiment_dissatisfied_rounded;
      case SideEffectSeverityLevel.severe:
        return Icons.sentiment_very_dissatisfied_rounded;
    }
  }

  Color _severityIconColor(SideEffectSeverityLevel level) {
    return level == SideEffectSeverityLevel.severe
        ? AppColors.symptomSevere
        : AppColors.textTeal;
  }

  Color _severityColor(SideEffectSeverityLevel level) {
    switch (level) {
      case SideEffectSeverityLevel.severe:
        return AppColors.symptomSevere;
      case SideEffectSeverityLevel.moderate:
      case SideEffectSeverityLevel.mild:
        return AppColors.formAccent;
    }
  }

  // ============================================================
  // EXPORT DOCTOR SUMMARY CARD
  // ============================================================

  Widget _buildExportCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.formAccent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.formAccent.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.surface,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Doctor Summary',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Share formatted PDF report',
                  style: TextStyle(color: AppColors.surface, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          GestureDetector(
            onTap: _exportSummary,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'Export',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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
          'Tap an entry to view or edit details',
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
              'Private & encrypted on this device',
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
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sentiment_satisfied_alt_rounded,
            color: AppColors.fieldHint,
            size: 45,
          ),

          const SizedBox(height: 10),

          Text(
            'No side effects recorded',
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
  // DATE/TIME HELPERS
  // ============================================================

  String _formatEntryDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(entryDay).inDays;

    if (difference == 0) {
      return 'Today, ${_formatTime(date)}';
    }

    if (difference == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    }

    return '${_shortWeekday(date.weekday)}, ${date.day} ${_shortMonth(date.month)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    final twelveHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final minuteText = minute.toString().padLeft(2, '0');

    return '$twelveHour:$minuteText $period';
  }

  String _shortWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
      default:
        return 'Sun';
    }
  }

  String _shortMonth(int month) {
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

    return months[month - 1];
  }
}
