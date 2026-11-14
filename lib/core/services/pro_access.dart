import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../repositories/firebase_subscription_repository.dart';
import '../subscription/pro_gate.dart';

/// Debug builds only. `--dart-define=PRO_DEBUG_UNLOCK=true` (or the older
/// `HEALTH_SYNC_DEBUG_UNLOCK=true`) skips the app-side Pro check so the
/// screens can be tried without a subscription. It is a compile-time constant
/// guarded by [kDebugMode], so it can never be on in a release build. It does
/// NOT bypass firestore.rules, which still read customers/{ownerUid}.
const bool _proDebugUnlock =
    bool.fromEnvironment('PRO_DEBUG_UNLOCK') ||
    bool.fromEnvironment('HEALTH_SYNC_DEBUG_UNLOCK');

/// The real wiring of [ProGate] used by the app (M16 step 7).
class ProAccess {
  ProAccess._();

  static final ProGate gate = ProGate(
    currentUid: () => FirebaseAuth.instance.currentUser?.uid,
    hasPremiumAccess: (uid) =>
        FirebaseSubscriptionRepository.instance.hasPremiumAccess(uid),
    profileOwnerUid: (profileId) async {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .get();
      return snap.data()?['ownerUid'] as String?;
    },
    debugUnlock: kDebugMode && _proDebugUnlock,
  );
}
