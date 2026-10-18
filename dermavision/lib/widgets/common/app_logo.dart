import 'package:flutter/material.dart';

/// Displays the DermaVision app logo — wordmark + optional tagline.
///
/// Usage:
/// ```dart
/// AppLogo()
/// AppLogo(showTagline: true, size: LogoSize.large)
/// ```
enum LogoSize { small, medium, large }

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = LogoSize.medium,
    this.showTagline = false,
    this.color,
  });

  final LogoSize size;
  final bool showTagline;

  /// Override the primary colour (defaults to brand purple).
  final Color? color;

  static const Color _purple = Color(0xFF7B4DFF);

  double get _iconSize {
    switch (size) {
      case LogoSize.small:
        return 28;
      case LogoSize.medium:
        return 38;
      case LogoSize.large:
        return 52;
    }
  }

  double get _titleSize {
    switch (size) {
      case LogoSize.small:
        return 18;
      case LogoSize.medium:
        return 24;
      case LogoSize.large:
        return 34;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = color ?? _purple;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon mark
        Container(
          width: _iconSize * 1.5,
          height: _iconSize * 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [brandColor, brandColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_iconSize * 0.35),
            boxShadow: [
              BoxShadow(
                color: brandColor.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.remove_red_eye_rounded,
            color: Colors.white,
            size: _iconSize,
          ),
        ),

        const SizedBox(height: 10),

        // Wordmark
        Text(
          'DermaVision',
          style: TextStyle(
            fontSize: _titleSize,
            fontWeight: FontWeight.w800,
            color: brandColor,
            letterSpacing: -0.5,
          ),
        ),

        // Tagline (optional)
        if (showTagline) ...[
          const SizedBox(height: 5),
          const Text(
            'AI Powered Skin Intelligence',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7B7B8B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
