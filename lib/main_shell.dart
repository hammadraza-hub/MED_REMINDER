import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'features/home/home_screen.dart';
import 'features/meds/meds_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'widgets/app_bottom_navigation.dart';

/// ============================================================
/// MED REMIND MAIN SHELL
///
/// PURPOSE:
/// App ke 5 main tabs ko manage karta hai.
///
/// TABS:
/// 0 → Home
/// 1 → Meds
/// 2 → Calendar
/// 3 → Reports
/// 4 → Settings
///
/// ARCHITECTURE:
/// • Main tab switching yahan hoti hai.
/// • Shared bottom bar AppBottomNavigation se aati hai.
/// • IndexedStack tab state preserve karta hai.
/// • Detail screens initialIndex ke through kisi specific
///   main tab par wapas aa sakti hain.
///
/// IMPORTANT:
/// Main tab screens apni duplicate bottom navigation NAHI rakhen.
///
/// Example:
/// const MedRemindShell(initialIndex: 1) → Meds
/// const MedRemindShell(initialIndex: 2) → Calendar
///
/// TODO Navigation:
/// Future mein go_router / Navigator 2.0 use karne par shell
/// navigation centralized routing ke saath integrate ki ja sakti hai.
/// ============================================================
class MedRemindShell extends StatefulWidget {
  const MedRemindShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MedRemindShell> createState() => _MedRemindShellState();
}

class _MedRemindShellState extends State<MedRemindShell> {
  late int _currentIndex;

  static const List<Widget> _tabs = [
    HomeScreen(),
    MedsScreen(),
    CalendarScreen(),
    _PlaceholderTab(title: 'Reports', icon: Icons.bar_chart_rounded),
    _PlaceholderTab(title: 'Settings', icon: Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();

    // Safety:
    // Agar galti se invalid index pass ho jaye to app crash na kare.
    _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

  void _onBottomNavigationTap(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationTap,
      ),
    );
  }
}

/// ============================================================
/// PLACEHOLDER TAB
///
/// Reports aur Settings ki actual screens banne tak
/// temporary placeholder.
/// ============================================================
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.fieldHint),
          const SizedBox(height: 16),
          Text(
            '$title — coming soon',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
