import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import 'email_verification_screen.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static const Color purple = Color(0xff7B4DFF);
  static const Color darkText = Color(0xff242424);
  static const Color background = Color(0xffF3EDFF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────
  // CREATE ACCOUNT
  // ─────────────────────────────────────

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Registration failed. Please try again.',
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = auth.currentUser;
    if (user == null) return;

    // Firebase email/password accounts are unverified until the user
    // clicks the verification link — route to EmailVerificationScreen.
    if (!user.isEmailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: user.email),
        ),
      );
      return;
    }

    // Already verified
    await context.read<ReportProvider>().loadReports(user.id);
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(username: user.name),
      ),
      (route) => false,
    );
  }

  // ─────────────────────────────────────
  // EMAIL VALIDATION
  // ─────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final email = value.trim();

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // ─────────────────────────────────────
  // PASSWORD VALIDATION
  // ─────────────────────────────────────

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 6) {
      return 'Password must contain at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;
            final double horizontalPadding = screenWidth < 360 ? 14.0 : 20.0;
            final double cardPadding = screenWidth < 360 ? 16.0 : 22.0;
            final double topPadding = (screenHeight * 0.07).clamp(40.0, 70.0);

            return Stack(
              children: [
                // BACKGROUND GLOW
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
                          purple.withValues(alpha: 0.28),
                          purple.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 160,
                  left: -160,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          purple.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // BACK BUTTON
                if (Navigator.canPop(context))
                  Positioned(
                    top: 12,
                    left: 18,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
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

                // MAIN CONTENT
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    30,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // LOGO
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: purple.withValues(alpha: 0.15),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'DermaVision',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // SIGNUP CARD
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            cardPadding,
                            28,
                            cardPadding,
                            25,
                          ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withValues(alpha: 0.09),
                            blurRadius: 35,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [

                          const Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),

                          const SizedBox(height: 8),

                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              children: [
                                TextSpan(text: 'Join '),
                                TextSpan(
                                  text: 'DermaVision',
                                  style: TextStyle(
                                    color: purple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: ' today'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 26),

                          // NAME
                          _buildInputField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter your name';
                              }

                              if (value.trim().length < 2) {
                                return 'Please enter a valid name';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // EMAIL
                          _buildInputField(
                            controller: _emailController,
                            hintText: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType:
                                TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),

                          const SizedBox(height: 14),

                          // PASSWORD
                          _buildInputField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // CONFIRM PASSWORD
                          _buildInputField(
                            controller:
                                _confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText:
                                _obscureConfirmPassword,
                            validator:
                                _validateConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // CREATE ACCOUNT
                          SizedBox(
                            width: 205,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _createAccount(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purple,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor:
                                    purple.withValues(alpha: 0.30),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(17),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'CREATE ACCOUNT',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // LOGIN LINK
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                            ),
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: purple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  // ─────────────────────────────────────
  // INPUT FIELD
  // ─────────────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: darkText,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: Colors.grey.shade500,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xffF8F6FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: purple,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade300,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}