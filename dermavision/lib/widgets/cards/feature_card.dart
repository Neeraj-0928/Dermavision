import 'package:flutter/material.dart';

/// A reusable feature card used on the home screen and elsewhere.
///
/// Usage:
/// ```dart
/// FeatureCard(
///   icon: Icons.bar_chart_rounded,
///   title: 'My Reports',
///   subtitle: 'View all your scan history',
///   onTap: () {},
/// )
/// ```
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.iconBackground,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackground;
  final Widget? trailing;

  static const Color _purple = Color(0xFF7B4DFF);
  static const Color _lightPurple = Color(0xFFF0E9FF);
  static const Color _darkText = Color(0xFF252530);
  static const Color _secondaryText = Color(0xFF676773);

  @override
  Widget build(BuildContext context) {
    final fgColor = iconColor ?? _purple;
    final bgColor = iconBackground ?? _lightPurple;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B4DFF).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: fgColor, size: 24),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing widget or default chevron
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _secondaryText,
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }
}
