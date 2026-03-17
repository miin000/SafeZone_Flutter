// Auth Repository Implementation
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../models/verification_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String phone, String password);
  Future<AuthResponse> register({
    required String phone,
    required String password,
    required String name,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? citizenId,
    String? fullAddress,
    String? province,
    String? district,
    String? ward,
    bool consentGiven = false,
  });
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
  Future<AuthResponse> register({
    required String phone,
    required String password,
    required String name,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? citizenId,
    String? fullAddress,
    String? province,
    String? district,
    String? ward,
    bool consentGiven = false,
  }) {
    return _remoteDatasource.register(
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
