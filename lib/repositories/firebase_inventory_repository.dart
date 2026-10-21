import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../core/inventory/inventory_repository.dart';

/// ============================================================
/// FIREBASE INVENTORY REPOSITORY
/// ============================================================
///
/// Implements [InventoryRepository] using Firestore.
///
/// Architecture:
///   - Inventory state stored ON medication document
///     (quantityOnHand, packageQuantity, unitsPerDay, etc.)
///   - Inventory events (deltas) stored in subcollection
///     (immutable audit log)
///   - Atomic updates via Firestore batch writes
///   - FieldValue.increment for concurrent-safe quantity updates
///
/// Firestore Paths:
///   profiles/{memberId}/medications/{medId}
///     - quantityOnHand, packageQuantity, unitsPerDay, unitLabel
///     - lowStockThresholdDays, lastAdjustedAt, adjustmentSource
///
///   profiles/{memberId}/medications/{medId}/inventoryEvents/{eventId}
///     - delta, reason, doseId, createdAt
///
/// All methods throw [AppException] on failure.
/// ============================================================
class FirebaseInventoryRepository implements InventoryRepository {
  // Singleton
  static final FirebaseInventoryRepository instance =
      FirebaseInventoryRepository._();
  FirebaseInventoryRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────
  // Path helpers
  // ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _medicationsRef(String memberId) {
    return _firestore
        .collection('profiles')
        .doc(memberId)
        .collection('medications');
  }

  CollectionReference<Map<String, dynamic>> _eventsRef(
    String memberId,
    String medicationId,
  ) {
    return _medicationsRef(memberId)
        .doc(medicationId)
        .collection('inventoryEvents');
  }

  // ───────────────────────────────────────────────────────────
  // Serialization helpers
  // ───────────────────────────────────────────────────────────

  /// Convert medication document → InventoryItem.
  /// Inventory fields are stored ON the med doc (not a separate collection).
  InventoryItem _fromMedDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String memberId,
  }) {
    final data = doc.data() ?? {};
    return InventoryItem(
      id: doc.id,
      medicationId: doc.id,
      memberId: memberId,
      medicineName: data['name'] as String? ?? '',
      strength: data['strength'] as String? ?? '',
      medicineType: data['form'] as String? ?? '',
      remainingQuantity: (data['quantityOnHand'] as num?)?.toInt() ?? 0,
      packageQuantity: (data['packageQuantity'] as num?)?.toInt(),
      unitsPerDay: (data['unitsPerDay'] as num?)?.toInt(),
      unitLabel: data['unitLabel'] as String?,
      lowStockThresholdDays:
          (data['lowStockThresholdDays'] as num?)?.toInt() ?? 7,
      lastAdjustedAt: (data['lastAdjustedAt'] as Timestamp?)?.toDate(),
      adjustmentSource: data['adjustmentSource'] as String?,
    );
  }

  /// Convert inventoryEvent document → InventoryEvent.
  InventoryEvent _fromEventDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String memberId,
    required String medicationId,
  }) {
    final data = doc.data() ?? {};
    return InventoryEvent(
      id: doc.id,
      medicationId: medicationId,
      memberId: memberId,
      delta: (data['delta'] as num?)?.toInt() ?? 0,
      reason: data['reason'] as String? ?? '',
      doseId: data['doseId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ============================================================
  // WATCH (realtime streams)
  // ============================================================

  @override
  Stream<List<InventoryItem>> watchInventory(String memberId) {
    try {
      return _medicationsRef(memberId)
          .where('active', isEqualTo: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((d) => _fromMedDoc(d, memberId: memberId))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Stream<List<InventoryEvent>> watchInventoryEvents({
    required String memberId,
    required String medicationId,
  }) {
    try {
      return _eventsRef(memberId, medicationId)
          .orderBy('createdAt', descending: true)
          .limit(50) // Last 50 events
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (d) => _fromEventDoc(
                    d,
                    memberId: memberId,
                    medicationId: medicationId,
                  ),
                )
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ============================================================
  // GET (one-time fetches)
  // ============================================================

  @override
  Future<List<InventoryItem>> getInventory(String memberId) async {
    try {
      final snapshot = await _medicationsRef(memberId)
          .where('active', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((d) => _fromMedDoc(d, memberId: memberId))
          .toList();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  @override
  Future<InventoryItem?> getInventoryForMedication({
    required String memberId,
    required String medicationId,
  }) async {
    try {
      final doc = await _medicationsRef(memberId).doc(medicationId).get();
      if (!doc.exists) return null;
      return _fromMedDoc(doc, memberId: memberId);
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  // ============================================================
  // ADJUST QUANTITY (atomic batch write)
  // ============================================================
  //
  // Uses Firestore batch to atomically:
  //   1. Add an event to inventoryEvents subcollection
  //   2. Update quantityOnHand on the medication document
  //
  // FieldValue.increment() ensures concurrent-safe updates
  // (multiple dose logs at the same time won't lose data).

  @override
  Future<void> adjustQuantity({
    required String memberId,
    required String medicationId,
    required int delta,
    required String reason,
    String? doseId,
  }) async {
    try {
      final medRef = _medicationsRef(memberId).doc(medicationId);
      final eventRef = _eventsRef(memberId, medicationId).doc();

      final batch = _firestore.batch();

      // 1. Add event to inventoryEvents subcollection
      batch.set(eventRef, {
        'delta': delta,
        'reason': reason,
        'doseId': doseId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update med doc — increment quantityOnHand atomically
      batch.update(medRef, {
        'quantityOnHand': FieldValue.increment(delta),
        'lastAdjustedAt': FieldValue.serverTimestamp(),
        'adjustmentSource': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(
        'Failed to adjust inventory: $e',
        originalError: e,
      );
    }
  }

  // ============================================================
  // SET INVENTORY CONFIG (initial setup)
  // ============================================================

  @override
  Future<void> setInventoryConfig({
    required String memberId,
    required String medicationId,
    int? packageQuantity,
    int? unitsPerDay,
    String? unitLabel,
    int? lowStockThresholdDays,
    int? initialQuantity,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (packageQuantity != null) {
        updateData['packageQuantity'] = packageQuantity;
      }
      if (unitsPerDay != null) {
        updateData['unitsPerDay'] = unitsPerDay;
      }
      if (unitLabel != null) {
        updateData['unitLabel'] = unitLabel;
      }
      if (lowStockThresholdDays != null) {
        updateData['lowStockThresholdDays'] = lowStockThresholdDays;
      }
      if (initialQuantity != null) {
        updateData['quantityOnHand'] = initialQuantity;
        updateData['lastAdjustedAt'] = FieldValue.serverTimestamp();
        updateData['adjustmentSource'] = 'initial_setup';
      }

      await _medicationsRef(memberId)
          .doc(medicationId)
          .set(updateData, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(
        'Failed to set inventory config: $e',
        originalError: e,
      );
    }
  }
}
