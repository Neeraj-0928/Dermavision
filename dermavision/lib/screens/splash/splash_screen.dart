import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFBFAFF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenHeight = constraints.maxHeight;
              final double screenWidth = constraints.maxWidth;

              // Proportional responsive sizing for the illustration
              final double illustrationSize =
                  (screenHeight * 0.38).clamp(180.0, 340.0);
              final double outerCircleSize = illustrationSize * (300 / 340);
              final double glowCircleSize = illustrationSize * (270 / 340);
              final double imageSize = illustrationSize * (260 / 340);

              // Responsive typography and spacing
              final double titleFontSize =
                  (screenHeight * 0.045).clamp(26.0, 38.0);
              final double subtitleFontSize =
                  (screenHeight * 0.02).clamp(13.0, 17.0);
              final double topGap = (screenHeight * 0.038).clamp(14.0, 35.0);
              final double horizontalPadding =
                  screenWidth < 360 ? 24.0 : 45.0;
              final double bottomGap = (screenHeight * 0.045).clamp(20.0, 45.0);

              return Stack(
                children: [
                  /// Top Right Glow
                  Positioned(
                    top: -120,
                    right: -100,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple.withValues(alpha: 0.07),
                      ),
                    ),
                  ),

                  /// Bottom Left Glow
                  Positioned(
                    bottom: -130,
                    left: -100,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purpleAccent.withValues(alpha: 0.08),
                      ),
                    ),
                  ),

                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(),

                            /// AI Illustration
                            AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    math.sin(_floatController.value *
                                            math.pi *
                                            2) *
                                        8,
                                  ),
                                  child: child,
                                );
                              },
                              child: SizedBox(
                                width: illustrationSize,
                                height: illustrationSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    RotationTransition(
                                      turns: _rotateController,
                                      child: Container(
                                        width: outerCircleSize,
                                        height: outerCircleSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xffD9CBFF),
                                            width: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Container(
                                      width: glowCircleSize,
                                      height: glowCircleSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xff7B4DFF)
                                                .withValues(alpha: 0.18),
                                            blurRadius: 90,
                                            spreadRadius: 20,
                                          ),
                                        ],
                                      ),
                                    ),

                                    Image.asset(
                                      "assets/images/splash_ai.png",
                                      width: imageSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: topGap),

                            Text(
                              "DermaVision",
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xff7B4DFF),
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "AI Powered Skin Intelligence",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: const Color(0xff7B7B8B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const Spacer(),

                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(seconds: 4),
                                builder: (context, value, child) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: LinearProgressIndicator(
                                      value: value,
                                      minHeight: 8,
                                      backgroundColor:
                                          const Color(0xffECE6FF),
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                        Color(0xff7B4DFF),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "Initializing AI Engine...",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xff7B7B8B),
                              ),
                            ),

                            SizedBox(height: bottomGap),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}