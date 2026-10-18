import 'package:flutter/material.dart';

/// A branded circular loading indicator.
///
/// Usage:
/// ```dart
/// LoadingIndicator()
/// LoadingIndicator(size: 40, message: 'Analysing skin...')
/// ```
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 30,
    this.strokeWidth = 3,
    this.message,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final String? message;
  final Color? color;

  static const Color _purple = Color(0xFF7B4DFF);

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? _purple;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            backgroundColor: indicatorColor.withValues(alpha: 0.12),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

/// A full-screen loading overlay.
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({
    super.key,
    this.message = 'Please wait...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
              ),
            ],
          ),
          child: LoadingIndicator(message: message),
        ),
      ),
    );
  }
}
