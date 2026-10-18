import 'package:flutter/material.dart';

class PageThree extends StatelessWidget {
  const PageThree({super.key});

  static const Color pageBackground = Color(0xffFBFAFF);
  static const Color purple = Color(0xff7B4DFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pageBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double screenHeight = constraints.maxHeight;
          final double boxSize = (screenHeight * 0.44).clamp(180.0, 330.0);
          final double glowSize = boxSize * (250 / 330);
          final double analyticsSize = boxSize * (310 / 330);
          final double gap = (screenHeight * 0.04).clamp(14.0, 38.0);
          final double titleSize = (screenHeight * 0.040).clamp(24.0, 32.0);
          final double bodySize = (screenHeight * 0.022).clamp(13.0, 16.0);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ANALYTICS ILLUSTRATION
                      SizedBox(
                        width: boxSize,
                        height: boxSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft purple glow
                            Container(
                              width: glowSize,
                              height: glowSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    purple.withValues(alpha: 0.14),
                                    purple.withValues(alpha: 0.05),
                                    pageBackground,
                                  ],
                                  stops: const [
                                    0.0,
                                    0.55,
                                    1.0,
                                  ],
                                ),
                              ),
                            ),

                            // Analytics image
                            ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                pageBackground,
                                BlendMode.multiply,
                              ),
                              child: Image.asset(
                                'assets/images/analytics.png',
                                width: analyticsSize,
                                height: analyticsSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: gap),

                      // TITLE
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: titleSize,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xff242424),
                            letterSpacing: -0.5,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Track. Improve.\n',
                            ),
                            TextSpan(
                              text: 'Glow Every Day.',
                              style: TextStyle(
                                color: Color(0xff7B4DFF),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: (gap * 0.45).clamp(10.0, 18.0)),

                      Text(
                        'Monitor your skin health\n'
                        'and see real improvements.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: bodySize,
                          height: 1.55,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}