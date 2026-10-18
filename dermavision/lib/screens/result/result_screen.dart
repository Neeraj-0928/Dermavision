import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/report_model.dart';

class ResultScreen extends StatefulWidget {
  // ================================================================
  // INPUT DATA
  // ================================================================

  final ReportModel? report;
  final String imagePath;
  final String condition;
  final double confidence;
  final String severity;
  final String diseaseInfo;
  final String? skinStatus;
  final double? skinConfidence;

  ResultScreen({
    super.key,
    this.report,
    String? imagePath,
    String? condition,
    double? confidence,
    String? severity,
    String? diseaseInfo,
    String? skinStatus,
    double? skinConfidence,
  })  : imagePath = imagePath ?? report?.imagePath ?? '',
        condition = condition ?? report?.condition ?? 'Melanocytic Nevus',
        confidence = confidence ?? report?.confidence ?? 0.92,
        severity = severity ?? report?.severity ?? 'Low Risk',
        skinStatus = skinStatus ?? report?.skinStatus,
        skinConfidence = skinConfidence ?? report?.skinConfidence,
        diseaseInfo = diseaseInfo ??
            ((report != null && report.description.isNotEmpty)
                ? report.description
                : 'A melanocytic nevus is a common type of skin lesion that is usually '
                    'harmless. It is formed by a cluster of pigment-producing cells called '
                    'melanocytes. Most nevi are benign; however, monitoring changes in '
                    'size, shape, or color is important to detect any early signs of '
                    'melanoma. AI-based analysis can help identify patterns that may '
                    'require further clinical attention.');

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color purple = Color(0xFF7B4DFF);
  static const Color lightPurple = Color(0xFFF0E9FF);
  static const Color background = Color(0xFFFAF9FF);
  static const Color darkText = Color(0xFF252530);
  static const Color secondaryText = Color(0xFF676773);

