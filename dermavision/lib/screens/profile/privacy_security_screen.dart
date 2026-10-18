import 'package:flutter/material.dart';

import 'help_support_screen.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  static const Color purple = Color(0xFF7B4DFF);
  static const Color lightPurple = Color(0xFFF0E9FF);
  static const Color background = Color(0xFFFBFAFF);
  static const Color darkText = Color(0xFF20202A);
  static const Color secondaryText = Color(0xFF666672);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkText,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double hPad =
                (constraints.maxWidth * 0.05).clamp(16.0, 22.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 22),

                  // ============================================================
                  // PRIVACY POLICY SECTION
                  // ============================================================
                  _buildSectionHeader(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                  ),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBodyText(
                          'DermaVision collects and stores specific information necessary to deliver account services and skin screening history:',
                        ),
                        const SizedBox(height: 12),
                        _buildBullet(
                          'Account Information: The app collects account information such as your name and email address when you register and sign in.',
                        ),
                        _buildBullet(
                          'Scan & Report Storage: The app stores scan and report information (including captured skin images and AI assessment results) associated with your user account so you can view your history across sessions.',
                        ),
                        const SizedBox(height: 12),
                        _buildBodyText(
                          'Firebase Authentication is used for user login and account management. Authentication credentials and account identity are managed through Firebase services.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ============================================================
                  // MEDICAL DISCLAIMER SECTION
                  // ============================================================
                  _buildSectionHeader(
                    icon: Icons.medical_services_outlined,
                    title: 'Medical Disclaimer',
                  ),
                  const SizedBox(height: 10),
                  _buildCard(
                    highlight: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECC8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFC76A00),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'DermaVision provides AI-based preliminary skin analysis and is not a substitute for professional medical diagnosis. Users should consult a qualified dermatologist for confirmation.',
                                  style: TextStyle(
                                    color: Color(0xFF8A4400),
                                    fontSize: 12.5,
                                    height: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBullet(
                          'Preliminary Screening: AI-generated screening results are for educational and preliminary awareness only. They do not constitute official clinical medical advice or diagnosis.',
                        ),
                        _buildBullet(
                          'Consult Qualified Doctors: Always consult a licensed dermatologist or medical practitioner for formal diagnosis, clinical evaluation, and treatment decisions.',
                        ),
                        _buildBullet(
                          'AI Assessment Limitations: Artificial intelligence models can produce false positives, false negatives, or inaccurate results and cannot replace an in-person physical examination.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ============================================================
                  // ACCOUNT & DATA SECTION
                  // ============================================================
                  _buildSectionHeader(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Account & Data',
                  ),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBodyText(
                          'You can manage your account information and use the available account management options in the app:',
                        ),
                        const SizedBox(height: 12),
                        _buildBullet(
                          'Update Profile: Users can update their profile information, such as their display name, phone number, and profile picture, at any time from the Edit Profile screen.',
                        ),
                        _buildBullet(
                          'Password Management: You can update your password from the Profile screen under "Change Password", or request a reset link if you forgot your credentials.',
                        ),
                        _buildBullet(
                          'Session Control: You can securely log out of your account at any time using the Log Out option on your Profile page.',
                        ),
                        _buildBullet(
                          'Account-Linked Scans: Your past skin assessments and generated reports remain associated with your signed-in account for review in "My Reports".',
                        ),
                        const SizedBox(height: 12),
                        _buildBodyText(
                          'For additional questions or support regarding your account, please visit the Help & Support section.',
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HelpSupportScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.help_outline_rounded, size: 16),
                            label: const Text(
                              'Go to Help & Support',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: purple,
                              side: const BorderSide(color: purple, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      'DermaVision Privacy & Security • Version 1.0.0',
                      style: TextStyle(
                        color: secondaryText.withValues(alpha: 0.65),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8755FF), Color(0xFF6330E8)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy & Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Understand how your account data is handled and review our medical disclaimer.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: lightPurple,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: purple, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child, bool highlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFFBF5) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: highlight
            ? Border.all(color: const Color(0xFFFFDFA6), width: 1.2)
            : Border.all(color: const Color(0xFFF0EAFF), width: 1),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? Colors.orange.withValues(alpha: 0.06)
                : purple.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: secondaryText,
        fontSize: 12.5,
        height: 1.55,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: purple,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 12.5,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
