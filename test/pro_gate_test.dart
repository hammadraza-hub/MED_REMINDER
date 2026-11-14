import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/subscription/pro_gate.dart';

ProGate gate({
  String? uid = 'me',
  Map<String, bool> pro = const {},
  String? owner = 'me',
  bool debug = false,
  bool throwOnPlan = false,
  bool throwOnOwner = false,
}) => ProGate(
  currentUid: () => uid,
  hasPremiumAccess: (u) async {
    if (throwOnPlan) throw Exception('offline');
    return pro[u] ?? false;
  },
  profileOwnerUid: (p) async {
    if (throwOnOwner) throw Exception('offline');
    return owner;
  },
  debugUnlock: debug,
);

void main() {
  test('own profile: Pro can write, free cannot', () async {
    expect(await gate(pro: {'me': true}).canWrite('p'), isTrue);
    expect(await gate(pro: {'me': false}).canWrite('p'), isFalse);
    expect(await gate().canWrite('p'), isFalse); // no record at all
  });

  test('signed out is never Pro', () async {
    expect(await gate(uid: null, pro: {'me': true}).canWrite('p'), isFalse);
    expect(await gate(uid: null).isPro(), isFalse);
  });

  test('a failing plan check fails closed', () async {
    expect(
      await gate(pro: {'me': true}, throwOnPlan: true).canWrite('p'),
      isFalse,
    );
    expect(await gate(pro: {'me': true}, throwOnPlan: true).isPro(), isFalse);
  });

  test(
    "someone else's profile: the server decides, so the screen lets it through",
    () async {
      expect(await gate(owner: 'other').canWrite('p'), isTrue);
      expect(
        await gate(owner: 'other', pro: {'me': true}).canWrite('p'),
        isTrue,
      );
    },
  );

  test(
    'if the owner cannot be read we fall back to the user\'s own plan',
    () async {
      expect(
        await gate(throwOnOwner: true, pro: {'me': true}).canWrite('p'),
        isTrue,
      );
      expect(await gate(throwOnOwner: true).canWrite('p'), isFalse);
      expect(await gate(owner: null).canWrite('p'), isFalse);
    },
  );

  test('debug unlock skips every check', () async {
    expect(await gate(debug: true, uid: null).canWrite('p'), isTrue);
    expect(await gate(debug: true, uid: null).isPro(), isTrue);
  });
}
