import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:dermavision/models/report_model.dart';
import 'package:dermavision/services/skin_detector_service.dart';

void main() {
  group('SkinDetectionResult Creation and Properties', () {
    test('creates successful skin detection via TFLite factory', () {
      final result = SkinDetectionResult.tflite(
        isSkin: true,
        pSkin: 0.964,
        confidence: 96.4,
      );

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.label, equals('SKIN'));
      expect(result.confidence, equals(96.4));
      expect(result.pSkin, equals(0.964));
      expect(result.message, contains('verified'));
      expect(result.source, equals('tflite'));
    });

    test('creates non-skin detection via TFLite factory', () {
      final result = SkinDetectionResult.tflite(
        isSkin: false,
        pSkin: 0.088,
        confidence: 91.2,
      );

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
      expect(result.label, equals('NON-SKIN'));
      expect(result.confidence, equals(91.2));
      expect(result.pSkin, equals(0.088));
      expect(result.message, contains('Non-skin'));
      expect(result.source, equals('tflite'));
    });

    test('creates heuristic detection fallback', () {
      final result = SkinDetectionResult.heuristic(
        isSkin: true,
        confidence: 85.0,
        skinPixelRatio: 0.45,
      );

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.source, equals('heuristic'));
      expect(result.confidence, equals(85.0));
    });

    test('creates error result', () {
      final result = SkinDetectionResult.error('Failed to run model');

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.error));
      expect(result.source, equals('error'));
      expect(result.error, equals('Failed to run model'));
    });
  });

  group('ReportModel Skin Verification Fields', () {
    test('serializes and deserializes skinStatus and skinConfidence', () {
      final report = ReportModel(
        id: 'rep_123',
        userId: 'user_456',
        condition: 'Melanocytic Nevus',
        confidence: 0.94,
        severity: 'Low Risk',
        date: DateTime(2026, 10, 8, 12, 0),
        imagePath: 'data:image/jpeg;base64,abc',
        skinStatus: 'SKIN',
        skinConfidence: 96.5,
      );

      final map = report.toMap();
      expect(map['skinStatus'], equals('SKIN'));
      expect(map['skinConfidence'], equals(96.5));

      final jsonStr = report.toJson();
      final fromJsonReport = ReportModel.fromJson(jsonStr);

      expect(fromJsonReport.skinStatus, equals('SKIN'));
      expect(fromJsonReport.skinConfidence, equals(96.5));
      expect(fromJsonReport.condition, equals('Melanocytic Nevus'));
    });
  });

  group('Skin Detection Image Verification & Hard-Negative Rejection', () {
    test('Wood (wooden table) → NON-SKIN', () async {
      // Create a 100x100 wooden table image with warm brown color and horizontal wood grain stripes
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        final bool isGrain = (y % 8 == 0) || (y % 8 == 1);
        final int r = isGrain ? 128 : 178;
        final int g = isGrain ? 78 : 118;
        final int b = isGrain ? 40 : 68;
        for (int x = 0; x < 100; x++) {
          testImg.setPixelRgb(x, y, r, g, b);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
      expect(result.label, equals('NON-SKIN'));
      expect(result.confidence, greaterThan(75.0));
      expect(result.message, contains('Non-skin'));
    });

    test('Wood (wooden door) → NON-SKIN', () async {
      // Create a 100x100 wooden door with vertical wood grain
      final testImg = img.Image(width: 100, height: 100);
      for (int x = 0; x < 100; x++) {
        final bool isGrain = (x % 7 == 0) || (x % 7 == 1);
        final int r = isGrain ? 122 : 172;
        final int g = isGrain ? 72 : 112;
        final int b = isGrain ? 36 : 64;
        for (int y = 0; y < 100; y++) {
          testImg.setPixelRgb(x, y, r, g, b);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
      expect(result.label, equals('NON-SKIN'));
      expect(result.confidence, greaterThan(75.0));
    });

    test('Wood (wooden chair / brown furniture) → NON-SKIN', () async {
      // Create brown furniture with repeating directional wood grain
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        final double stripe = (y % 10 < 3) ? 0.75 : 1.0;
        final int r = (165 * stripe).toInt();
        final int g = (105 * stripe).toInt();
        final int b = (55 * stripe).toInt();
        for (int x = 0; x < 100; x++) {
          testImg.setPixelRgb(x, y, r, g, b);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
    });

    test('Cardboard (flat brown packaging) → NON-SKIN', () async {
      // Flat brown cardboard with no biological micro-relief or pore structures
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          testImg.setPixelRgb(x, y, 182, 142, 98);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
    });

    test('Leather (polished brown leather with specular sheen) → NON-SKIN', () async {
      // Polished leather with harsh specular glints and sharp boundary steps
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          if (x == 30 || x == 60) {
            testImg.setPixelRgb(x, y, 245, 240, 235); // Specular sheen highlight
          } else {
            testImg.setPixelRgb(x, y, 120, 70, 42); // Deep brown leather
          }
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
    });

    test('Teal bottle → NON-SKIN', () async {
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          testImg.setPixelRgb(x, y, 40, 140, 160); // Teal bottle
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
      expect(result.confidence, greaterThan(75.0));
    });

    test('Wall (neutral off-white wall) → NON-SKIN', () async {
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          testImg.setPixelRgb(x, y, 215, 212, 208); // Off-white wall
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
    });

    test('Red/crimson bedsheet (phone photo) → NON-SKIN', () async {
      // Crimson bedsheet: ~(148, 32, 52). Blue dye makes g ≈ b violating skin invariant g > b.
      final testImg = img.Image(width: 100, height: 100);
      final rng = math.Random(7);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int noise = rng.nextInt(11) - 5;
          testImg.setPixelRgb(x, y, 148 + noise, 32 + noise, 52 + noise);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
      expect(result.confidence, greaterThan(75.0));
    });

    test('Warm-tinted indoor wall (beige under warm bulb, flat) → NON-SKIN', () async {
      // Real wall is perfectly flat — uniform color with no micro-relief or pores.
      // Texture gate detects near-zero lapVariance and low gradient magnitude.
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          testImg.setPixelRgb(x, y, 190, 172, 148); // No noise — flat wall surface
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isFalse);
      expect(result.status, equals(SkinDetectionStatus.nonSkin));
      expect(result.confidence, greaterThan(75.0));
    });

    test('Genuine skin (Fitzpatrick I-II light skin) → SKIN', () async {
      final testImg = img.Image(width: 100, height: 100);
      final rng = math.Random(11);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int noise = rng.nextInt(7) - 3;
          testImg.setPixelRgb(x, y, 230 + noise, 192 + noise, 172 + noise);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.confidence, greaterThan(70.0));
      expect(result.message, contains('verified'));
    });

    test('Genuine skin (Fitzpatrick III-IV medium/olive skin) → SKIN', () async {
      final testImg = img.Image(width: 100, height: 100);
      final rng = math.Random(42);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int noise = rng.nextInt(7) - 3;
          testImg.setPixelRgb(x, y, 190 + noise, 135 + noise, 100 + noise);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.confidence, greaterThan(70.0));
      expect(result.message, contains('verified'));
    });

    test('Genuine skin (Fitzpatrick V-VI deep/brown skin) → SKIN', () async {
      final testImg = img.Image(width: 100, height: 100);
      final rng = math.Random(99);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int noise = rng.nextInt(7) - 3;
          testImg.setPixelRgb(x, y, 110 + noise, 72 + noise, 52 + noise);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.confidence, greaterThan(70.0));
      expect(result.message, contains('verified'));
    });

    test('Genuine skin with dermatological lesion (melanocytic nevus) → SKIN', () async {
      // Skin background (Fitzpatrick III-IV) with centered circular dark nevus lesion
      final testImg = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final double dx = (x - 50).toDouble();
          final double dy = (y - 50).toDouble();
          final double dist = math.sqrt(dx * dx + dy * dy);

          final int noise = ((x * 13 + y * 19) % 7) - 3;

          if (dist < 18.0) {
            // Darker melanocytic nevus spot in center
            testImg.setPixelRgb(x, y, 92 + noise, 52 + noise, 36 + noise);
          } else {
            // Surrounding healthy skin
            testImg.setPixelRgb(x, y, 192 + noise, 138 + noise, 102 + noise);
          }
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.confidence, greaterThan(70.0));
      expect(result.message, contains('verified'));
    });

    test('Fair skin under indoor lighting / pale forearm (Sat ≈ 0.17) → SKIN', () async {
      // Pale forearm under diffuse indoor light: R=225, G=195, B=185 (Sat = 0.178)
      final testImg = img.Image(width: 100, height: 100);
      final rng = math.Random(101);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int noise = rng.nextInt(7) - 3;
          testImg.setPixelRgb(x, y, 225 + noise, 195 + noise, 185 + noise);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.confidence, greaterThan(65.0));
      expect(result.message, contains('verified'));
    });

    test('Smooth forearm skin with subtle lighting gradient → SKIN', () async {
      // Forearm with soft lighting falloff across surface and fine micro-relief
      final testImg = img.Image(width: 100, height: 100);
      final rng = math.Random(77);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int grad = ((x - 50) * 0.12).toInt();
          final int noise = rng.nextInt(5) - 2;
          testImg.setPixelRgb(x, y, 215 + grad + noise, 175 + grad + noise, 145 + grad + noise);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.confidence, greaterThan(65.0));
      expect(result.message, contains('verified'));
    });

    test('Skin arm centered with background (skin covering ~35% of frame) → SKIN', () async {
      // Arm in center 40 columns (columns 30..70), neutral gray background on sides
      final testImg = img.Image(width: 100, height: 100);
      final rng = math.Random(55);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int noise = rng.nextInt(5) - 2;
          if (x >= 32 && x <= 68) {
            // Centered arm (skin)
            testImg.setPixelRgb(x, y, 205 + noise, 155 + noise, 120 + noise);
          } else {
            // Background (neutral clothing / table)
            testImg.setPixelRgb(x, y, 160 + noise, 160 + noise, 160 + noise);
          }
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImg));

      final service = SkinDetectorService();
      final result = await service.detectSkin(imageBytes: bytes);

      expect(result.isSkin, isTrue);
      expect(result.status, equals(SkinDetectionStatus.skin));
      expect(result.confidence, greaterThan(65.0));
      expect(result.message, contains('verified'));
    });
  });
}

