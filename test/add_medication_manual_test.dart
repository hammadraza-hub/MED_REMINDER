import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/features/meds/add_medication_manual_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/medication.dart';
import 'package:med_remind_app/models/schedule.dart';

final schedule = Schedule(
  type: ScheduleType.daily,
  times: const ['08:00', '20:00'],
  startDate: DateTime(2026, 11, 18),
);

String? popped;
bool closed = false;

Future<void> open(
  WidgetTester t, {
  Schedule? initial,
  Future<String> Function(Medication)? onCreate,
}) async {
  t.view.physicalSize = const Size(900, 3000);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  popped = null;
  closed = false;
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            popped = await Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (_) => AddMedicationManualScreen(
                  profileId: 'p1',
                  initialSchedule: initial,
                  uidProvider: () => 'u1',
                  onCreate: onCreate ?? (_) async => 'med1',
                ),
              ),
            );
            closed = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('empty name is refused and nothing is created', (t) async {
    var created = 0;
    await open(
      t,
      initial: schedule,
      onCreate: (_) async {
        created++;
        return 'x';
      },
    );
    await t.tap(find.text('Save'));
    await t.pump();
    expect(find.text('Drug name is required'), findsOneWidget);
    expect(created, 0);
    expect(closed, isFalse);
  });

  testWidgets('no schedule is refused', (t) async {
    var created = 0;
    await open(
      t,
      onCreate: (_) async {
        created++;
        return 'x';
      },
    );
    await t.enterText(find.byType(TextField).first, 'Metformin');
    await t.tap(find.text('Save'));
    await t.pump();
    expect(find.text('Please set a schedule before saving'), findsOneWidget);
    expect(created, 0);
  });

  testWidgets('a name with whitespace only counts as empty', (t) async {
    await open(t, initial: schedule);
    await t.enterText(find.byType(TextField).first, '   ');
    await t.tap(find.text('Save'));
    await t.pump();
    expect(find.text('Drug name is required'), findsOneWidget);
  });

  testWidgets('valid form creates the medicine and returns its id', (t) async {
    Medication? saved;
    await open(
      t,
      initial: schedule,
      onCreate: (m) async {
        saved = m;
        return 'med42';
      },
    );
    await t.enterText(find.byType(TextField).first, '  Metformin ');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.name, 'Metformin', reason: 'trimmed');
    expect(saved!.profileId, 'p1');
    expect(saved!.status, MedicationStatus.active);
    expect(saved!.createdBy, 'u1');
    expect(saved!.updatedBy, 'u1');
    expect(saved!.schedule.times, ['08:00', '20:00']);
    expect(saved!.strength, isNull, reason: 'empty optional fields are null');
    expect(saved!.doseAmount, isNull);
    expect(popped, 'med42');
    expect(closed, isTrue);
  });

  testWidgets('a failing save shows an error, stays, and can retry', (t) async {
    var calls = 0;
    await open(
      t,
      initial: schedule,
      onCreate: (_) async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return 'med1';
      },
    );
    await t.enterText(find.byType(TextField).first, 'Aspirin');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.text('Save'), findsOneWidget, reason: 'spinner is gone');
    expect(find.byType(SnackBar), findsOneWidget);

    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(calls, 2);
    expect(popped, 'med1');
  });

  testWidgets('while saving the Save button is replaced by a spinner', (
    t,
  ) async {
    await open(
      t,
      initial: schedule,
      onCreate: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return 'm';
      },
    );
    await t.enterText(find.byType(TextField).first, 'Aspirin');
    await t.tap(find.text('Save'));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Save'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.pumpAndSettle();
    expect(popped, 'm');
  });

  testWidgets('dose amount is parsed as a number', (t) async {
    Medication? saved;
    await open(
      t,
      initial: schedule,
      onCreate: (m) async {
        saved = m;
        return 'm';
      },
    );
    await t.enterText(find.byType(TextField).first, 'Aspirin');
    await t.enterText(find.byType(TextField).at(3), '1.5');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(saved!.doseAmount, 1.5);
  });
}
