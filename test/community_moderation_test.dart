import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/community/community_models.dart';
import 'package:med_remind_app/core/community/community_moderation.dart';
import 'package:med_remind_app/core/community/community_profile_controller.dart';
import 'package:med_remind_app/core/community/community_safety.dart';
import 'package:med_remind_app/features/community/community_gate_screen.dart';
import 'package:med_remind_app/features/community/community_moderation_screen.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';

import 'community_posts_test.dart' as p;
import 'community_profile_test.dart' as prof;
import 'community_reactions_test.dart' as r;
import 'community_safety_test.dart' as s;

const me = p.me;
const other = p.other;

CommunityReport report(
  String id,
  String postId, {
  String? commentId,
  CommunityReportReason reason = CommunityReportReason.spam,
  int minute = 0,
  String group = 'g1',
}) => CommunityReport(
  id: id,
  reporterId: 'R$id'.padRight(20, '0'),
  target: commentId == null
      ? CommunityReportTarget.post
      : CommunityReportTarget.comment,
  groupId: group,
  postId: postId,
  commentId: commentId,
  reason: reason,
  createdAt: DateTime(2026, 11, 1, 0, minute),
);

class FakeModeration implements CommunityModerationStore {
  final List<CommunityReport> all = [];
  final Map<String, CommunityComment> comments = {};
  final List<String> log = [];
  bool fail = false;
  bool failReports = false;
  bool failNextPage = false;

  @override
  Future<CommunityReportPage> reports({
    Object? after,
    required int limit,
  }) async {
    if (failReports || (failNextPage && after != null)) {
      throw Exception('offline');
    }
    final sorted = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final start = after is int ? after : 0;
    final slice = sorted.skip(start).take(limit).toList();
    return CommunityReportPage(
      slice,
      start + slice.length,
      hasMore: slice.length >= limit,
    );
  }

  @override
  Future<CommunityComment?> getComment(
    String groupId,
    String postId,
    String commentId,
  ) async => comments['$groupId/$postId/$commentId'];

  @override
  Future<void> setHidden(String groupId, String postId, bool hidden) async {
    log.add('hidden:$postId:$hidden');
    if (fail) throw Exception('denied');
  }

  @override
  Future<void> deletePost(String groupId, String postId) async {
    log.add('deletePost:$postId');
    if (fail) throw Exception('denied');
  }

  @override
  Future<void> deleteComment(
    String groupId,
    String postId,
    String commentId,
  ) async {
    log.add('deleteComment:$commentId');
    if (fail) throw Exception('denied');
  }

  @override
  Future<void> deleteReportsFor(
    String groupId,
    String postId, {
    String? commentId,
  }) async {
    log.add('deleteReports:$postId:${commentId ?? '-'}');
    if (fail) throw Exception('denied');
    all.removeWhere(
      (r) =>
          r.groupId == groupId &&
          r.postId == postId &&
          r.commentId == commentId,
    );
  }
}

