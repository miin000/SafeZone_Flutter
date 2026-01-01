// Auth Provider
import 'package:flutter/foundation.dart';
import '../../core/utils/storage_utils.dart';
import '../../data/models/user_model.dart';
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

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

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
  Future<bool> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    _setError(null);

    try {
      final response = await _repository.login(email, password);
      _user = response.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Register
  Future<bool> register(
    String email,
    String password,
    String name, {
    String? phone,
  }) async {
    _setStatus(AuthStatus.loading);
    _setError(null);

    try {
      final response = await _repository.register(email, password, name, phone);
      _user = response.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setStatus(AuthStatus.error);
      return false;
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
    _setStatus(AuthStatus.unauthenticated);
  }
}
