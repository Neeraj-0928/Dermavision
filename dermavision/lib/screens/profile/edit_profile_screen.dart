import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final String username;

  const EditProfileScreen({
    super.key,
    required this.username,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color purple = Color(0xFF7B4DFF);
  static const Color darkText = Color(0xFF20202A);
  static const Color secondaryText = Color(0xFF666672);
  static const Color background = Color(0xFFFBFAFF);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    _nameController = TextEditingController(
      text: user?.name.isNotEmpty == true ? user!.name : widget.username,
    );
    _emailController = TextEditingController(
      text: user?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: user?.phone ?? '',
    );
    _avatarPath = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: purple,
                    ),
                  ),
                  title: const Text(
                    'Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Take a new photo with camera',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _chooseAvatar(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: purple,
                    ),
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Choose an image from gallery',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _chooseAvatar(ImageSource.gallery);
                  },
                ),
                if (_avatarPath != null && _avatarPath!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                      ),
                    ),
                    title: Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      setState(() {
                        _avatarPath = '';
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _chooseAvatar(ImageSource source) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (!kIsWeb && source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text(
                'Camera permission is required. Please enable it in Settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        } else if (!status.isGranted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to take a photo.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (picked == null || !mounted) return;

      String finalAvatarPath = '';
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        finalAvatarPath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final userId = auth.currentUser?.id ?? 'user';
          final fileName =
              'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedFile =
              await File(picked.path).copy('${appDir.path}/$fileName');
          finalAvatarPath = savedFile.path;
        } catch (_) {
          final bytes = await picked.readAsBytes();
          finalAvatarPath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }

      if (mounted) {
        setState(() {
          _avatarPath = finalAvatarPath;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select photo: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAvatarWidget() {
    Widget avatarChild;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (_avatarPath!.startsWith('data:image')) {
        try {
          final commaIndex = _avatarPath!.indexOf(',');
          final base64Data = commaIndex != -1
              ? _avatarPath!.substring(commaIndex + 1)
              : _avatarPath!;
          final bytes = base64Decode(base64Data);
          avatarChild = ClipOval(
            child: Image.memory(
              bytes,
              width: 95,
              height: 95,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person_rounded,
                color: purple,
                size: 50,
              ),
            ),
          );
        } catch (_) {
          avatarChild = const Icon(
            Icons.person_rounded,
            color: purple,
            size: 50,
          );
        }
      } else if (_avatarPath!.startsWith('http://') ||
          _avatarPath!.startsWith('https://') ||
          _avatarPath!.startsWith('blob:')) {
        avatarChild = ClipOval(
          child: Image.network(
            _avatarPath!,
            width: 95,
            height: 95,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.person_rounded,
              color: purple,
              size: 50,
            ),
          ),
        );
      } else if (!kIsWeb) {
        try {
          final localFile = File(_avatarPath!);
          if (localFile.existsSync()) {
            avatarChild = ClipOval(
              child: Image.file(
                localFile,
                width: 95,
                height: 95,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_rounded,
                  color: purple,
                  size: 50,
                ),
              ),
            );
          } else {
            avatarChild = const Icon(
              Icons.person_rounded,
              color: purple,
              size: 50,
            );
          }
        } catch (_) {
          avatarChild = const Icon(
            Icons.person_rounded,
            color: purple,
            size: 50,
          );
        }
      } else {
        avatarChild = const Icon(
          Icons.person_rounded,
          color: purple,
          size: 50,
        );
      }
    } else {
      avatarChild = const Icon(
        Icons.person_rounded,
        color: purple,
        size: 50,
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0E9FF),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: avatarChild,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: purple,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarUrl: _avatarPath,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF24A35A),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update profile.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar center card
                _buildAvatarWidget(),

                const SizedBox(height: 28),

                // Name field
                const Text(
                  'Full Name',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _nameController,
                  hintText: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email field - READ ONLY
                const Row(
                  children: [
                    Text(
                      'Email Address',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '(Read-only)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _emailController,
                  hintText: 'Registered email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  suffixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),

                const SizedBox(height: 20),

                // Phone field
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _phoneController,
                  hintText: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 35),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: readOnly ? Colors.grey.shade600 : darkText,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: readOnly ? Colors.grey.shade400 : purple,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF4F3F8) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: readOnly ? Colors.grey.shade300 : purple,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