  bool _isGeneratingPdf = false;

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final int confidencePercent = (widget.confidence * 100).round();

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================

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
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),

        title: const Text(
          'Analysis Result',
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final double horizontalPadding =
                (constraints.maxWidth * 0.05).clamp(16.0, 22.0);
            final double imageHeight =
                (screenHeight * 0.28).clamp(170.0, 230.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ====================================================
                  // COMPLETED HEADER
                  // ====================================================

                  _buildCompletedHeader(),

                  const SizedBox(height: 18),

                  // ====================================================
                  // IMAGE
                  // ====================================================

                  _buildImageCard(imageHeight),

                  const SizedBox(height: 20),

                  // ====================================================
                  // RESULT
                  // ====================================================

                  _buildResultCard(confidencePercent),

                  const SizedBox(height: 18),

                  // ====================================================
                  // INFORMATION
                  // ====================================================

                  _buildInformationCard(),

                  const SizedBox(height: 24),

                  // ====================================================
                  // DOWNLOAD REPORT
                  // ====================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isGeneratingPdf ? null : _downloadReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isGeneratingPdf
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded, size: 20),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Download Report',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ====================================================
                  // FIND NEARBY DERMATOLOGIST
                  // ====================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _findNearbyDermatologist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DA1F2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Find Nearby Dermatologist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ====================================================
                  // SCAN ANOTHER IMAGE
                  // ====================================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Pop back to scan or home
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: purple,
                        side: const BorderSide(
                          color: purple,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, size: 20),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Scan Another Image',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ====================================================
                  // DISCLAIMER
                  // ====================================================

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
  // COMPLETED HEADER
  // ================================================================

  Widget _buildCompletedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F9F0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF24A35A),
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Completed',
                  style: TextStyle(
                    color: purple,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Your skin image has been analyzed',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 10.5,
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

  // ================================================================
  // IMAGE CARD — web-safe and base64-safe
  // ================================================================

  Widget _buildImageCard([double height = 220]) {
    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8954FF),
            Color(0xFF6530E9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.20),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildImage(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xAA000000),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 15,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 13,
                  ),

                  SizedBox(width: 5),

                  Text(
                    'ANALYZED IMAGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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

  /// Returns a web-safe, file-safe, base64-safe image widget.
  Widget _buildImage() {
    if (widget.imagePath.isEmpty) {
      return _imagePlaceholder();
    }

    if (widget.imagePath.startsWith('data:image')) {
      try {
        final commaIndex = widget.imagePath.indexOf(',');
        final base64Data = commaIndex != -1
            ? widget.imagePath.substring(commaIndex + 1)
            : widget.imagePath;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
        );
      } catch (_) {
        return _imagePlaceholder();
      }
    }

    if (widget.imagePath.startsWith('http://') ||
        widget.imagePath.startsWith('https://') ||
        widget.imagePath.startsWith('blob:')) {
      return Image.network(
        widget.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }

    if (!kIsWeb) {
      final file = File(widget.imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
        );
      }
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: lightPurple,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: purple,
          size: 55,
        ),
      ),
    );
  }

  // ================================================================
  // RESULT CARD
  // ================================================================

  Widget _buildResultCard(int confidencePercent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.06),
            blurRadius: 23,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Result',
            style: TextStyle(
              color: purple,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          // CONDITION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: purple,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Condition',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        widget.condition,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // CONFIDENCE + SEVERITY
          Row(
            children: [
              Expanded(
                child: _resultStat(
                  icon: Icons.analytics_outlined,
                  title: 'Confidence',
                  value: '$confidencePercent%',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _resultStat(
                  icon: Icons.shield_outlined,
                  title: 'Risk Level',
                  value: widget.severity,
                ),
              ),
            ],
          ),

          if (widget.skinStatus != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF10B981),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DermaVision Skin Gate AI',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.skinStatus} (${(widget.skinConfidence ?? 95.0).toStringAsFixed(1)}% verified)',
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // RESULT STAT
  // ================================================================

  Widget _resultStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEFEAFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: purple,
            size: 19,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INFORMATION CARD
  // ================================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: purple,
                size: 20,
              ),

              SizedBox(width: 8),

              Text(
                'About This Condition',
                style: TextStyle(
                  color: purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          Text(
            widget.diseaseInfo,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Recommendation row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: purple,
                  size: 17,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Continue monitoring your skin regularly. If you notice '
                    'changes in size, shape, color, or appearance, consult '
                    'a dermatologist promptly.',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 10.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
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
              'AI results are for informational purposes only and should not '
              'replace professional medical advice. Always consult a qualified '
              'dermatologist for diagnosis and treatment.',
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
  // DOWNLOAD REPORT (PDF)
  // ================================================================

  Future<void> _downloadReport() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      // Load image bytes for embedding into PDF
      Uint8List? imageBytes;
      if (widget.imagePath.startsWith('data:image')) {
        try {
          final commaIndex = widget.imagePath.indexOf(',');
          final base64Data = commaIndex != -1
              ? widget.imagePath.substring(commaIndex + 1)
              : widget.imagePath;
          imageBytes = base64Decode(base64Data);
        } catch (_) {}
      } else if (!kIsWeb && widget.imagePath.isNotEmpty) {
        try {
          final file = File(widget.imagePath);
          if (file.existsSync()) {
            imageBytes = await file.readAsBytes();
          }
        } catch (_) {}
      }

      final confidencePercent = (widget.confidence * 100).round();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return [
              // ── HEADER ──
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#7B4DFF'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DermaVision',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'AI Skin Analysis Report',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 13,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: ${_formattedDate()}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── SCANNED IMAGE ──
              if (imageBytes != null) ...[
                pw.Text(
                  'Scanned Image',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#252530'),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    height: 200,
                    fit: pw.BoxFit.cover,
                  ),
                ),
                pw.SizedBox(height: 24),
              ],

              // ── RESULT SECTION ──
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromHex('#EFE9FF'),
                  ),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Analysis Result',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#7B4DFF'),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    _pdfRow('Detected Condition', widget.condition),
                    _pdfRow('Confidence', '$confidencePercent%'),
                    _pdfRow('Risk Level', widget.severity),
                    if (widget.skinStatus != null)
                      _pdfRow(
                        'Skin Gate Verified',
                        '${widget.skinStatus} (${(widget.skinConfidence ?? 95.0).toStringAsFixed(1)}%)',
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── DISEASE INFORMATION ──
              pw.Text(
                'About This Condition',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#252530'),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                widget.diseaseInfo,
                style: const pw.TextStyle(
                  fontSize: 11,
                  lineSpacing: 4,
                ),
              ),

              pw.SizedBox(height: 20),

              // ── DISCLAIMER ──
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F4F0FF'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Disclaimer',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#7B4DFF'),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'This report is generated by an AI system for '
                      'informational purposes only. It does not constitute '
                      'medical advice, diagnosis, or treatment. Always consult '
                      'a qualified dermatologist or healthcare professional for '
                      'proper evaluation and medical guidance.',
                      style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      // Print/save dialog
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'DermaVision_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#252530'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ================================================================
  // FIND NEARBY DERMATOLOGIST
  // ================================================================

  Future<void> _findNearbyDermatologist() async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/dermatologist+near+me',
    );
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open Maps. Please search for dermatologists manually.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Maps: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}