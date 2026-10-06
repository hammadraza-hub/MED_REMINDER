/// ============================================================
/// APPOINTMENTS DATA — backend-ready
///
/// MEMBER ISOLATION:
/// Sab methods memberId leti hain. Demo records sirf Sarah
/// (local_sarah) ke liye hain — Mom/Jake ko apne records
/// dikhte hain (jo abhi empty hain).
///
/// STATUS:
/// Upcoming/Past date se COMPUTE hota hai — hardcoded flag nahi.
/// Isliye waqt guzarne par appointment khud Past mein chala jayega.
///
/// Future:
/// Backend: Firestore appointments collection — UI zero change!
///
/// Firestore document shape (future):
/// {
///   id, memberId, doctorId?, doctorName, type, location?,
///   scheduledAt, note?, createdAt
/// }
/// ============================================================

class AppointmentEntry {
  const AppointmentEntry({
    required this.id,
    required this.memberId,
    required this.doctorName,
    required this.type,
    required this.scheduledAt,
    this.location,
    this.note,
  });

  /// Stable appointment identity.
  ///
  /// TODO Backend:
  /// Firestore appointment document ID use hoga.
  final String id;

  final String memberId;

  /// Prescriber ka display name.
  ///
  /// TODO Backend:
  /// doctorId reference — name prescriber record se resolve hoga.
  final String doctorName;

  /// Example: Cardiology follow-up, General checkup
  final String type;

  final DateTime scheduledAt;

  /// TODO Backend: location / clinic address field.
  final String? location;

  final String? note;

  // ================= COMPUTED =================

  /// Dynamic status — scheduledAt vs abhi ka waqt.
  /// Hardcoded flag nahi, isliye hamesha sahi rahega.
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class AppointmentsData {
  /// Is-session mein add kiye gaye appointments (in-memory).
  ///
  /// MEMBER ISOLATION:
  /// Har record apne memberId ke saath store hota hai.
  ///
  /// TODO Backend:
  /// Firestore appointments/{id} create se replace hoga.
  static final List<AppointmentEntry> _addedAppointments = [];

  /// Member ke saare appointments (seed + added).
  ///
  /// MEMBER ISOLATION:
  /// Sirf us member ke records return hote hain jiska
  /// memberId diya gaya hai.
  static List<AppointmentEntry> appointmentsFor(String? memberId) {
    if (memberId == null || memberId.isEmpty) {
      return const [];
    }

    final seeded = memberId == 'local_sarah'
        ? _seededSarahAppointments()
        : const <AppointmentEntry>[];

    final added = _addedAppointments
        .where((appointment) => appointment.memberId == memberId)
        .toList();

    return [...seeded, ...added];
  }

  /// Naya appointment in-memory save karta hai.
  static void addAppointment({
    required String memberId,
    required String doctorName,
    required String type,
    required DateTime scheduledAt,
    String? location,
    String? note,
  }) {
    _addedAppointments.insert(
      0,
      AppointmentEntry(
        id: 'apt_local_${DateTime.now().microsecondsSinceEpoch}',
        memberId: memberId,
        doctorName: doctorName,
        type: type,
        scheduledAt: scheduledAt,
        location: location,
        note: note,
      ),
    );
  }

  // ============================================================
  // SEED — sirf Sarah (demo design records)
  //
  // Dates relative hain (aaj se +5 din, -8 din) — isliye demo
  // hamesha fresh dikhega, chahe kab bhi app chalao.
  // ============================================================

  static List<AppointmentEntry> _seededSarahAppointments() {
    return [
      AppointmentEntry(
        id: 'apt_sarah_cardio_followup',
        memberId: 'local_sarah',
        doctorName: 'Dr. Sara Malik',
        type: 'Cardiology follow-up',
        location: 'City Care Clinic, Suite 4, Maple Street',
        scheduledAt: _onDay(5, 10, 30),
      ),
      AppointmentEntry(
        id: 'apt_sarah_general_checkup',
        memberId: 'local_sarah',
        doctorName: 'Dr. Ahmed Khan',
        type: 'General checkup',
        location: 'City Care Clinic, Suite 4, Maple Street',
        scheduledAt: _onDay(12, 16, 0),
      ),
      AppointmentEntry(
        id: 'apt_sarah_lab_results',
        memberId: 'local_sarah',
        doctorName: 'Dr. Sara Malik',
        type: 'Lab results review',
        location: 'City Care Clinic, Suite 4, Maple Street',
        scheduledAt: _onDay(-8, 11, 0),
      ),
    ];
  }

  /// Aaj se [days] aage/peeche, fixed time par DateTime.
  static DateTime _onDay(int days, int hour, int minute) {
    final now = DateTime.now();
    final day = now.add(Duration(days: days));

    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}
