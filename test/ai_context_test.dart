import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/ai/ai_context.dart';
import 'package:med_remind_app/core/ai/ai_text_scrubber.dart';
import 'package:med_remind_app/core/reports/report_models.dart';
import 'package:med_remind_app/models/allergy.dart';
import 'package:med_remind_app/models/medication.dart';
import 'package:med_remind_app/models/schedule.dart';

final now = DateTime(2026, 11, 16, 10, 0);

Medication med(
  String id,
  String name, {
  String? strength,
  String? form,
  String? instructions,
  MedicationStatus status = MedicationStatus.active,
  Schedule? schedule,
}) => Medication(
  id: id,
  profileId: 'p1',
  name: name,
  strength: strength,
  form: form,
  instructions: instructions,
  status: status,
  schedule:
      schedule ??
      Schedule(
        type: ScheduleType.daily,
        times: const ['08:00', '20:00'],
        startDate: DateTime(2026, 1, 1),
      ),
  createdAt: now,
  createdBy: 'u',
  updatedAt: now,
  updatedBy: 'u',
);

ReportDose dose(String id, String medId, ReportDoseStatus s, int daysAgo) =>
    ReportDose(
      id: id,
      medicationId: medId,
      medName: 'Metformin',
      strength: '500mg',
      scheduledAt: now.subtract(Duration(days: daysAgo)),
      status: s,
    );

AiContextBuilder builder({
  List<Medication>? meds,
  List<Allergy>? allergies,
  List<ReportDose>? doses,
  bool failMeds = false,
  bool failAllergies = false,
  bool failDoses = false,
}) => AiContextBuilder(
  fetchMedications: () async {
    if (failMeds) throw Exception('x');
    return meds ?? [];
  },
  fetchAllergies: () async {
    if (failAllergies) throw Exception('x');
    return allergies ?? [];
  },
  fetchDoses: (range) async {
    if (failDoses) throw Exception('x');
    return doses ?? [];
  },
);

