/// A "question for my doctor" at `profiles/{pid}/doctorNotes/{id}`.
/// Open list = notes with `doneAt == null`. M16 step 1.
class DoctorNote {
  const DoctorNote({
    required this.id,
    required this.body,
    required this.createdAt,
    this.doneAt,
    this.appointmentId,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final DateTime? doneAt;
  final String? appointmentId;

  bool get isOpen => doneAt == null;

  DoctorNote markDone(DateTime at) => DoctorNote(
    id: id,
    body: body,
    createdAt: createdAt,
    doneAt: at,
    appointmentId: appointmentId,
  );

  DoctorNote reopen() => DoctorNote(
    id: id,
    body: body,
    createdAt: createdAt,
    appointmentId: appointmentId,
  );

  Map<String, Object?> toMap() => {
    'body': body.trim(),
    'createdAt': createdAt,
    'doneAt': doneAt,
    if (appointmentId != null && appointmentId!.isNotEmpty)
      'appointmentId': appointmentId,
  };

  static DoctorNote fromMap(String id, Map<String, Object?> m) {
    final apt = m['appointmentId'];
    return DoctorNote(
      id: id,
      body: (m['body'] as String?)?.trim() ?? '',
      createdAt: m['createdAt'] as DateTime,
      doneAt: m['doneAt'] as DateTime?,
      appointmentId: apt is String && apt.isNotEmpty ? apt : null,
    );
  }

  /// Open notes first (newest first), then done ones (latest done first).
  static List<DoctorNote> sorted(Iterable<DoctorNote> notes) {
    final l = notes.toList();
    l.sort((a, b) {
      if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
      if (a.isOpen) return b.createdAt.compareTo(a.createdAt);
      return b.doneAt!.compareTo(a.doneAt!);
    });
    return l;
  }
}
