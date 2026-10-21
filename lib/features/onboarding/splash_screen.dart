import 'dart:async';
import 'dart:math' as math;

import '../../core/constants/app_colors.dart';
import '../../repositories/auth_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main_shell.dart';
import 'onboarding_screen.dart';

/// ============================================================
/// SPLASH SCREEN (M2 — Auth-based routing)
///
/// Listens to Firebase Auth state changes:
///   - No user → OnboardingScreen (Welcome Carousel)
///   - Signed-in user → MedRemindShell (Dashboard)
///
/// M2 Plan: "Splash listens to authStateChanges(): no user goes
/// to Welcome Carousel / Log In, a signed-in user goes to the
/// Dashboard. Don't store tokens yourself, because the Firebase
/// SDK persists and refreshes them securely."
/// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _authSubscription;
  bool _hasNavigated = false;

  // Branding delay — let users see the splash for at least 2 seconds
  // before routing, regardless of how fast auth state resolves.
  static const Duration _brandingDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _listenToAuthState();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────
  // Auth State Listener
  // ───────────────────────────────────────────────────────────

  void _listenToAuthState() {
    _authSubscription = AuthRepository.instance.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (Object error) {
        // On error, default to onboarding (logged-out state)
        debugPrint('⚠️ Auth state stream error: $error');
        _navigateToOnboarding();
      },
    );
  }

  void _onAuthStateChanged(User? user) {
    if (_hasNavigated) return;

    // Wait for branding duration, then route based on auth state
    Timer(_brandingDelay, () {
      if (!mounted || _hasNavigated) return;

      if (user != null) {
        debugPrint('🔥 Auth state: user signed in → ${user.uid}');
        _navigateToDashboard();
      } else {
        debugPrint('🔥 Auth state: no user → onboarding');
        _navigateToOnboarding();
      }
    });
  }

  // ───────────────────────────────────────────────────────────
  // Navigation helpers
  // ───────────────────────────────────────────────────────────

  void _navigateToDashboard() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MedRemindShell()),
    );
  }

  void _navigateToOnboarding() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  // ───────────────────────────────────────────────────────────
  // UI (unchanged)
  // ───────────────────────────────────────────────────────────

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
