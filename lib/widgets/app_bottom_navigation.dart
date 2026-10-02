import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// ============================================================
/// APP BOTTOM NAVIGATION
///
/// PURPOSE:
/// Puri app ke liye ek single reusable bottom navigation bar.
///
/// TABS:
/// 0 → Home
/// 1 → Meds
/// 2 → Calendar
/// 3 → Reports
/// 4 → Settings
///
/// IMPORTANT:
/// Ye widget sirf bottom navigation ka UI handle karta hai.
/// Actual screen/tab switching MedRemindShell handle karega.
///
/// BENEFIT:
/// • Same font size everywhere
/// • Same icons everywhere
/// • Same colors everywhere
/// • Same spacing everywhere
/// • Duplicate bottom bars ki zarurat nahi
///
/// TODO Navigation:
/// Future mein agar routing Navigator 2.0 / go_router par move hoti hai,
/// tab bhi feature screens ko change karne ke bajaye navigation
/// callback central level par update ki ja sakti hai.
/// ============================================================
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,

      type: BottomNavigationBarType.fixed,

      backgroundColor: AppColors.surface,

      selectedItemColor: AppColors.formAccent,
      unselectedItemColor: AppColors.fieldHint,

      elevation: 6,

      // User-friendly readable size.
      iconSize: 23,

      selectedFontSize: 12,
      unselectedFontSize: 12,

      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),

      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.medication_outlined),
          activeIcon: Icon(Icons.medication_rounded),
          label: 'Meds',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'Reports',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
