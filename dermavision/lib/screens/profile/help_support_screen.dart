import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/clinic_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // Theme colors consistent with DermaVision design
  static const Color purple = Color(0xFF7B4DFF);
  static const Color lightPurple = Color(0xFFF0E9FF);
  static const Color background = Color(0xFFFBFAFF);
  static const Color darkText = Color(0xFF20202A);
  static const Color secondaryText = Color(0xFF666672);

  // Placeholder support email that can be easily changed later
  static const String supportEmail = 'dermavision@gmail.com';

  // State to track expanded FAQ item
  int? _expandedIndex;

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I scan skin lesions using Camera or Gallery?',
      'icon': Icons.camera_alt_outlined,
      'answer':
          'DermaVision provides two convenient ways to scan skin lesions:\n\n'
          '1. Camera Scan: Go to the Scan tab and select Camera. Align the camera so the skin lesion is centered, sharp, and clearly visible under good lighting. Tap the shutter button to take the photo.\n\n'
          '2. Gallery Upload: On the Scan screen, tap Gallery to select an existing high-resolution photo from your device.\n\n'
          'Once the photo is captured or selected, confirm the preview to start the preliminary AI analysis.',
    },
    {
      'question': 'How do I view my previous scan history?',
      'icon': Icons.history_rounded,
      'answer':
          'You can access all past skin assessments from the "My Reports" screen (accessible from the bottom navigation or the Home screen).\n\n'
          'Each report in your history displays the detected condition, risk level, confidence score, and timestamp. Tapping any report card opens the full analysis breakdown.',
    },
    {
      'question': 'How do I download or share a PDF report?',
      'icon': Icons.download_rounded,
      'answer':
          'You can download a PDF report from any scan result screen:\n\n'
          '1. Perform a new skin scan or select an existing scan from "My Reports".\n'
          '2. On the Result screen, tap the "Download Report" button.\n'
          '3. DermaVision will compile a structured PDF report containing your patient details, scan image, predicted condition, confidence score, and clinical recommendations.\n\n'
          'You can then save the file to your device, print it, or share it with your healthcare provider.',
    },
    {
      'question': 'How do I find nearby dermatologists?',
      'icon': Icons.location_on_outlined,
      'hasAction': true,
      'answer':
          'DermaVision can help you locate certified dermatologists in your area:\n\n'
          '• From the Home screen, tap "Find Dermatologists near you".\n'
          '• Alternatively, on any scan Result screen, tap "Find Nearby Dermatologist".\n\n'
          'This will automatically open Google Maps showing licensed dermatologists and skin clinics near your current location.',
    },
    {
      'question': 'How do I reset or change my password?',
      'icon': Icons.lock_reset_rounded,
      'answer':
          'You can reset your account password in two ways:\n\n'
          '• If you are logged in: Go to the Profile screen and tap "Change Password". Enter your current password and your new password to update it directly.\n\n'
          '• If you forgot your password: On the Login screen, tap "Forgot Password?". Enter your registered email address and Firebase Authentication will send a secure password reset link to your email inbox.',
    },
  ];

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'DermaVision Support Request',
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        _copyEmail();
      }
    } catch (_) {
      _copyEmail();
    }
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Support email copied to clipboard!'),
          ],
        ),
        backgroundColor: purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
          'Help & Support',
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
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.support_agent_rounded,
                    title: 'Contact Support',
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(),
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    icon: Icons.help_outline_rounded,
                    title: 'Frequently Asked Questions',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqList(),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'DermaVision Support • Version 1.0.0',
                          style: TextStyle(
                            color: secondaryText.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Need further help? We typically respond within 24 hours.',
                          style: TextStyle(
                            color: secondaryText.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.all(20),
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
              Icons.help_center_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Browse our FAQs or reach out directly to our support team.',
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

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EAFF), width: 1),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need direct assistance? You can reach our support team anytime via email.',
            style: TextStyle(
              color: secondaryText,
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEBE6F8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: lightPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Email',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        supportEmail,
                        style: TextStyle(
                          color: darkText,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy email',
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: purple,
                    size: 19,
                  ),
                  onPressed: _copyEmail,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text(
                    'Email Support',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyEmail,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copy Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    side: const BorderSide(color: purple, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqList() {
    return Column(
      children: List.generate(_faqs.length, (index) {
        final faq = _faqs[index];
        final bool isExpanded = _expandedIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isExpanded ? purple.withValues(alpha: 0.5) : const Color(0xFFF0EAFF),
              width: isExpanded ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? purple.withValues(alpha: 0.08)
                    : purple.withValues(alpha: 0.035),
                blurRadius: isExpanded ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isExpanded ? purple : lightPurple,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            faq['icon'] as IconData,
                            color: isExpanded ? Colors.white : purple,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              faq['question'] as String,
                              style: TextStyle(
                                color: isExpanded ? purple : darkText,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isExpanded ? purple : secondaryText,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF3EDFF)),
                      const SizedBox(height: 12),
                      Text(
                        faq['answer'] as String,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 12.5,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (faq['hasAction'] == true) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              ClinicService.openNearbyDermatologists();
                            },
                            icon: const Icon(
                              Icons.map_outlined,
                              size: 16,
                              color: purple,
                            ),
                            label: const Text(
                              'Open Dermatologists on Maps',
                              style: TextStyle(
                                color: purple,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: lightPurple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
