import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/accessibility/accessibility_controller.dart';
import 'core/locale/locale_controller.dart';
import 'core/profile/profile_controller.dart';
import 'l10n/app_localizations.dart';
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

  // .env se API keys / config load karo (AI assistant ke liye).
  // File missing ho to app na crash ho — sirf AI disabled rahe.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env available nahi — AI features gracefully disabled rahenge.
  }

  // App render hone se pehle last selected family member restore karo.
  //
  // Example:
  // User ne Mom select ki →
  // local_mom SharedPreferences mein persist →
  // app fully close →
  // next launch par yahan local_mom restore →
  // Home SQLite members mein local_mom ko select karega.
  await ProfileController.instance.initialize();

  // App-wide text-size preference (Accessibility screen) restore karo.
  await AccessibilityController.instance.initialize();

  // Selected display language (Language screen) restore karo.
  await LocaleController.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedRemind',
      theme: ThemeData(useMaterial3: true),
      // Display language (Language screen) + RTL support:
      // supportedLocales mein Arabic bhi hai, is liye Arabic select
      // karne par layout automatically right-to-left ho jata hai.
      locale: LocaleController.instance.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // App-wide text scaling (Accessibility screen) + overflow safeguard.
      //
      // System font-scale aur app ke apne text-size preference ko
      // multiply karke ek combined scale banaya jata hai, aur usse safe
      // bounds [0.85, 1.3] ke andar clamp kar dete hain — is tarah text
      // poore app mein scale hota hai lekin fixed-height rows/headers
      // overflow nahi karte.
      builder: (context, child) {
        return ListenableBuilder(
          listenable: AccessibilityController.instance,
          builder: (context, _) {
            final media = MediaQuery.of(context);
            final systemScale = media.textScaler.scale(1.0);
            final combined = systemScale *
                AccessibilityController.instance.textScaleFactor;

            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(combined).clamp(
                  minScaleFactor: AccessibilityController.minScaleFactor,
                  maxScaleFactor: AccessibilityController.maxScaleFactor,
                ),
              ),
              child: child!,
            );
          },
        );
      },
      home: const MedRemindShell(),
    );
        },
      );
  }
}
