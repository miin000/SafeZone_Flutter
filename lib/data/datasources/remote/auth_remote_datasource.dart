// Auth Remote Datasource
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/storage_utils.dart';
import '../../models/user_model.dart';
import '../../models/verification_model.dart';

abstract class AuthRemoteDatasource {
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
    bool consentGiven,
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

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<AuthResponse> login(String phone, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'phone': phone,
          'password': password,
          'source': 'mobile',
        },
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user info
      await StorageUtils.saveToken(authResponse.accessToken);
      await StorageUtils.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email ?? '',
        name: authResponse.user.name,
      );
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
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
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'phone': phone,
          'password': password,
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
          if (gender != null) 'gender': gender,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (citizenId != null && citizenId.isNotEmpty) 'citizenId': citizenId,
          if (fullAddress != null && fullAddress.isNotEmpty) 'fullAddress': fullAddress,
          if (province != null && province.isNotEmpty) 'province': province,
          if (district != null && district.isNotEmpty) 'district': district,
          if (ward != null && ward.isNotEmpty) 'ward': ward,
          'consentGiven': consentGiven,
        },
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user info
      await StorageUtils.saveToken(authResponse.accessToken);
      await StorageUtils.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email ?? '',
        name: authResponse.user.name,
      );
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.profile);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.profile,
        data: data,
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout() async {
    await StorageUtils.clearAll();
  }

  @override
  Future<bool> verifyToken() async {
    try {
      await _apiClient.get(ApiConstants.verifyToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== Verification Methods ====================

  @override
  Future<VerificationStatus> getVerificationStatus() async {
    try {
      final response = await _apiClient.get(ApiConstants.verificationStatus);
      return VerificationStatus.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OtpResponse> sendEmailOtp() async {
    try {
      final response = await _apiClient.post(ApiConstants.sendEmailOtp);
      return OtpResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OtpResponse> verifyEmailOtp(String otp) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verifyEmail,
        data: {'otp': otp},
      );
      return OtpResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OtpResponse> sendPhoneOtp() async {
    try {
      final response = await _apiClient.post(ApiConstants.sendPhoneOtp);
      return OtpResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OtpResponse> verifyPhoneOtp(String otp) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verifyPhone,
        data: {'otp': otp},
      );
      return OtpResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      await _apiClient.post(
        ApiConstants.updateFcmToken,
        data: {'fcmToken': token},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    String message = 'Đã xảy ra lỗi';
    
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else {
        switch (e.response!.statusCode) {
          case 400:
            message = 'Dữ liệu không hợp lệ';
            break;
          case 401:
            message = 'Số điện thoại hoặc mật khẩu không đúng';
            break;
          case 409:
            message = 'Email đã được sử dụng';
            break;
          case 500:
            message = 'Lỗi máy chủ';
            break;
        }
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Kết nối quá thời gian, vui lòng thử lại';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Không thể kết nối đến máy chủ';
    }
    
    return Exception(message);
  }
}
