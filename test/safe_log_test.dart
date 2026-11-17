import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/core/safe_log.dart';

void main() {
  group('SafeLog.redact', () {
    test('e-mail addresses', () {
      expect(
        SafeLog.redact('sign in failed for sara.k+test@example.co.uk now'),
        'sign in failed for <email> now',
      );
    });

    test('phone-like numbers', () {
      expect(
        SafeLog.redact('call +1 (555) 010-0199 please'),
        'call <number> please',
      );
      expect(SafeLog.redact('03001234567'), '<number>');
    });

    test('long ids with letters and digits (uids, document ids, tokens)', () {
      expect(
        SafeLog.redact('doc profiles/P3tjfL11KArcsiiG4xveB5eHsJec/doses/r8'),
        'doc profiles/<id>/doses/r8',
      );
      expect(
        SafeLog.redact('token fcm:APA91bHxyz_abc-123456789012345'),
        contains('<id>'),
      );
    });

    test('ordinary text, short ids, versions and class names stay readable', () {
      const ok =
          'AppStartup: remote-config failed (v1.2.3+45) in CommunityFeedController';
      expect(SafeLog.redact(ok), ok);
      expect(SafeLog.redact('profiles/pO/doses/r8'), 'profiles/pO/doses/r8');
    });

    test('long text is cut', () {
      final out = SafeLog.redact('x' * 2000);
      expect(out.length, SafeLog.maxLength + 1); // + the ellipsis
      expect(out.endsWith('…'), isTrue);
    });
  });

  group('SafeLog.describe', () {
    test('Firebase errors: plugin and code only', () {
      final e = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing permission for profiles/abc123XYZabc123XYZab1/doses',
      );
      expect(
        SafeLog.describe(e),
        'FirebaseException(cloud_firestore/permission-denied)',
      );
    });

    test('AppException: its type only (its message can name a medicine)', () {
      final e = AppException.validation('Cannot log Metformin for Sara');
      final text = SafeLog.describe(e);
      expect(text, 'AppException(validation)');
      expect(text, isNot(contains('Metformin')));
    });

    test('timeouts', () {
      expect(SafeLog.describe(TimeoutException('x')), 'TimeoutException');
    });

    test('unknown errors: kind + redacted first line only', () {
      final text = SafeLog.describe(
        StateError(
          'bad state for sara@example.com\nsecond line with Metformin',
        ),
      );
      expect(text, startsWith('StateError: '));
      expect(text, contains('<email>'));
      expect(text, isNot(contains('sara@')));
      expect(text, isNot(contains('Metformin'))); // second line dropped
    });

    test('reported() wraps the safe text for Crashlytics', () {
      final r = SafeLog.reported(StateError('x for a@b.co'));
      expect(r, isA<SafeReportedError>());
      expect(r.toString(), isNot(contains('a@b.co')));
    });
  });

  group('SafeLog.install', () {
    final printed = <String?>[];
    late DebugPrintCallback saved;

    setUp(() {
      saved = debugPrint;
      printed.clear();
      debugPrint = (String? m, {int? wrapWidth}) => printed.add(m);
    });

    tearDown(() {
      SafeLog.uninstall();
      debugPrint = saved;
    });

    test('every debugPrint is redacted afterwards', () {
      SafeLog.install(force: true);
      debugPrint('login by sara@example.com on 03001234567');
      expect(printed.single, 'login by <email> on <number>');
    });

    test('installing twice does not redact twice or loop', () {
      SafeLog.install(force: true);
      SafeLog.install(force: true);
      debugPrint('a@b.co');
      expect(printed, ['<email>']);
    });

    test('a null message is passed through', () {
      SafeLog.install(force: true);
      debugPrint(null);
      expect(printed, [null]);
    });

    test('uninstall puts the original back', () {
      SafeLog.install(force: true);
      SafeLog.uninstall();
      debugPrint('a@b.co');
      expect(printed, ['a@b.co']);
    });
  });

  // The cheapest protection is not to log the data at all. This reads every
  // source file and fails when a print / debugPrint call names a personal or
  // health field. If it fails: log a count or an error code instead.
  group('source scan: no personal or health data in print / debugPrint', () {
    final risky = RegExp(
      r'\b(email|uid|displayName|medName|doseLabel|reasonText|phone|symptom'
      r'|strength|frequency|instructions|payload|address|dob|conditions'
      r'|allerg\w*)\b|\blines\[|\.body\b|\.note\b',
      caseSensitive: false,
    );

    String callAt(List<String> lines, int start) {
      final buf = StringBuffer();
      for (var i = start; i < lines.length && i < start + 8; i++) {
        buf.writeln(lines[i]);
        if (lines[i].trimRight().endsWith(');')) break;
      }
      return buf.toString();
    }

    test('lib/ has no risky log call', () {
      final hits = <String>[];
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final f in files) {
        if (f.path.replaceAll('\\', '/').endsWith('core/safe_log.dart')) {
          continue;
        }
        final lines = f.readAsLinesSync(
          encoding: const Utf8Codec(allowMalformed: true),
        );
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (!RegExp(r'\b(print|debugPrint)\(').hasMatch(line)) continue;
          if (line.trimLeft().startsWith('//')) continue;
          final call = callAt(lines, i);
          // Only what is INSERTED into the message matters (`$x`, `${x.y}`),
          // not words in the fixed text.
          final interpolated = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*')
              .allMatches(call)
              .map((x) => x.group(0)!)
              .join(' ');
          final m = risky.firstMatch(interpolated);
          if (m != null) {
            hits.add('${f.path}:${i + 1}  (${m.group(0)})  ${line.trim()}');
          }
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            'These log calls name personal or health data:\n${hits.join('\n')}',
      );
    });

    test('print( is never used (use debugPrint, which is redacted)', () {
      final hits = <String>[];
      for (final f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = f.readAsLinesSync(
          encoding: const Utf8Codec(allowMalformed: true),
        );
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'(^|[^A-Za-z_.])print\(').hasMatch(lines[i]) &&
              !lines[i].trimLeft().startsWith('//')) {
            hits.add('${f.path}:${i + 1}');
          }
        }
      }
      expect(hits, isEmpty);
    });
  });
}
