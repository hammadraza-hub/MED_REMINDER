import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/app_error_text.dart';
import 'package:med_remind_app/core/app_exception.dart';
import 'package:med_remind_app/l10n/app_localizations.dart';
import 'package:med_remind_app/l10n/app_localizations_ar.dart';
import 'package:med_remind_app/l10n/app_localizations_en.dart';
import 'package:med_remind_app/l10n/app_localizations_es.dart';
import 'package:med_remind_app/l10n/app_localizations_fr.dart';
import 'package:med_remind_app/l10n/app_localizations_hi.dart';

FirebaseException fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  final locales = <String, AppLocalizations>{
    'en': AppLocalizationsEn(),
    'es': AppLocalizationsEs(),
    'fr': AppLocalizationsFr(),
    'ar': AppLocalizationsAr(),
    'hi': AppLocalizationsHi(),
  };

  group('messages', () {
    test('English text for each kind of error', () {
      final l10n = AppLocalizationsEn();
      expect(
        AppErrorText.of(l10n, fs('unavailable')),
        'No internet connection. Please check it and try again.',
      );
      expect(
        AppErrorText.of(l10n, fs('permission-denied')),
        'You do not have access to this. If something changed, go back and sign in again.',
      );
      expect(
        AppErrorText.of(l10n, fs('not-found')),
        'We could not find this. It may have been removed.',
      );
      expect(
        AppErrorText.of(l10n, fs('invalid-argument')),
        'Something about this is not right. Please check it and try again.',
      );
      expect(
        AppErrorText.of(l10n, fs('internal')),
        'Something went wrong on our side. Please try again in a moment.',
      );
      expect(
        AppErrorText.of(l10n, StateError('x')),
        'Something went wrong. Please try again.',
      );
      expect(
        AppErrorText.of(l10n, TimeoutException('slow')),
        'No internet connection. Please check it and try again.',
      );
    });

    test('an expired session has its own message', () {
      final l10n = AppLocalizationsEn();
      expect(
        AppErrorText.of(l10n, fs('unauthenticated')),
        'Your session has expired. Please sign in again.',
      );
      expect(
        AppErrorText.of(
          l10n,
          FirebaseAuthException(code: 'user-token-expired'),
        ),
        'Your session has expired. Please sign in again.',
      );
    });

    test('the raw developer message is never shown', () {
      final l10n = AppLocalizationsEn();
      final text = AppErrorText.of(
        l10n,
        const AppException.server('INTERNAL: stack trace foo bar'),
      );
      expect(text, isNot(contains('INTERNAL')));
      expect(text, isNot(contains('stack')));
    });

    test('every kind has a non-empty, different text in all 5 languages', () {
      for (final entry in locales.entries) {
        final texts = [
          for (final t in AppExceptionType.values)
            AppErrorText.forType(entry.value, t),
          entry.value.appErrorSessionExpired,
        ];
        expect(
          texts.every((t) => t.trim().isNotEmpty),
          isTrue,
          reason: entry.key,
        );
        expect(texts.toSet().length, texts.length, reason: entry.key);
        expect(entry.value.appErrorRetry.trim(), isNotEmpty, reason: entry.key);
      }
    });

    test('translations are really translated (not the English text)', () {
      final en = AppLocalizationsEn();
      for (final key in ['es', 'fr', 'ar', 'hi']) {
        final l = locales[key]!;
        expect(l.appErrorNetwork, isNot(en.appErrorNetwork), reason: key);
        expect(l.appErrorServer, isNot(en.appErrorServer), reason: key);
        expect(l.appErrorRetry, isNot(en.appErrorRetry), reason: key);
      }
    });
  });

  group('retry and session decisions', () {
    test('retry makes sense for network, server and unknown only', () {
      expect(AppErrorText.canRetry(fs('unavailable')), isTrue);
      expect(AppErrorText.canRetry(fs('deadline-exceeded')), isTrue);
      expect(AppErrorText.canRetry(fs('internal')), isTrue);
      expect(AppErrorText.canRetry(TimeoutException('x')), isTrue);
      expect(AppErrorText.canRetry(StateError('x')), isTrue);

      expect(AppErrorText.canRetry(fs('permission-denied')), isFalse);
      expect(AppErrorText.canRetry(fs('not-found')), isFalse);
      expect(AppErrorText.canRetry(fs('invalid-argument')), isFalse);
      expect(AppErrorText.canRetry(fs('unauthenticated')), isFalse);
    });

    test('session problem vs revoked access', () {
      expect(AppErrorText.isSessionProblem(fs('unauthenticated')), isTrue);
      expect(
        AppErrorText.isSessionProblem(
          FirebaseAuthException(code: 'user-token-revoked'),
        ),
        isTrue,
      );
      expect(AppErrorText.isSessionProblem(fs('permission-denied')), isFalse);

      expect(AppErrorText.isAccessRevoked(fs('permission-denied')), isTrue);
      expect(AppErrorText.isAccessRevoked(fs('unauthenticated')), isFalse);
      expect(AppErrorText.isAccessRevoked(fs('unavailable')), isFalse);
    });

    test('works on an AppException that was already mapped', () {
      final e = AppException.fromAny(fs('unavailable'));
      expect(AppErrorText.canRetry(e), isTrue);
      expect(
        AppErrorText.of(AppLocalizationsEn(), e),
        AppLocalizationsEn().appErrorNetwork,
      );
    });
  });
}
