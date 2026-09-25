import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'features/home/home_screen.dart';

/// App ka navigation SHELL — bottom bar + tabs yahan.
/// Har tab apni screen; screens apni bottom nav NAHI rakhtin!
///
/// IndexedStack ka faida: tab switch par state save rehta hai —
/// Home ka scroll, filters — sab yaad rehta hai! 🎯
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    _PlaceholderTab(title: 'Meds', icon: Icons.medication_rounded),
    _PlaceholderTab(title: 'Calendar', icon: Icons.calendar_month_rounded),
    _PlaceholderTab(title: 'Reports', icon: Icons.bar_chart_rounded),
    _PlaceholderTab(title: 'Settings', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.formAccent, // ← SYSTEM! ✅
        unselectedItemColor: AppColors.fieldHint, // ← SYSTEM! ✅
        backgroundColor: AppColors.surface,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_rounded),
            label: 'Meds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Tab placeholder — asli screens baad mein banengi
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
