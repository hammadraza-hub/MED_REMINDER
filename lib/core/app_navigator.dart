import 'package:flutter/material.dart';

/// Root navigator key, for code that must navigate without a BuildContext
/// under the Navigator (e.g. the app-lock overlay, which sits above it).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Root messenger key, for notices that do not belong to one screen (a save
/// that was refused after the phone came back online, a lost session). M20.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Shows [text] as a snackbar on whatever screen is open. Does nothing when
/// the app has no messenger yet.
void showAppNotice(String text) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
}
