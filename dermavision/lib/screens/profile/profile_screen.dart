import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'privacy_security_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({
    super.key,
    required this.username,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color purple = Color(0xFF7B4DFF);
  static const Color lightPurple = Color(0xFFF0E9FF);
  static const Color background = Color(0xFFFBFAFF);
  static const Color darkText = Color(0xFF20202A);
  static const Color secondaryText = Color(0xFF666672);

  bool notificationsEnabled = true;

  // ================================================================
  // OPEN EDIT PROFILE
  // ================================================================

  void _openEditProfile(String currentName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          username: currentName,
        ),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final String username = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : (widget.username.trim().isEmpty ? 'User' : widget.username.trim());

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
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Profile',
          style: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            children: [
              _buildProfileHeader(username, user?.avatarUrl),

              const SizedBox(height: 22),

              _buildSectionTitle('Account'),

              const SizedBox(height: 10),

              // PERSONAL INFORMATION
              _buildProfileOption(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle: 'Manage your profile details',
                onTap: () => _openEditProfile(username),
              ),

              const SizedBox(height: 10),

              // EMAIL
              _buildProfileOption(
                icon: Icons.email_outlined,
                title: 'Email Address',
                subtitle: 'Manage your registered email',
                onTap: () => _openEditProfile(username),
              ),

              const SizedBox(height: 10),

              // CHANGE PASSWORD
              _buildProfileOption(
                icon: Icons.lock_reset_rounded,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: _openChangePassword,
              ),

              const SizedBox(height: 22),

              _buildSectionTitle('Preferences'),

              const SizedBox(height: 10),

              _buildNotificationOption(),

              const SizedBox(height: 10),

              _buildProfileOption(
                icon: Icons.lock_outline_rounded,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacySecurityScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _buildProfileOption(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Get help with Dermavision',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              _buildLogoutButton(),

              const SizedBox(height: 20),

              const Text(
                'Dermavision',
                style: TextStyle(
                  color: purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'AI Powered Skin Intelligence',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Color(0xFF9999A3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CHANGE PASSWORD DIALOG
  // ================================================================

  void _openChangePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isChanging = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_reset_rounded,
                            color: purple,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your new password must be at least 6 characters long.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Current password
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkText,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Current Password',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: purple,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => setSheetState(
                              () => obscureCurrent = !obscureCurrent,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xffF8F6FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: purple,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // New password
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkText,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your new password';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          if (v == currentPasswordController.text) {
                            return 'New password must be different from current';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'New Password',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: purple,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => setSheetState(
                              () => obscureNew = !obscureNew,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xffF8F6FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: purple,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Confirm new password
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkText,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (v != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Confirm New Password',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: purple,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => setSheetState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xffF8F6FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: purple,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isChanging
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setSheetState(() => isChanging = true);

                                  final auth = context.read<AuthProvider>();
                                  final messenger = ScaffoldMessenger.of(context);
                                  final sheetNav = Navigator.of(bottomSheetContext);

                                  final success = await auth.changePassword(
                                    currentPassword:
                                        currentPasswordController.text.trim(),
                                    newPassword:
                                        newPasswordController.text.trim(),
                                  );

                                  if (success) {
                                    sheetNav.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password updated successfully!',
                                        ),
                                        backgroundColor: Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    setSheetState(() => isChanging = false);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          auth.errorMessage ??
                                              'Failed to update password.',
                                        ),
                                        backgroundColor:
                                            Colors.red.shade400,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isChanging
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Update Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: TextButton(
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();
                            final email = auth.currentUser?.email;
                            final messenger = ScaffoldMessenger.of(context);
                            final sheetNav = Navigator.of(bottomSheetContext);

                            if (email != null && email.isNotEmpty) {
                              sheetNav.pop();
                              await auth.resetPassword(email);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reset email sent to $email. Check your inbox to change your password.',
                                  ),
                                  backgroundColor:
                                      const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Forgot current password? Send reset email',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
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
      },
    );
  }

  // ================================================================
  // PROFILE HEADER
  // ================================================================

  Widget _buildProfileHeader(String username, String? avatarUrl) {
    Widget avatarChild;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final commaIndex = avatarUrl.indexOf(',');
          final base64Data = commaIndex != -1
              ? avatarUrl.substring(commaIndex + 1)
              : avatarUrl;
          final bytes = base64Decode(base64Data);
          avatarChild = ClipOval(
            child: Image.memory(
              bytes,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person_rounded,
                color: purple,
                size: 43,
              ),
            ),
          );
        } catch (_) {
          avatarChild = const Icon(
            Icons.person_rounded,
            color: purple,
            size: 43,
          );
        }
      } else if (avatarUrl.startsWith('http://') ||
          avatarUrl.startsWith('https://') ||
          avatarUrl.startsWith('blob:')) {
        avatarChild = ClipOval(
          child: Image.network(
            avatarUrl,
            width: 82,
            height: 82,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.person_rounded,
              color: purple,
              size: 43,
            ),
          ),
        );
      } else if (!kIsWeb) {
        try {
          final file = File(avatarUrl);
          if (file.existsSync()) {
            avatarChild = ClipOval(
              child: Image.file(
                file,
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_rounded,
                  color: purple,
                  size: 43,
                ),
              ),
            );
          } else {
            avatarChild = const Icon(
              Icons.person_rounded,
              color: purple,
              size: 43,
            );
          }
        } catch (_) {
          avatarChild = const Icon(
            Icons.person_rounded,
            color: purple,
            size: 43,
          );
        }
      } else {
        avatarChild = const Icon(
          Icons.person_rounded,
          color: purple,
          size: 43,
        );
      }
    } else {
      avatarChild = const Icon(
        Icons.person_rounded,
        color: purple,
        size: 43,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8755FF),
            Color(0xFF7139F4),
            Color(0xFF6330E8),
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.23),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),

          Positioned(
            right: -70,
            bottom: -85,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.2,
                ),
              ),
            ),
          ),

          Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: avatarChild,
              ),

              const SizedBox(height: 13),

              Text(
                username,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Dermavision User',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // ====================================================
              // EDIT PROFILE BUTTON
              // ====================================================

              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _openEditProfile(username),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: purple,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: darkText,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ================================================================
  // PROFILE OPTION
  // ================================================================

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: purple.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.06),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: purple,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: purple,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // NOTIFICATION OPTION
  // ================================================================

  Widget _buildNotificationOption() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: purple,
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Skin scan reminders and updates',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: notificationsEnabled,
            activeThumbColor: Colors.white,
            activeTrackColor: purple,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOGOUT BUTTON
  // ================================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _showLogoutDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE05252),
          side: BorderSide(
            color: const Color(0xFFE05252).withValues(alpha: 0.25),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // LOGOUT DIALOG
  // ================================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Log Out?',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of Dermavision?',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final auth = context.read<AuthProvider>();
                final reportProv = context.read<ReportProvider>();

                // Sign out from Firebase before returning to login.
                await auth.logout();
                reportProv.clearReports();

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}