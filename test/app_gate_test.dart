import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/app_gate.dart';
import 'package:med_remind_app/features/onboarding/app_blocked_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

void main() {
  group('AppGate.compareVersions', () {
    test('equal versions', () {
      expect(AppGate.compareVersions('1.2.3', '1.2.3'), 0);
    });

    test('numeric, not lexical, comparison', () {
      expect(AppGate.compareVersions('1.2.10', '1.2.9'), greaterThan(0));
      expect(AppGate.compareVersions('1.9.0', '1.10.0'), lessThan(0));
    });

    test('missing parts count as zero', () {
      expect(AppGate.compareVersions('1.2', '1.2.0'), 0);
      expect(AppGate.compareVersions('2', '1.9.9'), greaterThan(0));
    });

    test('ignores build suffix and pre-release tag', () {
      expect(AppGate.compareVersions('1.0.0+45', '1.0.0'), 0);
      expect(AppGate.compareVersions('1.0.0-beta', '1.0.0'), 0);
    });

    test('malformed remote value never throws', () {
      expect(AppGate.compareVersions('1.0.0', ''), greaterThan(0));
      expect(AppGate.compareVersions('1.0.0', 'abc'), greaterThan(0));
    });
  });

  group('AppGate.evaluate', () {
    test('ok when current >= min and no maintenance', () {
      expect(
        AppGate.evaluate(
            currentVersion: '1.0.0', minVersion: '1.0.0', maintenanceMode: false),
        AppGateStatus.ok,
      );
    });

    test('updateRequired when current < min', () {
      expect(
        AppGate.evaluate(
            currentVersion: '1.0.0', minVersion: '1.1.0', maintenanceMode: false),
        AppGateStatus.updateRequired,
      );
    });

    test('maintenance wins over update', () {
      expect(
        AppGate.evaluate(
            currentVersion: '1.0.0', minVersion: '9.0.0', maintenanceMode: true),
        AppGateStatus.maintenance,
      );
    });
  });

  group('AppBlockedScreen', () {
    Widget host(AppGateStatus s) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppBlockedScreen(status: s),
        );

    testWidgets('update screen shows update text and button', (tester) async {
      await tester.pumpWidget(host(AppGateStatus.updateRequired));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsOneWidget);
      expect(find.text('Update now'), findsOneWidget);
    });

    testWidgets('maintenance screen shows retry button', (tester) async {
      await tester.pumpWidget(host(AppGateStatus.maintenance));
      await tester.pumpAndSettle();
      expect(find.text('Under maintenance'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
