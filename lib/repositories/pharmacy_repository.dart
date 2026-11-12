/// ============================================================
/// PHARMACY REPOSITORY
/// ============================================================
///
/// CRUD for pharmacies stored under:
///   profiles/{memberId}/pharmacies/{pharmacyId}
///
/// Fields: name, phone, address, isPrimary,
///         linkedMedicationIds, openingHours (list of maps)
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacy {
  final String id;
  final String memberId;
  final String name;
  final String phone;
  final String? address;
  final bool isPrimary;
  final List<String> linkedMedicationIds;
  final List<Map<String, dynamic>>? openingHours; // [{label, openTime, closeTime, isClosed}, ...]
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Pharmacy({
    required this.id,
    required this.memberId,
    required this.name,
    required this.phone,
    this.address,
    required this.isPrimary,
    required this.linkedMedicationIds,
    this.openingHours,
    this.createdAt,
    this.updatedAt,
  }
);

  factory Pharmacy.fromMap(String id, Map<String, dynamic> data) {
    final hours = (data['openingHours'] as List?)
        ?.map((h) => {
              'label': h['label'] as String?,
              'openTime': h['openTime'] as String?,
              'closeTime': h['closeTime'] as String?,
              'isClosed': h['isClosed'] as bool?,
            })
        .toList();

    return Pharmacy(
      id: id,
      memberId: data['memberId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String?,
      isPrimary: data['isPrimary'] as bool? ?? false,
      linkedMedicationIds: ((data['linkedMedicationIds'] as List?)
        ?.map((m) => m as String?)
        .where((m) => m != null)
        .map((m) => m!)
        .toList() ?? []),
      openingHours: hours,
      createdAt: data['createdAt'] as DateTime?,
      updatedAt: data['updatedAt'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    final hours = openingHours
        ?.map((h) => {
              'label': h['label'],
              'openTime': h['openTime'],
              'closeTime': h['closeTime'],
              'isClosed': h['isClosed'],
            })
        .toList();

    return {
      'id': id,
      'memberId': memberId,
      'name': name,
      'phone': phone,
      'address': address,
      'isPrimary': isPrimary,
      'linkedMedicationIds': linkedMedicationIds,
      'openingHours': hours,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Pharmacy copyWith({
    String? id,
    String? memberId,
    String? name,
    String? phone,
    String? address,
    bool? isPrimary,
    List<String>? linkedMedicationIds,
    List<Map<String, dynamic>>? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isPrimary: isPrimary ?? this.isPrimary,
      linkedMedicationIds: linkedMedicationIds ?? this.linkedMedicationIds,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// ============================================================
/// PHARMACY REPOSITORY IMPLEMENTATION
/// ============================================================

class PharmacyRepository {
  PharmacyRepository._();
  static final PharmacyRepository instance = PharmacyRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _pharmaciesRef(String memberId) =>
      _firestore.collection('profiles').doc(memberId).collection('pharmacies');

  /// Watch all pharmacies for a member (realtime stream).
  Stream<List<Pharmacy>> watchPharmacies(String memberId) {
    return _pharmaciesRef(memberId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Pharmacy.fromMap(doc.id, doc.data())).toList());
  }

  /// One-time fetch of all pharmacies for a member.
  Future<List<Pharmacy>> getPharmacies(String memberId) async {
    final snapshot = await _pharmaciesRef(memberId).get();
    return snapshot.docs
        .map((doc) => Pharmacy.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// One-time fetch of a single pharmacy.
  Future<Pharmacy?> getPharmacy(String memberId, String pharmacyId) async {
    final doc = await _pharmaciesRef(memberId).doc(pharmacyId).get();
    if (!doc.exists) return null;
    return Pharmacy.fromMap(doc.id, doc.data()!);
  }

  /// Create a new pharmacy for a member.
  /// Returns the new pharmacy's document ID.
  Future<String> createPharmacy(String memberId, Pharmacy pharmacy) async {
    // Ensure memberId matches
    final pharmacyWithMember = pharmacy.copyWith(memberId: memberId);
    final data = pharmacyWithMember.toMap();
    final docRef = await _pharmaciesRef(memberId).add(data);
    return docRef.id;
  }

  /// Update an existing pharmacy.
  Future<void> updatePharmacy(
      String memberId, String pharmacyId, Map<String, dynamic> data) async {
    await _pharmaciesRef(memberId).doc(pharmacyId).update(data);
  }

  /// Delete a pharmacy (hard delete — Firestore).
  Future<void> deletePharmacy(String memberId, String pharmacyId) async {
    await _pharmaciesRef(memberId).doc(pharmacyId).delete();
  }

  /// Set a pharmacy as primary (update isPrimary flag on all, then set this one).
  Future<void> setPrimaryPharmacy(
      String memberId, String pharmacyId, String previousPrimaryId) async {
    // Reset all to non-primary
    final pharmacies = await getPharmacies(memberId);
    final batch = _firestore.batch();

    for (final ph in pharmacies) {
      batch.update(
          _pharmaciesRef(memberId).doc(ph.id), {'isPrimary': false});
    }

    // Set the selected one as primary
    batch.update(
        _pharmaciesRef(memberId).doc(pharmacyId), {'isPrimary': true});

    await batch.commit();
  }
}