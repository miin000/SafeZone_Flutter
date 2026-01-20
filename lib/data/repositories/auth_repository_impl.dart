// Auth Repository Implementation
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../models/verification_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String phone, String password);
  Future<AuthResponse> register(String phone, String password, String name, String? email);
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(Map<String, dynamic> data);
  Future<void> logout();
  Future<bool> verifyToken();
  Future<void> updateFcmToken(String token);
  // Verification methods
  Future<VerificationStatus> getVerificationStatus();
  Future<OtpResponse> sendEmailOtp();
  Future<OtpResponse> verifyEmailOtp(String otp);
  Future<OtpResponse> sendPhoneOtp();
  Future<OtpResponse> verifyPhoneOtp(String otp);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl({AuthRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasourceImpl();

  @override
  Future<AuthResponse> login(String phone, String password) {
    return _remoteDatasource.login(phone, password);
  }

  @override
  Future<AuthResponse> register(
    String phone,
    String password,
    String name,
    String? email,
  ) {
    return _remoteDatasource.register(phone, password, name, email);
  }

  @override
  Future<UserModel> getProfile() {
    return _remoteDatasource.getProfile();
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) {
    return _remoteDatasource.updateProfile(data);
  }

  @override
  Future<void> logout() {
    return _remoteDatasource.logout();
  }

  @override
  Future<bool> verifyToken() {
    return _remoteDatasource.verifyToken();
  }

  // ==================== Verification Methods ====================

  @override
  Future<VerificationStatus> getVerificationStatus() {
    return _remoteDatasource.getVerificationStatus();
  }

  @override
  Future<OtpResponse> sendEmailOtp() {
    return _remoteDatasource.sendEmailOtp();
  }

  @override
  Future<OtpResponse> verifyEmailOtp(String otp) {
    return _remoteDatasource.verifyEmailOtp(otp);
  }

  @override
  Future<OtpResponse> sendPhoneOtp() {
    return _remoteDatasource.sendPhoneOtp();
  }

  @override
  Future<OtpResponse> verifyPhoneOtp(String otp) {
    return _remoteDatasource.verifyPhoneOtp(otp);
  }

  @override
  Future<void> updateFcmToken(String token) {
    return _remoteDatasource.updateFcmToken(token);
  }
}
