import '../../models/dose.dart';
import '../../repositories/dose_repository.dart';

/// What the Home screen needs from the dose store. The default talks to
/// Firestore through [DoseRepository]; widget tests pass a fake.
abstract class HomeDoseSource {
  const HomeDoseSource();

  factory HomeDoseSource.firestore() = _FirestoreHomeDoseSource;

  Stream<List<Dose>> watchTodaysDoses(String profileId);

  Future<List<Dose>> getDosesForDateRange(
    String profileId,
    DateTime from,
    DateTime to,
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
  Stream<List<Dose>> watchTodaysDoses(String profileId) =>
      _repo.watchTodaysDoses(profileId);

  @override
  Future<List<Dose>> getDosesForDateRange(
    String profileId,
    DateTime from,
    DateTime to,
  ) => _repo.getDosesForDateRange(profileId, from, to);

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
