import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/doctors/appointment_models.dart';
import 'package:med_remind_app/core/doctors/appointment_validator.dart';
import 'package:med_remind_app/core/doctors/doctor_note_models.dart';
import 'package:med_remind_app/core/doctors/doctor_note_validator.dart';
import 'package:med_remind_app/core/doctors/prescriber_models.dart';
import 'package:med_remind_app/core/doctors/prescriber_validator.dart';
import 'package:med_remind_app/core/doctors/reminder_planner.dart';

final now = DateTime(2026, 11, 14, 9, 0);
final start = DateTime(2026, 11, 20, 10, 30);

void main() {
  group('PrescriberValidator', () {
    test('valid minimal and full records', () {
      expect(PrescriberValidator.validate(name: 'Dr. Ahmed'), isEmpty);
      expect(
        PrescriberValidator.validate(
          name: 'Dr. Ahmed Khan',
          specialty: 'GP',
          phone: '+1 (555) 987-6543',
          clinic: 'City Care',
          address: 'Maple Street',
        ),
        isEmpty,
      );
    });

    test('name required and limited', () {
      expect(PrescriberValidator.validate(name: '   '), {
        PrescriberError.nameMissing,
      });
      expect(PrescriberValidator.validate(name: 'a' * 81), {
        PrescriberError.nameTooLong,
      });
      expect(PrescriberValidator.validate(name: 'a' * 80), isEmpty);
    });

    test('phone rules', () {
      expect(PrescriberValidator.isPhoneValid(null), isTrue);
      expect(PrescriberValidator.isPhoneValid('  '), isTrue);
      expect(PrescriberValidator.isPhoneValid('0300 1234567'), isTrue);
      expect(PrescriberValidator.isPhoneValid('12345'), isFalse); // too short
      expect(PrescriberValidator.isPhoneValid('1' * 16), isFalse); // too long
      expect(PrescriberValidator.isPhoneValid('abc1234567'), isFalse);
      expect(PrescriberValidator.isPhoneValid('12+34567890'), isFalse);
    });

    test('optional field lengths', () {
      final e = PrescriberValidator.validate(
        name: 'x',
        specialty: 'a' * 61,
        clinic: 'a' * 81,
        address: 'a' * 201,
      );
      expect(e, {
        PrescriberError.specialtyTooLong,
        PrescriberError.clinicTooLong,
        PrescriberError.addressTooLong,
      });
    });
  });

  group('Prescriber model', () {
    test('toMap trims and drops blanks', () {
      final m = const Prescriber(
        id: 'p1',
        name: '  Dr. A  ',
        specialty: ' ',
        phone: ' 123 ',
      ).toMap();
      expect(m, {'name': 'Dr. A', 'phone': '123'});
    });

    test('fromMap round trip', () {
      const p = Prescriber(
        id: 'p1',
        name: 'Dr. A',
        specialty: 'GP',
        clinic: 'C',
        address: 'Addr',
        phone: '1234567',
      );
      final back = Prescriber.fromMap('p1', p.toMap());
      expect(back.toMap(), p.toMap());
      expect(back.id, 'p1');
    });

    test('initials', () {
      Prescriber n(String s) => Prescriber(id: 'x', name: s);
      expect(n('Dr. Ahmed Khan').initials, 'AK');
      expect(n('Sara').initials, 'S');
      expect(n('Dr. Sara Bano Malik').initials, 'SM');
      expect(n('  ').initials, '?');
    });
  });

  group('AppointmentValidator', () {
    test('valid with defaults', () {
      expect(AppointmentValidator.validate(startsAt: start), isEmpty);
    });

    test('startsAt required; past only rejected when requireFuture', () {
      expect(AppointmentValidator.validate(startsAt: null), {
        AppointmentError.startsAtMissing,
      });
      final past = DateTime(2026, 11, 1);
      expect(AppointmentValidator.validate(startsAt: past), isEmpty);
      expect(
        AppointmentValidator.validate(
          startsAt: past,
          requireFuture: true,
          now: now,
        ),
        {AppointmentError.startsAtInPast},
      );
    });

    test('text limits', () {
      final e = AppointmentValidator.validate(
        startsAt: start,
        location: 'a' * 201,
        notes: 'a' * 501,
      );
      expect(e, {
        AppointmentError.locationTooLong,
        AppointmentError.notesTooLong,
      });
    });

    test('offsets', () {
      expect(AppointmentValidator.validateOffsets([]), isEmpty);
      expect(AppointmentValidator.validateOffsets([1440, 120]), isEmpty);
      expect(AppointmentValidator.validateOffsets([0]), {
        AppointmentError.offsetInvalid,
      });
      expect(AppointmentValidator.validateOffsets([-5]), {
        AppointmentError.offsetInvalid,
      });
      expect(AppointmentValidator.validateOffsets([43201]), {
        AppointmentError.offsetInvalid,
      });
      expect(AppointmentValidator.validateOffsets([43200]), isEmpty);
      expect(AppointmentValidator.validateOffsets([60, 60]), {
        AppointmentError.offsetDuplicate,
      });
      expect(AppointmentValidator.validateOffsets([1, 2, 3, 4, 5, 6]), {
        AppointmentError.offsetsTooMany,
      });
    });

    test('type codes', () {
      expect(AppointmentType.fromCode('lab_review'), AppointmentType.labReview);
      expect(AppointmentType.fromCode('nope'), isNull);
      expect(AppointmentType.fromCode(null), isNull);
    });
  });

  group('Appointment model', () {
    test('toMap normalises offsets and drops blanks', () {
      final m = Appointment(
        id: 'a',
        startsAt: start,
        location: ' ',
        notes: ' hi ',
        reminderOffsets: const [120, 1440, 120],
      ).toMap();
      expect(m['reminderOffsets'], [1440, 120]);
      expect(m['notes'], 'hi');
      expect(m.containsKey('location'), isFalse);
      expect(m.containsKey('prescriberId'), isFalse);
      expect(m['type'], 'follow_up');
    });

    test('fromMap round trip and fallbacks', () {
      final a = Appointment(
        id: 'a',
        startsAt: start,
        prescriberId: 'p1',
        type: AppointmentType.checkup,
        location: 'Clinic',
      );
      final back = Appointment.fromMap('a', a.toMap());
      expect(back.toMap(), a.toMap());

      final odd = Appointment.fromMap('b', {
        'startsAt': start,
        'type': 'weird',
      });
      expect(odd.type, AppointmentType.other);
      expect(odd.reminderOffsets, [1440, 120]);
    });

    test('isUpcoming', () {
      final a = Appointment(id: 'a', startsAt: start);
      expect(a.isUpcoming(now: now), isTrue);
      expect(a.isUpcoming(now: start.add(const Duration(minutes: 1))), isFalse);
    });
  });

  group('ReminderPlanner', () {
    final a = Appointment(id: 'apt1', startsAt: start);

    test('computes fire times earliest first with stable ids', () {
      final r = ReminderPlanner.all(a);
      expect(r.map((x) => x.id), ['apt1_1440', 'apt1_120']);
      expect(r[0].fireAt, DateTime(2026, 11, 19, 10, 30));
      expect(r[1].fireAt, DateTime(2026, 11, 20, 8, 30));
    });

    test('upcoming skips reminders already in the past', () {
      final late = DateTime(2026, 11, 19, 12, 0);
      final r = ReminderPlanner.upcoming(a, now: late);
      expect(r.map((x) => x.offsetMinutes), [120]);
      expect(ReminderPlanner.upcoming(a, now: start), isEmpty);
    });

    test('ids are stable, positive and differ per offset', () {
      final id1 = ReminderPlanner.notificationIdFor('apt1_1440');
      expect(id1, ReminderPlanner.notificationIdFor('apt1_1440'));
      expect(id1, isNonNegative);
      expect(id1, lessThanOrEqualTo(0x7fffffff));
      expect(id1, isNot(ReminderPlanner.notificationIdFor('apt1_120')));
    });

    test('editing the time keeps ids so old reminders can be cancelled', () {
      final moved = Appointment(
        id: 'apt1',
        startsAt: start.add(const Duration(days: 2)),
      );
      final oldIds = ReminderPlanner.all(a).map((x) => x.notificationId);
      final newIds = ReminderPlanner.all(moved).map((x) => x.notificationId);
      expect(newIds.toSet(), oldIds.toSet());
    });

    test('no offsets gives no reminders', () {
      final none = Appointment(
        id: 'z',
        startsAt: start,
        reminderOffsets: const [],
      );
      expect(ReminderPlanner.all(none), isEmpty);
    });
  });

  group('DoctorNote', () {
    test('validator', () {
      expect(DoctorNoteValidator.validate('ok'), isEmpty);
      expect(DoctorNoteValidator.validate('  '), {DoctorNoteError.bodyMissing});
      expect(DoctorNoteValidator.validate('a' * 501), {
        DoctorNoteError.bodyTooLong,
      });
      expect(DoctorNoteValidator.validate('a' * 500), isEmpty);
    });

    test('markDone and reopen', () {
      final n = DoctorNote(id: 'n', body: 'q', createdAt: now);
      expect(n.isOpen, isTrue);
      final d = n.markDone(start);
      expect(d.isOpen, isFalse);
      expect(d.doneAt, start);
      expect(d.reopen().isOpen, isTrue);
    });

    test('toMap writes doneAt null for open notes', () {
      final m = DoctorNote(id: 'n', body: ' q ', createdAt: now).toMap();
      expect(m['doneAt'], isNull);
      expect(m.containsKey('doneAt'), isTrue); // needed for doneAt == null
      expect(m['body'], 'q');
      expect(m.containsKey('appointmentId'), isFalse);
    });

    test('fromMap round trip', () {
      final n = DoctorNote(
        id: 'n',
        body: 'q',
        createdAt: now,
        doneAt: start,
        appointmentId: 'a1',
      );
      final back = DoctorNote.fromMap('n', n.toMap());
      expect(back.doneAt, start);
      expect(back.appointmentId, 'a1');
    });

    test('sorted: open newest first, then done latest first', () {
      final o1 = DoctorNote(id: 'o1', body: '1', createdAt: now);
      final o2 = DoctorNote(
        id: 'o2',
        body: '2',
        createdAt: now.add(const Duration(hours: 1)),
      );
      final d1 = DoctorNote(
        id: 'd1',
        body: '3',
        createdAt: now,
        doneAt: now.add(const Duration(days: 1)),
      );
      final d2 = DoctorNote(
        id: 'd2',
        body: '4',
        createdAt: now,
        doneAt: now.add(const Duration(days: 2)),
      );
      final s = DoctorNote.sorted([d1, o1, d2, o2]);
      expect(s.map((x) => x.id), ['o2', 'o1', 'd2', 'd1']);
    });
  });
}
