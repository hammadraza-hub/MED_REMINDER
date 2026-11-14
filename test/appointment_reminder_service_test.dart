import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/doctors/appointment_models.dart';
import 'package:med_remind_app/core/doctors/appointment_reminder_service.dart';
import 'package:med_remind_app/core/doctors/reminder_planner.dart';

class FakeBackend implements AppointmentNotificationBackend {
  final Map<int, ({String title, DateTime at, String payload})> scheduled = {};
  final List<PendingReminder> extraPending = [];
  final List<int> cancelCalls = [];

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  }) async {
    scheduled[id] = (title: title, at: at, payload: payload);
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls.add(id);
    scheduled.remove(id);
    extraPending.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<PendingReminder>> pending() async => [
    for (final e in scheduled.entries)
      PendingReminder(id: e.key, payload: e.value.payload),
    ...extraPending,
  ];
}

final now = DateTime(2026, 11, 14, 9, 0);
final start = DateTime(2026, 11, 20, 10, 30);

Appointment apt(String id, {DateTime? at, List<int>? offsets}) => Appointment(
  id: id,
  startsAt: at ?? start,
  reminderOffsets: offsets ?? const [1440, 120],
);

void main() {
  late FakeBackend backend;
  late AppointmentReminderService service;

  setUp(() {
    backend = FakeBackend();
    service = AppointmentReminderService(backend);
  });

  test('schedules one notification per future reminder', () async {
    final n = await service.schedule(
      apt('a1'),
      profileId: 'p',
      title: 'T',
      body: 'B',
      now: now,
    );
    expect(n, 2);
    expect(backend.scheduled.length, 2);
    final times = backend.scheduled.values.map((v) => v.at).toSet();
    expect(times, {
      DateTime(2026, 11, 19, 10, 30),
      DateTime(2026, 11, 20, 8, 30),
    });
  });

  test('reminders already in the past are skipped', () async {
    final n = await service.schedule(
      apt('a1', at: DateTime(2026, 11, 14, 10, 0)),
      profileId: 'p',
      title: 'T',
      body: 'B',
      now: now,
    );
    expect(n, 0); // 1 day before and 2 hours before are both before now
    expect(backend.scheduled, isEmpty);
  });

  test('editing the time replaces the old reminders (same ids)', () async {
    await service.schedule(
      apt('a1'),
      profileId: 'p',
      title: 'T',
      body: 'B',
      now: now,
    );
    final firstIds = backend.scheduled.keys.toSet();

    await service.schedule(
      apt('a1', at: start.add(const Duration(days: 3))),
      profileId: 'p',
      title: 'T2',
      body: 'B',
      now: now,
    );
    expect(backend.scheduled.keys.toSet(), firstIds);
    expect(
      backend.scheduled.values.map((v) => v.at),
      contains(DateTime(2026, 11, 22, 10, 30)),
    );
    expect(backend.scheduled.values.every((v) => v.title == 'T2'), isTrue);
  });

  test(
    'editing the offsets removes reminders that are no longer wanted',
    () async {
      await service.schedule(
        apt('a1'),
        profileId: 'p',
        title: 'T',
        body: 'B',
        now: now,
      );
      await service.schedule(
        apt('a1', offsets: const [60]),
        profileId: 'p',
        title: 'T',
        body: 'B',
        now: now,
      );
      expect(backend.scheduled.length, 1);
      expect(
        backend.scheduled.keys.single,
        ReminderPlanner.notificationIdFor('a1_60'),
      );
    },
  );

  test('cancel removes every reminder of the appointment', () async {
    await service.schedule(
      apt('a1'),
      profileId: 'p',
      title: 'T',
      body: 'B',
      now: now,
    );
    await service.schedule(
      apt('a2'),
      profileId: 'p',
      title: 'T',
      body: 'B',
      now: now,
    );
    await service.cancel(apt('a1'));
    expect(backend.scheduled.length, 2);
    expect(
      backend.scheduled.values.every((v) => v.payload.contains('a2')),
      isTrue,
    );
  });

  test(
    'a reminder that was already delivered is not cancelled by a sync',
    () async {
      // 1 day before (Nov 19 10:30) has fired and is no longer pending;
      // 2 hours before (Nov 20 08:30) is still waiting.
      final laterNow = DateTime(2026, 11, 19, 12, 0);
      final deliveredId = ReminderPlanner.notificationIdFor('a1_1440');

      await service.sync(
        profileId: 'p',
        plans: [
          AppointmentReminderPlan(
            appointment: apt('a1'),
            title: 'T',
            body: 'B',
          ),
        ],
        now: laterNow,
      );

      expect(backend.cancelCalls, isNot(contains(deliveredId)));
      expect(backend.scheduled.length, 1);
    },
  );

  test('deleting an appointment also clears delivered reminders', () async {
    final deliveredId = ReminderPlanner.notificationIdFor('a1_1440');
    await service.cancel(apt('a1'), includeDelivered: true);
    expect(backend.cancelCalls, contains(deliveredId));
  });

  test('payload marks appointment reminders', () {
    final p = AppointmentReminderService.payloadFor('p1', 'a1');
    expect(AppointmentReminderService.isAppointmentPayload(p), isTrue);
    expect(AppointmentReminderService.isAppointmentPayload(null), isFalse);
    expect(AppointmentReminderService.isAppointmentPayload(''), isFalse);
    expect(
      AppointmentReminderService.isAppointmentPayload('not json'),
      isFalse,
    );
    expect(
      AppointmentReminderService.isAppointmentPayload(
        '{"doseId":"d1","profileId":"p"}',
      ),
      isFalse,
    );
  });

  test(
    'sync removes stale appointment reminders but never dose reminders',
    () async {
      // a deleted appointment's reminders and a dose alert are already pending
      await service.schedule(
        apt('gone'),
        profileId: 'p',
        title: 'T',
        body: 'B',
        now: now,
      );
      backend.extraPending.add(
        const PendingReminder(
          id: 999,
          payload: '{"doseId":"d1","profileId":"p"}',
        ),
      );

      final result = await service.sync(
        profileId: 'p',
        plans: [
          AppointmentReminderPlan(
            appointment: apt('keep'),
            title: 'T',
            body: 'B',
          ),
        ],
        now: now,
      );

      expect(result.cancelled, 2);
      expect(result.scheduled, 2);
      expect(
        backend.scheduled.values.every((v) => v.payload.contains('keep')),
        isTrue,
      );
      expect(backend.extraPending.map((p) => p.id), [999]);
    },
  );

  test('sync with nothing planned clears all appointment reminders', () async {
    await service.schedule(
      apt('a1'),
      profileId: 'p',
      title: 'T',
      body: 'B',
      now: now,
    );
    final result = await service.sync(
      profileId: 'p',
      plans: const [],
      now: now,
    );
    expect(result.cancelled, 2);
    expect(backend.scheduled, isEmpty);
  });

  test(
    'offset options keep the standard ones and any extras, largest first',
    () {
      expect(ReminderOffsetOptions.standard, [10080, 1440, 120, 60, 30]);
      expect(ReminderOffsetOptions.withExtras(const [1440, 45]), [
        10080,
        1440,
        120,
        60,
        45,
        30,
      ]);
      expect(
        ReminderOffsetOptions.withExtras(const []),
        ReminderOffsetOptions.standard,
      );
    },
  );
}
