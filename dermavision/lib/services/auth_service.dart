import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // SharedPreferences keys for persistent local user preferences and cache
  static const String _notificationsKey = 'dermavision_notifications_';
  static const String _phoneKey = 'dermavision_phone_';
  static const String _avatarKey = 'dermavision_avatar_';
  static const String _nameKey = 'dermavision_name_';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Build a [UserModel] from a Firebase [User].
  Future<UserModel> _buildUserModel(User fbUser) async {
    final prefs = await SharedPreferences.getInstance();
    final notifs =
        prefs.getBool('$_notificationsKey${fbUser.uid}') ?? true;
    final phone = prefs.getString('$_phoneKey${fbUser.uid}') ?? '';
    final avatar = prefs.getString('$_avatarKey${fbUser.uid}') ??
        fbUser.photoURL ??
        '';
    final savedName = prefs.getString('$_nameKey${fbUser.uid}');
    final name = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
        ? fbUser.displayName!
        : ((savedName != null && savedName.trim().isNotEmpty)
            ? savedName
            : (fbUser.email?.split('@').first ?? 'User'));

    return UserModel(
      id: fbUser.uid,
      name: name,
      email: fbUser.email ?? '',
      phone: phone,
      avatarUrl: avatar,
      notificationsEnabled: notifs,
      isEmailVerified: fbUser.emailVerified,
      createdAt: DateTime.now(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SESSION CHECK
  // ──────────────────────────────────────────────────────────────

  /// Returns the currently authenticated [UserModel], or null.
  Future<UserModel?> getActiveUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;

    try {
      await fbUser.reload();
    } catch (_) {
      // Network may be unavailable; use cached state
    }

    final refreshed = _firebaseAuth.currentUser;
    if (refreshed == null) return null;

    return _buildUserModel(refreshed);
  }

  // ──────────────────────────────────────────────────────────────
  // REGISTER
  // ──────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth account and sends a verification email.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Registration failed. Please try again.');
      }

      await fbUser.updateDisplayName(name.trim());
      try {
        await fbUser.sendEmailVerification();
        debugPrint('Verification email dispatched to $normalizedEmail');
      } catch (e) {
        debugPrint('Initial verification email failed (can be resent): $e');
      }

      try {
        await fbUser.reload();
      } catch (_) {}

      final refreshed = _firebaseAuth.currentUser ?? fbUser;
      return _buildUserModel(refreshed);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // LOGIN
  // ──────────────────────────────────────────────────────────────

  /// Signs in with email/password. Returns [UserModel] regardless of
  /// email-verification status — the UI decides where to navigate.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Authentication failed. Please try again.');
      }

      try {
        await fbUser.reload();
      } catch (_) {}

      final refreshed = _firebaseAuth.currentUser ?? fbUser;
      return _buildUserModel(refreshed);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // EMAIL VERIFICATION
  // ──────────────────────────────────────────────────────────────

  /// Sends a Firebase verification email to the currently signed-in user.
  Future<void> sendFirebaseVerificationEmail() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      throw Exception('No signed-in user found. Please login first.');
    }
    try {
      await fbUser.sendEmailVerification();
      debugPrint('Verification email resent to ${fbUser.email}');
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Reloads the Firebase user and returns whether the email is verified.
  Future<bool> checkEmailVerification() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      debugPrint('checkEmailVerification: no active Firebase user');
      return false;
    }

    try {
      await fbUser.reload();
    } catch (e) {
      debugPrint('checkEmailVerification reload error: $e');
    }

    final isVerified = _firebaseAuth.currentUser?.emailVerified ?? false;
    debugPrint('checkEmailVerification: isVerified = $isVerified');
    return isVerified;
  }

  // ──────────────────────────────────────────────────────────────
  // UPDATE PROFILE
  // ──────────────────────────────────────────────────────────────

  Future<UserModel> updateProfile({
    required String id,
    String? name,
    String? phone,
    String? avatarUrl,
    bool? notificationsEnabled,
  }) async {
    final fbUser = _firebaseAuth.currentUser;

    if (fbUser != null && name != null && name.trim().isNotEmpty) {
      try {
        await fbUser.updateDisplayName(name.trim());
      } catch (_) {}
    }

    if (fbUser != null && avatarUrl != null) {
      try {
        await fbUser.updatePhotoURL(avatarUrl.trim());
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString('$_nameKey$id', name.trim());
    }
    if (phone != null) {
      await prefs.setString('$_phoneKey$id', phone.trim());
    }
    if (avatarUrl != null) {
      await prefs.setString('$_avatarKey$id', avatarUrl.trim());
    }
    if (notificationsEnabled != null) {
      await prefs.setBool('$_notificationsKey$id', notificationsEnabled);
    }

    if (fbUser != null) {
      try {
        await fbUser.reload();
      } catch (_) {}
      final refreshed = _firebaseAuth.currentUser ?? fbUser;
      return _buildUserModel(refreshed);
    }

    // Fallback: build from stored prefs if no Firebase user
    return UserModel(
      id: id,
      name: name ?? '',
      email: '',
      phone: phone ?? '',
      avatarUrl: avatarUrl ?? '',
      notificationsEnabled: notificationsEnabled ?? true,
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // CHANGE PASSWORD
  // ──────────────────────────────────────────────────────────────

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null || fbUser.email == null) {
      throw Exception('No active user found. Please login again.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(credential);
      await fbUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // FORGOT PASSWORD
  // ──────────────────────────────────────────────────────────────

  /// Sends a Firebase password-reset email. Returns true on success.
  Future<bool> resetPassword(String email) async {
    final normalized = email.trim().toLowerCase();
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: normalized);
      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // LOGOUT
  // ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────
  // ERROR MAPPING
  // ──────────────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
