import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'tflite_engine.dart';

// ============================================================
// DERMAVISION — ON-DEVICE SKIN GATE
// Uses the trained MobileNetV2 TFLite model bundled in assets.
// No Python server required — inference runs locally on device.
// ============================================================

enum SkinDetectionStatus {
  skin,
  nonSkin,
  uncertain,
  error,
}

class SkinDetectionResult {
  final bool isSkin;
  final SkinDetectionStatus status;
  final String label;
  final double confidence;
  final double pSkin;
  final String message;
  final String source;
  final String? error;

  const SkinDetectionResult({
    required this.isSkin,
    required this.status,
    required this.label,
    required this.confidence,
    required this.pSkin,
    required this.message,
    required this.source,
    this.error,
  });

  factory SkinDetectionResult.tflite({
    required bool isSkin,
    required double pSkin,
    required double confidence,
    String? message,
  }) {
    final label = isSkin ? 'SKIN' : 'NON-SKIN';
    final msg = message ?? (isSkin
        ? 'Human skin verified (${confidence.toStringAsFixed(1)}% confidence).'
        : 'Non-skin image detected (${confidence.toStringAsFixed(1)}% confidence).');
    return SkinDetectionResult(
      isSkin: isSkin,
      status: isSkin ? SkinDetectionStatus.skin : SkinDetectionStatus.nonSkin,
      label: label,
      confidence: confidence,
      pSkin: pSkin,
      message: msg,
      source: 'tflite',
    );
  }

  factory SkinDetectionResult.heuristic({
    required bool isSkin,
    required double confidence,
    required double skinPixelRatio,
    String? message,
  }) {
    final label = isSkin ? 'SKIN' : 'NON-SKIN';
    final msg = message ?? (isSkin
        ? 'Human skin verified (${confidence.toStringAsFixed(1)}% confidence).'
        : 'Non-skin image detected (${confidence.toStringAsFixed(1)}% confidence). Please capture a close-up photo of human skin.');
    return SkinDetectionResult(
      isSkin: isSkin,
      status: isSkin ? SkinDetectionStatus.skin : SkinDetectionStatus.nonSkin,
      label: label,
      confidence: confidence,
      pSkin: isSkin ? confidence / 100.0 : (100.0 - confidence) / 100.0,
      message: msg,
      source: 'heuristic',
    );
  }

  factory SkinDetectionResult.error(String errorMessage) {
    return SkinDetectionResult(
      isSkin: false,
      status: SkinDetectionStatus.error,
      label: 'ERROR',
      confidence: 0.0,
      pSkin: 0.0,
      message: errorMessage,
      source: 'error',
      error: errorMessage,
    );
  }
}

class SkinDetectorService {
  static const String _modelAsset = 'assets/models/skin_non_skin.tflite';
  static const double _skinThreshold = 0.62;
  static const double _nonSkinThreshold = 0.38;
  static const int _inputSize = 224;

  TfliteEngine? _engine;
  bool _modelLoaded = false;

  Future<void> loadModel() async {
    if (_modelLoaded || kIsWeb) return;
    try {
      _engine ??= createTfliteEngine();
      if (!_engine!.isSupported) return;
      await _engine!.loadModel(_modelAsset);
      _modelLoaded = true;
    } catch (_) {
      _modelLoaded = false;
    }
  }

  void dispose() {
    _engine?.close();
    _engine = null;
    _modelLoaded = false;
  }

  Future<SkinDetectionResult> detectSkin({required Uint8List imageBytes}) async {
    if (imageBytes.isEmpty) {
      return SkinDetectionResult.error('No image provided for skin detection.');
    }
    if (kIsWeb) return _runHeuristic(imageBytes);
    if (!_modelLoaded) await loadModel();
    if (_modelLoaded && _engine != null) {
      try {
        return await _runTFLite(imageBytes);
      } catch (_) {}
    }
    return _runHeuristic(imageBytes);
  }

