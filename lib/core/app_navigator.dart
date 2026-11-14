import 'package:flutter/widgets.dart';

/// Root navigator key, for code that must navigate without a BuildContext
/// under the Navigator (e.g. the app-lock overlay, which sits above it).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
