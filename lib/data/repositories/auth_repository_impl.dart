// Auth Repository Implementation
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(String email, String password, String name, String? phone);
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(Map<String, dynamic> data);
  Future<void> logout();
  Future<bool> verifyToken();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl({AuthRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasourceImpl();

  @override
  Future<AuthResponse> login(String email, String password) {
    return _remoteDatasource.login(email, password);
  }

  @override
  Future<AuthResponse> register(
    String email,
    String password,
    String name,
    String? phone,
  ) {
    return _remoteDatasource.register(email, password, name, phone);
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
}
