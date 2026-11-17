import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M21 step 6: no secret in the source. Reads the project files (not the
/// build output, not node_modules) and fails on a private key, a service
/// account, a vendor secret, or a Google API key outside the Firebase config
/// files (those keys are public by design; they are protected by App Check,
/// the security rules and the key restrictions in the Google Cloud console).
void main() {
  const skipDirs = {
    '.git',
    '.dart_tool',
    'build',
    'node_modules',
    '.gradle',
    'Pods',
    'graphify-out',
    '.idea',
  };
  const textExt = {
    '.dart',
    '.kt',
    '.java',
    '.swift',
    '.xml',
    '.plist',
    '.json',
    '.js',
    '.ts',
    '.yaml',
    '.yml',
    '.gradle',
    '.kts',
    '.properties',
    '.md',
    '.rules',
    '.txt',
    '.sh',
    '.py',
    '.example',
  };

  // Where a Firebase client key is expected.
  bool firebaseConfigFile(String path) {
    final p = path.replaceAll('\\', '/');
    return p.endsWith('google-services.json') ||
        p.endsWith('GoogleService-Info.plist') ||
        RegExp(r'lib/firebase_options[a-z_]*\.dart$').hasMatch(p);
  }

  List<File> projectFiles() {
    final out = <File>[];
    void walk(Directory d) {
      for (final e in d.listSync(followLinks: false)) {
        final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (e is Directory) {
          if (!skipDirs.contains(name)) walk(e);
        } else if (e is File) {
          // The real .env is gitignored and is checked separately below.
          if (name == '.env') continue;
          final dot = name.lastIndexOf('.');
          final ext = dot < 0 ? '' : name.substring(dot);
          if (textExt.contains(ext) && e.lengthSync() < 2000000) out.add(e);
        }
      }
    }

    walk(Directory('.'));
    return out;
  }

  final patterns = <String, RegExp>{
    'private key': RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    'AWS access key': RegExp(r'AKIA[0-9A-Z]{16}'),
    'service account file': RegExp(r'"type"\s*:\s*"service_account"'),
    'Twilio account sid': RegExp(r'\bAC[0-9a-f]{32}\b'),
    'vendor secret': RegExp(
      r'\b(sk_(live|test)_[0-9A-Za-z]{16,}|goog_[0-9A-Za-z]{20,}'
      r'|appl_[0-9A-Za-z]{20,}|sk-ant-[0-9A-Za-z_\-]{20,}'
      r'|sk-[0-9A-Za-z]{32,})\b',
    ),
    'JWT': RegExp(
      r'\beyJ[0-9A-Za-z_\-]{20,}\.[0-9A-Za-z_\-]{20,}\.[0-9A-Za-z_\-]{10,}',
    ),
  };
  final googleKey = RegExp(r'AIza[0-9A-Za-z_\-]{35}');

  test('no secret patterns in the project files', () {
    final hits = <String>[];
    for (final f in projectFiles()) {
      final text = f.readAsStringSync(
        encoding: const Utf8Codec(allowMalformed: true),
      );
      for (final e in patterns.entries) {
        if (e.value.hasMatch(text)) hits.add('${f.path}: ${e.key}');
      }
      if (!firebaseConfigFile(f.path) && googleKey.hasMatch(text)) {
        hits.add('${f.path}: Google API key outside the Firebase config files');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('the real .env and signing files are gitignored', () {
    final ignore = File('.gitignore').readAsStringSync();
    for (final entry in [
      '.env',
      '*.jks',
      'android/key.properties',
      '*.keystore',
    ]) {
      expect(ignore, contains(entry), reason: '.gitignore must list $entry');
    }
  });

  test('.env is not shipped inside the app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'assets:\s*((?:\s*-[^\n]*\n)+)').firstMatch(pubspec);
    expect(assets?.group(1) ?? '', isNot(contains('.env')));
    expect(pubspec, isNot(contains('flutter_dotenv')));
  });

  test('.env.example holds placeholders only, no real value', () {
    for (final line in File('.env.example').readAsLinesSync()) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      final value = t.split('=').skip(1).join('=').trim();
      // A placeholder (PASTE_YOUR_KEY_HERE) or a model name is short; a real
      // API key is 39 characters or more.
      expect(
        value.length,
        lessThanOrEqualTo(32),
        reason: 'looks like a real value: ${t.split('=').first}',
      );
      expect(googleKey.hasMatch(value), isFalse);
    }
  });
}
