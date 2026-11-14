import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/doctors/appointment_models.dart';
import '../../core/doctors/doctor_note_models.dart';
import '../../core/doctors/doctor_note_validator.dart';
import '../../core/doctors/note_day.dart';
import '../../core/profile/profile_controller.dart';
import '../../core/services/appointment_reminders.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../repositories/firebase_appointment_repository.dart';
import '../../repositories/firebase_doctor_note_repository.dart';
import '../../repositories/firebase_prescriber_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/pro_gate_widgets.dart';
import '../../core/services/pro_access.dart';
import 'appointment_screen.dart';

/// ============================================================
/// NOTES FOR DOCTOR — M16 step 6
///
/// PURPOSE:
/// Running list of questions/notes to bring to the next visit. Notes stay
/// "open" until they are ticked off after being discussed, so they carry
/// from one visit to the next.
///
/// DATA:
/// FirebaseDoctorNoteRepository (profiles/{pid}/doctorNotes:
/// body, createdAt, doneAt, appointmentId?). Open = `doneAt == null`.
/// Next appointment / links: FirebaseAppointmentRepository.
///
/// USER ACTIONS:
/// • Add a note (optionally linked to the next appointment)
/// • Tick / untick (discussed)
/// • Edit (tap the text or long press), delete
/// • Clear discussed notes
/// • Next Appointment → AppointmentsScreen
///
/// MEMBER ISOLATION:
/// ProfileController.memberId — each profile has its own notes.
/// ============================================================
class NotesForDoctorScreen extends StatefulWidget {
  const NotesForDoctorScreen({super.key});

  @override
  State<NotesForDoctorScreen> createState() => _NotesForDoctorScreenState();
}

class _NotesForDoctorScreenState extends State<NotesForDoctorScreen> {
  final TextEditingController _noteController = TextEditingController();

  List<DoctorNote> _notes = const [];
  List<Appointment> _upcoming = const [];
  String? _nextDoctorName;

  bool _loading = true;
  bool _failed = false;
  bool _busy = false;
  bool _linkToNext = false;
  bool _pro = true;

  String? get _memberId {
    final id = ProfileController.instance.memberId;
    return (id == null || id.isEmpty) ? null : id;
  }

