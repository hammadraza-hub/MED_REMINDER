// M16 step 3 — runs the prescriber / appointment / doctor-note repositories
// against the LOCAL Firebase emulators with the real firestore.rules.
//
// Needs, on the PC:
//   firebase emulators:start --only auth,firestore --project medapp-staging
// and a seeded owner (see graphify/HANDOFF.md §12):
//   owner2@example.com / Test1234!  owner of profile "pO" with active
//                                   medications m16_a, m16_b and archived m16_c
//   care@example.com   / Test1234!  NOT a member of "pO" (must be denied)
//
// Run (Android emulator):
//   flutter test integration_test/doctor_repositories_test.dart -d emulator-5554 \
//     --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
//
// Refuses to run without USE_EMULATOR so it can never touch a real project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/config/app_config.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/core/doctors/appointment_models.dart';
import 'package:med_remind_app/core/doctors/appointment_validator.dart';
import 'package:med_remind_app/core/doctors/prescriber_models.dart';
import 'package:med_remind_app/repositories/firebase_appointment_repository.dart';
import 'package:med_remind_app/repositories/firebase_doctor_note_repository.dart';
import 'package:med_remind_app/repositories/firebase_prescriber_repository.dart';

const _pid = 'pO';
const _host = '10.0.2.2';

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Test1234!',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final doctors = FirebasePrescriberRepository.instance;
  final appts = FirebaseAppointmentRepository.instance;
  final notes = FirebaseDoctorNoteRepository.instance;

  setUpAll(() async {
    expect(
      const bool.fromEnvironment('USE_EMULATOR'),
      isTrue,
      reason: 'Run with --dart-define=USE_EMULATOR=true (emulators only)',
    );
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    await _signIn('owner2@example.com');
  });

  DocumentReference<Map<String, dynamic>> med(String id) => FirebaseFirestore
      .instance
      .collection('profiles')
      .doc(_pid)
      .collection('medications')
      .doc(id);

  Future<void> linkMed(String id, String doctorId) => med(id).update({
    'prescriberId': doctorId,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  DateTime inDays(int n) => DateTime.now().add(Duration(days: n));

  test('doctor is saved, listed A-Z, edited and deleted', () async {
    final b = await doctors.add(
      _pid,
      const Prescriber(
        id: '',
        name: 'Dr. Zoya Bashir',
        specialty: 'Cardiologist',
        phone: '+92 300 1234567',
        clinic: 'Heart Care',
        address: 'Main Road',
      ),
    );
    final a = await doctors.add(
      _pid,
      const Prescriber(id: '', name: 'Dr. Ahmed Khan'),
    );
    expect(b.id, isNotEmpty);

    final list = await doctors.list(_pid);
    final names = list.map((d) => d.name).toList();
    expect(
      names.indexOf('Dr. Ahmed Khan'),
      lessThan(names.indexOf('Dr. Zoya Bashir')),
      reason: 'A to Z',
    );

    final got = await doctors.get(_pid, b.id);
    expect(got!.specialty, 'Cardiologist');
    expect(got.phone, '+92 300 1234567');

    // edit: change name, drop clinic and address
    await doctors.update(
      _pid,
      Prescriber(
        id: b.id,
        name: 'Dr. Zoya B.',
        specialty: 'Cardiologist',
        phone: '+92 300 1234567',
      ),
    );
    final edited = (await doctors.get(_pid, b.id))!;
    expect(edited.name, 'Dr. Zoya B.');
    expect(edited.clinic, isNull);
    expect(edited.address, isNull);

    await doctors.delete(_pid, b.id);
    await doctors.delete(_pid, a.id);
    expect(await doctors.get(_pid, b.id), isNull);
  });

  test('an invalid doctor is rejected before anything is written', () async {
    final before = (await doctors.list(_pid)).length;
    await expectLater(
      doctors.add(_pid, const Prescriber(id: '', name: '  ')),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      doctors.add(_pid, const Prescriber(id: '', name: 'Dr X', phone: '12')),
      throwsA(isA<AppException>()),
    );
    expect((await doctors.list(_pid)).length, before);
  });

  test('linked medication count only counts active medications', () async {
    final d = await doctors.add(
      _pid,
      const Prescriber(id: '', name: 'Dr Link'),
    );
    expect(await doctors.linkedMedicationCount(_pid, d.id), 0);

    await linkMed('m16_a', d.id);
    await linkMed('m16_b', d.id);
    await linkMed('m16_c', d.id); // archived
    expect(await doctors.linkedMedicationCount(_pid, d.id), 2);

    await doctors.delete(_pid, d.id);
  });

  test('setMedicationLinks links, replaces and unlinks medications', () async {
    final d1 = await doctors.add(
      _pid,
      const Prescriber(id: '', name: 'Dr One'),
    );
    final d2 = await doctors.add(
      _pid,
      const Prescriber(id: '', name: 'Dr Two'),
    );

    await doctors.setMedicationLinks(
      _pid,
      d1.id,
      toLink: ['m16_a', 'm16_b'],
      toUnlink: const [],
    );
    expect(await doctors.linkedMedicationCount(_pid, d1.id), 2);

    // linking m16_a to Dr Two replaces Dr One; m16_b is then unlinked
    await doctors.setMedicationLinks(
      _pid,
      d2.id,
      toLink: ['m16_a'],
      toUnlink: const [],
    );
    await doctors.setMedicationLinks(
      _pid,
      d1.id,
      toLink: const [],
      toUnlink: ['m16_b'],
    );
    expect(await doctors.linkedMedicationCount(_pid, d1.id), 0);
    expect(await doctors.linkedMedicationCount(_pid, d2.id), 1);
    expect((await med('m16_a').get()).data()!['prescriberId'], d2.id);

    await doctors.delete(_pid, d1.id);
    await doctors.delete(_pid, d2.id);
  });

  test(
    'deleting a doctor clears the link on medications and appointments',
    () async {
      final d = await doctors.add(
        _pid,
        const Prescriber(id: '', name: 'Dr Gone'),
      );
      await linkMed('m16_a', d.id);
      final apt = await appts.add(
        _pid,
        Appointment(id: '', startsAt: inDays(3), prescriberId: d.id),
      );
      expect((await appts.get(_pid, apt.id))!.prescriberId, d.id);

      await doctors.delete(_pid, d.id);

      expect(await doctors.get(_pid, d.id), isNull);
      expect(
        (await med('m16_a').get()).data()!.containsKey('prescriberId'),
        isFalse,
      );
      final after = (await appts.get(_pid, apt.id))!;
      expect(after.prescriberId, isNull);

      await appts.delete(_pid, apt.id);
    },
  );

  test('appointments: add, list soonest first, filter, edit, delete', () async {
    final d = await doctors.add(_pid, const Prescriber(id: '', name: 'Dr Apt'));
    final later = await appts.add(
      _pid,
      Appointment(
        id: '',
        startsAt: inDays(10),
        type: AppointmentType.labReview,
        location: 'Lab',
        notes: 'Fasting',
        reminderOffsets: const [60, 1440],
      ),
    );
    final sooner = await appts.add(
      _pid,
      Appointment(id: '', startsAt: inDays(2), prescriberId: d.id),
    );
    expect(later.reminderOffsets, [1440, 60], reason: 'largest first');

    final all = await appts.list(_pid);
    final ids = all.map((a) => a.id).toList();
    expect(ids.indexOf(sooner.id), lessThan(ids.indexOf(later.id)));

    final fromDay5 = await appts.list(_pid, from: inDays(5));
    expect(fromDay5.map((a) => a.id), contains(later.id));
    expect(fromDay5.map((a) => a.id), isNot(contains(sooner.id)));

    final got = (await appts.get(_pid, later.id))!;
    expect(got.type, AppointmentType.labReview);
    expect(got.location, 'Lab');
    expect(got.reminderOffsets, [1440, 60]);

    // edit: move the time, change the reminders, drop notes, add a doctor
    final newTime = inDays(12);
    await appts.update(
      _pid,
      Appointment(
        id: later.id,
        startsAt: newTime,
        prescriberId: d.id,
        type: AppointmentType.checkup,
        location: 'Lab',
        reminderOffsets: const [120],
      ),
    );
    final edited = (await appts.get(_pid, later.id))!;
    expect(edited.prescriberId, d.id);
    expect(edited.type, AppointmentType.checkup);
    expect(edited.notes, isNull);
    expect(edited.reminderOffsets, [120]);
    expect(edited.startsAt.difference(newTime).inSeconds.abs(), lessThan(2));

    await appts.delete(_pid, later.id);
    await appts.delete(_pid, sooner.id);
    await doctors.delete(_pid, d.id);
  });

  test(
    'a new appointment in the past is rejected, editing one is fine',
    () async {
      await expectLater(
        appts.add(
          _pid,
          Appointment(
            id: '',
            startsAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        appts.add(
          _pid,
          Appointment(
            id: '',
            startsAt: inDays(1),
            reminderOffsets: const [60, 60],
          ),
        ),
        throwsA(isA<AppException>()),
      );

      final a = await appts.add(_pid, Appointment(id: '', startsAt: inDays(1)));
      await appts.update(
        _pid,
        Appointment(
          id: a.id,
          startsAt: DateTime.now().subtract(const Duration(days: 1)),
          notes: 'happened',
        ),
      );
      expect((await appts.get(_pid, a.id))!.notes, 'happened');
      await appts.delete(_pid, a.id);
    },
  );

  test('doctor notes: open list, done, reopen, edit, clear done', () async {
    final apt = await appts.add(_pid, Appointment(id: '', startsAt: inDays(4)));
    final n1 = await notes.add(_pid, 'Ask about the dose');
    final n2 = await notes.add(_pid, 'Side effects?', appointmentId: apt.id);

    var open = await notes.listOpen(_pid);
    expect(
      await notes.openCount(_pid),
      open.length,
      reason: 'count() agrees with the open list',
    );
    expect(open.map((n) => n.id), containsAll([n1.id, n2.id]));
    expect(open.firstWhere((n) => n.id == n2.id).appointmentId, apt.id);

    await notes.markDone(_pid, n1.id);
    open = await notes.listOpen(_pid);
    expect(open.map((n) => n.id), isNot(contains(n1.id)));
    expect(open.map((n) => n.id), contains(n2.id));

    final all = await notes.list(_pid);
    final ids = all.map((n) => n.id).toList();
    expect(
      ids.indexOf(n2.id),
      lessThan(ids.indexOf(n1.id)),
      reason: 'open before done',
    );
    expect(all.firstWhere((n) => n.id == n1.id).doneAt, isNotNull);

    await notes.reopen(_pid, n1.id);
    expect((await notes.listOpen(_pid)).map((n) => n.id), contains(n1.id));

    await notes.editBody(_pid, n1.id, 'Ask about the new dose');
    expect(
      (await notes.list(_pid)).firstWhere((n) => n.id == n1.id).body,
      'Ask about the new dose',
    );

    await notes.markDone(_pid, n1.id);
    expect(await notes.clearDone(_pid), greaterThanOrEqualTo(1));
    final left = (await notes.list(_pid)).map((n) => n.id);
    expect(left, isNot(contains(n1.id)));
    expect(left, contains(n2.id));

    await notes.delete(_pid, n2.id);
    await appts.delete(_pid, apt.id);
  });

  test('invalid notes are rejected', () async {
    await expectLater(notes.add(_pid, '   '), throwsA(isA<AppException>()));
    await expectLater(notes.add(_pid, 'a' * 501), throwsA(isA<AppException>()));
  });

  test(
    'on the free plan: read and delete work, create and update are refused',
    () async {
      // care@example.com owns profile pF and has no subscription record.
      await _signIn('care@example.com');
      const free = 'pF';
      Matcher denied() => throwsA(
        isA<AppException>().having(
          (e) => e.type,
          'type',
          AppExceptionType.permission,
        ),
      );

      try {
        expect(
          (await doctors.list(free)).map((d) => d.id),
          contains('old_doc'),
        );
        expect((await notes.list(free)).map((n) => n.id), contains('old_note'));

        await expectLater(
          doctors.add(free, const Prescriber(id: '', name: 'Dr New')),
          denied(),
        );
        await expectLater(
          doctors.update(
            free,
            const Prescriber(id: 'old_doc', name: 'Renamed'),
          ),
          denied(),
        );
        await expectLater(
          appts.add(free, Appointment(id: '', startsAt: inDays(2))),
          denied(),
        );
        await expectLater(notes.add(free, 'New question'), denied());
        await expectLater(notes.markDone(free, 'old_note'), denied());
        await expectLater(notes.editBody(free, 'old_note', 'Edited'), denied());

        // deleting your own data is still allowed (read-only, never stuck)
        await notes.delete(free, 'old_note');
        await doctors.delete(free, 'old_doc');
        expect(await doctors.get(free, 'old_doc'), isNull);
      } finally {
        await _signIn('owner2@example.com');
      }
    },
  );

  test('someone who is not a member of the profile is denied', () async {
    await _signIn('care@example.com');
    try {
      await expectLater(
        doctors.add(_pid, const Prescriber(id: '', name: 'Dr Intruder')),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        appts.add(_pid, Appointment(id: '', startsAt: inDays(1))),
        throwsA(isA<AppException>()),
      );
      await expectLater(notes.add(_pid, 'hello'), throwsA(isA<AppException>()));
      await expectLater(doctors.list(_pid), throwsA(isA<AppException>()));
    } finally {
      await _signIn('owner2@example.com');
    }
  });
}
