import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/community/community_feed.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_posts.dart';
import 'package:med_remind_app/core/community/community_reactions.dart';
import 'package:med_remind_app/features/community/community_group_screen.dart';
import 'package:med_remind_app/features/community/community_post_card.dart';
import 'package:med_remind_app/features/community/community_saved_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

const me = 'ME000000000000000001';
const other = 'OT000000000000000002';

CommunityFeedPost postOf(
  String id,
  String author, {
  int votes = 0,
  bool hidden = false,
}) => CommunityFeedPost(
  id: id,
  groupId: 'g1',
  authorId: author,
  body: 'post body $id',
  createdAt: DateTime(2026, 11, 1),
  voteCount: votes,
  hidden: hidden,
);

class FakeVotes implements CommunityVoteStore {
  final Set<String> voted = {};
  final List<String> log = [];
  bool fail = false;
  bool deny = false;
  bool failLookup = false;
  Completer<void>? gate;

  /// Make "vote" look refused while the server already has the vote (another
  /// phone voted first).
  bool alreadyThere = false;

  @override
  Future<Set<String>> votedAmong(
    String voterId,
    List<CommunityFeedPost> posts,
  ) async {
    log.add('lookup:${posts.length}');
    if (failLookup) throw Exception('offline');
    return {
      for (final p in posts)
        if (voted.contains('${p.groupId}/${p.id}')) '${p.groupId}/${p.id}',
    };
  }

  @override
  Future<void> vote(CommunityFeedPost post, String voterId) async {
    log.add('vote:${post.id}:$voterId');
    if (gate != null) await gate!.future;
    if (alreadyThere) {
      voted.add('g1/${post.id}');
      throw const CommunityDeniedException();
    }
    if (deny) throw const CommunityDeniedException();
    if (fail) throw Exception('offline');
    voted.add('${post.groupId}/${post.id}');
  }

  @override
  Future<void> unvote(CommunityFeedPost post, String voterId) async {
    log.add('unvote:${post.id}:$voterId');
    if (gate != null) await gate!.future;
    if (deny) throw const CommunityDeniedException();
    if (fail) throw Exception('offline');
    voted.remove('${post.groupId}/${post.id}');
  }
}

class FakeSaves implements CommunityBookmarkStore {
  final Map<String, CommunityBookmark> saved = {};
  final List<String> log = [];
  bool fail = false;
  bool failPage = false;
  bool failNextPage = false;

  @override
  Future<Set<String>> savedAmong(List<String> postIds) async {
    log.add('lookup:${postIds.length}');
    return {
      for (final id in postIds)
        if (saved.containsKey(id)) id,
    };
  }

  @override
  Future<void> add(String postId, String groupId) async {
    log.add('add:$postId');
    if (fail) throw Exception('offline');
    saved[postId] = CommunityBookmark(
      postId: postId,
      groupId: groupId,
      createdAt: DateTime(2026, 11, 2, 0, saved.length),
    );
  }

  @override
  Future<void> remove(String postId) async {
    log.add('remove:$postId');
    if (fail) throw Exception('offline');
    saved.remove(postId);
  }

  @override
  Future<CommunityBookmarkPage> page({
    Object? after,
    required int limit,
  }) async {
    if (failPage || (failNextPage && after != null)) throw Exception('offline');
    final all = saved.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final start = after is int ? after : 0;
    final slice = all.skip(start).take(limit).toList();
    return CommunityBookmarkPage(
      slice,
      start + slice.length,
      hasMore: slice.length >= limit,
    );
  }
}

class FakePosts implements CommunityPostStore {
  final Map<String, CommunityFeedPost> posts = {};

  @override
  Future<CommunityFeedPost?> getPost(String groupId, String postId) async =>
      posts['$groupId/$postId'];

  @override
  Future<CommunityCommentPage> comments(
    String groupId,
    String postId, {
    Object? after,
    required int limit,
  }) async => const CommunityCommentPage([], null, hasMore: false);

  @override
  Future<int> commentCount(String groupId, String postId) async => 0;

