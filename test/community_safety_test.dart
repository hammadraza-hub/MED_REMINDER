import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/community/community_content_filter.dart';
import 'package:med_remind_app/core/community/community_feed.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_posts.dart';
import 'package:med_remind_app/core/community/community_reactions.dart';
import 'package:med_remind_app/core/community/community_safety.dart';
import 'package:med_remind_app/core/community/community_validator.dart';
import 'package:med_remind_app/features/community/community_blocked_screen.dart';
import 'package:med_remind_app/features/community/community_compose_screen.dart';
import 'package:med_remind_app/features/community/community_group_screen.dart';
import 'package:med_remind_app/features/community/community_post_screen.dart';
import 'package:med_remind_app/features/community/community_safety_ui.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

import 'community_posts_test.dart' as p;
import 'community_reactions_test.dart' as r;

const me = p.me;
const other = p.other;
const third = 'TH000000000000000003';

class FakeReports implements CommunityReportStore {
  final Map<String, Map<String, dynamic>> created = {};
  bool deny = false;
  bool fail = false;

  @override
  Future<void> create(String id, Map<String, dynamic> data) async {
    if (deny || created.containsKey(id)) throw const CommunityDeniedException();
    if (fail) throw Exception('offline');
    created[id] = data;
  }
}

class FakeBlocks implements CommunityBlockStore {
  final Set<String> ids = {};
  final List<String> log = [];
  bool fail = false;
  bool failLoad = false;

  @override
  Future<Set<String>> all() async {
    if (failLoad) throw Exception('offline');
    return {...ids};
  }

  @override
  Future<void> block(String cpid) async {
    log.add('block:$cpid');
    if (fail) throw Exception('offline');
    ids.add(cpid);
  }

  @override
  Future<void> unblock(String cpid) async {
    log.add('unblock:$cpid');
    if (fail) throw Exception('offline');
    ids.remove(cpid);
  }
}

