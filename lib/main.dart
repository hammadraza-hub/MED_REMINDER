import 'package:flutter/material.dart';

// import 'features/home/home_screen.dart';

import 'main_shell.dart';

void main() {
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
      // home: const HomeScreen(),
      home: const MainShell(),
    );
  }
}
