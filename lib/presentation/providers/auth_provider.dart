// Auth Provider
import 'package:flutter/foundation.dart';
import '../../core/utils/storage_utils.dart';
import '../../core/services/push_notification_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/verification_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepositoryImpl();

  // State
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;
  VerificationStatus? _verificationStatus;
  bool _isVerificationLoading = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  VerificationStatus? get verificationStatus => _verificationStatus;
  bool get isVerificationLoading => _isVerificationLoading;

  // Check if user is fully verified (both email and phone)
  bool get isFullyVerified =>
      _verificationStatus?.isFullyVerified ??
      (_user?.isEmailVerified == true && _user?.isPhoneVerified == true);

  bool get isEmailVerified =>
      _verificationStatus?.isEmailVerified ?? _user?.isEmailVerified ?? false;

  bool get isPhoneVerified =>
      _verificationStatus?.isPhoneVerified ?? _user?.isPhoneVerified ?? false;

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Check auth status on app start
  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);

    try {
      final isLoggedIn = await StorageUtils.isLoggedIn();

      if (isLoggedIn) {
        final isValid = await _repository.verifyToken();
        if (isValid) {
          _user = await _repository.getProfile();
          _setStatus(AuthStatus.authenticated);
        } else {
          await StorageUtils.clearAll();
          _setStatus(AuthStatus.unauthenticated);
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // Login
  Future<bool> login(String identifier, String password) async {
    _setStatus(AuthStatus.loading);
    _setError(null);

    try {
      final response = await _repository.login(identifier, password);
      // Always refresh profile from server after receiving token
      // to avoid stale/mismatched user info from login payload.
      try {
        _user = await _repository.getProfile();
      } catch (_) {
        _user = response.user;
      }

      if (_user != null) {
        await StorageUtils.saveUserInfo(
          userId: _user!.id,
          email: _user!.email ?? '',
          name: _user!.name,
        );
      }

      _setStatus(AuthStatus.authenticated);

      // Send FCM token to server
      await _updateFcmToken();

      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Register
  Future<bool> register(
    String phone,
    String password,
    String name, {
    String? email,
    String? gender,
    String? dateOfBirth,
    String? citizenId,
    String? fullAddress,
    String? province,
    String? district,
    String? ward,
    bool consentGiven = false,
  }) async {
    _setStatus(AuthStatus.loading);
    _setError(null);

    try {
      final response = await _repository.register(
        phone: phone,
        password: password,
        name: name,
        email: email,
        gender: gender,
        dateOfBirth: dateOfBirth,
        citizenId: citizenId,
        fullAddress: fullAddress,
        province: province,
        district: district,
        ward: ward,
        consentGiven: consentGiven,
      );
      // Keep behavior consistent with login: load canonical profile from API.
      try {
        _user = await _repository.getProfile();
      } catch (_) {
        _user = response.user;
      }

      if (_user != null) {
        await StorageUtils.saveUserInfo(
          userId: _user!.id,
          email: _user!.email ?? '',
          name: _user!.name,
        );
      }

      _setStatus(AuthStatus.authenticated);

      // Send FCM token to server
      await _updateFcmToken();

      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Update FCM token on server
  Future<void> _updateFcmToken() async {
    try {
      final fcmToken = PushNotificationService().fcmToken;
      if (fcmToken != null) {
        await _repository.updateFcmToken(fcmToken);
        debugPrint('✅ FCM token sent to server');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to update FCM token: $e');
    }
  }

  // Get profile
  Future<void> fetchProfile() async {
    try {
      _user = await _repository.getProfile();
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setStatus(AuthStatus.loading);
    _setError(null);

    try {
      _user = await _repository.updateProfile(data);
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setStatus(AuthStatus.authenticated);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _verificationStatus = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ==================== Verification Methods ====================

  // Fetch verification status
  Future<void> fetchVerificationStatus() async {
    _isVerificationLoading = true;
    notifyListeners();

    try {
      _verificationStatus = await _repository.getVerificationStatus();
      _isVerificationLoading = false;
      notifyListeners();
    } catch (e) {
      _isVerificationLoading = false;
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Send Email OTP
  Future<bool> sendEmailOtp() async {
    _isVerificationLoading = true;
    _setError(null);
    notifyListeners();

    try {
      await _repository.sendEmailOtp();
      _isVerificationLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isVerificationLoading = false;
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Verify Email OTP
  Future<bool> verifyEmailOtp(String otp) async {
    _isVerificationLoading = true;
    _setError(null);
    notifyListeners();

    try {
      final response = await _repository.verifyEmailOtp(otp);
      if (response.verified == true) {
        // Update local user state
        if (_user != null) {
          _user = _user!.copyWith(isEmailVerified: true);
        }
        // Update verification status
        await fetchVerificationStatus();
      }
      _isVerificationLoading = false;
      notifyListeners();
      return response.verified == true;
    } catch (e) {
      _isVerificationLoading = false;
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Send Phone OTP
  Future<bool> sendPhoneOtp() async {
    _isVerificationLoading = true;
    _setError(null);
    notifyListeners();

    try {
      await _repository.sendPhoneOtp();
      _isVerificationLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isVerificationLoading = false;
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Verify Phone OTP
  Future<bool> verifyPhoneOtp(String otp) async {
    _isVerificationLoading = true;
    _setError(null);
    notifyListeners();

    try {
      final response = await _repository.verifyPhoneOtp(otp);
      if (response.verified == true) {
        // Update local user state
        if (_user != null) {
          _user = _user!.copyWith(isPhoneVerified: true);
        }
        // Update verification status
        await fetchVerificationStatus();
      }
      _isVerificationLoading = false;
      notifyListeners();
      return response.verified == true;
    } catch (e) {
      _isVerificationLoading = false;
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}
