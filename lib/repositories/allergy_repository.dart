/// ============================================================
/// ALLERGY REPOSITORY IMPLEMENTATION
/// ============================================================

library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/allergy.dart';

class AllergyRepository {
  AllergyRepository._();
  static final AllergyRepository instance = AllergyRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _allergiesRef(String memberId) =>
      _firestore.collection('profiles').doc(memberId).collection('allergies');

  /// Watch all allergies for a member (realtime stream).
  Stream<List<Allergy>> watchAllergies(String memberId) {
    return _allergiesRef(memberId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Allergy.fromMap(doc.id, doc.data())).toList());
  }

  /// One-time fetch of all allergies for a member.
  Future<List<Allergy>> getAllergies(String memberId) async {
    final snapshot = await _allergiesRef(memberId).get();
    return snapshot.docs
        .map((doc) => Allergy.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// One-time fetch of a single allergy.
  Future<Allergy?> getAllergy(String memberId, String allergyId) async {
    final doc = await _allergiesRef(memberId).doc(allergyId).get();
    if (!doc.exists) return null;
    return Allergy.fromMap(doc.id, doc.data()!);
  }

  /// Create a new allergy for a member.
  /// Returns the new allergy's document ID.
  Future<String> createAllergy(String memberId, Allergy allergy) async {
    final allergyWithMember = allergy.copyWith(memberId: memberId);
    final data = allergyWithMember.toMap();
    final docRef = await _allergiesRef(memberId).add(data);
    return docRef.id;
  }

  /// Update an existing allergy.
  Future<void> updateAllergy(
      String memberId, String allergyId, Map<String, dynamic> data) async {
    await _allergiesRef(memberId).doc(allergyId).update(data);
  }

  /// Check if a medication name matches any allergy for the profile.
  /// Returns true if the patient is allergic to this medication.
  Future<bool> hasAllergyTo(String memberId, String medicationName) async {
    final allergies = await getAllergies(memberId);
    final medLower = medicationName.toLowerCase().trim();
    return allergies.any((a) => a.name.toLowerCase().trim() == medLower);
  }

  /// Delete an allergy (hard delete — Firestore).
  Future<void> deleteAllergy(String memberId, String allergyId) async {
    await _allergiesRef(memberId).doc(allergyId).delete();
  }
}