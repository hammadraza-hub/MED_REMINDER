import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/community/community_feed.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_time.dart';
import 'package:med_remind_app/features/community/community_group_screen.dart';
import 'package:med_remind_app/features/community/community_groups_list.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

class FakeFeedStore implements CommunityFeedStore {
  List<CommunityGroup> groupList = const [];
  final List<CommunityFeedPost> all = [];
  final Map<String, CommunityProfile> profileMap = {};
  final List<Set<String>> profileCalls = [];
  int postCalls = 0;
  bool failGroups = false;
  bool failPosts = false;
  bool failProfiles = false;

  /// Fail only calls that have a cursor (load more).
  bool failNext = false;
  Completer<void>? gate;

  @override
  Future<List<CommunityGroup>> groups() async {
    if (failGroups) throw Exception('offline');
    return groupList;
  }

  @override
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  }) async {
    postCalls++;
    if (gate != null) await gate!.future;
    if (failPosts || (failNext && after != null)) throw Exception('offline');
    final sorted = all.where((p) => p.groupId == groupId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final start = after is int ? after : 0;
    final slice = sorted.skip(start).take(limit).toList();
    return CommunityFeedPage(
      slice,
      start + slice.length,
      hasMore: slice.length >= limit,
    );
  }

  @override
  Future<Map<String, CommunityProfile>> profiles(Set<String> ids) async {
    profileCalls.add(ids);
    if (failProfiles) throw Exception('offline');
    return {
      for (final id in ids)
        if (profileMap.containsKey(id)) id: profileMap[id]!,
    };
  }
}

CommunityFeedPost post(
  int i, {
  String group = 'g1',
  String author = 'A',
  bool hidden = false,
  DateTime? at,
  DateTime? edited,
  int votes = 0,
}) => CommunityFeedPost(
  id: 'p$i',
  groupId: group,
  authorId: author,
  body: 'body $i',
  createdAt: at ?? DateTime(2026, 11, 1).add(Duration(minutes: i)),
  editedAt: edited,
  voteCount: votes,
  hidden: hidden,
);

