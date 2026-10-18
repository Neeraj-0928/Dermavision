import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  static const Color purple = Color(0xFF7B4DFF);

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isTakingPhoto = false;
  String? _errorMessage;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initSelectedCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });

    try {
      // On mobile devices, check runtime camera permission
      if (!kIsWeb) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Camera permission is permanently denied. Please enable it in system settings.';
            });
          }
          return;
        } else if (!status.isGranted) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Camera permission is required to capture skin photos.';
            });
          }
          return;
        }
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'No camera detected on this device. Please connect a webcam or enable camera access.';
          });
        }
        return;
      }

      _cameras = cameras;

      // Prefer rear camera on mobile, otherwise use first available camera (laptop webcam)
      int targetIndex = 0;
      for (int i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == CameraLensDirection.back) {
          targetIndex = i;
          break;
        }
      }
      _selectedCameraIndex = targetIndex;

      await _initSelectedCamera();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to start camera: $e';
        });
      }
    }
  }

  Future<void> _initSelectedCamera() async {
    if (_cameras.isEmpty) return;

    final prev = _controller;
    _controller = null;
    await prev?.dispose();

    final cameraDesc = _cameras[_selectedCameraIndex];
    final controller = CameraController(
      cameraDesc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera initialization failed: $e';
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isTakingPhoto) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _isInitialized = false;
    });
    await _initSelectedCamera();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isTakingPhoto) {
      return;
    }

    setState(() => _isTakingPhoto = true);

    try {
      final XFile photo = await controller.takePicture();
      if (mounted) {
        Navigator.pop(context, photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTakingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ====================================================
            // CAMERA FEED / STATES
            // ====================================================
            if (_errorMessage != null)
              _buildErrorView()
            else if (!_isInitialized || _controller == null)
              _buildLoadingView()
            else
              _buildCameraPreview(),

            // ====================================================
            // TOP BAR OVERLAY
            // ====================================================
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),

                  // Header title badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'DermaVision Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flip camera button (if multiple cameras available)
                  if (_cameras.length > 1)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: _switchCamera,
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                ],
              ),
            ),

            // ====================================================
            // BOTTOM CONTROLS OVERLAY
            // ====================================================
            if (_isInitialized && _errorMessage == null)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align skin area inside the frame and tap capture',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Large circular shutter button
                    GestureDetector(
                      onTap: _isTakingPhoto ? null : _takePicture,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          color: purple,
                          boxShadow: [
                            BoxShadow(
                              color: purple.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isTakingPhoto
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double frameSize = (constraints.maxWidth * 0.72)
            .clamp(180.0, (constraints.maxHeight * 0.38).clamp(180.0, 270.0));

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: CameraPreview(_controller!),
            ),

            // Centered targeting scan guide frame
            Center(
              child: Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Corner accents in purple
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _cornerAccent(isTop: true, isLeft: true),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _cornerAccent(isTop: true, isLeft: false),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _cornerAccent(isTop: false, isLeft: true),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _cornerAccent(isTop: false, isLeft: false),
                    ),
                  ],
                ),
              ),
            ),

            // Scan guidance banner
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.center_focus_strong_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Align skin area inside target frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cornerAccent({required bool isTop, required bool isLeft}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: purple, width: 4.5)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: purple, width: 4.5)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: purple, width: 4.5)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: purple, width: 4.5)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft
              ? const Radius.circular(24)
              : Radius.zero,
          topRight: isTop && !isLeft
              ? const Radius.circular(24)
              : Radius.zero,
          bottomLeft: !isTop && isLeft
              ? const Radius.circular(24)
              : Radius.zero,
          bottomRight: !isTop && !isLeft
              ? const Radius.circular(24)
              : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(purple),
          ),
          SizedBox(height: 18),
          Text(
            'Starting camera feed...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: Colors.redAccent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Camera Unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to access camera.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
