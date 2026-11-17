import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/community/community_feed.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_posts.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/core/community/community_validator.dart';
import 'package:med_remind_app/features/community/community_compose_screen.dart';
import 'package:med_remind_app/features/community/community_group_screen.dart';
import 'package:med_remind_app/features/community/community_post_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

const me = 'ME000000000000000001';
const other = 'OT000000000000000002';

CommunityProfile profile(String id, String name) => CommunityProfile(
  id: id,
  pseudonym: name,
  avatar: 'a1',
  bio: '',
  createdAt: DateTime(2026, 10, 1),
);

class FakePostStore implements CommunityPostStore {
  final Map<String, CommunityFeedPost> posts = {};
  final Map<String, List<CommunityComment>> commentMap = {};
  final List<String> log = [];
  int _next = 1;
  bool failWrites = false;
  bool denyWrites = false;
  bool failComments = false;
  bool failCount = false;
  bool failNextPage = false;

  String _key(String g, String p) => '$g/$p';

  void _write() {
    if (denyWrites) throw const CommunityDeniedException();
    if (failWrites) throw Exception('offline');
  }

  @override
  Future<String> createPost(
    String groupId, {
    required String authorId,
    required String body,
  }) async {
    _write();
    final id = 'np${_next++}';
    log.add('createPost:$authorId:$body');
    posts[_key(groupId, id)] = CommunityFeedPost(
      id: id,
      groupId: groupId,
      authorId: authorId,
      body: body,
      createdAt: DateTime(2026, 11, 2),
      voteCount: 0,
      hidden: false,
    );
    return id;
  }

  @override
  Future<void> editPost(String groupId, String postId, String body) async {
    _write();
    log.add('editPost:$postId:$body');
    final old = posts[_key(groupId, postId)]!;
    posts[_key(groupId, postId)] = CommunityFeedPost(
      id: old.id,
      groupId: groupId,
      authorId: old.authorId,
      body: body,
      createdAt: old.createdAt,
      editedAt: DateTime(2026, 11, 3),
      voteCount: old.voteCount,
      hidden: old.hidden,
    );
  }

  @override
  Future<void> deletePost(String groupId, String postId) async {
    _write();
    log.add('deletePost:$postId');
    posts.remove(_key(groupId, postId));
  }

  @override
  Future<CommunityFeedPost?> getPost(String groupId, String postId) async =>
      posts[_key(groupId, postId)];

  @override
  Future<CommunityCommentPage> comments(
    String groupId,
    String postId, {
    Object? after,
    required int limit,
  }) async {
    if (failComments || (failNextPage && after != null)) {
      throw Exception('offline');
    }
    final all = [...(commentMap[_key(groupId, postId)] ?? <CommunityComment>[])]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final start = after is int ? after : 0;
    final slice = all.skip(start).take(limit).toList();
    return CommunityCommentPage(
      slice,
      start + slice.length,
      hasMore: slice.length >= limit,
    );
  }

  @override
  Future<int> commentCount(String groupId, String postId) async {
    if (failCount) throw Exception('offline');
    return (commentMap[_key(groupId, postId)] ?? []).length;
  }

  @override
  Future<String> createComment(
    String groupId,
    String postId, {
    required String authorId,
    required String body,
  }) async {
    _write();
    final id = 'nc${_next++}';
    log.add('createComment:$authorId:$body');
    commentMap
        .putIfAbsent(_key(groupId, postId), () => [])
        .add(
          CommunityComment(
            id: id,
            authorId: authorId,
            body: body,
            createdAt: DateTime(2026, 11, 2, 0, _next),
          ),
        );
    return id;
  }

  @override
  Future<void> editComment(
    String groupId,
    String postId,
    String commentId,
    String body,
  ) async {
    _write();
    log.add('editComment:$commentId:$body');
    final list = commentMap[_key(groupId, postId)]!;
    final i = list.indexWhere((c) => c.id == commentId);
    final old = list[i];
    list[i] = CommunityComment(
      id: old.id,
      authorId: old.authorId,
      body: body,
      createdAt: old.createdAt,
      editedAt: DateTime(2026, 11, 3),
    );
  }

  @override
  Future<void> deleteComment(
    String groupId,
    String postId,
    String commentId,
  ) async {
    _write();
    log.add('deleteComment:$commentId');
    commentMap[_key(groupId, postId)]!.removeWhere((c) => c.id == commentId);
  }
}

