/// A doctor stored at `profiles/{pid}/prescribers/{id}`. M16 step 1.
class Prescriber {
  const Prescriber({
    required this.id,
    required this.name,
    this.specialty,
    this.phone,
    this.clinic,
    this.address,
  });

  final String id;
  final String name;
  final String? specialty;
  final String? phone;
  final String? clinic;
  final String? address;

  /// Trimmed copy of the data; blank optionals are left out of the map so
  /// Firestore never stores empty strings.
  Map<String, Object?> toMap() => {
    'name': name.trim(),
    if (_has(specialty)) 'specialty': specialty!.trim(),
    if (_has(phone)) 'phone': phone!.trim(),
    if (_has(clinic)) 'clinic': clinic!.trim(),
    if (_has(address)) 'address': address!.trim(),
  };

  static Prescriber fromMap(String id, Map<String, Object?> m) => Prescriber(
    id: id,
    name: (m['name'] as String?)?.trim() ?? '',
    specialty: _opt(m['specialty']),
    phone: _opt(m['phone']),
    clinic: _opt(m['clinic']),
    address: _opt(m['address']),
  );

  Prescriber copyWith({
    String? name,
    String? specialty,
    String? phone,
    String? clinic,
    String? address,
  }) => Prescriber(
    id: id,
    name: name ?? this.name,
    specialty: specialty ?? this.specialty,
    phone: phone ?? this.phone,
    clinic: clinic ?? this.clinic,
    address: address ?? this.address,
  );

  /// "Dr. Ahmed Khan" -> "AK"; one word -> first letter; empty -> "?".
  String get initials {
    final clean = name
        .replaceAll(RegExp(r'^Dr\.?\s+', caseSensitive: false), '')
        .trim();
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static bool _has(String? s) => s != null && s.trim().isNotEmpty;
  static String? _opt(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