void main() {
  late FakeModeration store;
  late p.FakePostStore posts;
  late p.FakeProfiles feed;

  CommunityModerationController make({int pageSize = 20}) =>
      CommunityModerationController(store, posts, feed, pageSize: pageSize);

  setUp(() {
    store = FakeModeration();
    posts = p.FakePostStore();
    feed = p.FakeProfiles();
  });

  group('CommunityModerationController', () {
    test(
      'reports about the same post become one entry with a count and reasons',
      () async {
        posts.posts['g1/p1'] = p.postOf('p1', other);
        store.all.addAll([
          report('a', 'p1', minute: 3),
          report('b', 'p1', minute: 2, reason: CommunityReportReason.abuse),
          report('c', 'p1', minute: 1),
        ]);
        final c = make();
        await c.refresh();
        expect(c.status, CommunityModerationStatus.ready);
        expect(c.entries.length, 1);
        final e = c.entries.single;
        expect(e.reports.length, 3);
        expect(e.reasons.first.key, CommunityReportReason.spam);
        expect(e.reasons.first.value, 2);
        expect(e.post!.body, 'post body p1');
        expect(e.author!.pseudonym, 'other_person');
        expect(e.isGone, isFalse);
        c.dispose();
      },
    );

    test(
      'newest reported first; comment report loads the comment and its author',
      () async {
        posts.posts['g1/p1'] = p.postOf('p1', other);
        posts.posts['g1/p2'] = p.postOf('p2', other);
        store.comments['g1/p2/c1'] = p.commentOf(1, me);
        store.all.addAll([
          report('a', 'p1', minute: 1),
          report('b', 'p2', commentId: 'c1', minute: 5),
        ]);
        final c = make();
        await c.refresh();
        expect(c.entries.map((e) => e.key), ['g1/p2/c1', 'g1/p1']);
        final comment = c.entries.first;
        expect(comment.isComment, isTrue);
        expect(comment.comment!.body, 'comment 1');
        expect(comment.author!.pseudonym, 'me_myself');
        c.dispose();
      },
    );

    test('a deleted post or comment is marked gone', () async {
      store.all.addAll([
        report('a', 'nopost', minute: 2),
        report('b', 'p2', commentId: 'nocomment', minute: 1),
      ]);
      posts.posts['g1/p2'] = p.postOf('p2', other);
      final c = make();
      await c.refresh();
      expect(c.entries.every((e) => e.isGone), isTrue);
      c.dispose();
    });

    test('a hidden post is shown to the moderator as hidden', () async {
      posts.posts['g1/p1'] = r.postOf('p1', other, hidden: true);
      store.all.add(report('a', 'p1'));
      final c = make();
      await c.refresh();
      expect(c.entries.single.post!.hidden, isTrue);
      c.dispose();
    });

    test('paging: 25 reports on different posts = 20 + 5; the same post on page 2 joins its entry', () async {
      for (var i = 1; i <= 25; i++) {
        posts.posts['g1/p$i'] = p.postOf('p$i', other);
        store.all.add(report('r$i', 'p$i', minute: 100 - i));
      }
      // an old extra report about p1 (newest first, so it lands on page 2)
      store.all.add(report('extra', 'p1', minute: 0));
      final c = make();
      await c.refresh();
      expect(c.entries.length, 20);
      await c.loadMore();
      expect(c.entries.length, 25);
      expect(c.hasMore, isFalse);
      expect(c.entries.firstWhere((e) => e.key == 'g1/p1').reports.length, 2);
      c.dispose();
    });

    test('hide and show again', () async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.all.add(report('a', 'p1'));
      final c = make();
      await c.refresh();
      await c.setHidden(c.entries.single, true);
      expect(store.log.last, 'hidden:p1:true');
      expect(c.entries.single.post!.hidden, isTrue);
      await c.setHidden(c.entries.single, false);
      expect(store.log.last, 'hidden:p1:false');
      expect(c.entries.single.post!.hidden, isFalse);
      c.dispose();
    });

    test('hide does nothing for a comment report', () async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.comments['g1/p1/c1'] = p.commentOf(1, me);
      store.all.add(report('a', 'p1', commentId: 'c1'));
      final c = make();
      await c.refresh();
      await c.setHidden(c.entries.single, true);
      expect(store.log, isEmpty);
      c.dispose();
    });

    test(
      'delete a post: post and all its reports go, entry leaves the list',
      () async {
        posts.posts['g1/p1'] = p.postOf('p1', other);
        store.all.addAll([report('a', 'p1'), report('b', 'p1', minute: 1)]);
        final c = make();
        await c.refresh();
        await c.deleteTarget(c.entries.single);
        expect(store.log, ['deletePost:p1', 'deleteReports:p1:-']);
        expect(c.entries, isEmpty);
        expect(store.all, isEmpty);
        c.dispose();
      },
    );

    test('delete a comment: only that comment and its reports', () async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.comments['g1/p1/c1'] = p.commentOf(1, me);
      store.all.addAll([
        report('a', 'p1', commentId: 'c1', minute: 2),
        report('b', 'p1', minute: 1),
      ]);
      final c = make();
      await c.refresh();
      final entry = c.entries.firstWhere((e) => e.isComment);
      await c.deleteTarget(entry);
      expect(store.log, ['deleteComment:c1', 'deleteReports:p1:c1']);
      expect(c.entries.map((e) => e.key), ['g1/p1']);
      c.dispose();
    });

    test(
      'an item that is already gone only needs its reports cleared',
      () async {
        store.all.add(report('a', 'nopost'));
        final c = make();
        await c.refresh();
        await c.deleteTarget(c.entries.single);
        expect(store.log, ['deleteReports:nopost:-']);
        expect(c.entries, isEmpty);
        c.dispose();
      },
    );

    test('dismiss: reports go, the post stays', () async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.all.add(report('a', 'p1'));
      final c = make();
      await c.refresh();
      await c.dismiss(c.entries.single);
      expect(store.log, ['deleteReports:p1:-']);
      expect(c.entries, isEmpty);
      c.dispose();
    });

    test('a refused action throws and changes nothing', () async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.all.add(report('a', 'p1'));
      final c = make();
      await c.refresh();
      store.fail = true;
      await expectLater(c.deleteTarget(c.entries.single), throwsException);
      await expectLater(c.setHidden(c.entries.single, true), throwsException);
      await expectLater(c.dismiss(c.entries.single), throwsException);
      expect(c.entries.length, 1);
      expect(c.entries.single.post!.hidden, isFalse);
      c.dispose();
    });

    test(
      'offline: failed, retry works; load-more failure keeps page 1',
      () async {
        for (var i = 1; i <= 25; i++) {
          posts.posts['g1/p$i'] = p.postOf('p$i', other);
          store.all.add(report('r$i', 'p$i', minute: 100 - i));
        }
        store.failReports = true;
        final c = make();
        await c.refresh();
        expect(c.status, CommunityModerationStatus.failed);
        store.failReports = false;
        await c.refresh();
        store.failNextPage = true;
        await c.loadMore();
        expect(c.loadMoreFailed, isTrue);
        expect(c.entries.length, 20);
        store.failNextPage = false;
        await c.loadMore();
        expect(c.entries.length, 25);
        c.dispose();
      },
    );

    test('no reports: ready and empty', () async {
      final c = make();
      await c.refresh();
      expect(c.status, CommunityModerationStatus.ready);
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

  Widget screen() => host(
    CommunityModerationScreen(
      store: store,
      postStore: posts,
      feedStore: feed,
      now: () => DateTime(2026, 11, 1, 5),
    ),
  );

  group('moderation screen', () {
    testWidgets('card: count, reasons, author, text, actions', (tester) async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.all.addAll([
        report('a', 'p1', minute: 2),
        report('b', 'p1', minute: 1, reason: CommunityReportReason.medical),
      ]);
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Reported post'), findsOneWidget);
      expect(find.text('2 reports'), findsOneWidget);
      expect(find.text('Spam'), findsOneWidget);
      expect(find.text('Wrong medical advice'), findsOneWidget);
      expect(find.textContaining('other_person'), findsOneWidget);
      expect(find.text('post body p1'), findsOneWidget);
      expect(find.byKey(const Key('mod-hide-g1/p1')), findsOneWidget);
      expect(find.byKey(const Key('mod-delete-g1/p1')), findsOneWidget);
      expect(find.byKey(const Key('mod-dismiss-g1/p1')), findsOneWidget);
    });

    testWidgets(
      'hide shows the Hidden chip and the button becomes "Show post again"',
      (tester) async {
        posts.posts['g1/p1'] = p.postOf('p1', other);
        store.all.add(report('a', 'p1'));
        await tester.pumpWidget(screen());
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mod-hide-g1/p1')));
        await tester.pumpAndSettle();
        expect(store.log.last, 'hidden:p1:true');
        expect(find.byKey(const Key('mod-hidden-g1/p1')), findsOneWidget);
        expect(find.text('Show post again'), findsOneWidget);
        await tester.tap(find.byKey(const Key('mod-hide-g1/p1')));
        await tester.pumpAndSettle();
        expect(store.log.last, 'hidden:p1:false');
        expect(find.byKey(const Key('mod-hidden-g1/p1')), findsNothing);
      },
    );

    testWidgets('delete asks first: cancel keeps, confirm removes', (
      tester,
    ) async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.all.add(report('a', 'p1'));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mod-delete-g1/p1')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this post?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mod-cancel')));
      await tester.pumpAndSettle();
      expect(store.log, isEmpty);

      await tester.tap(find.byKey(const Key('mod-delete-g1/p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mod-confirm-delete')));
      await tester.pumpAndSettle();
      expect(store.log, ['deletePost:p1', 'deleteReports:p1:-']);
      expect(find.byKey(const Key('mod-empty')), findsOneWidget);
    });

    testWidgets(
      'comment report: no hide button, delete asks about the comment',
      (tester) async {
        posts.posts['g1/p1'] = p.postOf('p1', other);
        store.comments['g1/p1/c1'] = p.commentOf(1, me);
        store.all.add(report('a', 'p1', commentId: 'c1'));
        await tester.pumpWidget(screen());
        await tester.pumpAndSettle();
        expect(find.text('Reported comment'), findsOneWidget);
        expect(find.text('comment 1'), findsOneWidget);
        expect(find.byKey(const Key('mod-hide-g1/p1/c1')), findsNothing);
        await tester.tap(find.byKey(const Key('mod-delete-g1/p1/c1')));
        await tester.pumpAndSettle();
        expect(find.text('Delete this comment?'), findsOneWidget);
      },
    );

    testWidgets('dismiss clears the reports and keeps the post', (
      tester,
    ) async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.all.add(report('a', 'p1'));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mod-dismiss-g1/p1')));
      await tester.pumpAndSettle();
      expect(store.log, ['deleteReports:p1:-']);
      expect(find.byKey(const Key('mod-empty')), findsOneWidget);
    });

    testWidgets('an already removed item offers only "Dismiss reports"', (
      tester,
    ) async {
      store.all.add(report('a', 'nopost'));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('Already removed.'), findsOneWidget);
      expect(find.byKey(const Key('mod-delete-g1/nopost')), findsNothing);
      expect(find.byKey(const Key('mod-hide-g1/nopost')), findsNothing);
      expect(find.byKey(const Key('mod-dismiss-g1/nopost')), findsOneWidget);
    });

    testWidgets('a refused action shows a message', (tester) async {
      posts.posts['g1/p1'] = p.postOf('p1', other);
      store.all.add(report('a', 'p1'));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      store.fail = true;
      await tester.tap(find.byKey(const Key('mod-hide-g1/p1')));
      await tester.pumpAndSettle();
      expect(find.text('Could not do that. Please try again.'), findsOneWidget);
    });

    testWidgets('empty and offline states', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mod-empty')), findsOneWidget);

      store.failReports = true;
      await tester.pumpWidget(
        host(
          CommunityModerationScreen(
            key: UniqueKey(),
            store: store,
            postStore: posts,
            feedStore: feed,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mod-retry')), findsOneWidget);
      store.failReports = false;
      await tester.tap(find.byKey(const Key('mod-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mod-empty')), findsOneWidget);
    });
  });

  group('the Moderation button', () {
    Future<void> openGate(
      WidgetTester tester, {
      required bool moderator,
      bool throwCheck = false,
    }) async {
      final profiles = prof.FakeStore()
        ..myId = 'E' * 20
        ..profiles['E' * 20] = CommunityProfile(
          id: 'E' * 20,
          pseudonym: 'some_name',
          avatar: 'a1',
          bio: '',
          createdAt: DateTime(2026, 11, 1),
        );
      await tester.pumpWidget(
        host(
          CommunityGateScreen(
            controller: CommunityProfileController(profiles),
            feedStore: p.FakeProfiles(),
            safety: CommunitySafety(
              reports: CommunityReportActions(s.FakeReports(), () async => me),
              blocks: CommunityBlocksController(s.FakeBlocks(), () async => me),
            ),
            moderatorCheck: () async {
              if (throwCheck) throw Exception('offline');
              return moderator;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a moderator sees it and can open the screen', (tester) async {
      await openGate(tester, moderator: true);
      expect(find.byKey(const Key('community-moderation')), findsOneWidget);
      expect(find.text('Moderation'), findsOneWidget);
    });

    testWidgets('a normal user does not see it', (tester) async {
      await openGate(tester, moderator: false);
      expect(find.byKey(const Key('community-moderation')), findsNothing);
      expect(find.byKey(const Key('community-saved')), findsOneWidget);
    });

    testWidgets('a failed check means no button', (tester) async {
      await openGate(tester, moderator: true, throwCheck: true);
      expect(find.byKey(const Key('community-moderation')), findsNothing);
    });
  });
}
