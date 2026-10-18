import 'package:flutter/material.dart';

class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenHeight = constraints.maxHeight;
        final double imageSize = (screenHeight * 0.44).clamp(180.0, 360.0);
        final double gap = (screenHeight * 0.042).clamp(16.0, 42.0);
        final double titleSize = (screenHeight * 0.042).clamp(24.0, 34.0);
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
                    // AI Illustration
                    Image.asset(
                      'assets/images/onboarding_ai.png',
                      height: imageSize,
                      width: imageSize,
                      fit: BoxFit.contain,
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
                            text: 'Smart AI\n',
                          ),
                          TextSpan(
                            text: 'Skin Analysis',
                            style: TextStyle(
                              color: Color(0xff7B4DFF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: (gap * 0.45).clamp(10.0, 18.0)),

                    Text(
                      'Detect skin conditions early using\n'
                      'advanced AI technology.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: bodySize,
                        height: 1.55,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}