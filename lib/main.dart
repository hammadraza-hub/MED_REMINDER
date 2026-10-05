import 'package:flutter/material.dart';

import 'core/profile/profile_controller.dart';
import 'main_shell.dart';

/// ============================================================
/// APP ENTRY POINT
///
/// App UI start hone se pehle lightweight persisted profile/member
/// selection restore hoti hai.
///
/// IMPORTANT:
/// Selected member ID SharedPreferences se restore hoti hai.
/// Structured health data Drift / SQLite mein hi rahega.
///
/// TODO Backend:
/// Firebase phase mein yahin Firebase.initializeApp(),
/// authentication/session bootstrap aur required startup services
/// initialize kiye ja sakte hain before runApp().
/// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App render hone se pehle last selected family member restore karo.
  //
  // Example:
  // User ne Mom select ki →
  // local_mom SharedPreferences mein persist →
  // app fully close →
  // next launch par yahan local_mom restore →
  // Home SQLite members mein local_mom ko select karega.
  await ProfileController.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedRemind',
      theme: ThemeData(useMaterial3: true),
      home: const MedRemindShell(),
    );
  }
}