  Appointment? get _next => _upcoming.isEmpty ? null : _upcoming.first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _load() async {
    final memberId = _memberId;
    if (memberId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final notes = await FirebaseDoctorNoteRepository.instance.list(memberId);
      final pro = await ProAccess.gate.canWrite(memberId);

      // Appointments only add the "next appointment" card and link tags, so
      // a failure here must not hide the notes.
      var upcoming = <Appointment>[];
      String? doctor;
      try {
        upcoming = await FirebaseAppointmentRepository.instance.list(
          memberId,
          from: DateTime.now(),
          limit: 50,
        );
        final doctorId = upcoming.isEmpty ? null : upcoming.first.prescriberId;
        if (doctorId != null) {
          doctor = (await FirebasePrescriberRepository.instance.get(
            memberId,
            doctorId,
          ))?.name;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _notes = notes;
        _pro = pro;
        _upcoming = upcoming;
        _nextDoctorName = doctor;
        if (upcoming.isEmpty) _linkToNext = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  int get _openCount => _notes.where((n) => n.isOpen).length;
  int get _discussedCount => _notes.where((n) => !n.isOpen).length;

  Appointment? _appointmentFor(DoctorNote note) {
    final id = note.appointmentId;
    if (id == null) return null;
    for (final a in _upcoming) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _noteError(String text, AppLocalizations l10n) {
    final errors = DoctorNoteValidator.validate(text);
    if (errors.contains(DoctorNoteError.bodyMissing)) return l10n.notesErrEmpty;
    if (errors.contains(DoctorNoteError.bodyTooLong)) {
      return l10n.notesErrTooLong;
    }
    return null;
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

  Future<void> _addNote() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final text = _noteController.text.trim();

    final memberId = _memberId;
    if (memberId == null) {
      _showMessage(l10n.vitalsErrNoProfile);
      return;
    }

    final problem = _noteError(text, l10n);
    if (problem != null) {
      _showMessage(problem);
      return;
    }

    if (!await ensureProForWrite(context, memberId)) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await FirebaseDoctorNoteRepository.instance.add(
        memberId,
        text,
        appointmentId: _linkToNext ? _next?.id : null,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (isProDenied(e)) {
        await showProRequiredDialog(context);
      } else {
        _showMessage(l10n.notesSaveFailed);
      }
      return;
    }

    if (!mounted) return;
    _noteController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = false;
      _linkToNext = false;
    });
    await _load();
  }

  // ============================================================
  // CHECK / UNCHECK
  // ============================================================

  Future<void> _toggleDiscussed(DoctorNote note) async {
    final memberId = _memberId;
    if (memberId == null || _busy) return;
    final l10n = AppLocalizations.of(context);

    if (!await ensureProForWrite(context, memberId)) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final repo = FirebaseDoctorNoteRepository.instance;
      if (note.isOpen) {
        await repo.markDone(memberId, note.id);
      } else {
        await repo.reopen(memberId, note.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (isProDenied(e)) {
        await showProRequiredDialog(context);
      } else {
        _showMessage(l10n.notesSaveFailed);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
  }

  // ============================================================
  // EDIT NOTE
  // ============================================================

  Future<void> _editNote(DoctorNote note) async {
    final l10n = AppLocalizations.of(context);

    final gateId = _memberId;
    if (gateId != null && !await ensureProForWrite(context, gateId)) return;
    if (!mounted) return;

    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditNoteDialog(initial: note.body),
    );

    final memberId = _memberId;
    if (updatedText == null || memberId == null || !mounted) return;
    if (updatedText == note.body) return;

    setState(() => _busy = true);
    try {
      await FirebaseDoctorNoteRepository.instance.editBody(
        memberId,
        note.id,
        updatedText,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (isProDenied(e)) {
        await showProRequiredDialog(context);
      } else {
        _showMessage(l10n.notesSaveFailed);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
  }

  // ============================================================
  // DELETE / CLEAR
  // ============================================================

  Future<bool> _confirm({
    required String title,
    String? body,
    required String action,
  }) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteNote(DoctorNote note) async {
    final memberId = _memberId;
    if (memberId == null || _busy) return;
    final l10n = AppLocalizations.of(context);

    if (!await _confirm(
      title: l10n.notesDeleteTitle,
      action: l10n.notesDeleteAction,
    )) {
      return;
    }
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await FirebaseDoctorNoteRepository.instance.delete(memberId, note.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(l10n.notesSaveFailed);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _showMessage(l10n.notesDeleted);
    await _load();
  }

  Future<void> _clearDiscussed() async {
    final memberId = _memberId;
    if (memberId == null || _discussedCount == 0 || _busy) return;
    final l10n = AppLocalizations.of(context);

    if (!await _confirm(
      title: l10n.notesClearTitle,
      body: l10n.notesClearBody(_discussedCount),
      action: l10n.notesClearDiscussed,
    )) {
      return;
    }
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await FirebaseDoctorNoteRepository.instance.clearDone(memberId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(l10n.notesSaveFailed);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _showMessage(l10n.notesCleared);
    await _load();
  }

  // ============================================================
  // BUILD
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

              Expanded(
                child: Text(
                  AppLocalizations.of(context).notesTitle,
                  style: const TextStyle(
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
        if (!_loading && !_pro) const ProReadOnlyBanner(),

        _buildInfoBanner(),

        const SizedBox(height: 12),

        _buildAddNoteRow(),

        if (_next != null) _buildLinkSwitch(),

        const SizedBox(height: 12),

        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_failed)
          _buildErrorState()
        else if (_notes.isEmpty)
          _buildEmptyState()
        else
          for (final note in _notes) ...[
            _buildNoteCard(note),
            const SizedBox(height: 10),
          ],

        const SizedBox(height: 4),

        if (!_loading && !_failed) _buildSummaryRow(),

        const SizedBox(height: 14),

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textTeal,
            size: 18,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              AppLocalizations.of(context).notesBanner,
              style: const TextStyle(
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
              onSubmitted: (_) => _addNote(),
              inputFormatters: [
                LengthLimitingTextInputFormatter(DoctorNoteLimits.bodyMax),
              ],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).notesAddHint,
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
            onTap: _busy ? null : _addNote,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _busy
                  ? const Padding(
                      padding: EdgeInsets.all(17),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.surface,
                      ),
                    )
                  : const Icon(
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

  /// "Link to next appointment (Fri, Nov 20)": only when one exists.
  Widget _buildLinkSwitch() {
    final l10n = AppLocalizations.of(context);
    final next = _next!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.notesLinkSwitch(_shortDate(next.startsAt)),
              style: const TextStyle(color: AppColors.textTeal, fontSize: 11.5),
            ),
          ),
          Switch(
            value: _linkToNext,
            onChanged: _busy ? null : (v) => setState(() => _linkToNext = v),
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppColors.primaryDark,
            inactiveThumbColor: AppColors.surface,
            inactiveTrackColor: AppColors.divider,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTE CARD
  // ============================================================

  Widget _buildNoteCard(DoctorNote note) {
    final l10n = AppLocalizations.of(context);
    final discussed = !note.isOpen;
    final linked = _appointmentFor(note);

    return GestureDetector(
      onLongPress: () => _editNote(note),
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
            // Checkbox: green once discussed
            InkWell(
              onTap: () => _toggleDiscussed(note),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: discussed ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: discussed ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: discussed
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
                  InkWell(
                    onTap: () => _editNote(note),
                    child: Text(
                      note.body,
                      style: TextStyle(
                        color: discussed
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                        decoration: discussed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (discussed)
                    _buildTag(l10n.notesDiscussed, discussed: true)
                  else if (linked != null)
                    _buildTag(
                      l10n.notesLinkedTag(_shortDate(linked.startsAt)),
                      discussed: false,
                    ),

                  if (discussed || linked != null) const SizedBox(height: 8),

                  Row(
                    children: [
                      const Spacer(),

                      const SizedBox(width: 8),

                      Text(
                        _formatTimestamp(
                          discussed && note.doneAt != null
                              ? note.doneAt!
                              : note.createdAt,
                        ),
                        style: const TextStyle(
                          color: AppColors.textTeal,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(width: 8),

                      InkWell(
                        onTap: () => _deleteNote(note),
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

  Widget _buildTag(String label, {required bool discussed}) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.upcomingBackground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              discussed ? Icons.check_rounded : Icons.event_outlined,
              size: 11,
              color: AppColors.textTeal,
            ),

            const SizedBox(width: 5),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTeal,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryRow() {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.notesSummary(_openCount, _discussedCount),
            style: const TextStyle(
              color: AppColors.textTeal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        TextButton(
          onPressed: (_discussedCount == 0 || _busy) ? null : _clearDiscussed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.notesClearDiscussed,
            style: const TextStyle(
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
    final appointment = _next;
    if (appointment == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final who =
        _nextDoctorName ?? AppointmentTexts.typeLabel(l10n, appointment.type);

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
                  Text(
                    l10n.notesNextAppointment,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '$who · ${_shortDate(appointment.startsAt)}',
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
  // ERROR / EMPTY
  // ============================================================

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.fieldHint,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.notesLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: Text(l10n.notesRetry)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.note_alt_outlined,
            color: AppColors.textTeal,
            size: 34,
          ),

          const SizedBox(height: 10),

          Text(
            l10n.notesEmptyTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            l10n.notesEmptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTeal, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openAppointments() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
  }

  // ============================================================
  // DATE FORMAT (app language)
  // ============================================================

  String _shortDate(DateTime date) =>
      DateFormat.MMMEd(AppLocalizations.of(context).localeName).format(date);

  String _formatTimestamp(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final local = date.toLocal();
    final time = DateFormat.jm(locale).format(local);

    switch (NoteDayResolver.of(local)) {
      case NoteDay.today:
        return l10n.notesToday(time);
      case NoteDay.yesterday:
        return l10n.notesYesterday(time);
      case NoteDay.other:
        return l10n.notesDateTime(DateFormat.MMMd(locale).format(local), time);
    }
  }
}

/// Owns its text controller, so the controller is disposed only when the
/// dialog (and its closing animation) is really gone.
class _EditNoteDialog extends StatefulWidget {
  const _EditNoteDialog({required this.initial});

  final String initial;

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.notesEditTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        inputFormatters: [
          LengthLimitingTextInputFormatter(DoctorNoteLimits.bodyMax),
        ],
        decoration: InputDecoration(
          hintText: l10n.notesEditHint,
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) return;
            Navigator.of(context).pop(value);
          },
          child: Text(l10n.notesSave),
        ),
      ],
    );
  }
}