  Future<SkinDetectionResult> _runTFLite(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return _runHeuristic(bytes);

    // 1. Center-crop to square (exact match to Python load_rgb_square)
    img.Image squareImg = decoded;
    if (decoded.width != decoded.height) {
      final side = decoded.width < decoded.height ? decoded.width : decoded.height;
      final x = (decoded.width - side) ~/ 2;
      final y = (decoded.height - side) ~/ 2;
      squareImg = img.copyCrop(decoded, x: x, y: y, width: side, height: side);
    }

    final resized = img.copyResize(squareImg, width: _inputSize, height: _inputSize);
    final inputData = _buildInputTensor(resized);
    final outputData = List.generate(1, (_) => List.filled(1, 0.0));

    _engine!.run(inputData, outputData);

    final double pSkin = outputData[0][0].clamp(0.0, 1.0);

    // 2. Consistency check with biological skin loci:
    // If an image has virtually no biological skin pixels (< 18%),
    // it cannot be classified as skin regardless of neural network overconfidence.
    // This rejects red bedsheets (0%), teal bottles (0%), off-white walls (0%), and blue clothes.
    final double colorRatio = _calculateSkinPixelRatio(resized);
    if (colorRatio < 0.18) {
      final double conf = ((1.0 - colorRatio) * 100.0).clamp(80.0, 99.0);
      return SkinDetectionResult.tflite(
        isSkin: false,
        pSkin: math.min(pSkin, colorRatio),
        confidence: conf,
        message: 'Non-skin image detected (${conf.toStringAsFixed(1)}% confidence). Color profile does not match human skin.',
      );
    }

    // 3. Texture & visual appearance gate:
    // Reject wood grain, wooden tables, doors, chairs, brown furniture, cardboard, leather
    final textureAnalysis = _analyzeTexture(resized);
    if (!textureAnalysis.isSkinTexture) {
      final double nonSkinConf = (78.0 + textureAnalysis.nonSkinEvidence * 20.0).clamp(78.0, 99.0);
      return SkinDetectionResult.tflite(
        isSkin: false,
        pSkin: math.min(pSkin, 0.12),
        confidence: nonSkinConf,
        message: 'Non-skin surface detected (${textureAnalysis.reason}, ${nonSkinConf.toStringAsFixed(1)}% confidence). Please capture a close-up photo of human skin.',
      );
    }

    if (pSkin >= _skinThreshold && colorRatio >= 0.20) {
      return SkinDetectionResult.tflite(
        isSkin: true,
        pSkin: pSkin,
        confidence: pSkin * 100.0,
      );
    } else if (pSkin <= _nonSkinThreshold || colorRatio < 0.18) {
      final double conf = ((1.0 - pSkin) * 100.0).clamp(70.0, 99.0);
      return SkinDetectionResult.tflite(
        isSkin: false,
        pSkin: pSkin,
        confidence: conf,
      );
    } else {
      return _runHeuristic(bytes);
    }
  }

