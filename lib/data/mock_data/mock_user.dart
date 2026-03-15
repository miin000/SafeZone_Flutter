// lib/data/mock_data/mock_user.dart
import 'package:mobile_flutter/data/models/user_model.dart';

class MockUser {
  static UserModel get currentUser => UserModel(
    id: 'user_001',
    email: 'user@example.com',
    name: 'Nguyễn Văn A',
    phone: '0912345678',
    role: UserRole.user,
    isEmailVerified: true,
    isPhoneVerified: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  static UserModel get healthWorker => UserModel(
    id: 'hw_001',
    email: 'doctor@hospital.vn',
    name: 'Bác sĩ Trần Văn B',
    phone: '0987654321',
    role: UserRole.healthWorker,
    isEmailVerified: true,
    isPhoneVerified: true,
  );
}