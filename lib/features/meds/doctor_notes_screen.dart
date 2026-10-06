import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../features/meds/appointments_data.dart';
import '../../features/meds/appointment_screen.dart';
import 'doctor_notes_data.dart';

/// ============================================================
/// NOTES FOR DOCTOR
///
/// PURPOSE:
/// Running list of questions/notes to bring to the next visit.
///
/// KEY ELEMENTS:
/// • Simple text list with add/check-off
/// • Timestamp per note
/// • Medication tag
/// • Next appointment card (live — nearest upcoming)
///
/// USER ACTIONS:
/// • Add a note
/// • Check off after discussing (tap checkbox)
/// • Edit a note (tap note text / long press)
/// • Clear discussed notes
/// • Next Appointment → AppointmentsScreen
///
/// SCREEN TYPE:
/// Pushed detail screen.
///
/// BOTTOM BAR:
/// Shared AppBottomNavigation (baaki detail screens jaisi).
///
/// DATA:
/// UI → DoctorNotesData (member-isolated)
/// Next appointment → AppointmentsData (nearest upcoming)
///
/// MEMBER ISOLATION:
/// ProfileController.memberId se notes filter hote hain —
/// Sarah/Mom/Jake ke notes alag-alag.
///
/// TODO Backend:
/// Firestore doctor_notes/{id} persist.
/// ============================================================
class NotesForDoctorScreen extends StatefulWidget {
  const NotesForDoctorScreen({super.key});

  @override
  State<NotesForDoctorScreen> createState() => _NotesForDoctorScreenState();
}

class _NotesForDoctorScreenState extends State<NotesForDoctorScreen> {
  final TextEditingController _noteController = TextEditingController();

  List<DoctorNoteEntry> _notes = [];

  @override
  void initState() {
    super.initState();

    _loadNotes();
  }

  // ============================================================
  // DATA
  // ============================================================

