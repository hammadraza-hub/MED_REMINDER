import '../../core/doctors/appointment_models.dart';
import '../../core/home_day.dart';
import '../../core/inventory/inventory_repository.dart';
import '../../core/services/reminder_permission_service.dart';
import '../../core/vitals/symptom_entry.dart';
import '../../models/dose.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/firebase_appointment_repository.dart';
import '../../repositories/firebase_inventory_repository.dart';
import '../../repositories/firebase_symptom_repository.dart';
import 'home_dose_source.dart';

/// Where the Notifications screen reads its data. There is no server inbox on
/// the Spark plan, so the list is built from what the app already stores:
/// today's doses, stock, symptoms, appointments. Each source can fail on its
/// own (a viewer without health access cannot read symptoms) without losing
/// the others. The default talks to Firestore; tests pass a fake.
abstract class NotificationSources {
  const NotificationSources();

  factory NotificationSources.firestore({HomeDoseSource? doseSource}) =
      _FirestoreSources;

  String? get myUid;

  Future<List<Dose>> todayDoses(String profileId);

  Future<List<InventoryItem>> inventory(String profileId);

  Future<List<SymptomEntry>> symptoms(String profileId, DateTime since);

  Future<List<Appointment>> appointments(String profileId, DateTime from);

  /// Can reminders fail to ring (a phone permission is missing)?
  Future<bool> remindersAtRisk();
}

class _FirestoreSources extends NotificationSources {
  _FirestoreSources({HomeDoseSource? doseSource})
    : _doses = doseSource ?? HomeDoseSource.firestore();

  final HomeDoseSource _doses;

  @override
  String? get myUid => AuthRepository.instance.currentUid;

  @override
  Future<List<Dose>> todayDoses(String profileId) async {
    final zone = await _doses.zoneOf(profileId);
    final day = HomeDay.of(zone);
    return _doses.getDosesBetween(profileId, day.startUtc, day.endUtc);
  }

  @override
  Future<List<InventoryItem>> inventory(String profileId) =>
      FirebaseInventoryRepository.instance.getInventory(profileId);

  @override
  Future<List<SymptomEntry>> symptoms(String profileId, DateTime since) =>
      FirebaseSymptomRepository.instance.list(profileId, since: since);

  @override
  Future<List<Appointment>> appointments(String profileId, DateTime from) =>
      FirebaseAppointmentRepository.instance.list(
        profileId,
        from: from,
        limit: 20,
      );

  @override
  Future<bool> remindersAtRisk() async =>
      (await ReminderPermissionService.instance.check()).atRisk;
}
