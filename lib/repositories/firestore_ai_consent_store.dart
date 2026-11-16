import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/ai/ai_consent.dart';

/// Reads and writes `users/{uid}.aiConsentAt`. Security rules allow only the
/// server time (give) or null (withdraw). M18 step 1.
class FirestoreAiConsentStore implements AiConsentStore {
  static const Duration _timeout = Duration(seconds: 10);

  DocumentReference<Map<String, dynamic>> _doc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  Future<DateTime?> read() async {
    final snap = await _doc().get().timeout(_timeout);
    final raw = snap.data()?['aiConsentAt'];
    return raw is Timestamp ? raw.toDate() : null;
  }

  @override
  Future<void> grant() => _doc()
      .update({
        'aiConsentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      .timeout(_timeout);

  @override
  Future<void> withdraw() => _doc()
      .update({'aiConsentAt': null, 'updatedAt': FieldValue.serverTimestamp()})
      .timeout(_timeout);
}
