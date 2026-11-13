import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/legal_gate.dart';
import 'package:med_remind_app/features/onboarding/legal_reconsent_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

void main() {
  group('LegalGate.needsAcceptance', () {
    bool needs({
      String? t,
      String? p,
      String rt = '1.0',
      String rp = '1.0',
    }) =>
        LegalGate.needsAcceptance(
          acceptedTerms: t,
          acceptedPrivacy: p,
          requiredTerms: rt,
          requiredPrivacy: rp,
        );

    test('up to date -> no prompt', () {
      expect(needs(t: '1.0', p: '1.0'), isFalse);
    });

    test('newer than required -> no prompt', () {
      expect(needs(t: '2.0', p: '1.5'), isFalse);
    });

    test('terms outdated -> prompt', () {
      expect(needs(t: '1.0', p: '1.0', rt: '1.1'), isTrue);
    });

    test('privacy outdated -> prompt', () {
      expect(needs(t: '1.0', p: '1.0', rp: '2.0'), isTrue);
    });

    test('numeric not lexical: 1.10 is newer than 1.9', () {
      expect(needs(t: '1.9', p: '1.9', rt: '1.10', rp: '1.10'), isTrue);
      expect(needs(t: '1.10', p: '1.10', rt: '1.9', rp: '1.9'), isFalse);
    });

    test('legacy user with no record -> prompt once', () {
      expect(needs(t: null, p: null), isTrue);
      expect(needs(t: '', p: '1.0'), isTrue);
    });

    test('blank required version is ignored (fail open)', () {
      expect(needs(t: null, p: null, rt: '', rp: '  '), isFalse);
    });
  });

  group('LegalReconsentScreen', () {
    Widget host() => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LegalReconsentScreen(
            uid: 'u1',
            next: (_) => const Scaffold(body: Text('dashboard')),
          ),
        );

    testWidgets('shows text and Accept is disabled until agreed',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text("We've updated our terms"), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      final accept = find.widgetWithText(ElevatedButton, 'Accept and continue');
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNotNull);
    });

    testWidgets('has a sign out action', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
