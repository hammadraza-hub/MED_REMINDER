import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app_exception.dart';

/// Keeps personal and health data out of logs and crash reports. M21 step 3.
///
/// Two layers:
///  * [redact] / [describe] turn text and errors into something that is safe to
///    print or send: e-mail addresses, phone-like numbers and long ids are
///    replaced, exceptions are reduced to their kind and code.
///  * [install] makes every `debugPrint` of a release / profile build go through
///    [redact], and crash reports go through [reported], so a log line added
///    later by mistake still cannot carry an address or an id.
///
/// The first line of defence is still not to log the data at all (the source
/// scan in `test/safe_log_test.dart` fails on `$email`, `$uid`, medicine
/// names, OCR text and the like inside `print` / `debugPrint`).
class SafeLog {
  SafeLog._();

  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );

  // 7+ digits with optional separators: phone numbers, card-like numbers.
  static final RegExp _number = RegExp(r'\+?\d[\d ()\-]{6,}\d');

  // 20+ character token that mixes letters and digits: Firestore document
  // ids, Firebase uids, FCM tokens, API keys.
  static final RegExp _id = RegExp(
    r'(?=[A-Za-z0-9_\-]{20,})(?=[A-Za-z0-9_\-]*\d)(?=[A-Za-z0-9_\-]*[A-Za-z])'
    r'[A-Za-z0-9_\-]{20,}',
  );

  /// Longest text [redact] returns.
  static const int maxLength = 500;

  /// [text] without e-mail addresses, phone-like numbers and long ids, cut to
  /// [maxLength] characters.
  static String redact(String text) {
    var out = text
        .replaceAll(_email, '<email>')
        .replaceAll(_id, '<id>')
        .replaceAll(_number, '<number>');
    if (out.length > maxLength) out = '${out.substring(0, maxLength)}…';
    return out;
  }

  /// A short, safe description of [error]: only its kind and, where there is
  /// one, its code. The message of an unknown error is redacted and cut to its
  /// first line (messages can carry names or values).
  static String describe(Object error) {
    if (error is FirebaseException) {
      return 'FirebaseException(${error.plugin}/${error.code})';
    }
    if (error is AppException) return 'AppException(${error.type.name})';
    if (error is TimeoutException) return 'TimeoutException';
    final first = error.toString().split('\n').first;
    final safe = redact(first);
    final short = safe.length > 160 ? '${safe.substring(0, 160)}…' : safe;
    return '${error.runtimeType}: $short';
  }

  /// What is sent to Crashlytics instead of the raw error.
  static Object reported(Object error) => SafeReportedError(describe(error));

  static DebugPrintCallback? _original;

  /// Routes every `debugPrint` through [redact] in release and profile builds.
  /// Debug builds keep the full text for development. Safe to call twice.
  static void install({bool force = false}) {
    if (kDebugMode && !force) return;
    _original ??= debugPrint;
    final original = _original!;
    debugPrint = (String? message, {int? wrapWidth}) {
      original(message == null ? null : redact(message), wrapWidth: wrapWidth);
    };
  }

  /// Puts `debugPrint` back (tests).
  @visibleForTesting
  static void uninstall() {
    final original = _original;
    if (original != null) debugPrint = original;
    _original = null;
  }
}

/// An error that only carries an already-safe description.
class SafeReportedError implements Exception {
  const SafeReportedError(this.message);

  final String message;

  @override
  String toString() => message;
}
