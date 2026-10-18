import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../result/result_screen.dart';
import '../scan/scan_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color purple = Color(0xFF7B4DFF);
  static const Color lightPurple = Color(0xFFF0E9FF);
  static const Color background = Color(0xFFFAF9FF);
  static const Color darkText = Color(0xFF252530);
  static const Color secondaryText = Color(0xFF676773);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<ReportProvider>().loadReports(auth.currentUser!.id);
      }
    });
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final reports = reportProvider.reports;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkText,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'My Reports',
          style: TextStyle(
            color: darkText,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding =
                (constraints.maxWidth * 0.05).clamp(16.0, 22.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======================================================
                  // INTRO
                  // ======================================================
                  _buildIntro(),

                  const SizedBox(height: 22),

                  // ======================================================
                  // SUMMARY
                  // ======================================================
                  _buildSummaryCard(reports.length),

                  const SizedBox(height: 25),

                  // ======================================================
                  // RECENT REPORTS TITLE
                  // ======================================================
                  _buildSectionHeader(reports.length),

                  const SizedBox(height: 13),

                  // ======================================================
                  // REPORTS LIST
                  // ======================================================
                  if (reportProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(purple),
                        ),
                      ),
                    )
                  else if (reports.isEmpty)
                    _buildEmptyState()
                  else
                    ...reports.map((report) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: _buildReportCard(
                          context: context,
                          report: report,
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // ======================================================
                  // DISCLAIMER
                  // ======================================================
                  _buildDisclaimer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // INTRO
  // ================================================================

  Widget _buildIntro() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your skin journey',
          style: TextStyle(
            color: purple,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Review your previous skin analyses and keep '
          'track of changes over time.',
          style: TextStyle(
            color: secondaryText,
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // SUMMARY CARD
  // ================================================================

  Widget _buildSummaryCard(int totalReports) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8756FF),
            Color(0xFF6335E8),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.20),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.folder_copy_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalReports',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                const Text(
                  'Total skin analyses',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION HEADER
  // ================================================================

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        const Text(
          'Recent reports',
          style: TextStyle(
            color: purple,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        Text(
          '$count report${count == 1 ? '' : 's'}',
          style: const TextStyle(
            color: secondaryText,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.045),
            blurRadius: 19,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: purple,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reports yet',
            style: TextStyle(
              color: darkText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your completed skin scans will automatically appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_a_photo_outlined, size: 15),
              label: const Text(
                'Start a Skin Scan',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // REPORT CARD
  // ================================================================

  Widget _buildReportCard({
    required BuildContext context,
    required ReportModel report,
  }) {
    final confidencePercent = '${(report.confidence * 100).round()}%';
    final dateStr = _formatDate(report.date);

    Color riskColor = const Color(0xFF24A35A);
    final sevLower = report.severity.toLowerCase();
    if (sevLower.contains('high')) {
      riskColor = const Color(0xFFEF4444);
    } else if (sevLower.contains('monitor') || sevLower.contains('moderate')) {
      riskColor = const Color(0xFFE59A19);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.045),
            blurRadius: 19,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail / Icon
              _buildThumbnail(report.imagePath),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.condition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: secondaryText,
                          size: 11,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  _showOptions(context, report);
                },
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: secondaryText,
                  size: 21,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _smallStat(
                  icon: Icons.analytics_outlined,
                  title: 'Confidence',
                  value: confidencePercent,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _smallStat(
                  icon: Icons.shield_outlined,
                  title: 'Risk',
                  value: report.severity,
                  valueColor: riskColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // VIEW REPORT BUTTON
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => _openReport(context, report),
              style: OutlinedButton.styleFrom(
                foregroundColor: purple,
                side: BorderSide(
                  color: purple.withValues(alpha: 0.18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                  ),

                  SizedBox(width: 6),

                  Text(
                    'View Report',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String imagePath) {
    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith('data:image')) {
        try {
          final commaIndex = imagePath.indexOf(',');
          final base64Data = commaIndex != -1
              ? imagePath.substring(commaIndex + 1)
              : imagePath;
          final bytes = base64Decode(base64Data);
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(
              bytes,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _defaultIconContainer(),
            ),
          );
        } catch (_) {}
      } else if (imagePath.startsWith('http://') ||
          imagePath.startsWith('https://') ||
          imagePath.startsWith('blob:')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imagePath,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _defaultIconContainer(),
          ),
        );
      } else if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              file,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _defaultIconContainer(),
            ),
          );
        }
      }
    }

    return _defaultIconContainer();
  }

  Widget _defaultIconContainer() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.health_and_safety_outlined,
        color: purple,
        size: 23,
      ),
    );
  }

  void _openReport(BuildContext context, ReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          report: report,
          imagePath: report.imagePath,
          condition: report.condition,
          confidence: report.confidence,
          severity: report.severity,
          diseaseInfo: report.description,
        ),
      ),
    );
  }

  // ================================================================
  // SMALL STAT
  // ================================================================

  Widget _smallStat({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = darkText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEFEAFF),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: purple,
            size: 17,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DISCLAIMER
  // ================================================================

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: purple,
            size: 17,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'Your previous reports are stored for reference. '
              'AI analysis is informational and does not replace '
              'professional medical advice.',
              style: TextStyle(
                color: darkText.withValues(alpha: 0.72),
                fontSize: 9.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // OPTIONS BOTTOM SHEET
  // ================================================================

  void _showOptions(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              15,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0DDE8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(
                    Icons.visibility_outlined,
                    color: purple,
                  ),
                  title: const Text(
                    'View Report',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _openReport(context, report);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete Report',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await context
                        .read<ReportProvider>()
                        .deleteReport(report.userId, report.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report deleted successfully.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }
}