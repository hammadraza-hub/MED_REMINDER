import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_name_suggester.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/core/community/community_validator.dart';
import 'package:med_remind_app/features/community/community_gate_screen.dart';
import 'package:med_remind_app/features/community/community_profile_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

class FakeStore implements CommunityProfileStore {
  String? myId;
  final Map<String, CommunityProfile> profiles = {};
  final List<String> log = [];

  /// Make the next call of this kind throw.
  final Set<String> failOn = {};

  /// Simulates another phone saving an id first.
  String? raceId;

  void _maybeFail(String op) {
    if (failOn.contains(op)) throw Exception('$op failed');
  }

  @override
  Future<String?> readMyProfileId() async {
    log.add('readId');
    _maybeFail('readId');
    return myId;
  }

  @override
  Future<void> saveMyProfileId(String id) async {
    log.add('saveId');
    if (raceId != null) {
      myId = raceId;
      raceId = null;
      throw Exception('already set');
    }
    _maybeFail('saveId');
    if (myId != null) throw Exception('already set');
    myId = id;
  }

  @override
  Future<CommunityProfile?> readProfile(String id) async {
    log.add('readProfile');
    _maybeFail('readProfile');
    return profiles[id];
  }

  @override
  Future<void> createProfile(
    String id, {
    required String pseudonym,
    required String avatar,
    required String bio,
  }) async {
    log.add('create');
    _maybeFail('create');
    profiles[id] = CommunityProfile(
      id: id,
      pseudonym: pseudonym,
      avatar: avatar,
      bio: bio,
      createdAt: DateTime(2026, 11, 1),
    );
  }

  @override
  Future<void> updateProfile(
    String id, {
    required String pseudonym,
    required String avatar,
    required String bio,
  }) async {
    log.add('update');
    _maybeFail('update');
    final old = profiles[id]!;
    profiles[id] = CommunityProfile(
      id: id,
      pseudonym: pseudonym,
      avatar: avatar,
      bio: bio,
      createdAt: old.createdAt,
    );
  }
}

