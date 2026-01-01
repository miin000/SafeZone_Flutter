// User Model
import 'package:equatable/equatable.dart';

enum UserRole { user, admin, healthWorker }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.user,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      role: _parseRole(json['role']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'health_worker':
        return UserRole.healthWorker;
      default:
        return UserRole.user;
    }
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phone,
        avatarUrl,
        role,
        isEmailVerified,
        isPhoneVerified,
        createdAt,
        updatedAt,
      ];
}

// Auth response model
class AuthResponse {
  final String accessToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['token'] ?? json['access_token'] ?? json['accessToken'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}
