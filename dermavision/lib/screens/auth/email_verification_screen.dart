import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color purple = Color(0xFF7B4DFF);
  static const Color darkText = Color(0xFF242424);
  static const Color background = Color(0xFFF3EDFF);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _verificationTimer;
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-poll for verification every 5 seconds
    _verificationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerificationSilently(),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationSilently() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerification();
    if (verified && mounted) {
      _verificationTimer?.cancel();
      _navigateToHome();
    }
  }

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerification();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (verified) {
      _verificationTimer?.cancel();
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not yet verified. Please click the link in your inbox.',
          ),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.sendEmailVerification();

    if (!mounted) return;
    setState(() {
      _isResending = false;
      if (success) {
        _resendCooldown = 60;
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Check your inbox and spam folder.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) t.cancel();
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Could not send verification email. Try again shortly.',
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToHome() {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      context.read<ReportProvider>().loadReports(auth.currentUser!.id);
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(username: auth.displayName),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenHeight = constraints.maxHeight;
            final double screenWidth = constraints.maxWidth;
            final double topPadding = (screenHeight * 0.07).clamp(30.0, 75.0);
            final double iconContainerSize =
                (screenHeight * 0.13).clamp(80.0, 110.0);
            final double iconSize = iconContainerSize * 0.47;

            return Stack(
              children: [
                // Background glows
                Positioned(
                  top: -100,
                  right: -80,
                  child: Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          purple.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  left: -90,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          purple.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Back to Login
                Positioned(
                  top: 12,
                  left: 18,
                  child: GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.88),
                        border: Border.all(
                          color: purple.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: purple,
                      ),
                    ),
                  ),
                ),

                // Main content
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    screenWidth < 360 ? 16 : 24,
                    topPadding,
                    screenWidth < 360 ? 16 : 24,
                    30,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - topPadding - 30,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated envelope icon
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: iconContainerSize,
                              height: iconContainerSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    purple.withValues(alpha: 0.15),
                                    purple.withValues(alpha: 0.07),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: purple.withValues(alpha: 0.18),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.mark_email_unread_rounded,
                                color: purple,
                                size: iconSize,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Verify Your Email',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'We sent a verification link to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            constraints: BoxConstraints(
                              maxWidth: screenWidth - 48,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: purple.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              widget.email,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: purple,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                    const SizedBox(height: 14),

                    Text(
                      'Click the link in the email to verify your account. '
                      'This page checks automatically every 5 seconds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Auto-checking indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(
                              purple.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Checking automatically...',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Check now button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isChecking ? null : _checkNow,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded,
                                size: 18),
                        label: Text(
                          _isChecking
                              ? 'Checking...'
                              : "I've Verified — Continue",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: purple.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Resend button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: (_resendCooldown > 0 || _isResending)
                            ? null
                            : _resendEmail,
                        icon: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : _isResending
                                  ? 'Sending...'
                                  : 'Resend Verification Email',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: purple,
                          side: BorderSide(
                            color: purple.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
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
);
}
}
