import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/core/profile/profile_controller.dart';
import 'package:med_remind_app/features/profile/invite_member_screen.dart';
import 'package:med_remind_app/features/profile/invites_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> open(
  WidgetTester tester, {
  required bool Function() popped,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final r = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const InviteMemberScreen()),
                );
                if (r == true) _popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

bool _popped = false;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _popped = false;
  });

  testWidgets('shows the invite form with a Send Invite button', (t) async {
    await open(t, popped: () => _popped);
    expect(find.text('Send Invite'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('no profile selected: refuses and stays', (t) async {
    await open(t, popped: () => _popped);
    await t.tap(find.text('Send Invite'));
    await t.pump();
    expect(find.text('No family member selected.'), findsOneWidget);
    expect(find.text('Send Invite'), findsOneWidget);
  });

  testWidgets('adult invite without contact is refused', (t) async {
    await ProfileController.instance.selectProfile(
      memberId: 'm1',
      displayName: 'Mom',
    );
    final before = InvitesData.invitesFor('m1').length;
    await open(t, popped: () => _popped);
    await t.tap(find.text('Send Invite'));
    await t.pump();
    expect(find.text('Please enter email or phone number.'), findsOneWidget);
    expect(
      InvitesData.invitesFor('m1').length,
      before,
      reason: 'nothing created',
    );
  });

  testWidgets('adult invite with a contact is created and the screen closes', (
    t,
  ) async {
    await ProfileController.instance.selectProfile(
      memberId: 'm1',
      displayName: 'Mom',
    );
    final before = InvitesData.invitesFor('m1').length;
    await open(t, popped: () => _popped);
    await t.enterText(find.byType(TextField).first, 'care@example.com');
    await t.tap(find.text('Send Invite'));
    await t.pump(); // sending state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpAndSettle();
    expect(InvitesData.invitesFor('m1').length, before + 1);
    expect(_popped, isTrue, reason: 'screen returned true');
  });

  testWidgets('a second tap while sending does not create two invites', (
    t,
  ) async {
    await ProfileController.instance.selectProfile(
      memberId: 'm1',
      displayName: 'Mom',
    );
    final before = InvitesData.invitesFor('m1').length;
    await open(t, popped: () => _popped);
    await t.enterText(find.byType(TextField).first, 'a@b.com');
    await t.tap(find.text('Send Invite'));
    await t.pump();
    // The button is disabled while sending.
    final button = t.widget<ElevatedButton>(find.byType(ElevatedButton).first);
    expect(button.onPressed, isNull);
    await t.pumpAndSettle();
    expect(InvitesData.invitesFor('m1').length, before + 1);
  });

  testWidgets('Skip for now closes without creating anything', (t) async {
    final before = InvitesData.invitesFor('m1').length;
    await open(t, popped: () => _popped);
    await t.tap(find.text('Skip for now'));
    await t.pumpAndSettle();
    expect(find.text('Send Invite'), findsNothing);
    expect(InvitesData.invitesFor('m1').length, before);
    expect(_popped, isFalse);
  });
}
