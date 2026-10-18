import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get displayName => _currentUser?.name.isNotEmpty == true
      ? _currentUser!.name
      : 'User';

  String get displayEmail => _currentUser?.email ?? '';

  Future<bool> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getActiveUser();
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentUser != null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // EMAIL VERIFICATION
  // ──────────────────────────────────────────────────────────────

  /// Reloads the Firebase user and returns true if email is verified.
  Future<bool> checkEmailVerification() async {
    final verified = await _authService.checkEmailVerification();
    if (verified) {
      _currentUser = await _authService.getActiveUser();
      notifyListeners();
    }
    return verified;
  }

  /// Sends/resends the Firebase verification email.
  Future<bool> sendEmailVerification() async {
    try {
      await _authService.sendFirebaseVerificationEmail();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // PROFILE
  // ──────────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    bool? notificationsEnabled,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateProfile(
        id: _currentUser!.id,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
        notificationsEnabled: notificationsEnabled,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleNotifications(bool value) async {
    if (_currentUser == null) return;
    await updateProfile(notificationsEnabled: value);
  }

  Future<bool> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