void main() {
  group('contact check', () {
    test('catches email, link and phone numbers', () {
      expect(CommunityValidator.containsContact('me@mail.com'), isTrue);
      expect(CommunityValidator.containsContact('see www.site.com'), isTrue);
      expect(CommunityValidator.containsContact('https://x.y'), isTrue);
      expect(CommunityValidator.containsContact('call 0300 1234567'), isTrue);
      expect(CommunityValidator.containsContact('+1 (555) 123-4567'), isTrue);
    });

    test('lets normal text through', () {
      expect(CommunityValidator.containsContact('Type 2 for 5 years'), isFalse);
      expect(CommunityValidator.containsContact('calm_river42'), isFalse);
      expect(CommunityValidator.containsContact(''), isFalse);
    });

    test('pseudonym and bio use it', () {
      expect(
        CommunityValidator.pseudonym('user03001234567'),
        CommunityInputError.containsContact,
      );
      expect(
        CommunityValidator.bio('write me a@b.com'),
        CommunityInputError.containsContact,
      );
      // characters are still reported first for a pseudonym
      expect(
        CommunityValidator.pseudonym('me@mail.com'),
        CommunityInputError.badCharacters,
      );
      expect(CommunityValidator.bio('I take metformin'), isNull);
    });
  });

  group('name suggester and avatars', () {
    test('every suggestion passes the validator', () {
      final r = Random(7);
      for (var i = 0; i < 500; i++) {
        final s = CommunityNameSuggester.suggest(r);
        expect(CommunityValidator.pseudonym(s), isNull, reason: s);
      }
    });

    test('suggestions vary', () {
      final r = Random(3);
      final set = {
        for (var i = 0; i < 50; i++) CommunityNameSuggester.suggest(r),
      };
      expect(set.length, greaterThan(20));
    });

    test('unknown avatar key falls back', () {
      expect(CommunityAvatars.safe('a5'), 'a5');
      expect(CommunityAvatars.safe('zzz'), CommunityAvatars.fallback);
      expect(CommunityAvatars.safe(null), CommunityAvatars.fallback);
      expect(CommunityAvatars.keys.length, 12);
    });
  });

  group('CommunityProfileController', () {
    late FakeStore store;
    late CommunityProfileController c;

    setUp(() {
      store = FakeStore();
      c = CommunityProfileController(store, newId: () => 'N' * 20);
    });

    test('load: no id means no profile', () async {
      expect(await c.load(), isNull);
      expect(c.profile.value, isNull);
    });

    test('create: saves the id FIRST, then the profile', () async {
      final p = await c.save(
        pseudonym: ' calm_river ',
        avatar: 'a3',
        bio: ' hi ',
      );
      expect(p.id, 'N' * 20);
      expect(p.pseudonym, 'calm_river');
      expect(p.bio, 'hi');
      expect(store.myId, 'N' * 20);
      expect(store.log.where((e) => e == 'saveId' || e == 'create').toList(), [
        'saveId',
        'create',
      ]);
      expect(store.profiles['N' * 20]!.avatar, 'a3');
      expect((await c.load())!.pseudonym, 'calm_river');
    });

    test('edit: updates, keeps the id and the created time', () async {
      await c.save(pseudonym: 'first_name', avatar: 'a1', bio: '');
      final id = store.myId;
      store.log.clear();
      final p = await c.save(pseudonym: 'second_name', avatar: 'a2', bio: 'x');
      expect(store.myId, id);
      expect(store.log, isNot(contains('saveId')));
      expect(store.log, contains('update'));
      expect(p.createdAt, DateTime(2026, 11, 1));
      expect(store.profiles[id]!.pseudonym, 'second_name');
    });

    test('bad input throws and writes nothing', () async {
      await expectLater(
        c.save(pseudonym: 'ab', avatar: 'a1', bio: ''),
        throwsA(
          isA<CommunityInputException>()
              .having((e) => e.field, 'field', CommunityField.pseudonym)
              .having((e) => e.error, 'error', CommunityInputError.tooShort),
        ),
      );
      await expectLater(
        c.save(pseudonym: 'good_name', avatar: 'a1', bio: 'mail me a@b.co'),
        throwsA(
          isA<CommunityInputException>().having(
            (e) => e.field,
            'field',
            CommunityField.bio,
          ),
        ),
      );
      expect(store.log, isEmpty);
      expect(store.myId, isNull);
    });

    test('resumes when the id was saved but the profile was not', () async {
      store.myId = 'R' * 20; // an earlier attempt stopped half way
      final p = await c.save(pseudonym: 'calm_river', avatar: 'a1', bio: '');
      expect(p.id, 'R' * 20);
      expect(store.log, isNot(contains('saveId')));
      expect(store.log, contains('create'));
    });

    test('another phone saved an id first: that id is used', () async {
      store.raceId = 'O' * 20;
      final p = await c.save(pseudonym: 'calm_river', avatar: 'a1', bio: '');
      expect(p.id, 'O' * 20);
      expect(store.profiles.keys, ['O' * 20]);
    });

    test('a store failure is passed on and the cache is unchanged', () async {
      store.failOn.add('create');
      await expectLater(
        c.save(pseudonym: 'calm_river', avatar: 'a1', bio: ''),
        throwsException,
      );
      expect(c.profile.value, isNull);
    });

    test('a blank or oversized avatar key becomes a1', () async {
      final p = await c.save(pseudonym: 'calm_river', avatar: '', bio: '');
      expect(p.avatar, 'a1');
    });

    test('load fails loudly when offline', () async {
      store.failOn.add('readId');
      await expectLater(c.load(), throwsException);
    });
  });

  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  group('screens', () {
    testWidgets('gate: no profile shows the create form and saves', (
      tester,
    ) async {
      final store = FakeStore();
      final c = CommunityProfileController(store, newId: () => 'N' * 20);
      await tester.pumpWidget(host(CommunityGateScreen(controller: c)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('community-name')), findsOneWidget);
      expect(find.text('Create your community profile'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('community-name')),
        'calm_river',
      );
      await tester.tap(find.byKey(const Key('community-avatar-a4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('community-save')));
      await tester.pumpAndSettle();

      expect(store.profiles['N' * 20]!.pseudonym, 'calm_river');
      expect(store.profiles['N' * 20]!.avatar, 'a4');
      expect(find.byKey(const Key('community-profile-name')), findsOneWidget);
      expect(find.text('calm_river'), findsOneWidget);
    });

    testWidgets('form shows a clear message and does not save', (tester) async {
      final store = FakeStore();
      final c = CommunityProfileController(store);
      await tester.pumpWidget(host(CommunityProfileScreen(controller: c)));

      await tester.tap(find.byKey(const Key('community-save')));
      await tester.pump();
      expect(find.text('Please enter a name.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('community-name')), 'ab');
      await tester.tap(find.byKey(const Key('community-save')));
      await tester.pump();
      expect(find.text('Use at least 3 characters.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('community-name')),
        'user03001234567',
      );
      await tester.tap(find.byKey(const Key('community-save')));
      await tester.pump();
      expect(
        find.text('Please do not include an email, phone number or web link.'),
        findsOneWidget,
      );
      expect(store.log, isEmpty);
    });

    testWidgets('suggest button fills a valid name', (tester) async {
      final c = CommunityProfileController(FakeStore());
      await tester.pumpWidget(host(CommunityProfileScreen(controller: c)));
      await tester.ensureVisible(find.byKey(const Key('community-suggest')));
      await tester.tap(find.byKey(const Key('community-suggest')));
      await tester.pump();
      final text = tester
          .widget<TextField>(find.byKey(const Key('community-name')))
          .controller!
          .text;
      expect(CommunityValidator.pseudonym(text), isNull);
    });

    testWidgets('a save failure shows a message and the form stays', (
      tester,
    ) async {
      final store = FakeStore()..failOn.add('create');
      final c = CommunityProfileController(store, newId: () => 'N' * 20);
      await tester.pumpWidget(host(CommunityProfileScreen(controller: c)));
      await tester.enterText(
        find.byKey(const Key('community-name')),
        'calm_river',
      );
      await tester.tap(find.byKey(const Key('community-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(find.byKey(const Key('community-save')), findsOneWidget);
    });

    testWidgets('gate: existing profile is shown and can be edited', (
      tester,
    ) async {
      final store = FakeStore()
        ..myId = 'E' * 20
        ..profiles['E' * 20] = CommunityProfile(
          id: 'E' * 20,
          pseudonym: 'old_name',
          avatar: 'a2',
          bio: 'my bio',
          createdAt: DateTime(2026, 11, 1),
        );
      final c = CommunityProfileController(store);
      await tester.pumpWidget(host(CommunityGateScreen(controller: c)));
      await tester.pumpAndSettle();
      expect(find.text('old_name'), findsOneWidget);
      expect(find.text('my bio'), findsOneWidget);

      await tester.tap(find.byKey(const Key('community-edit')));
      await tester.pumpAndSettle();
      expect(find.text('Edit profile'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('community-name')),
        'new_name',
      );
      await tester.tap(find.byKey(const Key('community-save')));
      await tester.pumpAndSettle();

      expect(find.text('new_name'), findsOneWidget);
      expect(find.text('Profile saved'), findsOneWidget);
      expect(store.profiles['E' * 20]!.createdAt, DateTime(2026, 11, 1));
    });

    testWidgets('gate: offline shows try again, which then works', (
      tester,
    ) async {
      final store = FakeStore()..failOn.add('readId');
      final c = CommunityProfileController(store);
      await tester.pumpWidget(host(CommunityGateScreen(controller: c)));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not open the community'),
        findsOneWidget,
      );

      store.failOn.clear();
      await tester.tap(find.byKey(const Key('community-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('community-name')), findsOneWidget);
    });
  });
}
