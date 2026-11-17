// These three packages come with firebase_auth / firebase_core and are the
// ones Firebase documents for faking the plugin in tests, so they are not
// added to pubspec.yaml separately.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/services/connectivity_service.dart';
import 'package:med_remind_app/features/onboarding/onboarding_screen.dart';
import 'package:med_remind_app/main.dart';
import 'package:med_remind_app/widgets/offline_banner.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Firebase Auth that has nobody signed in and no network: just enough for
/// the app shell and the splash screen to run in a test.
class _SignedOutAuth extends FirebaseAuthPlatform
    with MockPlatformInterfaceMixin {
  _SignedOutAuth({FirebaseApp? app}) : super(appInstance: app);

  final StreamController<UserPlatform?> _changes =
      StreamController<UserPlatform?>.broadcast();

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) =>
      _SignedOutAuth(app: app);

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser => null;

  @override
  Stream<UserPlatform?> authStateChanges() async* {
    // What Firebase does: tell the listener about the current (empty) state.
    yield null;
    yield* _changes.stream;
  }

  @override
  Stream<UserPlatform?> idTokenChanges() => authStateChanges();

  @override
  Stream<UserPlatform?> userChanges() => authStateChanges();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutAuth();
  });

  testWidgets('App build hoti hai', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);

    // Let the splash finish (2 s branding delay) so no timer is left over.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('shell: MaterialApp, offline bar host, and a signed-out start '
      'goes from the splash to onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(OfflineBannerHost), findsOneWidget);

    // Nobody is signed in: after the branding delay the splash opens the
    // onboarding. (Uses the real SplashScreen.)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('shell shows the offline bar when the phone is offline', (
    WidgetTester tester,
  ) async {
    ConnectivityService.instance.status.value = ConnectionStatus.offline;
    addTearDown(
      () =>
          ConnectivityService.instance.status.value = ConnectionStatus.unknown,
    );

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