void main() {
  group('AiTextScrubber', () {
    test('null and blank give null', () {
      expect(AiTextScrubber.clean(null), isNull);
      expect(AiTextScrubber.clean('   '), isNull);
    });

    test('removes emails and links', () {
      final s = AiTextScrubber.clean(
        'mail me a@b.com or see https://x.org/y and www.z.com',
      )!;
      expect(s, isNot(contains('@')));
      expect(s, isNot(contains('http')));
      expect(s, isNot(contains('www')));
      expect(s, contains('[removed]'));
    });

    test('removes phone numbers in many shapes', () {
      for (final p in [
        '0300-1234567',
        '+92 300 1234567',
        '(021) 555 0199',
        '03001234567',
        '555.123.4567',
      ]) {
        final s = AiTextScrubber.clean('call $p now')!;
        expect(s, isNot(contains(RegExp(r'\d{4}'))), reason: p);
        expect(s, contains('[removed]'), reason: p);
      }
    });

    test('keeps doses and small numbers', () {
      expect(
        AiTextScrubber.clean('Take 1-2 tablets, 500 mg, every 8 hours'),
        'Take 1-2 tablets, 500 mg, every 8 hours',
      );
      expect(AiTextScrubber.clean('10-20 mg'), '10-20 mg');
    });

    test('removes a birth date written after born / DOB', () {
      for (final t in [
        'patient born 12/03/1990 takes this',
        'DOB: 1990-03-12',
        'date of birth 12 March 1990',
      ]) {
        final s = AiTextScrubber.clean(t)!;
        expect(s, isNot(contains('1990')), reason: t);
      }
    });

    test('removes long digit runs', () {
      expect(AiTextScrubber.clean('id 1234567890'), isNot(contains('1234567')));
    });

    test('collapses spaces and cuts long text', () {
      expect(AiTextScrubber.clean('a   b \n c'), 'a b c');
      final long = AiTextScrubber.clean('x' * 500, maxLength: 50)!;
      expect(long.length, 50);
      expect(long.endsWith('…'), isTrue);
    });
  });

  group('AiContextBuilder', () {
    test('only active medicines are included', () async {
      final ctx = await builder(
        meds: [
          med('1', 'Metformin'),
          med('2', 'OldDrug', status: MedicationStatus.archived),
        ],
      ).build(now: now);
      expect(ctx.medications!.map((m) => m.name), ['Metformin']);
    });

    test('medicine line has strength, form, schedule, instructions', () async {
      final ctx = await builder(
        meds: [
          med(
            '1',
            'Metformin',
            strength: '500 MG',
            form: 'Tablet',
            instructions: 'with food',
          ),
        ],
      ).build(now: now);
      final text = ctx.toPromptText();
      expect(text, contains('Metformin 500 MG [Tablet]'));
      expect(text, contains('Daily at 08:00, 20:00'));
      expect(text, contains('instructions: with food'));
    });

    test('a cyclical schedule keeps its start date', () async {
      final ctx = await builder(
        meds: [
          med(
            '1',
            'Cyc',
            schedule: Schedule(
              type: ScheduleType.cyclical,
              cycleOn: 5,
              cycleOff: 2,
              cycleStart: DateTime(2026, 11, 1),
              startDate: DateTime(2026, 11, 1),
            ),
          ),
        ],
      ).build(now: now);
      expect(ctx.toPromptText(), contains('2026-11-01'));
    });

    test(
      'adherence uses the report numbers (taken/(taken+missed+skipped))',
      () async {
        final ctx = await builder(
          meds: [med('1', 'Metformin')],
          doses: [
            dose('a', '1', ReportDoseStatus.taken, 1),
            dose('b', '1', ReportDoseStatus.taken, 2),
            dose('c', '1', ReportDoseStatus.taken, 3),
            dose('d', '1', ReportDoseStatus.missed, 4),
            dose('e', '1', ReportDoseStatus.pending, 0),
          ],
        ).build(now: now);
        final t = ctx.adherenceTotal!;
        expect(t.taken, 3);
        expect(t.missed, 1);
        expect(t.percent, 75);
        final text = ctx.toPromptText();
        expect(text, contains('75%'));
        expect(text, contains('3 taken, 1 missed'));
      },
    );

    test('doses outside the 30 days are ignored', () async {
      final ctx = await builder(
        doses: [
          dose('a', '1', ReportDoseStatus.taken, 5),
          dose('old', '1', ReportDoseStatus.missed, 90),
        ],
      ).build(now: now);
      expect(ctx.adherenceTotal!.missed, 0);
    });

    test('no doses says so', () async {
      final ctx = await builder().build(now: now);
      expect(ctx.toPromptText(), contains('no doses recorded'));
    });

    test('allergies are listed with severity', () async {
      final ctx = await builder(
        allergies: [
          Allergy(
            id: 'a',
            memberId: 'p1',
            name: 'Penicillin',
            severity: 'severe',
            description: 'rash',
          ),
        ],
      ).build(now: now);
      expect(ctx.toPromptText(), contains('Penicillin (severe) — rash'));
    });

    test(
      'a failing source is marked unavailable, the others still work',
      () async {
        final ctx = await builder(
          meds: [med('1', 'Metformin')],
          failDoses: true,
          failAllergies: true,
        ).build(now: now);
        final text = ctx.toPromptText();
        expect(text, contains('Metformin'));
        expect(text, contains('Adherence (last 30 days): unavailable'));
        expect(text, contains('Allergies: unavailable'));
        final text2 = (await builder(failMeds: true).build(now: now))
            .toPromptText();
        expect(text2, contains('Medicines: unavailable'));
      },
    );

    test('lists are capped', () async {
      final ctx = await builder(
        meds: [for (var i = 0; i < 80; i++) med('$i', 'Med$i')],
        allergies: [
          for (var i = 0; i < 50; i++)
            Allergy(id: '$i', memberId: 'p1', name: 'A$i', severity: 'mild'),
        ],
      ).build(now: now);
      expect(ctx.medications!.length, AiContextBuilder.maxMedications);
      expect(ctx.allergies!.length, AiContextBuilder.maxAllergies);
    });

    test('long free text is cut', () async {
      final ctx = await builder(meds: [med('1', 'M', instructions: 'z' * 1000)])
          .build(now: now);
      expect(
        ctx.medications!.first.instructions!.length,
        AiContextBuilder.maxTextLength,
      );
    });
  });

  group('privacy: nothing personal reaches the AI text', () {
    test('contact details typed into free text are removed', () async {
      final ctx = await builder(
        meds: [
          med(
            '1',
            'Metformin',
            instructions:
                'Dr Ahmed 0300-1234567, mail ahmed@clinic.com, born 12/03/1990',
          ),
        ],
        allergies: [
          Allergy(
            id: 'a',
            memberId: 'p1',
            name: 'Penicillin',
            severity: 'mild',
            description: 'call +92 321 7654321 or visit https://x.pk',
          ),
        ],
      ).build(now: now);
      final text = ctx.toPromptText();
      expect(text, isNot(contains('0300')));
      expect(text, isNot(contains('1234567')));
      expect(text, isNot(contains('@')));
      expect(text, isNot(contains('1990')));
      expect(text, isNot(contains('321 7654321')));
      expect(text, isNot(contains('https')));
    });

    test('the profile id / member id is never in the text', () async {
      final ctx = await builder(
        meds: [med('med-id-123', 'Metformin')],
        allergies: [
          Allergy(
            id: 'allergy-id-9',
            memberId: 'p1-secret-member',
            name: 'Dust',
            severity: 'mild',
          ),
        ],
        doses: [dose('dose-id-77', 'med-id-123', ReportDoseStatus.taken, 1)],
      ).build(now: now);
      final text = ctx.toPromptText();
      for (final id in [
        'med-id-123',
        'allergy-id-9',
        'p1-secret-member',
        'dose-id-77',
        'p1',
      ]) {
        expect(text, isNot(contains(id)), reason: id);
      }
    });

    test('the context model has no personal fields', () {
      // The classes only expose these members; a name / DOB / email / phone
      // field would have to be added on purpose and would fail this review.
      final ctx = AiContext(date: DateTime(2026, 11, 16));
      final text = ctx.toPromptText().toLowerCase();
      for (final word in ['name:', 'email', 'phone', 'birth', 'dob']) {
        expect(text, isNot(contains(word)), reason: word);
      }
    });
  });
}
