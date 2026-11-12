import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool _precacheDone = false;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding_1.jpg',
      'title': 'Never Miss a Dose',
      'subtitle': 'Get timely reminders for every medication — for you and your whole family — automatically.',
    },
    {
      'image': 'assets/images/onboarding_2.jpg',
      'title': 'Stay on Track',
      'subtitle': 'Keep your medication schedule organized — simple, clear, and reliable — every day.',
    },
    {
      'image': 'assets/images/onboarding_3.jpg',
      'title': 'Care for Your Family',
      'subtitle': 'Manage medication reminders for your loved ones — all from one place — easily.',
    },
    {
      'image': 'assets/images/onboarding_4.jpg',
      'title': 'Your Health, Simplified',
      'subtitle': 'Build healthier medication habits — with reminders that fit — your routine.',
    },
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_precacheDone) return;

    _precacheDone = true;

    for (final page in _pages) {
      precacheImage(AssetImage(page['image']!), context);
    }

    precacheImage(
      const AssetImage('assets/images/med_reminder_logo.png'),
      context,
    );

    for (final asset in [
      'assets/images/signup_pill1.jpg',
      'assets/images/signup_pill2.jpg',
      'assets/images/signup_pill3.jpg',
    ]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  void _goToSignup() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  void _nextPage() {
    if (_isLastPage) {
      _goToSignup();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);

          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final double topSafe = media.padding.top;
          final double bottomSafe = media.padding.bottom;

          // =====================================================
          // DEVICE
          // =====================================================

          final bool landscape = width > height;

          final double shortestSide = math.min(width, height);

          final bool tablet = shortestSide >= 600;
          final bool largeTablet = shortestSide >= 800;

          final bool compactPhone = !tablet && height < 700;

          // =====================================================
          // HERO
          // =====================================================

          final double heroWidth = width;

          double heroHeight;

          if (tablet) {
            if (landscape) {
              // iPad/tablet landscape
              heroHeight = height * 0.58;
            } else {
              // iPad Mini / iPad / iPad Pro portrait
              // Mobile jaisi hero proportion
              heroHeight = height * 0.54;
            }
          } else if (compactPhone) {
            heroHeight = height * 0.43;
          } else {
            heroHeight = height * 0.48;
          }

          // Only phones need this clamp.
          // Tablet ko clamp nahi karenge, warna iPad Pro par chota ho jayega.
          if (!tablet) {
            heroHeight = heroHeight.clamp(230.0, 440.0);
          }

          // =====================================================
          // TEXT
          // =====================================================

          final double titleSize = largeTablet
              ? 38
              : tablet
              ? 34
              : compactPhone
              ? 24
              : 28;

          final double subtitleSize = largeTablet
              ? 19
              : tablet
              ? 17
              : compactPhone
              ? 14
              : 15.5;

          // =====================================================
          // TEXT WIDTH
          // =====================================================

          final double titleMaxWidth;

          final double subtitleMaxWidth;

          if (largeTablet) {
            titleMaxWidth = math.min(width * 0.72, 800);
            subtitleMaxWidth = math.min(width * 0.70, 720);
          } else if (tablet) {
            titleMaxWidth = math.min(width * 0.78, 680);
            subtitleMaxWidth = math.min(width * 0.72, 620);
          } else {
            titleMaxWidth = width - 40;
            subtitleMaxWidth = math.min(width - 48, 430);
          }

          // =====================================================
          // BUTTON
          // =====================================================

          final double buttonWidth;

          if (largeTablet) {
            buttonWidth = math.min(width * 0.55, 620);
          } else if (tablet) {
            buttonWidth = math.min(width * 0.65, 560);
          } else {
            buttonWidth = width - 48;
          }

          final double buttonHeight = largeTablet
              ? 64
              : tablet
              ? 60
              : compactPhone
              ? 50
              : 56;

          // =====================================================
          // OVERLAY
          // =====================================================

          final double horizontalMargin = largeTablet
              ? 40
              : tablet
              ? 32
              : 20;

          final double overlayTop = topSafe + (tablet ? 18 : 14);

          // =====================================================
          // SPACING
          // =====================================================

          final double dotsGap = tablet ? 10 : 7;

          final double titleGap = largeTablet
              ? 26
              : tablet
              ? 22
              : compactPhone
              ? 13
              : 20;

          final double subtitleGap = tablet ? 14 : 11;

          return Stack(
            children: [
              // =================================================
              // PAGES
              // =================================================
              PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Column(
                    children: [
                      // ==========================================
                      // HERO IMAGE
                      // ==========================================

                      SizedBox(
                        width: heroWidth,
                        height: heroHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            // ====================================
                            // IMAGE
                            // ====================================

                            Image.asset(
                              page['image']!,
                              width: heroWidth,
                              height: heroHeight,

                              // Tablet/iPad:
                              // complete image visible.
                              //
                              // Phone:
                              // preserve existing design.
                              fit: BoxFit.cover,

                              alignment: Alignment.center,

                              filterQuality: FilterQuality.medium,

                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primaryLight,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.medication_rounded,
                                    color: AppColors.primary,
                                    size: tablet ? 120 : 90,
                                  ),
                                );
                              },
                            ),

                            // ====================================
                            // BOTTOM FADE
                            // ====================================
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -4,
                              height: largeTablet
                                  ? 160
                                  : tablet
                                  ? 135
                                  : 100,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.48, 0.82, 1.0],
                                      colors: [
                                        AppColors.background.withValues(
                                          alpha: 0,
                                        ),
                                        AppColors.background.withValues(
                                          alpha: 0.35,
                                        ),
                                        AppColors.background.withValues(
                                          alpha: 0.94,
                                        ),
                                        AppColors.background,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==========================================
                      // DOTS
                      // ==========================================
                      SizedBox(height: dotsGap),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _currentPage;

                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              margin: EdgeInsets.symmetric(
                                horizontal: tablet ? 5 : 4,
                              ),
                              width: active
                                  ? largeTablet
                                        ? 38
                                        : tablet
                                        ? 32
                                        : 27
                                  : largeTablet
                                  ? 11
                                  : tablet
                                  ? 9
                                  : 8,
                              height: largeTablet
                                  ? 11
                                  : tablet
                                  ? 9
                                  : 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.dotInactive,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: titleGap),

                      // ==========================================
                      // TITLE
                      // ==========================================
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: titleMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            page['title']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: titleSize,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: subtitleGap),

                      // ==========================================
                      // SUBTITLE
                      // ==========================================
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: subtitleMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            page['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textTeal,
                              fontSize: subtitleSize,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ==========================================
                      // BUTTON
                      // ==========================================
                      SafeArea(
                        top: false,
                        minimum: EdgeInsets.only(
                          bottom: math.max(tablet ? 20 : 12, bottomSafe),
                        ),
                        child: SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primaryDark.withValues(
                                alpha: 0.22,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  tablet ? 18 : 15,
                                ),
                              ),
                            ),
                            child: Text(
                              _isLastPage ? 'Get Started →' : 'Next →',
                              style: TextStyle(
                                fontSize: largeTablet
                                    ? 20
                                    : tablet
                                    ? 18
                                    : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // =================================================
              // BRAND
              // =================================================
              Positioned(
                top: overlayTop,
                left: horizontalMargin,
                child: Container(
                  height: largeTablet
                      ? 58
                      : tablet
                      ? 52
                      : 47,
                  padding: EdgeInsets.symmetric(
                    horizontal: largeTablet
                        ? 20
                        : tablet
                        ? 18
                        : 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/med_reminder_logo.png',
                        width: largeTablet
                            ? 31
                            : tablet
                            ? 27
                            : 24,
                        height: largeTablet
                            ? 31
                            : tablet
                            ? 27
                            : 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.primary,
                            size: tablet ? 27 : 24,
                          );
                        },
                      ),
                      SizedBox(width: tablet ? 11 : 9),
                      Text(
                        'MedRemind',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: largeTablet
                              ? 20
                              : tablet
                              ? 17
                              : 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =================================================
              // SKIP
              // =================================================
              Positioned(
                top: overlayTop + (tablet ? 5 : 4),
                right: horizontalMargin,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goToSignup,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: largeTablet
                          ? 48
                          : tablet
                          ? 42
                          : 39,
                      padding: EdgeInsets.symmetric(
                        horizontal: largeTablet
                            ? 21
                            : tablet
                            ? 18
                            : 16,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textTeal,
                          fontSize: largeTablet
                              ? 17
                              : tablet
                              ? 15
                              : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
