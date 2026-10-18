import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static Future<void> generateAndPreviewReport({
    required String patientName,
    required String patientEmail,
    required String condition,
    required double confidence,
    required String severity,
    required DateTime date,
    String? imagePath,
    String? description,
    String? recommendation,
    List<String> precautions = const [],
    String? skinStatus,
    double? skinConfidence,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? scannedImage;
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('data:image')) {
        try {
          final commaIndex = imagePath.indexOf(',');
          final base64Data = commaIndex != -1
              ? imagePath.substring(commaIndex + 1)
              : imagePath;
          final bytes = base64Decode(base64Data);
          scannedImage = pw.MemoryImage(bytes);
        } catch (_) {}
      } else if (!kIsWeb) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            scannedImage = pw.MemoryImage(bytes);
          }
        } catch (_) {}
      }
    }

    final confidencePercent = (confidence * 100).round();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final PdfColor primaryColor = PdfColor.fromInt(0xFF7B4DFF);
    final PdfColor darkTextColor = PdfColor.fromInt(0xFF252530);
    final PdfColor greyTextColor = PdfColor.fromInt(0xFF676773);
    final PdfColor cardBg = PdfColor.fromInt(0xFFF7F4FF);

    PdfColor riskColor = PdfColor.fromInt(0xFF24A35A);
    if (severity.toLowerCase().contains('high')) {
      riskColor = PdfColor.fromInt(0xFFEF4444);
    } else if (severity.toLowerCase().contains('monitor') ||
        severity.toLowerCase().contains('moderate')) {
      riskColor = PdfColor.fromInt(0xFFF59E0B);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DermaVision',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'AI-Assisted Skin Intelligence Analysis Report',
                        style: pw.TextStyle(
                          color: greyTextColor,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: cardBg,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'Report ID: DV-${date.millisecondsSinceEpoch.toString().substring(6)}',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColor.fromInt(0xFFE5E7EB)),
              pw.SizedBox(height: 12),

              // Patient & Assessment Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PATIENT INFORMATION',
                          style: pw.TextStyle(
                            color: greyTextColor,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          patientName.isEmpty ? 'DermaVision User' : patientName,
                          style: pw.TextStyle(
                            color: darkTextColor,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (patientEmail.isNotEmpty)
                          pw.Text(
                            patientEmail,
                            style: pw.TextStyle(
                              color: greyTextColor,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'DATE & TIME',
                          style: pw.TextStyle(
                            color: greyTextColor,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          formattedDate,
                          style: pw.TextStyle(
                            color: darkTextColor,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Image & Diagnosis Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (scannedImage != null)
                    pw.Container(
                      width: 140,
                      height: 140,
                      margin: const pw.EdgeInsets.only(right: 16),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 10,
                        verticalRadius: 10,
                        child: pw.Image(scannedImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DETECTED CONDITION',
                          style: pw.TextStyle(
                            color: greyTextColor,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          condition,
                          style: pw.TextStyle(
                            color: darkTextColor,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: cardBg,
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'CONFIDENCE',
                                    style: pw.TextStyle(
                                      color: greyTextColor,
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Text(
                                    '$confidencePercent%',
                                    style: pw.TextStyle(
                                      color: primaryColor,
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: cardBg,
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'RISK LEVEL',
                                    style: pw.TextStyle(
                                      color: greyTextColor,
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Text(
                                    severity,
                                    style: pw.TextStyle(
                                      color: riskColor,
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (skinStatus != null) ...[
                              pw.SizedBox(width: 12),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: cardBg,
                                  borderRadius: pw.BorderRadius.circular(8),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'SKIN GATE VERIFIED',
                                      style: pw.TextStyle(
                                        color: greyTextColor,
                                        fontSize: 7.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      '$skinStatus (${(skinConfidence ?? 95.0).toStringAsFixed(0)}%)',
                                      style: pw.TextStyle(
                                        color: PdfColor.fromInt(0xFF10B981),
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 18),

              // Clinical Description
              if (description != null && description.isNotEmpty) ...[
                pw.Text(
                  'About this Condition',
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    color: darkTextColor,
                    fontSize: 10,
                    lineSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // Recommendations
              pw.Text(
                'Recommended Next Steps',
                style: pw.TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                recommendation ??
                    'Continue monitoring the skin lesion. If you observe rapid changes in shape, size, color, or bleeding, schedule an appointment with a licensed dermatologist.',
                style: pw.TextStyle(
                  color: darkTextColor,
                  fontSize: 10,
                  lineSpacing: 2,
                ),
              ),

              if (precautions.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Precautions & Preventive Care',
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                ...precautions.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(color: primaryColor)),
                        pw.Expanded(
                          child: pw.Text(
                            item,
                            style: pw.TextStyle(
                              color: darkTextColor,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              pw.Spacer(),

              // Medical Disclaimer Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF3F4F6),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFE5E7EB),
                    width: 0.8,
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DISCLAIMER: ',
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xFF6B7280),
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'This document is computer-generated by DermaVision for screening assistance and educational purposes only. It is not an official medical diagnosis. Always consult a qualified medical professional or certified dermatologist for formal medical advice.',
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF6B7280),
                          fontSize: 7.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'DermaVision_Report_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }
}