/// Pumps a little instead of settling: while a warning dialog is open the
/// screen's save spinner keeps animating, so `pumpAndSettle` would never end.
Future<void> pumpSome(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('CommunityContentFilter', () {
    CommunityVerdict v(String t) => CommunityContentFilter.check(t);

    test('normal text is fine', () {
      for (final t in [
        'My sugar was 120 this morning, feeling good.',
        'Does anyone use a pill organiser?',
        'I take metformin with dinner.',
        'My class starts at nine and the assistant is kind.',
        'Scunthorpe is a town.',
        'We need to kill time before the appointment.',
        'I want to diet and walk more.',
        'My doctor said to double check the dose.',
        'I stopped taking it after my doctor said so.',
        'Blood pressure 140/90, pulse 72, sugar 130 and 150 and 160',
        '',
      ]) {
        expect(v(t), CommunityVerdict.ok, reason: t);
      }
    });

    test('abuse is refused (also with letter swaps and repeats)', () {
      for (final t in [
        'you are a bitch',
        'what a sh1t advice',
        'fuuuuck this',
        'tum harami ho',
        'KUTTA',
        'kill yourself',
        'go die',
        'kys',
        'आप हरामी हैं',
      ]) {
        expect(v(t), CommunityVerdict.abusive, reason: t);
      }
    });

    test('e-mail addresses and links are refused', () {
      expect(v('write to me at a.b@mail.com'), CommunityVerdict.contact);
      expect(v('see https://example.org/x'), CommunityVerdict.contact);
      expect(v('visit www.shop.pk now'), CommunityVerdict.contact);
      expect(v('visit mysite.com'), CommunityVerdict.contact);
    });

    test('self-harm wording gets the caring message', () {
      for (final t in [
        'I want to die',
        'i want to kill myself',
        'thinking about suicide',
        'I do not want to live anymore',
        "don't want to be alive",
        'i keep hurting myself',
        'khudkushi ka khayal aata hai',
        'आत्महत्या',
        'خودکشی',
        'me quiero morir',
      ]) {
        expect(v(t), CommunityVerdict.selfHarm, reason: t);
      }
    });

    test('risky medicine advice gets a warning', () {
      for (final t in [
        'Just stop taking your insulin',
        'you can skip your medication',
        'double your dose if it hurts',
        'you do not need a doctor for this',
        "don't see a doctor",
        'use this instead of your medicine',
        'this cures diabetes',
        'dawai band kar do',
      ]) {
        expect(v(t), CommunityVerdict.medicalWarning, reason: t);
      }
    });

    test('the most serious finding wins', () {
      expect(v('you bitch, go die'), CommunityVerdict.abusive);
      expect(v('i want to die, mail me a@b.co'), CommunityVerdict.contact);
      expect(
        v('i want to die, so stop taking your insulin'),
        CommunityVerdict.selfHarm,
      );
    });

    test('names and bios: abuse is not allowed', () {
      expect(
        CommunityValidator.pseudonym('bitch_slap'),
        CommunityInputError.inappropriate,
      );
      expect(
        CommunityValidator.bio('I am a harami'),
        CommunityInputError.inappropriate,
      );
      expect(CommunityValidator.pseudonym('calm_river42'), isNull);
      expect(CommunityValidator.bio('Type 2, five years in.'), isNull);
    });
  });

  group('CommunityPostActions + filter', () {
    late p.FakePostStore store;
    late CommunityPostActions actions;

    setUp(() {
      store = p.FakePostStore();
      actions = CommunityPostActions(store, () async => me);
    });

    test('abuse and contact details are never sent', () async {
      await expectLater(
        actions.createPost('g1', 'you bitch'),
        throwsA(
          isA<CommunityContentException>().having(
            (e) => e.verdict,
            'verdict',
            CommunityVerdict.abusive,
          ),
        ),
      );
      await expectLater(
        actions.createComment('g1', 'p1', 'mail me a@b.co'),
        throwsA(
          isA<CommunityContentException>().having(
            (e) => e.verdict,
            'verdict',
            CommunityVerdict.contact,
          ),
        ),
      );
      // even "confirmed" does not let abuse through
      await expectLater(
        actions.createPost('g1', 'you bitch', confirmed: true),
        throwsA(isA<CommunityContentException>()),
      );
      expect(store.log, isEmpty);
    });

    test('self-harm / medical need a yes first, then go through', () async {
      await expectLater(
        actions.createPost('g1', 'I want to die'),
        throwsA(
          isA<CommunityNeedsConfirmException>().having(
            (e) => e.verdict,
            'verdict',
            CommunityVerdict.selfHarm,
          ),
        ),
      );
      expect(store.log, isEmpty);
      await actions.createPost('g1', 'I want to die', confirmed: true);
      expect(store.log.single, 'createPost:$me:I want to die');

      await expectLater(
        actions.createComment('g1', 'p1', 'just stop taking your insulin'),
        throwsA(isA<CommunityNeedsConfirmException>()),
      );
      await actions.createComment(
        'g1',
        'p1',
        'just stop taking your insulin',
        confirmed: true,
      );
      expect(store.log.length, 2);
    });

    test('edits are checked too', () async {
      final post = p.postOf('p1', me);
      store.posts['g1/p1'] = post;
      await expectLater(
        actions.editPost(post, 'you bitch'),
        throwsA(isA<CommunityContentException>()),
      );
      await expectLater(
        actions.editComment('g1', 'p1', p.commentOf(1, me), 'go die'),
        throwsA(isA<CommunityContentException>()),
      );
      expect(store.log, isEmpty);
    });
  });

  group('CommunityReportActions', () {
    test('report shape: community id, no uid or name; fixed id', () async {
      final store = FakeReports();
      final a = CommunityReportActions(store, () async => me);
      await a.report(
        groupId: 'g1',
        postId: 'p1',
        reason: CommunityReportReason.spam,
      );
      await a.report(
        groupId: 'g1',
        postId: 'p1',
        commentId: 'c1',
        reason: CommunityReportReason.abuse,
      );
      expect(store.created.keys.toSet(), {'${me}_p1', '${me}_p1_c1'});
      final post = store.created['${me}_p1']!;
      expect(post['reporterId'], me);
      expect(post['targetType'], 'post');
      expect(post['reason'], 'spam');
      expect(post.containsKey('commentId'), isFalse);
      final comment = store.created['${me}_p1_c1']!;
      expect(comment['targetType'], 'comment');
      expect(comment['commentId'], 'c1');
      for (final m in [post, comment]) {
        for (final k in m.keys) {
          expect(k.toLowerCase(), isNot(contains('uid')));
          expect(k.toLowerCase(), isNot(contains('email')));
        }
      }
    });

    test('the same thing twice is refused by the store', () async {
      final store = FakeReports();
      final a = CommunityReportActions(store, () async => me);
      await a.report(
        groupId: 'g1',
        postId: 'p1',
        reason: CommunityReportReason.spam,
      );
      await expectLater(
        a.report(
          groupId: 'g1',
          postId: 'p1',
          reason: CommunityReportReason.other,
        ),
        throwsA(isA<CommunityDeniedException>()),
      );
    });

    test('no profile: nothing is sent', () async {
      final store = FakeReports();
      final a = CommunityReportActions(store, () async => null);
      await expectLater(
        a.report(
          groupId: 'g1',
          postId: 'p1',
          reason: CommunityReportReason.spam,
        ),
        throwsA(isA<CommunityNoProfileException>()),
      );
      expect(store.created, isEmpty);
    });
  });

  group('CommunityBlocksController', () {
    late FakeBlocks store;
    late CommunityBlocksController c;

    setUp(() {
      store = FakeBlocks();
      c = CommunityBlocksController(store, () async => me);
    });

    test('load, block, unblock', () async {
      store.ids.add(other);
      await c.load();
      expect(c.isBlocked(other), isTrue);
      await c.block(third);
      expect(c.ids, {other, third});
      expect(store.ids, {other, third});
      await c.unblock(other);
      expect(c.ids, {third});
    });

    test('you cannot block yourself, and no profile cannot block', () async {
      await c.block(me);
      expect(store.log, isEmpty);
      final none = CommunityBlocksController(store, () async => null);
      await expectLater(
        none.block(other),
        throwsA(isA<CommunityNoProfileException>()),
      );
    });

    test('a failed block changes nothing', () async {
      store.fail = true;
      await expectLater(c.block(other), throwsException);
      expect(c.ids, isEmpty);
    });

    test('a failed load keeps the old list; reset clears it', () async {
      store.ids.add(other);
      await c.load();
      store.failLoad = true;
      await c.load();
      expect(c.ids, {other});
      c.reset();
      expect(c.ids, isEmpty);
      expect(c.isLoaded, isFalse);
    });

    test('people() adds the profiles (null for a deleted account)', () async {
      store.ids.addAll({other, 'GONE'});
      await c.load();
      final people = await c.people(p.FakeProfiles());
      expect(people.length, 2);
      expect(
        people.firstWhere((x) => x.id == other).profile!.pseudonym,
        'other_person',
      );
      expect(people.firstWhere((x) => x.id == 'GONE').profile, isNull);
    });
  });

  group('lists hide blocked people', () {
    test('feed: hidden, shows again after unblock, loads on when a page is all blocked', () async {
      final blocked = <String>{};
      final store = _PagedFeed()
        ..all = [
          for (var i = 1; i <= 25; i++)
            p.postOf('p$i', i <= 20 ? other : third),
        ];
      final c = CommunityFeedController(
        store,
        'g1',
        pageSize: 20,
        blocked: () => blocked,
      );
      await c.refresh();
      expect(c.items.length, 20);
      blocked.add(other);
      expect(c.items, isEmpty);
      blocked.clear();
      expect(c.items.length, 20);

      // block before loading: the first page (20 posts) is all hidden, so the
      // next page is fetched by itself
      blocked.add(other);
      final c2 = CommunityFeedController(
        store,
        'g1',
        pageSize: 20,
        blocked: () => blocked,
      );
      await c2.refresh();
      expect(c2.items.map((i) => i.post.authorId).toSet(), {third});
      expect(c2.items.length, 5);
      c.dispose();
      c2.dispose();
    });

    test('comments: hidden for blocked authors', () async {
      final blocked = <String>{other};
      final store = p.FakePostStore();
      store.commentMap['g1/p1'] = [
        p.commentOf(1, me),
        p.commentOf(2, other),
        p.commentOf(3, me),
      ];
      final c = CommunityCommentsController(
        store,
        p.FakeProfiles(),
        'g1',
        'p1',
        blocked: () => blocked,
      );
      await c.refresh();
      expect(c.items.map((i) => i.comment.id), ['c1', 'c3']);
      blocked.clear();
      expect(c.items.length, 3);
      c.dispose();
    });

    test('saved list: hidden for blocked authors, gone posts stay', () async {
      final blocked = <String>{other};
      final saves = r.FakeSaves();
      final posts = r.FakePosts();
      posts.posts['g1/a'] = r.postOf('a', other);
      posts.posts['g1/b'] = r.postOf('b', third);
      for (final id in ['a', 'b', 'gone']) {
        saves.saved[id] = CommunityBookmark(
          postId: id,
          groupId: 'g1',
          createdAt: DateTime(2026, 11, 1, 0, id.length + id.codeUnitAt(0)),
        );
      }
      final c = CommunitySavedController(
        saves,
        posts,
        r.FakeFeed(),
        blocked: () => blocked,
      );
      await c.refresh();
      expect(c.entries.map((e) => e.bookmark.postId).toSet(), {'b', 'gone'});
      c.dispose();
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

  CommunitySafety safetyWith(FakeReports reports, FakeBlocks blocks) =>
      CommunitySafety(
        reports: CommunityReportActions(reports, () async => me),
        blocks: CommunityBlocksController(blocks, () async => me),
      );

  group('menu: report and block', () {
    Widget menuHost(CommunitySafety safety, {String? commentId}) => host(
      Scaffold(
        body: Center(
          child: CommunitySafetyMenu(
            key: const Key('the-menu'),
            safety: safety,
            groupId: 'g1',
            postId: 'p1',
            commentId: commentId,
            authorId: other,
            authorName: 'other_person',
          ),
        ),
      ),
    );

    testWidgets('report a post: choose a reason, send, thanks', (tester) async {
      final reports = FakeReports();
      await tester.pumpWidget(menuHost(safetyWith(reports, FakeBlocks())));
      await tester.tap(find.byKey(const Key('the-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-report')));
      await tester.pumpAndSettle();
      expect(find.text('Report this'), findsOneWidget);
      await tester.tap(find.byKey(const Key('reason-medical')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pumpAndSettle();

      expect(reports.created['${me}_p1']!['reason'], 'medical');
      expect(find.text('Thank you. We will look at it.'), findsOneWidget);
    });

    testWidgets('report a comment, and cancelling sends nothing', (
      tester,
    ) async {
      final reports = FakeReports();
      await tester.pumpWidget(
        menuHost(safetyWith(reports, FakeBlocks()), commentId: 'c9'),
      );
      await tester.tap(find.byKey(const Key('the-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-report')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(reports.created, isEmpty);

      await tester.tap(find.byKey(const Key('the-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-report')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pumpAndSettle();
      expect(reports.created.keys.single, '${me}_p1_c9');
    });

    testWidgets('reporting twice shows the "already" message', (tester) async {
      final reports = FakeReports()..deny = true;
      await tester.pumpWidget(menuHost(safetyWith(reports, FakeBlocks())));
      await tester.tap(find.byKey(const Key('the-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-report')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pumpAndSettle();
      expect(
        find.text('This could not be sent. You may have reported it already.'),
        findsOneWidget,
      );
    });

    testWidgets('block: confirm asks by name, then blocks', (tester) async {
      final blocks = FakeBlocks();
      await tester.pumpWidget(menuHost(safetyWith(FakeReports(), blocks)));
      await tester.tap(find.byKey(const Key('the-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-block')));
      await tester.pumpAndSettle();
      expect(find.text('Block other_person?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('block-cancel')));
      await tester.pumpAndSettle();
      expect(blocks.log, isEmpty);

      await tester.tap(find.byKey(const Key('the-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-block')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('block-confirm')));
      await tester.pumpAndSettle();
      expect(blocks.log.single, 'block:$other');
      expect(find.text('Blocked.'), findsOneWidget);
    });

    testWidgets('a failed block shows a message', (tester) async {
      final blocks = FakeBlocks()..fail = true;
      await tester.pumpWidget(menuHost(safetyWith(FakeReports(), blocks)));
      await tester.tap(find.byKey(const Key('the-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-block')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('block-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Could not block. Please try again.'), findsOneWidget);
    });
  });

  group('warnings before posting', () {
    testWidgets('self-harm: caring message; "Post anyway" posts', (
      tester,
    ) async {
      final store = p.FakePostStore();
      final actions = CommunityPostActions(store, () async => me);
      await tester.pumpWidget(
        host(CommunityComposeScreen(groupId: 'g1', actions: actions)),
      );
      await tester.enterText(
        find.byKey(const Key('compose-text')),
        'I want to die',
      );
      await tester.tap(find.byKey(const Key('compose-save')));
      await pumpSome(tester);
      expect(find.byKey(const Key('warning-self-harm')), findsOneWidget);
      expect(find.text('You are not alone'), findsOneWidget);
      expect(store.log, isEmpty);

      await tester.tap(find.byKey(const Key('warning-back')));
      await pumpSome(tester);
      expect(store.log, isEmpty);
      expect(find.byKey(const Key('compose-save')), findsOneWidget);

      await tester.tap(find.byKey(const Key('compose-save')));
      await pumpSome(tester);
      await tester.tap(find.byKey(const Key('warning-post')));
      // the compose screen is the root route here, so it cannot close and
      // its spinner keeps running: pump a little instead of settling
      expect(store.log.single, 'createPost:$me:I want to die');
    });

    testWidgets('medical: warning; "Post anyway" posts', (tester) async {
      final store = p.FakePostStore();
      final actions = CommunityPostActions(store, () async => me);
      await tester.pumpWidget(
        host(CommunityComposeScreen(groupId: 'g1', actions: actions)),
      );
      await tester.enterText(
        find.byKey(const Key('compose-text')),
        'just stop taking your insulin',
      );
      await tester.tap(find.byKey(const Key('compose-save')));
      await pumpSome(tester);
      expect(find.byKey(const Key('warning-medical')), findsOneWidget);
      await tester.tap(find.byKey(const Key('warning-post')));
      expect(store.log.single, startsWith('createPost:$me:'));
    });

    testWidgets('abuse: refused with a message, nothing sent', (tester) async {
      final store = p.FakePostStore();
      final actions = CommunityPostActions(store, () async => me);
      await tester.pumpWidget(
        host(CommunityComposeScreen(groupId: 'g1', actions: actions)),
      );
      await tester.enterText(
        find.byKey(const Key('compose-text')),
        'you bitch',
      );
      await tester.tap(find.byKey(const Key('compose-save')));
      await pumpSome(tester);
      expect(
        find.text('Please keep it kind. This wording is not allowed.'),
        findsOneWidget,
      );
      expect(store.log, isEmpty);
    });

    testWidgets('a link in a post is refused with its own message', (
      tester,
    ) async {
      final store = p.FakePostStore();
      final actions = CommunityPostActions(store, () async => me);
      await tester.pumpWidget(
        host(CommunityComposeScreen(groupId: 'g1', actions: actions)),
      );
      await tester.enterText(
        find.byKey(const Key('compose-text')),
        'see www.x.com',
      );
      await tester.tap(find.byKey(const Key('compose-save')));
      await pumpSome(tester);
      expect(
        find.text('Please do not share e-mail addresses or links.'),
        findsOneWidget,
      );
    });

    testWidgets('comment with a warning: asks, then sends', (tester) async {
      final store = p.FakePostStore();
      final post = p.postOf('p1', other);
      store.posts['g1/p1'] = post;
      final feed = p.FakeProfiles();
      await tester.pumpWidget(
        host(
          CommunityPostScreen(
            item: CommunityFeedItem(post, feed.map[other]),
            feedStore: feed,
            postStore: store,
            actions: CommunityPostActions(store, () async => me),
            myId: me,
            reactions: CommunityReactionsController(
              r.FakeVotes(),
              r.FakeSaves(),
              () async => me,
            ),
            safety: safetyWith(FakeReports(), FakeBlocks()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('comment-input')),
        'stop taking it, double your dose',
      );
      await tester.tap(find.byKey(const Key('comment-send')));
      await pumpSome(tester);
      expect(find.byKey(const Key('warning-medical')), findsOneWidget);
      expect(store.log, isEmpty);
      await tester.tap(find.byKey(const Key('warning-post')));
      await pumpSome(tester);
      expect(store.log.single, startsWith('createComment:$me:'));
    });
  });

  group('blocked screen', () {
    testWidgets('lists blocked people and unblocks', (tester) async {
      final blocks = FakeBlocks()..ids.addAll({other, 'GONE'});
      final safety = safetyWith(FakeReports(), blocks);
      await tester.pumpWidget(
        host(
          CommunityBlockedScreen(safety: safety, feedStore: p.FakeProfiles()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Blocked people'), findsOneWidget);
      expect(find.text('other_person'), findsOneWidget);
      expect(find.text('[deleted]'), findsOneWidget);

      await tester.tap(find.byKey(Key('unblock-$other')));
      await tester.pumpAndSettle();
      expect(blocks.log.last, 'unblock:$other');
      expect(find.text('other_person'), findsNothing);
    });

    testWidgets('empty state', (tester) async {
      await tester.pumpWidget(
        host(
          CommunityBlockedScreen(
            safety: safetyWith(FakeReports(), FakeBlocks()),
            feedStore: p.FakeProfiles(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('blocked-empty')), findsOneWidget);
    });
  });

  group('feed: block removes posts at once', () {
    testWidgets(
      'report / block menu only on other people\'s posts; blocking hides them',
      (tester) async {
        final feed = _PagedFeed()
          ..all = [p.postOf('mine', me), p.postOf('theirs', other)];
        final blocks = FakeBlocks();
        final safety = safetyWith(FakeReports(), blocks);
        final votes = r.FakeVotes();
        final saves = r.FakeSaves();
        await tester.pumpWidget(
          host(
            CommunityGroupScreen(
              group: const CommunityGroup(
                id: 'g1',
                name: 'Diabetes',
                description: '',
                order: 1,
              ),
              store: feed,
              postStore: p.FakePostStore(),
              reactions: CommunityReactionsController(
                votes,
                saves,
                () async => me,
              ),
              safety: safety,
              myId: me,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('post-mine')), findsOneWidget);
        expect(find.byKey(const Key('post-theirs')), findsOneWidget);
        expect(find.byKey(const Key('safety-mine')), findsNothing);
        expect(find.byKey(const Key('safety-theirs')), findsOneWidget);

        await tester.tap(find.byKey(const Key('safety-theirs')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('menu-block')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('block-confirm')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('post-theirs')), findsNothing);
        expect(find.byKey(const Key('post-mine')), findsOneWidget);
      },
    );
  });
}

class _PagedFeed extends p.FakeProfiles {
  List<CommunityFeedPost> all = [];

  @override
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  }) async {
    final start = after is int ? after : 0;
    final slice = all.skip(start).take(limit).toList();
    return CommunityFeedPage(
      slice,
      start + slice.length,
      hasMore: slice.length >= limit,
    );
  }
}
