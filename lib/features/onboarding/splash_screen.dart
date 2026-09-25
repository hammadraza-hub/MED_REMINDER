import 'dart:async';
import 'dart:math' as math;

import '../../core/constants/app_colors.dart';

import 'package:flutter/material.dart';

import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Center Logo Card (Image ke sath)
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/images/med_reminder_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shield_rounded,
                      size: 72,
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tagline
            const Text(
              'Your Health. Your Family. On Time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.brandTeal,
              ),
            ),

            const SizedBox(height: 32),

            // ===== Animated Loading Dots =====
            const _LoadingDots(),

            const Spacer(),

            // Footer
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                '© 2026 MedRemind · Secure & Private',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
//  Animated Loading Dots Widget
//  Dots sequence mein bounce + fade hote hain
// ============================================
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(); // hamesha chalta rahega
  }

  @override
  void dispose() {
    _controller.dispose(); // memory leak se bachao
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Har dot apne cycle mein 1/3 aage shifted hai
            final phase = (_controller.value + i / 3) % 1.0;
            final wave = math.sin(phase * math.pi); // 0 → 1 → 0

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: 0.3 + 0.7 * wave, // dim → bright → dim
                child: Transform.translate(
                  offset: Offset(0, -6 * wave), // neeche → upar → neeche
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.brandTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
