// User Model

enum UserRole { user, admin, healthWorker }

class UserModel {
  final String id;
  final String? email;
  final String name;
  final String phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  // Enhanced profile fields
  final String? gender; // 'male', 'female', 'other'
  final String? dateOfBirth;
  final String? citizenId;
  final String? fullAddress;
  final String? province;
  final String? district;
  final String? ward;
  // Organization info (for health workers)
  final String? organizationName;
  final String? organizationLevel;
  final String? organizationAddress;
  // Reputation & status
  final int reputationScore;
  final bool isBlacklisted;
  final bool consentGiven;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.email,
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.role = UserRole.user,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.gender,
    this.dateOfBirth,
    this.citizenId,
    this.fullAddress,
    this.province,
    this.district,
    this.ward,
    this.organizationName,
    this.organizationLevel,
    this.organizationAddress,
    this.reputationScore = 100,
    this.isBlacklisted = false,
    this.consentGiven = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'],
      role: _parseRole(json['role']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
      citizenId: json['citizenId'],
      fullAddress: json['fullAddress'],
      province: json['province'],
      district: json['district'],
      ward: json['ward'],
      organizationName: json['organizationName'],
      organizationLevel: json['organizationLevel'],
      organizationAddress: json['organizationAddress'],
      reputationScore: json['reputationScore'] ?? 100,
      isBlacklisted: json['isBlacklisted'] ?? false,
      consentGiven: json['consentGiven'] ?? false,
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
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (citizenId != null) 'citizenId': citizenId,
      if (fullAddress != null) 'fullAddress': fullAddress,
      if (province != null) 'province': province,
      if (district != null) 'district': district,
      if (ward != null) 'ward': ward,
      if (organizationName != null) 'organizationName': organizationName,
      if (organizationLevel != null) 'organizationLevel': organizationLevel,
      if (organizationAddress != null) 'organizationAddress': organizationAddress,
      'reputationScore': reputationScore,
      'isBlacklisted': isBlacklisted,
      'consentGiven': consentGiven,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'health_worker':
      case 'health_authority':
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
    String? gender,
    String? dateOfBirth,
    String? citizenId,
    String? fullAddress,
    String? province,
    String? district,
    String? ward,
    String? organizationName,
    String? organizationLevel,
    String? organizationAddress,
    int? reputationScore,
    bool? isBlacklisted,
    bool? consentGiven,
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
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      citizenId: citizenId ?? this.citizenId,
      fullAddress: fullAddress ?? this.fullAddress,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      organizationName: organizationName ?? this.organizationName,
      organizationLevel: organizationLevel ?? this.organizationLevel,
      organizationAddress: organizationAddress ?? this.organizationAddress,
      reputationScore: reputationScore ?? this.reputationScore,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      consentGiven: consentGiven ?? this.consentGiven,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
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
