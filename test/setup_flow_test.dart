import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/setup_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'an account with no mark (an existing user) is not sent to setup',
    () async {
      expect(await SetupFlow.isPending('old-user'), isFalse);
    },
  );

  test('a new account is pending until the setup is finished', () async {
    await SetupFlow.markPending('u1');
    expect(await SetupFlow.isPending('u1'), isTrue);
    expect(
      await SetupFlow.isPending('u1'),
      isTrue,
      reason: 'survives a re-open',
    );
    await SetupFlow.clear('u1');
    expect(await SetupFlow.isPending('u1'), isFalse);
  });

  test('the mark belongs to one account only', () async {
    await SetupFlow.markPending('u1');
    expect(await SetupFlow.isPending('u2'), isFalse);
    await SetupFlow.clear('u2');
    expect(await SetupFlow.isPending('u1'), isTrue);
  });
}