class FakeProfiles implements CommunityFeedStore {
  final Map<String, CommunityProfile> map = {
    me: profile(me, 'me_myself'),
    other: profile(other, 'other_person'),
  };

  @override
  Future<List<CommunityGroup>> groups() async => const [];

  @override
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  }) async => const CommunityFeedPage([], null, hasMore: false);

  @override
  Future<Map<String, CommunityProfile>> profiles(Set<String> ids) async => {
    for (final id in ids)
      if (map.containsKey(id)) id: map[id]!,
  };
}

CommunityFeedPost postOf(String id, String author, {String group = 'g1'}) =>
    CommunityFeedPost(
      id: id,
      groupId: group,
      authorId: author,
      body: 'post body $id',
      createdAt: DateTime(2026, 11, 1),
      voteCount: 2,
      hidden: false,
    );

CommunityComment commentOf(int i, String author) => CommunityComment(
  id: 'c$i',
  authorId: author,
  body: 'comment $i',
  createdAt: DateTime(2026, 11, 1, 0, i),
);

void main() {
  group('CommunityPostActions', () {
    late FakePostStore store;
    late CommunityPostActions actions;

    setUp(() {
      store = FakePostStore();
      actions = CommunityPostActions(store, () async => me);
    });

    test('create post: trims and uses my community id', () async {
      final id = await actions.createPost('g1', '  hello there  ');
      expect(store.log.single, 'createPost:$me:hello there');
      expect(store.posts['g1/$id']!.authorId, me);
    });

    test(
      'create post: empty and too long are refused before any write',
      () async {
        await expectLater(
          actions.createPost('g1', '   '),
          throwsA(
            isA<CommunityInputException>()
                .having((e) => e.field, 'field', CommunityField.body)
                .having((e) => e.error, 'error', CommunityInputError.empty),
          ),
        );
        await expectLater(
          actions.createPost('g1', 'x' * 2001),
          throwsA(
            isA<CommunityInputException>().having(
              (e) => e.error,
              'error',
              CommunityInputError.tooLong,
            ),
          ),
        );
        await actions.createPost('g1', 'x' * 2000);
        expect(store.log.length, 1);
      },
    );

    test('comment limit is 800', () async {
      await expectLater(
        actions.createComment('g1', 'p', 'x' * 801),
        throwsA(isA<CommunityInputException>()),
      );
      await actions.createComment('g1', 'p', 'x' * 800);
      expect(store.log.single, startsWith('createComment:$me:'));
    });

    test('no profile: nothing is written', () async {
      final none = CommunityPostActions(store, () async => null);
      await expectLater(
        none.createPost('g1', 'hi'),
        throwsA(isA<CommunityNoProfileException>()),
      );
      await expectLater(
        none.createComment('g1', 'p', 'hi'),
        throwsA(isA<CommunityNoProfileException>()),
      );
      expect(store.log, isEmpty);
    });

    test('edit and delete work only on my own post / comment', () async {
      final mine = postOf('p1', me);
      final theirs = postOf('p2', other);
      store.posts['g1/p1'] = mine;
      store.posts['g1/p2'] = theirs;
      await actions.editPost(mine, ' new text ');
      expect(store.log.last, 'editPost:p1:new text');
      await expectLater(
        actions.editPost(theirs, 'x'),
        throwsA(isA<CommunityNotAuthorException>()),
      );
      await expectLater(
        actions.deletePost(theirs),
        throwsA(isA<CommunityNotAuthorException>()),
      );
      await actions.deletePost(mine);
      expect(store.posts.containsKey('g1/p1'), isFalse);
      expect(store.posts.containsKey('g1/p2'), isTrue);

      final c = commentOf(1, other);
      await expectLater(
        actions.editComment('g1', 'p1', c, 'x'),
        throwsA(isA<CommunityNotAuthorException>()),
      );
      await expectLater(
        actions.deleteComment('g1', 'p1', c),
        throwsA(isA<CommunityNotAuthorException>()),
      );
    });

    test('store errors pass through', () async {
      store.denyWrites = true;
      await expectLater(
        actions.createComment('g1', 'p', 'hi'),
        throwsA(isA<CommunityDeniedException>()),
      );
    });
  });

  group('CommunityCommentsController', () {
    late FakePostStore store;
    late FakeProfiles profiles;

    CommunityCommentsController make({int pageSize = 20}) =>
        CommunityCommentsController(
          store,
          profiles,
          'g1',
          'p1',
          pageSize: pageSize,
        );

    setUp(() {
      store = FakePostStore();
      profiles = FakeProfiles();
    });

    test('oldest first, with authors and the count', () async {
      store.commentMap['g1/p1'] = [
        commentOf(2, other),
        commentOf(1, me),
        commentOf(3, 'GONE'),
      ];
      final c = make();
      await c.refresh();
      expect(c.status, CommunityCommentsStatus.ready);
      expect(c.items.map((i) => i.comment.id), ['c1', 'c2', 'c3']);
      expect(c.items.first.author!.pseudonym, 'me_myself');
      expect(c.items.last.author, isNull);
      expect(c.count, 3);
      c.dispose();
    });

    test('paging 25 = 20 + 5, no duplicates', () async {
      store.commentMap['g1/p1'] = [
        for (var i = 1; i <= 25; i++) commentOf(i, me),
      ];
      final c = make();
      await c.refresh();
      expect(c.items.length, 20);
      expect(c.hasMore, isTrue);
      await c.loadMore();
      expect(c.items.length, 25);
      expect(c.hasMore, isFalse);
      expect(c.count, 25);
      c.dispose();
    });

    test('reloadThroughEnd shows a comment on the last page', () async {
      store.commentMap['g1/p1'] = [
        for (var i = 1; i <= 20; i++) commentOf(i, me),
      ];
      final c = make();
      await c.refresh();
      store.commentMap['g1/p1']!.add(commentOf(21, other));
      await c.reloadThroughEnd();
      expect(c.items.length, 21);
      expect(c.items.last.comment.id, 'c21');
      c.dispose();
    });

    test('a failed count is not fatal', () async {
      store.commentMap['g1/p1'] = [commentOf(1, me)];
      store.failCount = true;
      final c = make();
      await c.refresh();
      expect(c.status, CommunityCommentsStatus.ready);
      expect(c.count, isNull);
      c.dispose();
    });

    test(
      'offline: failed, retry works; load-more failure keeps page 1',
      () async {
        store.commentMap['g1/p1'] = [
          for (var i = 1; i <= 25; i++) commentOf(i, me),
        ];
        store.failComments = true;
        final c = make();
        await c.refresh();
        expect(c.status, CommunityCommentsStatus.failed);
        store.failComments = false;
        await c.refresh();
        expect(c.items.length, 20);
        store.failNextPage = true;
        await c.loadMore();
        expect(c.loadMoreFailed, isTrue);
        expect(c.items.length, 20);
        store.failNextPage = false;
        await c.loadMore();
        expect(c.items.length, 25);
        c.dispose();
      },
    );

    test('empty post is ready with no items and count 0', () async {
      final c = make();
      await c.refresh();
      expect(c.items, isEmpty);
      expect(c.count, 0);
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

  group('compose screen', () {
    testWidgets('shows the safety note; empty text shows a message', (
      tester,
    ) async {
      final store = FakePostStore();
      final actions = CommunityPostActions(store, () async => me);
      await tester.pumpWidget(
        host(CommunityComposeScreen(groupId: 'g1', actions: actions)),
      );
      expect(find.byKey(const Key('compose-safety')), findsOneWidget);
      await tester.tap(find.byKey(const Key('compose-save')));
      await tester.pumpAndSettle();
      expect(find.text('Please write something.'), findsOneWidget);
      expect(store.log, isEmpty);
    });

    testWidgets('saving creates the post and closes', (tester) async {
      final store = FakePostStore();
      final actions = CommunityPostActions(store, () async => me);
      bool? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CommunityComposeScreen(
                        groupId: 'g1',
                        actions: actions,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('compose-text')),
        'my first post',
      );
      await tester.tap(find.byKey(const Key('compose-save')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(store.log.single, 'createPost:$me:my first post');
    });

    testWidgets('a refused or failed write shows a message and stays', (
      tester,
    ) async {
      final store = FakePostStore()..denyWrites = true;
      final actions = CommunityPostActions(store, () async => me);
      await tester.pumpWidget(
        host(CommunityComposeScreen(groupId: 'g1', actions: actions)),
      );
      await tester.enterText(find.byKey(const Key('compose-text')), 'hello');
      await tester.tap(find.byKey(const Key('compose-save')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This could not be saved. The post may no longer be available.',
        ),
        findsOneWidget,
      );

      store
        ..denyWrites = false
        ..failWrites = true;
      await tester.tap(find.byKey(const Key('compose-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(find.byKey(const Key('compose-save')), findsOneWidget);
    });

    testWidgets('no profile shows the "create your profile" message', (
      tester,
    ) async {
      final actions = CommunityPostActions(FakePostStore(), () async => null);
      await tester.pumpWidget(
        host(CommunityComposeScreen(groupId: 'g1', actions: actions)),
      );
      await tester.enterText(find.byKey(const Key('compose-text')), 'hello');
      await tester.tap(find.byKey(const Key('compose-save')));
      await tester.pumpAndSettle();
      expect(find.text('Create your community profile first.'), findsOneWidget);
    });

    testWidgets('editing starts with the old text and saves the new one', (
      tester,
    ) async {
      final store = FakePostStore();
      final post = postOf('p1', me);
      store.posts['g1/p1'] = post;
      final actions = CommunityPostActions(store, () async => me);
      await tester.pumpWidget(
        host(
          CommunityComposeScreen(
            groupId: 'g1',
            existing: post,
            actions: actions,
          ),
        ),
      );
      expect(find.text('post body p1'), findsOneWidget);
      expect(find.text('Edit post'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('compose-text')), 'changed');
      await tester.tap(find.byKey(const Key('compose-save')));
      await tester.pumpAndSettle();
      expect(store.log.last, 'editPost:p1:changed');
    });
  });

  group('post screen', () {
    Widget screen({
      required FakePostStore store,
      required CommunityFeedPost post,
      String? myId = me,
    }) {
      final feed = FakeProfiles();
      return host(
        CommunityPostScreen(
          item: CommunityFeedItem(post, feed.map[post.authorId]),
          feedStore: feed,
          postStore: store,
          actions: CommunityPostActions(store, () async => myId),
          myId: myId,
          now: () => DateTime(2026, 11, 1, 5),
        ),
      );
    }

    testWidgets('post, comment count and comments (oldest first)', (
      tester,
    ) async {
      final store = FakePostStore();
      final post = postOf('p1', other);
      store.posts['g1/p1'] = post;
      store.commentMap['g1/p1'] = [commentOf(2, me), commentOf(1, other)];
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();

      expect(find.text('post body p1'), findsOneWidget);
      expect(find.text('other_person'), findsWidgets);
      expect(find.text('2 comments'), findsOneWidget);
      final first = tester.getTopLeft(find.text('comment 1')).dy;
      final second = tester.getTopLeft(find.text('comment 2')).dy;
      expect(first, lessThan(second));
      // not my post: no post menu
      expect(find.byKey(const Key('post-menu')), findsNothing);
    });

    testWidgets('empty comments message', (tester) async {
      final store = FakePostStore();
      final post = postOf('p1', other);
      store.posts['g1/p1'] = post;
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('comments-empty')), findsOneWidget);
    });

    testWidgets('sending a comment adds it with my id and shows it', (
      tester,
    ) async {
      final store = FakePostStore();
      final post = postOf('p1', other);
      store.posts['g1/p1'] = post;
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('comment-input')),
        'nice post',
      );
      await tester.tap(find.byKey(const Key('comment-send')));
      await tester.pumpAndSettle();

      expect(store.log.single, 'createComment:$me:nice post');
      expect(find.text('nice post'), findsOneWidget);
      expect(find.text('1 comment'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('comment-input')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('an empty comment is refused with a message', (tester) async {
      final store = FakePostStore();
      final post = postOf('p1', other);
      store.posts['g1/p1'] = post;
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment-send')));
      await tester.pumpAndSettle();
      expect(find.text('Please write something.'), findsOneWidget);
      expect(store.log, isEmpty);
    });

    testWidgets(
      'a refused comment (post hidden meanwhile) shows a message and keeps the text',
      (tester) async {
        final store = FakePostStore()..denyWrites = true;
        final post = postOf('p1', other);
        store.posts['g1/p1'] = post;
        await tester.pumpWidget(screen(store: store, post: post));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('comment-input')),
          'my words',
        );
        await tester.tap(find.byKey(const Key('comment-send')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'This could not be saved. The post may no longer be available.',
          ),
          findsOneWidget,
        );
        expect(find.text('my words'), findsOneWidget);
      },
    );

    testWidgets('menus only on my own comment; delete asks first', (
      tester,
    ) async {
      final store = FakePostStore();
      final post = postOf('p1', other);
      store.posts['g1/p1'] = post;
      store.commentMap['g1/p1'] = [commentOf(1, me), commentOf(2, other)];
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('comment-menu-c1')), findsOneWidget);
      expect(find.byKey(const Key('comment-menu-c2')), findsNothing);

      await tester.tap(find.byKey(const Key('comment-menu-c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this comment?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      expect(store.log, isEmpty);

      await tester.tap(find.byKey(const Key('comment-menu-c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(store.log.single, 'deleteComment:c1');
      expect(find.text('comment 1'), findsNothing);
      expect(find.text('comment 2'), findsOneWidget);
    });

    testWidgets('edit my comment', (tester) async {
      final store = FakePostStore();
      final post = postOf('p1', other);
      store.posts['g1/p1'] = post;
      store.commentMap['g1/p1'] = [commentOf(1, me)];
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment-menu-c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-comment-text')),
        'fixed words',
      );
      await tester.tap(find.byKey(const Key('edit-comment-save')));
      await tester.pumpAndSettle();
      expect(store.log.single, 'editComment:c1:fixed words');
      expect(find.text('fixed words'), findsOneWidget);
      expect(find.textContaining('edited'), findsOneWidget);
    });

    testWidgets('my post has a menu; deleting it asks first and closes', (
      tester,
    ) async {
      final store = FakePostStore();
      final post = postOf('p1', me);
      store.posts['g1/p1'] = post;
      bool? popped;
      final feed = FakeProfiles();
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CommunityPostScreen(
                        item: CommunityFeedItem(post, feed.map[me]),
                        feedStore: feed,
                        postStore: store,
                        actions: CommunityPostActions(store, () async => me),
                        myId: me,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('post-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this post?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();

      expect(store.log.single, 'deletePost:p1');
      expect(popped, isTrue);
    });

    testWidgets('a post that no longer exists shows a message', (tester) async {
      final store = FakePostStore(); // post not in the store
      final post = postOf('p1', other);
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('post-gone')), findsOneWidget);
    });

    testWidgets('comments offline: try again works', (tester) async {
      final store = FakePostStore()..failComments = true;
      final post = postOf('p1', other);
      store.posts['g1/p1'] = post;
      store.commentMap['g1/p1'] = [commentOf(1, me)];
      await tester.pumpWidget(screen(store: store, post: post));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('comments-retry')), findsOneWidget);
      store.failComments = false;
      await tester.tap(find.byKey(const Key('comments-retry')));
      await tester.pumpAndSettle();
      expect(find.text('comment 1'), findsOneWidget);
    });
  });

  group('group screen: write and open', () {
    testWidgets('new post button opens compose; saving refreshes the feed', (
      tester,
    ) async {
      final feed = _FeedWithPosts();
      final store = FakePostStore();
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
            postStore: store,
            actions: CommunityPostActions(store, () async => me),
            myId: me,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('post body p1'), findsOneWidget);
      final before = feed.postCalls;

      await tester.tap(find.byKey(const Key('new-post')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('compose-text')),
        'brand new',
      );
      await tester.tap(find.byKey(const Key('compose-save')));
      await tester.pumpAndSettle();

      expect(store.log.single, 'createPost:$me:brand new');
      expect(feed.postCalls, before + 1);
    });

    testWidgets('tapping a post opens it with its comments', (tester) async {
      final feed = _FeedWithPosts();
      final store = FakePostStore();
      store.posts['g1/p1'] = feed.list.first;
      store.commentMap['g1/p1'] = [commentOf(1, me)];
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
            postStore: store,
            actions: CommunityPostActions(store, () async => me),
            myId: me,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('post-p1')));
      await tester.pumpAndSettle();
      expect(find.text('Comments'), findsWidgets);
      expect(find.text('comment 1'), findsOneWidget);
    });
  });
}

class _FeedWithPosts extends FakeProfiles {
  final List<CommunityFeedPost> list = [postOf('p1', other)];
  int postCalls = 0;

  @override
  Future<CommunityFeedPage> posts(
    String groupId, {
    Object? after,
    required int limit,
  }) async {
    postCalls++;
    return CommunityFeedPage(list, null, hasMore: false);
  }
}