  void _loadNotes() {
    final memberId = ProfileController.instance.memberId;

    setState(() {
      _notes = DoctorNotesData.notesFor(memberId);
    });
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get _openCount => _notes.where((note) => !note.isDiscussed).length;

  int get _discussedCount => _notes.where((note) => note.isDiscussed).length;

  // ============================================================
  // NEXT APPOINTMENT — live nearest upcoming
  // ============================================================

  AppointmentEntry? get _nextAppointment {
    final memberId = ProfileController.instance.memberId;

    final upcoming =
        AppointmentsData.appointmentsFor(memberId)
            .where((appointment) => appointment.isUpcoming)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return upcoming.isEmpty ? null : upcoming.first;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // ADD NOTE
  // ============================================================

  void _addNote() {
    final text = _noteController.text.trim();

    if (text.isEmpty) {
      _showMessage('Please enter a question or note.');
      return;
    }

    final memberId = ProfileController.instance.memberId;

    if (memberId == null || memberId.isEmpty) {
      _showMessage('No family member selected.');
      return;
    }

    DoctorNotesData.addNote(memberId: memberId, note: text);

    _noteController.clear();
    _loadNotes();

    FocusScope.of(context).unfocus();

    // TODO Backend:
    // Create note in Firestore.
  }

  // ============================================================
  // CHECK / UNCHECK
  // ============================================================

  void _toggleDiscussed(DoctorNoteEntry note) {
    final memberId = ProfileController.instance.memberId;

    if (memberId == null) {
      return;
    }

    DoctorNotesData.toggleDiscussed(memberId: memberId, noteId: note.id);

    _loadNotes();

    // TODO Backend:
    // Update discussed status.
  }

  // ============================================================
  // EDIT NOTE
  // ============================================================

  Future<void> _editNote(DoctorNoteEntry note) async {
    final controller = TextEditingController(text: note.note);

    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Edit Note',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter a question or note...',
              filled: true,
              fillColor: AppColors.background,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (updatedText == null || updatedText.trim().isEmpty || !mounted) {
      return;
    }

    final memberId = ProfileController.instance.memberId;

    if (memberId == null) {
      return;
    }

    DoctorNotesData.updateNoteText(
      memberId: memberId,
      noteId: note.id,
      newText: updatedText.trim(),
    );

    _loadNotes();

    // TODO Backend:
    // Update note text.
  }

  // ============================================================
  // CLEAR DISCUSSED
  // ============================================================

  void _clearDiscussed() {
    if (_discussedCount == 0) return;

    final memberId = ProfileController.instance.memberId;

    DoctorNotesData.clearDiscussed(memberId);

    _loadNotes();

    // TODO Backend:
    // Delete/archive discussed notes.
  }
  // ============================================================
  // DELETE NOTE
  // ============================================================

  void _deleteNote(DoctorNoteEntry note) {
    final memberId = ProfileController.instance.memberId;

    if (memberId == null) {
      return;
    }

    DoctorNotesData.deleteNote(memberId: memberId, noteId: note.id);

    _loadNotes();

    _showMessage('Note deleted');

    // TODO Backend:
    // Delete note in Firestore.
  }
  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BUILD
  //
  // AnnotatedRegion:
  // Status bar style sirf ISI screen par scoped hai.
  // Pop karne par khud revert ho jata hai.
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerDark,
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: AppBottomNavigation(
          currentIndex: 0,
          onTap: _onBottomNavigationTap,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
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

              const Expanded(
                child: Text(
                  'Notes for Doctor',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // INFO BANNER
        // ======================================================

        _buildInfoBanner(),

        const SizedBox(height: 12),

        // ======================================================
        // ADD NOTE
        // ======================================================
        _buildAddNoteRow(),

        const SizedBox(height: 12),

        // ======================================================
        // NOTES
        // ======================================================
        if (_notes.isEmpty)
          _buildEmptyState()
        else
          for (final note in _notes) ...[
            _buildNoteCard(note),
            const SizedBox(height: 10),
          ],

        const SizedBox(height: 4),

        // ======================================================
        // SUMMARY
        // ======================================================
        _buildSummaryRow(),

        const SizedBox(height: 14),

        // ======================================================
        // NEXT APPOINTMENT
        // ======================================================
        _buildNextAppointmentCard(),
      ],
    );
  }

  // ============================================================
  // INFO BANNER
  // ============================================================

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.upcomingBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textTeal.withValues(alpha: 0.20)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textTeal, size: 18),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'These notes carry into your next '
              'appointment — check off after discussing.',
              style: TextStyle(
                color: AppColors.textTeal,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD NOTE ROW
  // ============================================================

  Widget _buildAddNoteRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: TextField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _addNote();
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Add a question or note...',
                hintStyle: const TextStyle(
                  color: AppColors.fieldHint,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.textTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Material(
          color: AppColors.primaryDark,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _addNote,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.add_rounded,
                color: AppColors.surface,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOTE CARD
  // ============================================================

  Widget _buildNoteCard(DoctorNoteEntry note) {
    return GestureDetector(
      onLongPress: () {
        _editNote(note);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox — green jab discussed
            InkWell(
              onTap: () {
                _toggleDiscussed(note);
              },
              borderRadius: BorderRadius.circular(7),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: note.isDiscussed
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: note.isDiscussed
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: note.isDiscussed
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppColors.surface,
                      )
                    : null,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note text — tap par edit
                  InkWell(
                    onTap: () {
                      _editNote(note);
                    },
                    child: Text(
                      note.note,
                      style: TextStyle(
                        color: note.isDiscussed
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                        decoration: note.isDiscussed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // Tag — medication ya Discussed
                      if (note.linkedMedication != null)
                        _buildTag(note.linkedMedication!, discussed: false)
                      else if (note.isDiscussed)
                        _buildTag('Discussed', discussed: true),

                      const Spacer(),

                      const SizedBox(width: 8),

                      Text(
                        note.isDiscussed && note.discussedAt != null
                            ? _formatTimestamp(note.discussedAt!)
                            : _formatTimestamp(note.createdAt),
                        style: const TextStyle(
                          color: AppColors.textTeal,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Delete note
                      InkWell(
                        onTap: () {
                          _deleteNote(note);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                            color: AppColors.fieldHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAG
  // ============================================================

  Widget _buildTag(String label, {required bool discussed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.upcomingBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            discussed ? Icons.check_rounded : Icons.circle,
            size: discussed ? 11 : 6,
            color: AppColors.textTeal,
          ),

          const SizedBox(width: 5),

          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTeal,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$_openCount open · '
            '$_discussedCount discussed',
            style: const TextStyle(
              color: AppColors.textTeal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        TextButton(
          onPressed: _discussedCount == 0 ? null : _clearDiscussed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Clear discussed',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NEXT APPOINTMENT — live data, tap → Appointments
  // ============================================================

  Widget _buildNextAppointmentCard() {
    final appointment = _nextAppointment;

    // Koi upcoming appointment nahi — card hidden.
    if (appointment == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _openAppointments,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.upcomingBackground,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.textTeal,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Appointment',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${appointment.doctorName} · '
                    '${_formatShortDate(appointment.scheduledAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTeal,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.note_alt_outlined, color: AppColors.textTeal, size: 34),

          SizedBox(height: 10),

          Text(
            'No notes yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Add a question to discuss at your next appointment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTeal, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION — Appointments
  // ============================================================

  void _openAppointments() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();

    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    if (isToday) {
      return 'Today, $hour:$minute $period';
    }

    final isYesterday = now.subtract(const Duration(days: 1)).day == date.day;

    if (isYesterday) {
      return 'Yesterday · $hour:$minute $period';
    }

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

    return '${date.day} '
        '${months[date.month - 1]} · '
        '$hour:$minute $period';
  }

  String _formatShortDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }
}
