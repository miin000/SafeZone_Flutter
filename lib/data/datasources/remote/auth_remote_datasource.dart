// Auth Remote Datasource
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/storage_utils.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDatasource {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(String email, String password, String name, String? phone);
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(Map<String, dynamic> data);
  Future<void> logout();
  Future<bool> verifyToken();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user info
      await StorageUtils.saveToken(authResponse.accessToken);
      await StorageUtils.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
        name: authResponse.user.name,
      );
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<AuthResponse> register(
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and user info
      await StorageUtils.saveToken(authResponse.accessToken);
      await StorageUtils.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
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
            message = 'Email hoặc mật khẩu không đúng';
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
