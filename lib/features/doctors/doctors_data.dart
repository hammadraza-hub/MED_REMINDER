/// ============================================================
/// DOCTORS DATA — backend-ready
///
/// Prescriber list ki data/model layer.
///
/// MEMBER ISOLATION:
/// Sab methods memberId leti hain. Demo records sirf Sarah
/// (local_sarah) ke liye hain — Mom/Jake ko apne records
/// dikhte hain (jo abhi empty hain).
///
/// Current phase:
/// Demo doctor records (2 on file — design mock).
///
/// Future:
/// Backend: Firestore prescribers/doctors collection — UI zero change!
///
/// Firestore document shape (future):
/// {
///   id, memberId, name, specialty, phone?, clinicAddress?,
///   linkedMedicationIds: [...],
///   createdAt
/// }
/// ============================================================

class PrescriberDoctor {
  const PrescriberDoctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.linkedMeds,
    this.phone,
    this.clinicAddress,
  });

  /// Stable prescriber identity.
  ///
  /// TODO Backend:
  /// Firestore prescriber document ID use hoga.
  final String id;

  /// Example: Dr. Ahmed Khan
  final String name;

  /// Example: General Physician, Cardiologist
  final String specialty;

  /// Contact — Add Doctor form se aata hai.
  /// TODO Backend: Firestore phone field.
  final String? phone;

  /// Clinic/address — Add Doctor form se aata hai.
  /// TODO Backend: Firestore clinicAddress field.
  final String? clinicAddress;

  /// Linked medicines (display summary).
  ///
  /// Example: ['Metformin 500mg', 'Amlodipine 5mg']
  ///
  /// TODO Backend:
  /// Medication IDs se references banenge.
  final List<String> linkedMeds;

  // ================= COMPUTED =================

  int get medsCount => linkedMeds.length;

  /// Chip label: "1 med" | "2 meds"
  String get chipLabel => medsCount == 1 ? '1 med' : '$medsCount meds';

  /// Card footer summary: "Metformin 500mg, Amlodipine 5mg"
  String get medsSummary => linkedMeds.join(', ');

  /// Avatar initials — "Dr. Ahmed Khan" → "AK".
  String get initials {
    final cleanName = name.replaceAll(RegExp(r'^Dr\.\s*'), '').trim();
    final parts = cleanName.split(RegExp(r'\s+'));

    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class DoctorsData {
  /// Backend: prescribers collection filtered by memberId.
  ///
  /// MEMBER ISOLATION:
  /// Demo records sirf Sarah ke hain. Baaki members ko apne
  /// records milte hain (abhi empty).
  static List<PrescriberDoctor> doctorsFor(String? memberId) {
    if (memberId == null || memberId != 'local_sarah') {
      return const [];
    }

    return const [
      PrescriberDoctor(
        id: 'doc_ahmed_khan',
        name: 'Dr. Ahmed Khan',
        specialty: 'General Physician',
        phone: '+1 (555) 987-6543',
        clinicAddress: 'City Care Clinic, Suite 4, Maple Street',
        linkedMeds: ['Metformin 500mg', 'Amlodipine 5mg'],
      ),
      PrescriberDoctor(
        id: 'doc_sara_malik',
        name: 'Dr. Sara Malik',
        specialty: 'Cardiologist',
        linkedMeds: ['Amlodipine 5mg'],
      ),
    ];
  }

  /// Is-session mein save ki gayi doctor records (in-memory).
  ///
  /// MEMBER ISOLATION:
  /// Har record apne memberId ke saath store hota hai —
  /// members ke doctors mix nahi hote.
  ///
  /// TODO Backend:
  /// Firestore prescribers/{id} create se replace hogi — UI same rahegi.
  static final List<({String memberId, PrescriberDoctor doctor})>
  _addedDoctors = [];

  /// Naya doctor in-memory save karta hai.
  ///
  /// Phone/clinic bhi persist hote hain — form ka koi data
  /// lose nahi hota.
  static void addDoctor({
    required String memberId,
    required String name,
    required String specialty,
    required String phone,
    String? clinicAddress,
    required List<String> linkedMeds,
  }) {
    _addedDoctors.insert(0, (
      memberId: memberId,
      doctor: PrescriberDoctor(
        id: 'doc_local_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        specialty: specialty,
        phone: phone.isEmpty ? null : phone,
        clinicAddress: clinicAddress,
        linkedMeds: linkedMeds,
      ),
    ));
  }

  /// All doctors (seed + added) — member-filtered.
  ///
  /// MEMBER ISOLATION:
  /// Sirf us member ke records return hote hain jiska
  /// memberId diya gaya hai.
  static List<PrescriberDoctor> allDoctorsFor(String? memberId) {
    final added = _addedDoctors
        .where((record) => record.memberId == memberId)
        .map((record) => record.doctor)
        .toList();

    return [...added, ...doctorsFor(memberId)];
  }
}