  List<List<List<List<double>>>> _buildInputTensor(img.Image image) {
    final int total = image.width * image.height;
    final yArr = List<double>.filled(total, 0.0);
    double ySum = 0.0;

    int idx = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = (p.r / 255.0).clamp(0.0, 1.0);
        final g = (p.g / 255.0).clamp(0.0, 1.0);
        final b = (p.b / 255.0).clamp(0.0, 1.0);
        final lum = 0.299 * r + 0.587 * g + 0.114 * b;
        yArr[idx] = lum;
        ySum += lum;
        idx++;
      }
    }

    final double mean = ySum / total;
    double varSum = 0.0;
    for (int i = 0; i < total; i++) {
      final diff = yArr[i] - mean;
      varSum += diff * diff;
    }
    final double std = math.sqrt(varSum / total) + 1e-5;

    // MobileNetV2 expects input range [0.0, 255.0] because preprocess_input inside
    // the model scales (x / 127.5) - 1.0.
    return List.generate(1, (_) {
      return List.generate(image.height, (y) {
        return List.generate(image.width, (x) {
          final p = image.getPixel(x, y);
          final double r = (p.r / 255.0).clamp(0.0, 1.0);
          final double g = (p.g / 255.0).clamp(0.0, 1.0);
          final double b = (p.b / 255.0).clamp(0.0, 1.0);

          final double lum = yArr[y * image.width + x];
          final double yNew = (lum - mean) / std * 0.18 + 0.42;
          final double scale = (yNew / (lum + 1e-5)).clamp(0.40, 2.50);

          return [
            (r * scale).clamp(0.0, 1.0) * 255.0,
            (g * scale).clamp(0.0, 1.0) * 255.0,
            (b * scale).clamp(0.0, 1.0) * 255.0,
          ];
        });
      });
    });
  }

  double _calculateSkinPixelRatio(img.Image image) {
    int skinCount = 0;
    final int total = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        if (_isSkinPixel(p.r.toDouble(), p.g.toDouble(), p.b.toDouble())) {
          skinCount++;
        }
      }
    }
    return total > 0 ? skinCount / total : 0.0;
  }

  SkinDetectionResult _runHeuristic(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return SkinDetectionResult.heuristic(
          isSkin: false,
          confidence: 85.0,
          skinPixelRatio: 0.0,
        );
      }

      final resized = img.copyResize(decoded, width: 120, height: 120);
      int total = 0;
      int skinCount = 0;
      int centerTotal = 0;
      int centerSkinCount = 0;

      final int cxStart = (resized.width * 0.20).toInt();
      final int cxEnd = (resized.width * 0.80).toInt();
      final int cyStart = (resized.height * 0.20).toInt();
      final int cyEnd = (resized.height * 0.80).toInt();

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final p = resized.getPixel(x, y);
          final r = p.r.toDouble();
          final g = p.g.toDouble();
          final b = p.b.toDouble();

          final bool isSkin = _isSkinPixel(r, g, b);

          total++;
          if (isSkin) skinCount++;

          if (x >= cxStart && x < cxEnd && y >= cyStart && y < cyEnd) {
            centerTotal++;
            if (isSkin) centerSkinCount++;
          }
        }
      }

      final double globalRatio = total > 0 ? skinCount / total : 0.0;
      final double centerRatio = centerTotal > 0 ? centerSkinCount / centerTotal : 0.0;

      // In a legitimate dermatological scan, skin must be present globally (>= 18%)
      // and centered (>= 20%).
      // Backgrounds, rooms, walls, bottles, furniture, electronics will have ratios < 12%.
      final bool passesSkinCheck = globalRatio >= 0.18 && centerRatio >= 0.20;

      if (!passesSkinCheck) {
        // High confidence that it is NOT skin when ratio is low
        final double nonSkinScore = (1.0 - (globalRatio * 0.5 + centerRatio * 0.5));
        final double conf = (75.0 + nonSkinScore * 24.0).clamp(75.0, 99.0);
        return SkinDetectionResult.heuristic(
          isSkin: false,
          confidence: conf,
          skinPixelRatio: globalRatio,
        );
      }

      // Visual appearance & texture verification:
      // Even if color resembles human skin (such as wooden furniture, wooden doors, cardboard, leather),
      // verify that visual texture conforms to biological human skin rather than wood grain or synthetic surfaces.
      final textureAnalysis = _analyzeTexture(resized);
      if (!textureAnalysis.isSkinTexture) {
        final double nonSkinScore = textureAnalysis.nonSkinEvidence;
        final double conf = (76.0 + nonSkinScore * 22.0).clamp(76.0, 99.0);
        return SkinDetectionResult.heuristic(
          isSkin: false,
          confidence: conf,
          skinPixelRatio: globalRatio,
          message: 'Non-skin surface detected (${textureAnalysis.reason}, ${conf.toStringAsFixed(1)}% confidence). Please capture a close-up photo of human skin.',
        );
      }

      final double score = (globalRatio * 0.5 + centerRatio * 0.5);
      final double conf = (70.0 + score * 28.0).clamp(70.0, 98.0);
      return SkinDetectionResult.heuristic(
        isSkin: true,
        confidence: conf,
        skinPixelRatio: globalRatio,
      );
    } catch (_) {
      return SkinDetectionResult.heuristic(
        isSkin: false,
        confidence: 85.0,
        skinPixelRatio: 0.0,
      );
    }
  }

  static bool _isSkinPixel(double r, double g, double b) {
    // 1. Lightness / Darkness range for human skin
    if (r < 35 || g < 18 || b < 10) return false;
    // Exclude overexposed pure white / light wall glare
    if (r > 250 && g > 250 && b > 250) return false;

    // 2. Biological Human Skin Invariants (Hemoglobin & Melanin Spectral Absorption):
    // Melanin and hemoglobin absorb blue light much more strongly than green and red light.
    // For all human skin tones (Fitzpatrick I-VI), Red strictly dominates both Green and Blue:
    if (r <= g || r <= b) return false;

    // In real cameras & JPEG compression (4:2:0 chroma subsampling), green and blue can drift,
    // but synthetic magenta/purple dyes have blue significantly exceeding green.
    // Allow minor camera shift (g >= b - 4), strictly rejecting cyan/magenta/violet.
    if ((g - b) < -4) return false;

    // Red-Green difference: human skin has distinct hemoglobin separation from neutral grays.
    if ((r - g) < 5) return false;

    // Total chromatic separation: r - b must be substantial for skin
    if ((r - b) < 10) return false;

    // 3. YCbCr conversion (standard Chai & Ngan skin locus with illumination tolerance)
    final double yVal = 0.299 * r + 0.587 * g + 0.114 * b;
    final double cb = 128.0 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final double cr = 128.0 + 0.5 * r - 0.418688 * g - 0.081312 * b;

    // Exclude extreme brightness/shadows
    if (yVal < 25 || yVal > 240) return false;

    // Chai & Ngan empirical YCbCr skin bounds:
    if (cr < 128 || cr > 185) return false;
    if (cb < 70 || cb > 135) return false;

    // 4. HSV Hue and Saturation verification
    final double maxVal = math.max(r, math.max(g, b));
    final double minVal = math.min(r, math.min(g, b));
    final double diff = maxVal - minVal;
    if (diff < 6) return false; // achromatic gray/white/black

    double h = 0.0;
    if (maxVal == r) {
      h = 60.0 * (((g - b) / diff) % 6);
    } else if (maxVal == g) {
      h = 60.0 * (((b - r) / diff) + 2);
    } else {
      h = 60.0 * (((r - g) / diff) + 4);
    }
    if (h < 0) h += 360.0;

    final double sat = diff / maxVal;

    // Saturation filter:
    // Off-white / beige walls under warm bulbs have sat < 0.10. Real skin (even very pale) has sat >= 0.10.
    // Synthetic neon plastics have sat > 0.85.
    if (sat < 0.10 || sat > 0.85) return false;

    // Physiological hue angle:
    // Genuine human melanin-hemoglobin produces warm golden-orange to orange-red hues (4° to 50°).
    // Magenta / crimson / purplish bedsheets lie in 330°-360° or 0°-3°, strictly rejected!
    if (h < 4.0 || h > 50.0) return false;

    return true;
  }

  /// Evaluates surface visual appearance and texture structure.
  /// Rejects wood grain, wooden tables/doors/chairs, brown furniture, cardboard,
  /// and leather, while preserving genuine human skin (all tones and lesions).
  static _TextureAnalysisResult _analyzeTexture(img.Image image) {
    final int w = image.width;
    final int h = image.height;

    if (w < 8 || h < 8) {
      return const _TextureAnalysisResult(
        isSkinTexture: true,
        nonSkinEvidence: 0.0,
        reason: 'Image too small for texture analysis',
      );
    }

    // Pre-extract luminance: Y = 0.299R + 0.587G + 0.114B
    final luminances = List<double>.filled(w * h, 0.0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        luminances[y * w + x] = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }

    double sxx = 0.0;
    double syy = 0.0;
    double sxy = 0.0;

    double sumL = 0.0;
    double sumL2 = 0.0;

    final hist = List<double>.filled(8, 0.0);
    double totalEdgeMag = 0.0;
    int harshEdgeCount = 0;
    int validPixels = 0;

    final double binWidth = math.pi / 8.0;

    for (int y = 1; y < h - 1; y++) {
      final int rowIdx = y * w;
      for (int x = 1; x < w - 1; x++) {
        final int idx = rowIdx + x;
        final double cur = luminances[idx];

        // Central difference gradients
        final double dx = (luminances[idx + 1] - luminances[idx - 1]) * 0.5;
        final double dy = (luminances[idx + w] - luminances[idx - w]) * 0.5;

        sxx += dx * dx;
        syy += dy * dy;
        sxy += dx * dy;

        // Laplacian for micro-texture roughness
        final double lap = 4.0 * cur -
            luminances[idx + 1] -
            luminances[idx - 1] -
            luminances[idx + w] -
            luminances[idx - w];
        sumL += lap;
        sumL2 += lap * lap;

        final double mag = math.sqrt(dx * dx + dy * dy);
        if (mag > 3.0) {
          double angle = math.atan2(dy, dx);
          if (angle < 0) angle += math.pi;
          int bin = (angle / binWidth).floor();
          if (bin >= 8) bin = 7;
          hist[bin] += mag;
          totalEdgeMag += mag;
        }

        if (mag > 40.0) {
          harshEdgeCount++;
        }

        validPixels++;
      }
    }

    if (validPixels == 0) {
      return const _TextureAnalysisResult(
        isSkinTexture: true,
        nonSkinEvidence: 0.0,
        reason: 'Insufficient pixels',
      );
    }

    final double lapMean = sumL / validPixels;
    final double lapVariance = (sumL2 / validPixels) - (lapMean * lapMean);
    final double meanMag = totalEdgeMag / validPixels;
    final double harshEdgeRatio = harshEdgeCount / validPixels;

    // Structure tensor coherence (directional anisotropy)
    final double diff = sxx - syy;
    final double delta = math.sqrt(diff * diff + 4.0 * sxy * sxy);
    final double sumEig = sxx + syy + 1e-5;
    final double coherence = (delta / sumEig).clamp(0.0, 1.0);

    // Directional axis ratio (horizontal vs vertical stripe dominance)
    final double maxAxis = sxx > syy ? sxx : syy;
    final double minAxis = sxx < syy ? sxx : syy;
    final double axisRatio = maxAxis / (minAxis + 1.0);

    // Dominant orientation concentration
    double maxBin = 0.0;
    for (int b = 0; b < 8; b++) {
      if (hist[b] > maxBin) maxBin = hist[b];
    }
    final double dominantOrientationRatio =
        totalEdgeMag > 0 ? (maxBin / totalEdgeMag) : 0.0;

    // -------------------------------------------------------------
    // NON-SKIN HARD NEGATIVE DETECTION
    // -------------------------------------------------------------

    // 1. Wood grain / linear directional texture (table, door, chair, brown furniture)
    // Real wood from phone camera has coherence >= 0.22 and dominant orientation >= 0.24.
    final bool hasStrongWoodGrain = (coherence >= 0.22 && dominantOrientationRatio >= 0.24) ||
        (axisRatio >= 2.5 && dominantOrientationRatio >= 0.24) ||
        (coherence >= 0.38);

    if (hasStrongWoodGrain) {
      final double evidence = (0.80 + coherence * 0.6).clamp(0.80, 0.98);
      return _TextureAnalysisResult(
        isSkinTexture: false,
        nonSkinEvidence: evidence,
        reason: 'wood grain / directional linear texture',
      );
    }

    // 2. Flat / very-low-variance surfaces (walls, painted surfaces, smooth fabric, cardboard).
    // Truly flat painted walls or flat cardboard have near-zero texture: lapVariance < 3.5 && meanMag < 1.2.
    // Genuine human skin (even smooth skin on an arm or face) has natural organic curvature,
    // lighting gradations, and micro-pore structure that produces lapVariance >= 4.0.
    final bool isFlatSurface = (lapVariance < 3.5 && meanMag < 1.2);
    if (isFlatSurface) {
      return const _TextureAnalysisResult(
        isSkinTexture: false,
        nonSkinEvidence: 0.88,
        reason: 'flat / smooth non-skin surface (wall, cardboard)',
      );
    }

    // 3. Harsh specular steps / polished furniture / polished leather
    final bool isHarshFurnitureOrLeather = (harshEdgeRatio > 0.08 &&
        (coherence > 0.28 || dominantOrientationRatio > 0.26));
    if (isHarshFurnitureOrLeather) {
      return const _TextureAnalysisResult(
        isSkinTexture: false,
        nonSkinEvidence: 0.90,
        reason: 'artificial furniture or leather surface pattern',
      );
    }

    // 4. Corrugated cardboard ridges / fluted packaging
    final bool isCorrugated = (coherence >= 0.38 && axisRatio >= 2.8);
    if (isCorrugated) {
      return const _TextureAnalysisResult(
        isSkinTexture: false,
        nonSkinEvidence: 0.92,
        reason: 'corrugated / periodic packaging texture',
      );
    }

    return const _TextureAnalysisResult(
      isSkinTexture: true,
      nonSkinEvidence: 0.0,
      reason: 'organic human skin texture verified',
    );
  }
}

class _TextureAnalysisResult {
  final bool isSkinTexture;
  final double nonSkinEvidence;
  final String reason;

  const _TextureAnalysisResult({
    required this.isSkinTexture,
    required this.nonSkinEvidence,
    required this.reason,
  });
}
