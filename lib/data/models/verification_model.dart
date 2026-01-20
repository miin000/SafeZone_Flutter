// Verification Status Model
import 'package:equatable/equatable.dart';

class VerificationStatus extends Equatable {
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isFullyVerified;
  final String email;
  final String? phone;

  const VerificationStatus({
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isFullyVerified,
    required this.email,
    this.phone,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isFullyVerified: json['isFullyVerified'] ?? false,
      email: json['email'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isFullyVerified': isFullyVerified,
      'email': email,
      'phone': phone,
    };
  }

  @override
  List<Object?> get props => [
        isEmailVerified,
        isPhoneVerified,
        isFullyVerified,
        email,
        phone,
      ];
}

// OTP Response model
class OtpResponse {
  final String message;
  final bool? verified;

  const OtpResponse({
    required this.message,
    this.verified,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      message: json['message'] ?? '',
      verified: json['verified'],
    );
  }
}