CommunityProfile profile(String id, String name) => CommunityProfile(
  id: id,
  pseudonym: name,
  avatar: 'a1',
  bio: '',
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  group('CommunityTime.ago', () {
    final now = DateTime(2026, 11, 16, 12);
    test('units', () {
      expect(
        CommunityTime.ago(now.subtract(const Duration(seconds: 30)), now),
        const CommunityAgo(CommunityAgoUnit.justNow),
      );
      expect(
        CommunityTime.ago(now.subtract(const Duration(minutes: 5)), now),
        const CommunityAgo(CommunityAgoUnit.minutes, 5),
      );
      expect(
        CommunityTime.ago(now.subtract(const Duration(minutes: 59)), now),
        const CommunityAgo(CommunityAgoUnit.minutes, 59),
      );
      expect(
        CommunityTime.ago(now.subtract(const Duration(minutes: 60)), now),
        const CommunityAgo(CommunityAgoUnit.hours, 1),
      );
      expect(
        CommunityTime.ago(now.subtract(const Duration(hours: 23)), now),
        const CommunityAgo(CommunityAgoUnit.hours, 23),
      );
      expect(
        CommunityTime.ago(now.subtract(const Duration(hours: 24)), now),
        const CommunityAgo(CommunityAgoUnit.days, 1),
      );
      expect(
        CommunityTime.ago(now.subtract(const Duration(days: 6)), now),
        const CommunityAgo(CommunityAgoUnit.days, 6),
      );
      expect(
        CommunityTime.ago(now.subtract(const Duration(days: 7)), now),
        const CommunityAgo(CommunityAgoUnit.date),
      );
    });

    test('a time in the future counts as just now', () {
      expect(
        CommunityTime.ago(now.add(const Duration(minutes: 3)), now),
        const CommunityAgo(CommunityAgoUnit.justNow),
      );
    });
  });

  group('CommunityFeedController', () {
    late FakeFeedStore store;

    setUp(() {
      store = FakeFeedStore()
        ..profileMap['A'] = profile('A', 'calm_river')
        ..profileMap['B'] = profile('B', 'brave_otter');
    });

    test('first page: newest first, with authors', () async {
      for (var i = 1; i <= 3; i++) {
        store.all.add(post(i, author: i.isEven ? 'B' : 'A'));
      }
      final c = CommunityFeedController(store, 'g1', pageSize: 20);
      expect(c.status, CommunityFeedStatus.loading);
      await c.refresh();
      expect(c.status, CommunityFeedStatus.ready);
      expect(c.items.map((i) => i.post.id), ['p3', 'p2', 'p1']);
      expect(c.items.first.author!.pseudonym, 'calm_river');
      expect(c.hasMore, isFalse);
      c.dispose();
    });

    test('paging: 25 posts = 20 + 5, no duplicates', () async {
      for (var i = 1; i <= 25; i++) {
        store.all.add(post(i));
      }
      final c = CommunityFeedController(store, 'g1', pageSize: 20);
      await c.refresh();
      expect(c.items.length, 20);
      expect(c.hasMore, isTrue);
      await c.loadMore();
      expect(c.items.length, 25);
      expect(c.hasMore, isFalse);
      expect(c.items.map((i) => i.post.id).toSet().length, 25);
      // at the end, nothing more is asked
      final calls = store.postCalls;
      await c.loadMore();
      expect(store.postCalls, calls);
      c.dispose();
    });

    test('an author is looked up only once, even across pages', () async {
      for (var i = 1; i <= 25; i++) {
        store.all.add(post(i));
      }
      final c = CommunityFeedController(store, 'g1', pageSize: 20);
      await c.refresh();
      await c.loadMore();
      expect(store.profileCalls.length, 1);
      expect(store.profileCalls.single, {'A'});
      c.dispose();
    });

    test('deleted account: author is null, post still shows', () async {
      store.all.add(post(1, author: 'GONE'));
      final c = CommunityFeedController(store, 'g1');
      await c.refresh();
      expect(c.items.single.author, isNull);
      // not asked again on refresh
      await c.refresh();
      expect(store.profileCalls.length, 1);
      c.dispose();
    });

    test('a hidden post never shows, even if the store returns it', () async {
      store.all
        ..add(post(1))
        ..add(post(2, hidden: true));
      final c = CommunityFeedController(store, 'g1');
      await c.refresh();
      expect(c.items.map((i) => i.post.id), ['p1']);
      c.dispose();
    });

    test('only the asked group is shown', () async {
      store.all
        ..add(post(1))
        ..add(post(2, group: 'g2'));
      final c = CommunityFeedController(store, 'g1');
      await c.refresh();
      expect(c.items.map((i) => i.post.id), ['p1']);
      c.dispose();
    });

    test('empty group is ready with no items', () async {
      final c = CommunityFeedController(store, 'g1');
      await c.refresh();
      expect(c.status, CommunityFeedStatus.ready);
      expect(c.items, isEmpty);
      c.dispose();
    });

    test('offline first load fails; retry works', () async {
      store.all.add(post(1));
      store.failPosts = true;
      final c = CommunityFeedController(store, 'g1');
      await c.refresh();
      expect(c.status, CommunityFeedStatus.failed);
      store.failPosts = false;
      await c.refresh();
      expect(c.status, CommunityFeedStatus.ready);
      expect(c.items.length, 1);
      c.dispose();
    });

    test(
      'a failed author lookup fails the page (no wrong "[deleted]")',
      () async {
        store.all.add(post(1));
        store.failProfiles = true;
        final c = CommunityFeedController(store, 'g1');
        await c.refresh();
        expect(c.status, CommunityFeedStatus.failed);
        c.dispose();
      },
    );

    test('load-more failure keeps the first page and can retry', () async {
      for (var i = 1; i <= 25; i++) {
        store.all.add(post(i));
      }
      final c = CommunityFeedController(store, 'g1', pageSize: 20);
      await c.refresh();
      store.failNext = true;
      await c.loadMore();
      expect(c.loadMoreFailed, isTrue);
      expect(c.items.length, 20);
      expect(c.status, CommunityFeedStatus.ready);
      store.failNext = false;
      await c.loadMore();
      expect(c.loadMoreFailed, isFalse);
      expect(c.items.length, 25);
      c.dispose();
    });

    test('refresh failure with items keeps showing them', () async {
      store.all.add(post(1));
      final c = CommunityFeedController(store, 'g1');
      await c.refresh();
      store.failPosts = true;
      await c.refresh();
      expect(c.status, CommunityFeedStatus.ready);
      expect(c.items.length, 1);
      c.dispose();
    });

    test('two load-more calls at once load one page', () async {
      for (var i = 1; i <= 25; i++) {
        store.all.add(post(i));
      }
      final c = CommunityFeedController(store, 'g1', pageSize: 20);
      await c.refresh();
      final before = store.postCalls;
      await Future.wait([c.loadMore(), c.loadMore()]);
      expect(store.postCalls, before + 1);
      expect(c.items.length, 25);
      c.dispose();
    });

    test('a slow older refresh cannot overwrite a newer one', () async {
      store.all.add(post(1));
      final c = CommunityFeedController(store, 'g1');
      final slowGate = Completer<void>();
      store.gate = slowGate;
      final slow = c.refresh();
      store.gate = null;
      store.all.add(post(2));
      await c.refresh();
      expect(c.items.length, 2);
      slowGate.complete();
      await slow;
      expect(c.items.length, 2);
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

  const group1 = CommunityGroup(
    id: 'g1',
    name: 'Diabetes',
    description: 'About diabetes',
    order: 1,
  );

  group('groups list', () {
    testWidgets('shows groups and opens a feed', (tester) async {
      final store = FakeFeedStore()
        ..groupList = [
          group1,
          const CommunityGroup(
            id: 'g2',
            name: 'Caregivers',
            description: '',
            order: 2,
          ),
        ]
        ..profileMap['A'] = profile('A', 'calm_river');
      store.all.add(post(1));

      await tester.pumpWidget(
        host(Scaffold(body: CommunityGroupsList(store: store))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Diabetes'), findsOneWidget);
      expect(find.text('Caregivers'), findsOneWidget);

      await tester.tap(find.byKey(const Key('group-g1')));
      await tester.pumpAndSettle();
      expect(find.text('body 1'), findsOneWidget);
      expect(find.text('calm_river'), findsOneWidget);
    });

    testWidgets('empty and offline states', (tester) async {
      final store = FakeFeedStore();
      await tester.pumpWidget(
        host(Scaffold(body: CommunityGroupsList(store: store))),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('groups-empty')), findsOneWidget);

      final off = FakeFeedStore()..failGroups = true;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: CommunityGroupsList(store: off, key: UniqueKey()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('groups-retry')), findsOneWidget);

      off
        ..failGroups = false
        ..groupList = [group1];
      await tester.tap(find.byKey(const Key('groups-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Diabetes'), findsOneWidget);
    });
  });

  group('feed screen', () {
    final fixedNow = DateTime(2026, 11, 1, 12);

    testWidgets('post card: author, time, edited, votes, deleted author', (
      tester,
    ) async {
      final store = FakeFeedStore()
        ..profileMap['A'] = profile('A', 'calm_river');
      store.all
        ..add(
          post(
            1,
            at: fixedNow.subtract(const Duration(hours: 2)),
            edited: fixedNow.subtract(const Duration(hours: 1)),
            votes: 4,
          ),
        )
        ..add(
          post(
            2,
            author: 'GONE',
            at: fixedNow.subtract(const Duration(minutes: 5)),
          ),
        );

      await tester.pumpWidget(
        host(
          CommunityGroupScreen(
            group: group1,
            store: store,
            now: () => fixedNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diabetes'), findsOneWidget);
      expect(find.text('calm_river'), findsOneWidget);
      expect(find.text('2 h ago · edited'), findsOneWidget);
      expect(find.text('[deleted]'), findsOneWidget);
      expect(find.text('5 min ago'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('loading, then empty message', (tester) async {
      final store = FakeFeedStore()..gate = Completer<void>();
      await tester.pumpWidget(
        host(CommunityGroupScreen(group: group1, store: store)),
      );
      await tester.pump();
      expect(find.byKey(const Key('feed-loading')), findsOneWidget);
      store.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feed-empty')), findsOneWidget);
      expect(find.text('No posts in this group yet.'), findsOneWidget);
    });

    testWidgets('offline shows try again, which then works', (tester) async {
      final store = FakeFeedStore()
        ..failPosts = true
        ..profileMap['A'] = profile('A', 'calm_river');
      store.all.add(post(1));
      await tester.pumpWidget(
        host(CommunityGroupScreen(group: group1, store: store)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feed-retry')), findsOneWidget);

      store.failPosts = false;
      await tester.tap(find.byKey(const Key('feed-retry')));
      await tester.pumpAndSettle();
      expect(find.text('body 1'), findsOneWidget);
    });

    testWidgets('scrolling to the end loads the next page', (tester) async {
      final store = FakeFeedStore()
        ..profileMap['A'] = profile('A', 'calm_river');
      for (var i = 1; i <= 25; i++) {
        store.all.add(post(i));
      }
      await tester.pumpWidget(
        host(CommunityGroupScreen(group: group1, store: store)),
      );
      await tester.pumpAndSettle();
      expect(store.postCalls, 1);

      await tester.drag(
        find.byKey(const Key('feed-list')),
        const Offset(0, -6000),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('feed-list')),
        const Offset(0, -6000),
      );
      await tester.pumpAndSettle();
      expect(store.postCalls, 2);
      expect(find.text('body 1'), findsOneWidget);
    });
  });
}
