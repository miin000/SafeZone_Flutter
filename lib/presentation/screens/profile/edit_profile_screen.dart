import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_flutter/presentation/providers/auth_provider.dart';
import 'package:mobile_flutter/presentation/screens/auth/verification_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  String? _newAvatarUrl;
  bool _isUploadingAvatar = false;

  Future<void> _openEmailVerificationFlow() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationScreen(
          type: VerificationType.email,
          canSkip: false,
          onVerified: () {
            context.read<AuthProvider>().fetchProfile();
          },
        ),
      ),
    );

    if (result == true && mounted) {
      context.read<AuthProvider>().fetchProfile();
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final pathParts = image.path.split(RegExp(r'[\\/]'));
      final String fileName = pathParts.isNotEmpty
          ? pathParts.last
          : 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await image.readAsBytes();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'upload_preset': 'safezone',
        'folder': 'safezone/avatars',
      });

      final dio = Dio();
      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/ddquvbdc7/image/upload',
        data: formData,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null &&
          response.data['secure_url'] != null) {
        setState(() {
          _newAvatarUrl = response.data['secure_url'];
        });
      } else {
        throw Exception('Upload thất bại: phản hồi không hợp lệ từ Cloudinary');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh thành công. Nhấn dấu ✓ để lưu avatar.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      String message = 'Không thể tải ảnh lên. Vui lòng thử lại!';

      if (e.response?.data is Map && e.response?.data['error'] != null) {
        final err = e.response!.data['error'];
        if (err is Map && err['message'] != null) {
          message = 'Lỗi Cloudinary: ${err['message']}';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh lên: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      if (_newAvatarUrl != null) 'avatarUrl': _newAvatarUrl,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Cập nhật thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          IconButton(
            onPressed: _saveProfile,
            icon: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade100,
                      child: _isUploadingAvatar
                          ? const CircularProgressIndicator()
                          : (_newAvatarUrl ?? user?.avatarUrl) != null
                          ? ClipOval(
                              child: Image.network(
                                (_newAvatarUrl ?? user!.avatarUrl!),
                                width: 116,
                                height: 116,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              user?.name.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chạm để đổi ảnh đại diện',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  if (value.trim().length < 2) {
                    return 'Họ tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email verification status and button
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: user.isEmailVerified
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: user.isEmailVerified
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        user.isEmailVerified
                            ? Icons.verified
                            : Icons.info_outline,
                        color: user.isEmailVerified
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isEmailVerified
                                  ? 'Email đã được xác nhận'
                                  : 'Email chưa được xác nhận',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: user.isEmailVerified
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                            if (!user.isEmailVerified)
                              Text(
                                'Nhấn nút bên để gửi mã xác nhận',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Verification status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trạng thái xác minh',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _VerificationStatusItem(
                        label: 'Email',
                        verified: user?.isEmailVerified ?? false,
                        onVerify: () {
                          _openEmailVerificationFlow();
                        },
                      ),
                      const SizedBox(height: 8),
                      _VerificationStatusItem(
                        label: 'Số điện thoại',
                        verified: user?.isPhoneVerified ?? false,
                        onVerify: () {
                          // TODO: Implement phone verification
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationStatusItem extends StatelessWidget {
  final String label;
  final bool verified;
  final VoidCallback onVerify;

  const _VerificationStatusItem({
    required this.label,
    required this.verified,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          verified ? Icons.verified : Icons.pending,
          color: verified ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label ${verified ? 'đã xác minh' : 'chưa xác minh'}',
            style: TextStyle(
              color: verified ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          ),
        ),
        if (!verified)
          ElevatedButton(
            onPressed: onVerify,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              elevation: 0,
            ),
            child: const Text('Xác minh'),
          ),
      ],
    );
  }
}
