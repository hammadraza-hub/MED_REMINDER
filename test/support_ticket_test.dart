import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/features/settings/submit_request_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/models/support_ticket.dart';

void main() {
  group('SupportTicket.validate', () {
    test('ok for normal text', () {
      expect(
        SupportTicket.validate('Reminders not ringing', 'Since yesterday.'),
        TicketValidation.ok,
      );
    });

    test('empty or whitespace subject/body', () {
      expect(SupportTicket.validate('', 'b'), TicketValidation.subjectEmpty);
      expect(SupportTicket.validate('   ', 'b'), TicketValidation.subjectEmpty);
      expect(SupportTicket.validate('s', ''), TicketValidation.bodyEmpty);
      expect(SupportTicket.validate('s', ' \n '), TicketValidation.bodyEmpty);
    });

    test('limits match the Firestore rules (120 / 2000, inclusive)', () {
      expect(
        SupportTicket.validate('x' * 120, 'y' * 2000),
        TicketValidation.ok,
      );
      expect(
        SupportTicket.validate('x' * 121, 'b'),
        TicketValidation.subjectTooLong,
      );
      expect(
        SupportTicket.validate('s', 'y' * 2001),
        TicketValidation.bodyTooLong,
      );
    });

    test('length is measured after trimming', () {
      expect(
        SupportTicket.validate('  ${'x' * 120}  ', 'b'),
        TicketValidation.ok,
      );
    });
  });

  group('SupportTicket.fromForm / toMap', () {
    test('trims text, clamps auto fields, keeps expected keys', () {
      final t = SupportTicket.fromForm(
        uid: 'u1',
        subject: '  Hello  ',
        body: '\nWorld\n',
        appVersion: 'v' * 100,
        device: 'd' * 500,
        locale: 'hi',
      );
      expect(t.subject, 'Hello');
      expect(t.body, 'World');
      expect(t.appVersion.length, SupportTicket.maxAppVersion);
      expect(t.device.length, SupportTicket.maxDevice);

      final m = t.toMap();
      expect(m.keys.toSet(), {
        'uid',
        'subject',
        'body',
        'appVersion',
        'device',
        'locale',
        'status',
      });
      expect(m['status'], 'open');
      expect(m['uid'], 'u1');
    });

    test('locale omitted when missing or too long', () {
      final a = SupportTicket.fromForm(
        uid: 'u',
        subject: 's',
        body: 'b',
        appVersion: '1',
        device: 'd',
      );
      expect(a.toMap().containsKey('locale'), isFalse);

      final b = SupportTicket.fromForm(
        uid: 'u',
        subject: 's',
        body: 'b',
        appVersion: '1',
        device: 'd',
        locale: 'x' * 11,
      );
      expect(b.toMap().containsKey('locale'), isFalse);
    });
  });

  group('SubmitRequestScreen', () {
    Widget host() => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SubmitRequestScreen(),
        );

    testWidgets('shows form and validates empty fields before sending',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('Submit a Request'), findsOneWidget);
      expect(find.text('Send request'), findsOneWidget);

      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a subject'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.pumpAndSettle();
      // error clears when the user types again
      expect(find.text('Please enter a subject'), findsNothing);

      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(find.text('Please describe your request'), findsOneWidget);
    });
  });
}
