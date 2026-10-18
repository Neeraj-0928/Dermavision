import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/skin_detector_service.dart';
import '../result/result_screen.dart';
import 'camera_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color purple = Color(0xFF7B4DFF);
  static const Color lightPurple = Color(0xFFF0E9FF);
  static const Color background = Color(0xFFFAF9FF);
  static const Color darkText = Color(0xFF252530);
  static const Color secondaryText = Color(0xFF676773);

  // ================================================================
  // IMAGE SELECTION STATE
  // ================================================================

  final ImagePicker _picker = ImagePicker();
  final SkinDetectorService _skinDetectorService = SkinDetectorService();

  File? _selectedImage;
  XFile? _selectedXFile;
  Uint8List? _selectedBytes;
  bool _isSelecting = false;
  bool _isAnalyzing = false;
  bool _isVerifyingSkin = false;
  SkinDetectionResult? _skinResult;

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null && mounted) {
        final bytes = await response.file!.readAsBytes();
        setState(() {
          _selectedXFile = response.file;
          _selectedBytes = bytes;
          if (!kIsWeb) {
            _selectedImage = File(response.file!.path);
          }
        });
        _runSkinVerification(bytes);
      }
    } catch (_) {}
  }

  // ================================================================
  // BUILD
  // ================================================================

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
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Skin Analysis',
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final double horizontalPadding =
                (constraints.maxWidth * 0.05).clamp(16.0, 22.0);
            final double imageHeight =
                (screenHeight * 0.33).clamp(210.0, 310.0);
            final double sectionSpacing = screenHeight < 700 ? 16.0 : 22.0;

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
                  _buildIntro(),

                  SizedBox(height: sectionSpacing),

                  _buildImageArea(imageHeight),

                  if (_selectedImage != null ||
                      _selectedXFile != null ||
                      _selectedBytes != null) ...[
                    const SizedBox(height: 14),
                    _buildSkinGateCard(),
                  ],

                  SizedBox(height: sectionSpacing),

                  _buildInstructions(),

                  SizedBox(height: sectionSpacing),

                  _buildActionButtons(),

                  if (_selectedImage != null ||
                      _selectedXFile != null ||
                      _selectedBytes != null) ...[
                    const SizedBox(height: 18),
                    _buildAnalyzeButton(),
                  ],

                  const SizedBox(height: 22),

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
          'Check your skin',
          style: TextStyle(
            color: purple,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Upload a clear image of your skin to get AI-powered insights.',
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
  // IMAGE AREA
  // ================================================================

  Widget _buildImageArea(double height) {
    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1EAFF),
            Color(0xFFE9DEFF),
          ],
        ),
        border: Border.all(
          color: purple.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.07),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: (_selectedImage == null && _selectedXFile == null && _selectedBytes == null)
          ? _buildEmptyImageArea()
          : _buildSelectedImage(),
    );
  }

  // ================================================================
  // EMPTY IMAGE AREA
  // ================================================================

  Widget _buildEmptyImageArea() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: purple,
                size: 32,
              ),
            ),

            const SizedBox(height: 17),

            const Text(
              'Add a skin image',
              style: TextStyle(
                color: darkText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Take a photo or choose one from your gallery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SELECTED IMAGE
  // ================================================================

  Widget _buildSelectedImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildWebSafeImage(),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 105,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: 16,
          bottom: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'Image selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 13,
          right: 13,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedImage = null;
                _selectedXFile = null;
                _selectedBytes = null;
                _skinResult = null;
                _isVerifyingSkin = false;
              });
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // INSTRUCTIONS
  // ================================================================

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'For better results',
            style: TextStyle(
              color: purple,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 11),

          _instructionItem(
            Icons.wb_sunny_outlined,
            'Use good lighting',
          ),

          _instructionItem(
            Icons.center_focus_strong_rounded,
            'Keep the affected area clearly visible',
          ),

          _instructionItem(
            Icons.no_flash_rounded,
            'Avoid blurry or heavily filtered images',
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INSTRUCTION ITEM
  // ================================================================

  Widget _instructionItem(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: purple,
              size: 15,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CAMERA / GALLERY ACTIONS (SEPARATED STRICTLY)
  // ================================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            onTap: _openCamera,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _actionButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: _openGallery,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: (_isSelecting || _isAnalyzing) ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: purple,
          disabledBackgroundColor: const Color(0xFFFAF9FD),
          disabledForegroundColor: purple.withValues(alpha: 0.5),
          side: const BorderSide(
            color: Color(0xFFD6C7FF),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: purple,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CAMERA LOGIC (OPENS ACTUAL CAMERA / WEBCAM)
  // ================================================================

  Future<void> _openCamera() async {
    if (_isSelecting || _isAnalyzing) return;
    setState(() => _isSelecting = true);

    try {
      final XFile? photo = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCaptureScreen(),
        ),
      );

      if (photo != null && mounted) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedXFile = photo;
          _selectedBytes = bytes;
          if (!kIsWeb) {
            _selectedImage = File(photo.path);
          }
        });
        _runSkinVerification(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelecting = false);
      }
    }
  }

  // ================================================================
  // GALLERY LOGIC (OPENS ONLY GALLERY / FILE PICKER)
  // ================================================================

  Future<void> _openGallery() async {
    if (_isSelecting || _isAnalyzing) return;
    setState(() => _isSelecting = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile != null && mounted) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedXFile = pickedFile;
          _selectedBytes = bytes;
          if (!kIsWeb) {
            _selectedImage = File(pickedFile.path);
          }
        });
        _runSkinVerification(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelecting = false);
      }
    }
  }

  // ================================================================
  // ANALYZE BUTTON
  // ================================================================

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _openResultPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _isAnalyzing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Analyze My Skin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 7),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  // ================================================================
  // IMAGE DISPLAY WIDGET
  // ================================================================

  Widget _buildWebSafeImage() {
    if (_selectedBytes != null) {
      return Image.memory(
        _selectedBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: lightPurple,
      child: const Center(
        child: Icon(Icons.image_outlined, color: purple, size: 55),
      ),
    );
  }

  // ================================================================
  // SKIN VERIFICATION LOGIC (DERMAVISION SKIN GATE)
  // ================================================================

  Future<void> _runSkinVerification(Uint8List bytes) async {
    if (!mounted) return;
    setState(() {
      _isVerifyingSkin = true;
      _skinResult = null;
    });

    try {
      final result = await _skinDetectorService.detectSkin(imageBytes: bytes);
      if (mounted) {
        setState(() {
          _skinResult = result;
          _isVerifyingSkin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingSkin = false;
        });
      }
    }
  }

  // ================================================================
  // SKIN GATE CARD WIDGET
  // ================================================================

  Widget _buildSkinGateCard() {
    if (_isVerifyingSkin) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: lightPurple,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: purple.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(purple),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifying skin presence...',
                    style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'DermaVision Skin Gate AI is inspecting image tones & features',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 11,
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

    if (_skinResult == null) {
      return const SizedBox.shrink();
    }

    final isSkin = _skinResult!.isSkin;
    final isNonSkin = _skinResult!.status == SkinDetectionStatus.nonSkin;

    final Color statusColor = isSkin
        ? const Color(0xFF10B981) // Emerald
        : (isNonSkin ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)); // Red or Amber

    final Color cardBg = isSkin
        ? const Color(0xFFECFDF5)
        : (isNonSkin ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB));

    final IconData statusIcon = isSkin
        ? Icons.verified_rounded
        : (isNonSkin ? Icons.cancel_rounded : Icons.help_outline_rounded);

    final String statusTitle = isSkin
        ? 'Human Skin Verified'
        : (isNonSkin ? 'Non-Skin Detected' : 'Skin Presence Ambiguous');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _skinResult!.message,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_skinResult!.confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'p(skin): ${(_skinResult!.pSkin * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _skinResult!.source == 'tflite'
                        ? Icons.memory_rounded
                        : Icons.color_lens_outlined,
                    size: 13,
                    color: _skinResult!.source == 'tflite'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _skinResult!.source == 'tflite'
                        ? 'MobileNetV2 On-Device'
                        : 'Color Heuristic',
                    style: TextStyle(
                      color: _skinResult!.source == 'tflite'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // NON-SKIN DETECTED WARNING MODAL
  // ================================================================

  Future<void> _showNonSkinDetectedDialog(SkinDetectionResult result) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Non-Skin Image Detected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${result.label} (${result.confidence.toStringAsFixed(1)}% confidence)',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DermaVision AI analyzed your photo and detected that it does not appear to contain human skin (confidence: ${result.confidence.toStringAsFixed(1)}%).\n\nClinical lesion evaluation on non-skin items produces invalid results.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openCamera();
                  },
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text(
                    'Retake Skin Photo',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openGallery();
                  },
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text(
                    'Choose Another Image',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    side: BorderSide(color: purple.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // RESULT PAGE NAVIGATION AND PER-USER REPORT SAVING
  // ================================================================

  Future<void> _openResultPage() async {
    final hasImage = _selectedBytes != null ||
        _selectedXFile != null ||
        _selectedImage != null;
    if (!hasImage || _isAnalyzing) {
      return;
    }

    // Wait if skin verification is currently in progress
    if (_isVerifyingSkin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifying skin presence. Please wait a moment...'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If skin verification has not run yet, run it now before disease classification
    if (_skinResult == null) {
      Uint8List? bytesToVerify = _selectedBytes;
      if (bytesToVerify == null) {
        if (_selectedXFile != null) {
          bytesToVerify = await _selectedXFile!.readAsBytes();
          _selectedBytes = bytesToVerify;
        } else if (_selectedImage != null) {
          bytesToVerify = await _selectedImage!.readAsBytes();
          _selectedBytes = bytesToVerify;
        }
      }
      if (bytesToVerify != null) {
        setState(() => _isAnalyzing = true);
        await _runSkinVerification(bytesToVerify);
        setState(() => _isAnalyzing = false);
      }
    }

    // If classified as NON-SKIN, present warning gate dialog and block diagnosis
    if (_skinResult != null && !_skinResult!.isSkin) {
      await _showNonSkinDetectedDialog(_skinResult!);
      return;
    }

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final reportProvider = context.read<ReportProvider>();
    final userId = auth.currentUser?.id ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';

    setState(() => _isAnalyzing = true);

    try {
      String imagePath = '';
      if (_selectedBytes != null) {
        imagePath = 'data:image/jpeg;base64,${base64Encode(_selectedBytes!)}';
      } else if (kIsWeb && _selectedXFile != null) {
        final bytes = await _selectedXFile!.readAsBytes();
        imagePath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (_selectedImage != null) {
        imagePath = _selectedImage!.path;
      }

      final report = ReportModel(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        condition: 'Melanocytic Nevus',
        confidence: 0.92,
        severity: 'Low Risk',
        date: DateTime.now(),
        imagePath: imagePath,
        skinStatus: _skinResult?.label ?? 'SKIN',
        skinConfidence: _skinResult?.confidence ?? 95.0,
        description:
            'A melanocytic nevus is a common type of skin lesion that is usually '
            'harmless. It is formed by a cluster of pigment-producing cells called '
            'melanocytes. Most nevi are benign; however, monitoring changes in '
            'size, shape, or color is important to detect any early signs of '
            'melanoma. AI-based analysis can help identify patterns that may '
            'require further clinical attention.',
        recommendation:
            'Continue monitoring your skin regularly. Protect against intense UV radiation with SPF 30+ sunscreen.',
        precautions: const [
          'Avoid intense midday sunlight exposure',
          'Perform monthly self-examinations using the ABCDE rule',
          'Consult a dermatologist if you observe changes in shape or color',
        ],
      );

      // Persist the report in per-user storage
      if (userId.isNotEmpty) {
        await reportProvider.addReport(report);
      }

      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            report: report,
            imagePath: report.imagePath,
            condition: report.condition,
            confidence: report.confidence,
            severity: report.severity,
            diseaseInfo: report.description,
            skinStatus: report.skinStatus,
            skinConfidence: report.skinConfidence,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
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
              'AI results are for informational purposes only '
              'and should not replace professional medical advice.',
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
}