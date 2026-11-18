// M22 follow-up — the in-app permission helper on a real Android runtime:
// the native channel (manufacturer, battery saving) and the plugin checks.
//
// Run: flutter test integration_test/reminder_permissions_test.dart -d emulator-5554
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_remind_app/core/services/reminder_permission_service.dart';
import 'package:med_remind_app/core/services/reminder_scheduler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('check() reads every permission from the phone', (t) async {
    await ReminderScheduler.instance.init();
    final r = await ReminderPermissionService.instance.check();
    debugPrint(
      'READINESS notif=${r.notifications} exact=${r.exactAlarms} '
      'battery=${r.batteryUnrestricted} maker=${r.manufacturer} '
      'missing=${r.missing.map((e) => e.name).toList()}',
    );
    expect(r.manufacturer, isNotEmpty, reason: 'the native channel answered');
    expect(r.missing.length, lessThanOrEqualTo(4));
  });
}