  @override
  Future<String> createPost(
    String groupId, {
    required String authorId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<void> editPost(String groupId, String postId, String body) =>
      throw UnimplementedError();

  @override
  Future<void> deletePost(String groupId, String postId) =>
      throw UnimplementedError();

  @override
  Future<String> createComment(
    String groupId,
    String postId, {
    required String authorId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<void> editComment(
    String groupId,
    String postId,
    String commentId,
    String body,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteComment(String groupId, String postId, String commentId) =>
      throw UnimplementedError();
}

class FakeFeed implements CommunityFeedStore {
  final Map<String, CommunityProfile> profiles_ = {
    other: CommunityProfile(
      id: other,
      pseudonym: 'other_person',
      avatar: 'a1',
      bio: '',
      createdAt: DateTime(2026, 10, 1),
    ),
  };
  List<CommunityFeedPost> list = [];

  @override
  Future<List<CommunityGroup>> groups() async => const [];

  @override
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  }) async => CommunityFeedPage(list, null, hasMore: false);

  @override
  Future<Map<String, CommunityProfile>> profiles(Set<String> ids) async => {
    for (final id in ids)
      if (profiles_.containsKey(id)) id: profiles_[id]!,
  };
}

void main() {
  late FakeVotes votes;
  late FakeSaves saves;

  CommunityReactionsController make({String? myId = me}) =>
      CommunityReactionsController(votes, saves, () async => myId);

  setUp(() {
    votes = FakeVotes();
    saves = FakeSaves();
  });

  group('CommunityReactionsController: loading', () {
    test('looks up votes and saves once per post', () async {
      votes.voted.add('g1/p1');
      saves.saved['p2'] = CommunityBookmark(
        postId: 'p2',
        groupId: 'g1',
        createdAt: DateTime(2026, 11, 1),
      );
      final c = make();
      final p1 = postOf('p1', other, votes: 3);
      final p2 = postOf('p2', other);
      await c.ensureLoaded([p1, p2]);
      expect(c.isVoted(p1), isTrue);
      expect(c.isVoted(p2), isFalse);
      expect(c.isSaved(p2), isTrue);
      expect(c.isSaved(p1), isFalse);

      await c.ensureLoaded([p1, p2]);
      expect(votes.log.where((l) => l.startsWith('lookup')).length, 1);
      c.dispose();
    });

    test('only new posts are looked up on the next page', () async {
      final c = make();
      await c.ensureLoaded([postOf('p1', other)]);
      await c.ensureLoaded([postOf('p1', other), postOf('p2', other)]);
      expect(votes.log, ['lookup:1', 'lookup:1']);
      c.dispose();
    });

    test('a failed lookup is not fatal, and is retried later', () async {
      votes.failLookup = true;
      final c = make();
      final p = postOf('p1', other);
      await c.ensureLoaded([p]);
      expect(c.isVoted(p), isFalse);
      votes.failLookup = false;
      votes.voted.add('g1/p1');
      await c.ensureLoaded([p]);
      expect(c.isVoted(p), isTrue);
      c.dispose();
    });

    test('forgetAll makes the next call look again', () async {
      final c = make();
      final p = postOf('p1', other);
      await c.ensureLoaded([p]);
      c.forgetAll();
      await c.ensureLoaded([p]);
      expect(votes.log.where((l) => l.startsWith('lookup')).length, 2);
      c.dispose();
    });

    test('no profile: nothing is looked up for votes', () async {
      final c = make(myId: null);
      await c.ensureLoaded([postOf('p1', other)]);
      expect(votes.log, isEmpty);
      c.dispose();
    });
  });

  group('CommunityReactionsController: voting', () {
    test('vote: instant +1, store called with my id, stays', () async {
      final c = make();
      final p = postOf('p1', other, votes: 4);
      await c.ensureLoaded([p]);
      final f = c.toggleVote(p);
      // before the store answers, the change is already visible
      expect(c.isVoted(p), isTrue);
      expect(c.votesOf(p), 5);
      await f;
      expect(votes.log.last, 'vote:p1:$me');
      expect(c.isVoted(p), isTrue);
      expect(c.votesOf(p), 5);
      c.dispose();
    });

    test('unvote: instant -1', () async {
      votes.voted.add('g1/p1');
      final c = make();
      final p = postOf('p1', other, votes: 4);
      await c.ensureLoaded([p]);
      await c.toggleVote(p);
      expect(votes.log.last, 'unvote:p1:$me');
      expect(c.isVoted(p), isFalse);
      expect(c.votesOf(p), 3);
      c.dispose();
    });

    test('failure: rolled back and thrown', () async {
      votes.fail = true;
      final c = make();
      final p = postOf('p1', other, votes: 4);
      await c.ensureLoaded([p]);
      await expectLater(c.toggleVote(p), throwsException);
      expect(c.isVoted(p), isFalse);
      expect(c.votesOf(p), 4);
      expect(c.isBusy(p), isFalse);
      c.dispose();
    });

    test('double tap while busy sends one request', () async {
      votes.gate = Completer<void>();
      final c = make();
      final p = postOf('p1', other, votes: 4);
      await c.ensureLoaded([p]);
      final a = c.toggleVote(p);
      final b = c.toggleVote(p);
      await Future<void>.delayed(Duration.zero);
      votes.gate!.complete();
      await Future.wait([a, b]);
      expect(votes.log.where((l) => l.startsWith('vote')).length, 1);
      expect(c.votesOf(p), 5);
      c.dispose();
    });

    test(
      'refused because the vote was already there: keeps "voted", no error',
      () async {
        votes.alreadyThere = true;
        final c = make();
        final p = postOf('p1', other, votes: 4);
        await c.ensureLoaded([p]);
        await c.toggleVote(p); // does not throw
        expect(c.isVoted(p), isTrue);
        // count is unknown now: the post's own number is shown
        expect(c.votesOf(p), 4);
        c.dispose();
      },
    );

    test(
      'refused for another reason (post gone): rolled back and thrown',
      () async {
        votes.deny = true;
        final c = make();
        final p = postOf('p1', other, votes: 4);
        await c.ensureLoaded([p]);
        await expectLater(
          c.toggleVote(p),
          throwsA(isA<CommunityDeniedException>()),
        );
        expect(c.isVoted(p), isFalse);
        expect(c.votesOf(p), 4);
        c.dispose();
      },
    );

    test('own post: no vote is sent', () async {
      final c = make();
      final p = postOf('p1', me, votes: 2);
      await c.ensureLoaded([p]);
      expect(c.isMine(p), isTrue);
      await c.toggleVote(p);
      expect(votes.log.where((l) => l.startsWith('vote')), isEmpty);
      expect(c.votesOf(p), 2);
      c.dispose();
    });

    test('no profile: throws, nothing sent', () async {
      final c = make(myId: null);
      await expectLater(
        c.toggleVote(postOf('p1', other)),
        throwsA(isA<CommunityNoProfileException>()),
      );
      expect(votes.log, isEmpty);
      c.dispose();
    });

    test(
      'after a refresh the server count is shown, not my +1 again',
      () async {
        final c = make();
        final p = postOf('p1', other, votes: 4);
        await c.ensureLoaded([p]);
        await c.toggleVote(p);
        expect(c.votesOf(p), 5);
        // the feed reloaded: the server count (5) already includes my vote
        final fresh = postOf('p1', other, votes: 5);
        expect(c.votesOf(fresh), 5);
        // and if someone else voted too, that number wins
        expect(c.votesOf(postOf('p1', other, votes: 7)), 7);
        c.dispose();
      },
    );
  });

  group('CommunityReactionsController: saving', () {
    test('save and un-save, with rollback on failure', () async {
      final c = make();
      final p = postOf('p1', other);
      await c.ensureLoaded([p]);
      await c.toggleSave(p);
      expect(c.isSaved(p), isTrue);
      expect(saves.saved.containsKey('p1'), isTrue);
      await c.toggleSave(p);
      expect(c.isSaved(p), isFalse);
      expect(saves.saved, isEmpty);

      saves.fail = true;
      await expectLater(c.toggleSave(p), throwsException);
      expect(c.isSaved(p), isFalse);
      c.dispose();
    });

    test('saving works on my own post too', () async {
      final c = make();
      final p = postOf('p1', me);
      await c.ensureLoaded([p]);
      await c.toggleSave(p);
      expect(c.isSaved(p), isTrue);
      c.dispose();
    });
  });

  group('CommunitySavedController', () {
    late FakePosts posts;
    late FakeFeed feed;

    CommunitySavedController makeSaved({int pageSize = 20}) =>
        CommunitySavedController(saves, posts, feed, pageSize: pageSize);

    void save(String id, int minute) {
      saves.saved[id] = CommunityBookmark(
        postId: id,
        groupId: 'g1',
        createdAt: DateTime(2026, 11, 1, 0, minute),
      );
    }

    setUp(() {
      posts = FakePosts();
      feed = FakeFeed();
    });

    test(
      'newest saved first, with authors; gone and hidden posts are marked',
      () async {
        for (final p in [
          postOf('a', other),
          postOf('hid', other, hidden: true),
        ]) {
          posts.posts['g1/${p.id}'] = p;
        }
        save('a', 1);
        save('gone', 2);
        save('hid', 3);
        final c = makeSaved();
        await c.refresh();
        expect(c.status, CommunitySavedStatus.ready);
        expect(c.entries.map((e) => e.bookmark.postId), ['hid', 'gone', 'a']);
        expect(c.entries[0].item, isNull);
        expect(c.entries[1].item, isNull);
        expect(c.entries[2].item!.author!.pseudonym, 'other_person');
        c.dispose();
      },
    );

    test('paging 25 = 20 + 5', () async {
      for (var i = 1; i <= 25; i++) {
        posts.posts['g1/p$i'] = postOf('p$i', other);
        save('p$i', i);
      }
      final c = makeSaved();
      await c.refresh();
      expect(c.entries.length, 20);
      expect(c.hasMore, isTrue);
      await c.loadMore();
      expect(c.entries.length, 25);
      expect(c.entries.map((e) => e.bookmark.postId).toSet().length, 25);
      c.dispose();
    });

    test('remove takes it out of the list and the store', () async {
      posts.posts['g1/a'] = postOf('a', other);
      save('a', 1);
      final c = makeSaved();
      await c.refresh();
      await c.remove(c.entries.single);
      expect(c.entries, isEmpty);
      expect(saves.saved, isEmpty);
      c.dispose();
    });

    test(
      'offline: failed, retry works; load-more failure keeps page 1',
      () async {
        for (var i = 1; i <= 25; i++) {
          posts.posts['g1/p$i'] = postOf('p$i', other);
          save('p$i', i);
        }
        saves.failPage = true;
        final c = makeSaved();
        await c.refresh();
        expect(c.status, CommunitySavedStatus.failed);
        saves.failPage = false;
        await c.refresh();
        saves.failNextPage = true;
        await c.loadMore();
        expect(c.loadMoreFailed, isTrue);
        expect(c.entries.length, 20);
        saves.failNextPage = false;
        await c.loadMore();
        expect(c.entries.length, 25);
        c.dispose();
      },
    );

    test('empty list is ready', () async {
      final c = makeSaved();
      await c.refresh();
      expect(c.status, CommunitySavedStatus.ready);
      expect(c.entries, isEmpty);
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

  group('reaction bar', () {
    Future<CommunityReactionsController> pump(
      WidgetTester tester,
      CommunityFeedPost p,
    ) async {
      final c = make();
      await c.ensureLoaded([p]);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: CommunityReactionBar(post: p, reactions: c),
          ),
        ),
      );
      return c;
    }

    testWidgets('vote changes the count and the icon at once', (tester) async {
      final p = postOf('p1', other, votes: 4);
      await pump(tester, p);
      expect(find.byKey(const Key('votes-p1')), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.byKey(const Key('vote-p1')));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('vote-p1')));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('a failed vote shows a message and goes back', (tester) async {
      votes.fail = true;
      final p = postOf('p1', other, votes: 4);
      await pump(tester, p);
      await tester.tap(find.byKey(const Key('vote-p1')));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not update your vote. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('own post: no vote button, but it can be saved', (
      tester,
    ) async {
      final p = postOf('p1', me, votes: 2);
      await pump(tester, p);
      expect(find.byKey(const Key('vote-p1')), findsNothing);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-p1')));
      await tester.pumpAndSettle();
      expect(saves.saved.containsKey('p1'), isTrue);
    });

    testWidgets('save icon toggles', (tester) async {
      final p = postOf('p1', other);
      await pump(tester, p);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-p1')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('a failed save shows a message', (tester) async {
      saves.fail = true;
      final p = postOf('p1', other);
      await pump(tester, p);
      await tester.tap(find.byKey(const Key('save-p1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });
  });

  group('feed and saved screens', () {
    testWidgets('feed cards have vote and save buttons', (tester) async {
      final feed = FakeFeed()..list = [postOf('p1', other, votes: 1)];
      final c = make();
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
            postStore: FakePosts(),
            reactions: c,
            myId: me,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('vote-p1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('vote-p1')));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(votes.voted.contains('g1/p1'), isTrue);
    });

    testWidgets('saved screen: list, gone post, remove', (tester) async {
      final posts = FakePosts();
      posts.posts['g1/a'] = postOf('a', other);
      saves.saved['a'] = CommunityBookmark(
        postId: 'a',
        groupId: 'g1',
        createdAt: DateTime(2026, 11, 1, 0, 1),
      );
      saves.saved['gone'] = CommunityBookmark(
        postId: 'gone',
        groupId: 'g1',
        createdAt: DateTime(2026, 11, 1, 0, 2),
      );
      await tester.pumpWidget(
        host(
          CommunitySavedScreen(
            bookmarkStore: saves,
            postStore: posts,
            feedStore: FakeFeed(),
            reactions: make(),
            myId: me,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved posts'), findsOneWidget);
      expect(find.text('post body a'), findsOneWidget);
      expect(find.byKey(const Key('saved-gone-gone')), findsOneWidget);
      expect(find.text('This post is no longer available.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('saved-remove-gone')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saved-gone-gone')), findsNothing);
      expect(saves.saved.containsKey('gone'), isFalse);
      expect(saves.saved.containsKey('a'), isTrue);
    });

    testWidgets('saved screen: empty and offline states', (tester) async {
      await tester.pumpWidget(
        host(
          CommunitySavedScreen(
            bookmarkStore: saves,
            postStore: FakePosts(),
            feedStore: FakeFeed(),
            reactions: make(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saved-empty')), findsOneWidget);

      saves.failPage = true;
      await tester.pumpWidget(
        host(
          CommunitySavedScreen(
            key: UniqueKey(),
            bookmarkStore: saves,
            postStore: FakePosts(),
            feedStore: FakeFeed(),
            reactions: make(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saved-retry')), findsOneWidget);
      saves.failPage = false;
      await tester.tap(find.byKey(const Key('saved-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saved-empty')), findsOneWidget);
    });

    testWidgets('saved screen: tapping a saved post opens it', (tester) async {
      final posts = FakePosts();
      posts.posts['g1/a'] = postOf('a', other);
      saves.saved['a'] = CommunityBookmark(
        postId: 'a',
        groupId: 'g1',
        createdAt: DateTime(2026, 11, 1),
      );
      await tester.pumpWidget(
        host(
          CommunitySavedScreen(
            bookmarkStore: saves,
            postStore: posts,
            feedStore: FakeFeed(),
            reactions: make(),
            actions: CommunityPostActions(posts, () async => me),
            myId: me,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('post-a')));
      await tester.pumpAndSettle();
      expect(find.text('Comments'), findsWidgets);
      expect(find.byKey(const Key('vote-a')), findsOneWidget);
    });
  });
}
