import 'appointment_validator.dart';

/// An appointment stored at `profiles/{pid}/appointments/{id}`. M16 step 1.
class Appointment {
  const Appointment({
    required this.id,
    required this.startsAt,
    this.prescriberId,
    this.type = AppointmentType.followUp,
    this.location,
    this.notes,
    this.reminderOffsets = AppointmentLimits.defaultOffsets,
  });

  final String id;
  final DateTime startsAt;
  final String? prescriberId;
  final AppointmentType type;
  final String? location;
  final String? notes;

  /// Minutes before [startsAt].
  final List<int> reminderOffsets;

  bool isUpcoming({DateTime? now}) => startsAt.isAfter(now ?? DateTime.now());

  Map<String, Object?> toMap() => {
    'startsAt': startsAt,
    'type': type.code,
    if (_has(prescriberId)) 'prescriberId': prescriberId,
    if (_has(location)) 'location': location!.trim(),
    if (_has(notes)) 'notes': notes!.trim(),
    'reminderOffsets': normalizeOffsets(reminderOffsets),
  };

  /// [startsAt] is already converted to a DateTime by the repository.
  static Appointment fromMap(String id, Map<String, Object?> m) {
    final raw = m['reminderOffsets'];
    final offsets = raw is List
        ? raw.whereType<num>().map((n) => n.toInt()).toList()
        : AppointmentLimits.defaultOffsets;
    return Appointment(
      id: id,
      startsAt: m['startsAt'] as DateTime,
      prescriberId: _opt(m['prescriberId']),
      type:
          AppointmentType.fromCode(m['type'] as String?) ??
          AppointmentType.other,
      location: _opt(m['location']),
      notes: _opt(m['notes']),
      reminderOffsets: normalizeOffsets(offsets),
    );
  }

  /// Largest first, no duplicates.
  static List<int> normalizeOffsets(List<int> offsets) =>
      offsets.toSet().toList()..sort((a, b) => b.compareTo(a));

  static bool _has(String? s) => s != null && s.trim().isNotEmpty;
  static String? _opt(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
