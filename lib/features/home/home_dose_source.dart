import 'package:timezone/timezone.dart' as tz;

import '../../core/dose_zone.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/dose.dart';
import '../../repositories/dose_repository.dart';

/// What the Home screen needs from the dose store. The default talks to
/// Firestore through [DoseRepository]; widget tests pass a fake.
abstract class HomeDoseSource {
  const HomeDoseSource();

  factory HomeDoseSource.firestore() = _FirestoreHomeDoseSource;

  /// The time zone doses of this profile are generated in.
  Future<tz.Location> zoneOf(String profileId);

  /// Doses whose time is in [startUtc, endUtc).
  Stream<List<Dose>> watchDoses(
    String profileId,
    DateTime startUtc,
    DateTime endUtc,
  );

  /// One-time read of the doses in [startUtc, endUtc) (the streak history).
  Future<List<Dose>> getDosesBetween(
    String profileId,
    DateTime startUtc,
    DateTime endUtc,
  );

  Future<void> logDose({
    required String profileId,
    required String doseId,
    required DoseStatus status,
    required String loggedBy,
    String? reasonText,
  });

  Future<void> undoDose({required String profileId, required String doseId});

  Future<void> snoozeDose({
    required String profileId,
    required String doseId,
    required Duration snoozeDuration,
  });
}

class _FirestoreHomeDoseSource extends HomeDoseSource {
  const _FirestoreHomeDoseSource();

  DoseRepository get _repo => DoseRepository.instance;

  @override
  Future<tz.Location> zoneOf(String profileId) async {
    String? name;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .get()
          .timeout(const Duration(seconds: 4));
      name = doc.data()?['timezone'] as String?;
    } catch (_) {
      name = null; // unknown: the phone's zone
    }
    return DoseZone.forProfile(name);
  }

  @override
  Stream<List<Dose>> watchDoses(
    String profileId,
    DateTime startUtc,
    DateTime endUtc,
  ) => _repo.watchDosesBetween(profileId, startUtc, endUtc);

  @override
  Future<List<Dose>> getDosesBetween(
    String profileId,
    DateTime startUtc,
    DateTime endUtc,
  ) => _repo.getDosesBetween(profileId, startUtc, endUtc);

  @override
  Future<void> logDose({
    required String profileId,
    required String doseId,
    required DoseStatus status,
    required String loggedBy,
    String? reasonText,
  }) => _repo.logDose(
    profileId: profileId,
    doseId: doseId,
    status: status,
    loggedBy: loggedBy,
    reasonText: reasonText,
  );

  @override
  Future<void> undoDose({required String profileId, required String doseId}) =>
      _repo.undoDose(profileId: profileId, doseId: doseId);

  @override
  Future<void> snoozeDose({
    required String profileId,
    required String doseId,
    required Duration snoozeDuration,
  }) => _repo.snoozeDose(
    profileId: profileId,
    doseId: doseId,
    snoozeDuration: snoozeDuration,
  );
}
