import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/clinic_service.dart';
import '../profile/profile_screen.dart';
import '../result/result_screen.dart';
import '../scan/scan_screen.dart';
import '../reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({
    super.key,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color purple = Color(0xFF7B4DFF);
  static const Color lightPurple = Color(0xFFF0E9FF);

  static const Color background = Color(0xFFFAF9FF);
  static const Color darkText = Color(0xFF252530);
  static const Color secondaryText = Color(0xFF676773);

  int _selectedIndex = 0;

  // ================================================================
  // GREETING
  // ================================================================

  String _getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    }

    return 'Good Night';
  }

  String _getGreetingEmoji() {
    final int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return '☀️';
    }

    if (hour >= 12 && hour < 17) {
      return '🌤️';
    }

    if (hour >= 17 && hour < 21) {
      return '🌆';
    }

    return '🌙';
  }

  // ================================================================
  // OPEN SCAN
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserReports();
    });
  }

  void _loadUserReports() {
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      context.read<ReportProvider>().loadReports(uid);
    }
  }

  // ================================================================
  // OPEN SCAN
  // ================================================================

  Future<void> _openScanScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(),
      ),
    );
    if (mounted) {
      _loadUserReports();
    }
  }

  // ================================================================
  // OPEN PROFILE
  // ================================================================

  void _openProfileScreen() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final currentUsername = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : widget.username;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          username: currentUsername,
        ),
      ),
    );
  }

  // ================================================================
  // OPEN REPORTS
  // ================================================================

  Future<void> _openReportsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportsScreen(),
      ),
    );
    if (mounted) {
      _loadUserReports();
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      bottomNavigationBar: _buildBottomNavigation(),

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ======================================================
            // BACKGROUND GLOW
            // ======================================================

            Positioned(
              top: -100,
              right: -100,
              child: _glowCircle(
                size: 270,
                color: purple.withValues(alpha: 0.10),
              ),
            ),

            Positioned(
              top: 300,
              left: -180,
              child: _glowCircle(
                size: 320,
                color: const Color(0xFFB99AFF).withValues(
                  alpha: 0.055,
                ),
              ),
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isCompact = constraints.maxHeight < 730;
                  final double horizontalPadding =
                      (constraints.maxWidth * 0.05).clamp(16.0, 22.0);
                  final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    14,
                  );

                  // ── TALL SCREENS (≥730dp, e.g. Pixel 7) ─────────────────
                  // Use a plain Column with Expanded so the Skin Journey card
                  // is pinned to the bottom. No scroll needed.
                  if (!isCompact) {
                    return Padding(
                      padding: contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 14),
                          _buildAiAnalysisCard(),
                          const SizedBox(height: 17),
                          _buildQuickAccessTitle(),
                          const SizedBox(height: 8),
                          _buildQuickAccessCards(),
                          const SizedBox(height: 14),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _buildSkinJourneyCard(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    );
                  }

                  // ── COMPACT SCREENS (<730dp, e.g. Realme P4 Lite) ───────
                  // Use SingleChildScrollView + plain Column (no Expanded).
                  // Content flows naturally; user can scroll if needed.
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 14),
                          _buildAiAnalysisCard(),
                          const SizedBox(height: 17),
                          _buildQuickAccessTitle(),
                          const SizedBox(height: 8),
                          _buildQuickAccessCards(),
                          const SizedBox(height: 14),
                          _buildSkinJourneyCard(),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHomeAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final commaIndex = avatarUrl.indexOf(',');
          final base64Data = commaIndex != -1
              ? avatarUrl.substring(commaIndex + 1)
              : avatarUrl;
          final bytes = base64Decode(base64Data);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person_outline_rounded,
                color: purple,
                size: 21,
              ),
            ),
          );
        } catch (_) {}
      } else if (avatarUrl.startsWith('http://') ||
          avatarUrl.startsWith('https://') ||
          avatarUrl.startsWith('blob:')) {
        return ClipOval(
          child: Image.network(
            avatarUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.person_outline_rounded,
              color: purple,
              size: 21,
            ),
          ),
        );
      } else if (!kIsWeb) {
        try {
          final file = File(avatarUrl);
          if (file.existsSync()) {
            return ClipOval(
              child: Image.file(
                file,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_outline_rounded,
                  color: purple,
                  size: 21,
                ),
              ),
            );
          }
        } catch (_) {}
      }
    }
    return const Icon(
      Icons.person_outline_rounded,
      color: purple,
      size: 21,
    );
  }

  Widget _buildHeader() {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final String username = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : widget.username.trim();

    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} ${_getGreetingEmoji()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                    letterSpacing: 0.05,
                  ),
                ),

                const SizedBox(height: 3),

                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      if (username.isNotEmpty)
                        TextSpan(
                          text: '$username, ',
                          style: const TextStyle(
                            color: purple,
                            fontSize: 19,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),

                      TextSpan(
                        text: username.isEmpty
                            ? 'How is your skin today?'
                            : 'how is your skin today?',
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          GestureDetector(
            onTap: _openProfileScreen,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.13),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _buildHomeAvatar(user?.avatarUrl),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SMART SKIN CHECK CARD
  // ================================================================

  Widget _buildAiAnalysisCard() {
    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final double cardWidth = cardConstraints.maxWidth;
        final double textWidth = (cardWidth * 0.52).clamp(145.0, 195.0);
        final double btnWidth = (cardWidth * 0.44).clamp(135.0, 160.0);
        final double girlWidth = (cardWidth * 0.60).clamp(180.0, 230.0);

        return Container(
          width: double.infinity,
          height: 208,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8954FF),
                Color(0xFF7139F4),
                Color(0xFF6530E9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: purple.withValues(alpha: 0.26),
                blurRadius: 27,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -55,
                top: -55,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // GIRL IMAGE
              Positioned(
                right: cardWidth < 350 ? 6 : 14,
                bottom: -40,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: cardWidth < 350 ? 1.05 : 1.12,
                    alignment: Alignment.bottomRight,
                    child: Image.asset(
                      'assets/images/skin_ai_girl.png',
                      width: girlWidth,
                      height: 265,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: (cardWidth * 0.58).clamp(170.0, 210.0),
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF7A45F7).withValues(alpha: 0.99),
                          const Color(0xFF7A45F7).withValues(alpha: 0.90),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  17,
                  18,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Skin Check',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.02,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 7),

                    SizedBox(
                      width: textWidth,
                      child: Text(
                        'Get quick insights about your\n'
                        'skin with an AI-assisted\n'
                        'analysis.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontSize: cardWidth < 350 ? 10.5 : 11,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: btnWidth,
                      height: 39,
                      child: ElevatedButton(
                        onPressed: _openScanScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: purple,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Check Your Skin',
                              style: TextStyle(
                                fontSize: 11.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // QUICK ACCESS TITLE
  // ================================================================

  Widget _buildQuickAccessTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: darkText,
            letterSpacing: -0.2,
          ),
        ),

        GestureDetector(
          onTap: _openReportsScreen,
          child: const Row(
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: purple,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 3),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: purple,
                size: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // QUICK ACCESS CARDS
  // ================================================================

  Widget _buildQuickAccessCards() {
    return SizedBox(
      height: 155,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildAccessCard(
              icon: Icons.description_outlined,
              title: 'Reports',
              subtitle:
                  'View your previous\n'
                  'skin analysis reports',
              onTap: _openReportsScreen,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _buildAccessCard(
              icon: Icons.location_on_outlined,
              title: 'Nearby',
              subtitle:
                  'Find trusted\n'
                  'dermatologists near you',
              onTap: () async {
                final opened =
                    await ClinicService.openNearbyDermatologists();
                if (!opened && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open Maps. Please try again.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACCESS CARD
  // ================================================================

  Widget _buildAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double textMaxWidth =
            (constraints.maxWidth - 38).clamp(95.0, 160.0);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          child: InkWell(
            borderRadius: BorderRadius.circular(21),
            onTap: onTap,
            child: Container(
              height: 154,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.055),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 37,
                        height: 37,
                        decoration: BoxDecoration(
                          color: lightPurple,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: purple.withValues(alpha: 0.07),
                              blurRadius: 9,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: purple,
                          size: 19,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 1),

                      SizedBox(
                        width: textMaxWidth,
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 9.2,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ARROW AT BOTTOM
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: lightPurple,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: purple,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // SCAN HISTORY
  // ================================================================

  Color _getSeverityColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('high')) return const Color(0xFFEF4444);
    if (s.contains('monitor') || s.contains('moderate')) return const Color(0xFFE59A19);
    return const Color(0xFF24A35A);
  }

  String _formatReportDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0 && now.day == date.day) {
      return 'Today';
    } else if (difference.inDays <= 1 && now.day - date.day == 1) {
      return 'Yesterday';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildSkinJourneyCard() {
    final reportProvider = context.watch<ReportProvider>();
    final ReportModel? latest = reportProvider.latestReport;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.055),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openReportsScreen,
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: lightPurple,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.auto_graph_rounded,
                    color: purple,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan History',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 1),

                      Text(
                        latest != null
                            ? '${reportProvider.totalCount} scan${reportProvider.totalCount == 1 ? '' : 's'} recorded'
                            : 'Keep track of your previous skin scans',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 9.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: purple,
                  size: 13,
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          // LAST SCAN
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: purple,
                  size: 15,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Last scan',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  latest != null
                      ? _formatReportDate(latest.date)
                      : 'No scan yet',
                  style: TextStyle(
                    color: latest != null ? purple : secondaryText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // SCAN PREVIEW OR EMPTY
          if (latest != null)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultScreen(
                        report: latest,
                        imagePath: latest.imagePath,
                        condition: latest.condition,
                        confidence: latest.confidence,
                        severity: latest.severity,
                        diseaseInfo: latest.description,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: purple.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: lightPurple,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          color: purple,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          latest.condition,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(latest.severity)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          latest.severity,
                          style: TextStyle(
                            color: _getSeverityColor(latest.severity),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: purple,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 40,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEDE7FF),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: purple,
                    size: 16,
                  ),

                  SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'Your completed skin scans will appear here.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 9.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // START SCAN / VIEW ALL
          GestureDetector(
            onTap: latest != null ? _openReportsScreen : _openScanScreen,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  latest != null
                      ? 'View all reports (${reportProvider.totalCount})'
                      : 'Start a new skin scan',
                  style: const TextStyle(
                    color: purple,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 5),

                const Icon(
                  Icons.arrow_forward_rounded,
                  color: purple,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: purple.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
            ),

            Expanded(
              child: _navItem(
                icon: Icons.document_scanner_outlined,
                label: 'Scan',
                index: 1,
                isCenter: true,
              ),
            ),

            Expanded(
              child: _navItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                index: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // NAV ITEM
  // ================================================================

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final bool selected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index == 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        if (index == 1) {
          setState(() {
            _selectedIndex = 1;
          });

          _openScanScreen();
          return;
        }

        if (index == 2) {
          setState(() {
            _selectedIndex = 2;
          });

          _openProfileScreen();
          return;
        }
      },
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCenter)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8755FF),
                      Color(0xFF6330E8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              )
            else
              Icon(
                icon,
                color: selected
                    ? purple
                    : const Color(0xFFAAAAAF),
                size: 21,
              ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? purple
                    : const Color(0xFF99999F),
                fontSize: 9.5,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // GLOW CIRCLE
  // ================================================================

  Widget _glowCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}