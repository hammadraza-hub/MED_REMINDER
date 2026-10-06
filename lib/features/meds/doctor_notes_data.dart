/// ============================================================
/// DOCTOR NOTES DATA — backend-ready
///
/// SEEDING:
/// Seed notes EK BAAR list mein add hote hain (_seededMembers
/// guard). Uske baad saare operations (toggle/edit/clear) usi
/// list par chalte hain — isliye seeded notes bhi toggle,
/// edit aur clear ho sakte hain.
///
/// MEMBER ISOLATION:
/// Har note apne memberId ke saath store hota hai —
/// Sarah/Mom/Jake ke notes alag-alag.
///
/// Future:
/// Backend: Firestore doctor_notes collection — UI zero change!
///
/// Firestore document shape (future):
/// {
///   id, memberId, note, linkedMedication?,
///   isDiscussed, discussedAt?, createdAt
/// }
/// ============================================================

class DoctorNoteEntry {
  const DoctorNoteEntry({
    required this.id,
    required this.memberId,
    required this.note,
    required this.createdAt,
    this.linkedMedication,
    this.isDiscussed = false,
    this.discussedAt,
  });

  /// Stable note identity.
  ///
  /// TODO Backend:
  /// Firestore note document ID use hoga.
  final String id;

  final String memberId;

  /// Question/note text.
  final String note;

  /// Optional medication tag — "Metformin 500mg".
  ///
  /// TODO Backend:
  /// medicationId reference se resolve hoga.
  final String? linkedMedication;

  final DateTime createdAt;

  final bool isDiscussed;
  final DateTime? discussedAt;

  // ================= COPY =================

  DoctorNoteEntry copyWith({
    String? note,
    bool? isDiscussed,
    DateTime? discussedAt,
    bool clearDiscussedAt = false,
  }) {
    return DoctorNoteEntry(
      id: id,
      memberId: memberId,
      note: note ?? this.note,
      createdAt: createdAt,
      linkedMedication: linkedMedication,
      isDiscussed: isDiscussed ?? this.isDiscussed,
      discussedAt: clearDiscussedAt ? null : discussedAt ?? this.discussedAt,
    );
  }
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class DoctorNotesData {
  /// Saare notes — ek hi list, har entry apne memberId ke saath.
  ///
  /// TODO Backend:
  /// Firestore doctor_notes/{id} operations se replace hoga.
  static final List<DoctorNoteEntry> _notes = [];

  /// Jin members ke liye seed ek baar ho chuka hai.
  ///
  /// Ye guard seed ko idempotent banata hai — har notesFor()
  /// call par duplicate seed NAHI bante. Aur kyunki seed notes
  /// _notes mein rehte hain, unka toggle/edit state session
  /// mein preserve hota hai.
  static final Set<String> _seededMembers = {};

  /// Member ke saare notes — newest pehle.
  ///
  /// MEMBER ISOLATION:
  /// Sirf us member ke notes return hote hain jiska
  /// memberId diya gaya hai.
  static List<DoctorNoteEntry> notesFor(String? memberId) {
    if (memberId == null || memberId.isEmpty) {
      return const [];
    }

    _seedIfMissing(memberId);

    final memberNotes = _notes
        .where((note) => note.memberId == memberId)
        .toList();

    // Newest pehle.
    memberNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return memberNotes;
  }

  /// Seed sirf pehli access par — ek hi baar.
  static void _seedIfMissing(String memberId) {
    if (_seededMembers.contains(memberId)) {
      return;
    }

    if (memberId == 'local_sarah') {
      _notes.addAll(_seededSarahNotes());
    }

    _seededMembers.add(memberId);
  }

  /// Naya note add karta hai (top par aayega).
  static void addNote({required String memberId, required String note}) {
    _notes.insert(
      0,
      DoctorNoteEntry(
        id: 'note_local_${DateTime.now().microsecondsSinceEpoch}',
        memberId: memberId,
        note: note,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Check-off toggle — seeded notes bhi toggle ho sakte hain
  /// kyunki wo bhi _notes mein rehte hain.
  static void toggleDiscussed({
    required String memberId,
    required String noteId,
  }) {
    _replaceNote(
      memberId: memberId,
      noteId: noteId,
      transform: (note) {
        final nowDiscussed = !note.isDiscussed;

        return note.copyWith(
          isDiscussed: nowDiscussed,
          discussedAt: nowDiscussed ? DateTime.now() : null,
          clearDiscussedAt: !nowDiscussed,
        );
      },
    );
  }

  /// Note text edit.
  static void updateNoteText({
    required String memberId,
    required String noteId,
    required String newText,
  }) {
    _replaceNote(
      memberId: memberId,
      noteId: noteId,
      transform: (note) => note.copyWith(note: newText),
    );
  }

  /// Discussed notes remove karta hai.
  static void clearDiscussed(String? memberId) {
    if (memberId == null || memberId.isEmpty) {
      return;
    }

    _notes.removeWhere((note) => note.memberId == memberId && note.isDiscussed);
  }

  /// Ek note delete karta hai.
  static void deleteNote({required String memberId, required String noteId}) {
    _notes.removeWhere(
      (note) => note.memberId == memberId && note.id == noteId,
    );
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  static void _replaceNote({
    required String memberId,
    required String noteId,
    required DoctorNoteEntry Function(DoctorNoteEntry) transform,
  }) {
    for (var i = 0; i < _notes.length; i++) {
      final note = _notes[i];

      if (note.id == noteId && note.memberId == memberId) {
        _notes[i] = transform(note);
        return;
      }
    }
  }

  // ============================================================
  // SEED — sirf Sarah (demo design records)
  //
  // Timestamps relative hain — demo hamesha fresh dikhega.
  // ============================================================

  static List<DoctorNoteEntry> _seededSarahNotes() {
    final now = DateTime.now();

    return [
      DoctorNoteEntry(
        id: 'note_sarah_metformin_vitamin',
        memberId: 'local_sarah',
        note: 'Is it safe to take Metformin with my new vitamin?',
        linkedMedication: 'Metformin 500mg',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      DoctorNoteEntry(
        id: 'note_sarah_amlodipine_winter',
        memberId: 'local_sarah',
        note: 'Should my Amlodipine dose change before winter?',
        linkedMedication: 'Amlodipine 5mg',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      DoctorNoteEntry(
        id: 'note_sarah_vitamind3_stop',
        memberId: 'local_sarah',
        note: 'Can I stop Vitamin D3 after this course?',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        isDiscussed: true,
        discussedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
