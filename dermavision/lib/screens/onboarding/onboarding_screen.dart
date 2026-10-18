import 'package:flutter/material.dart';

import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // NEXT / DONE
  void _nextPage() {
    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      // FINAL PAGE → LOGIN
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  // SKIP → PAGE 3
  void _skip() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFBFAFF),

      body: SafeArea(
        child: Column(
          children: [

            // TOP BAR
            SizedBox(
              height: 55,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentPage != 2)
                      TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xff7B4DFF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // PAGES
            Expanded(
              child: PageView(
                controller: _pageController,

                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },

                children: const [
                  PageOne(),
                  PageTwo(),
                  PageThree(),
                ],
              ),
            ),

            // BOTTOM
            Builder(
              builder: (context) {
                final double screenHeight = MediaQuery.of(context).size.height;
                final double bottomPadding = screenHeight < 700 ? 16.0 : 28.0;
                final double buttonSize = screenHeight < 700 ? 52.0 : 58.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    28,
                    8,
                    28,
                    bottomPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // DOTS
                      Row(
                        children: List.generate(
                          3,
                          (index) {
                            final active = _currentPage == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 7),
                              width: active ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xff7B4DFF)
                                    : const Color(0xffDDD7EE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          },
                        ),
                      ),

                      // NEXT / CHECK BUTTON
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            color: const Color(0xff7B4DFF),
                            borderRadius: BorderRadius.circular(19),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff7B4DFF)
                                    .withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _currentPage == 2
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: buttonSize * 0.43,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}