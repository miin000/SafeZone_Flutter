import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _citizenIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  bool _consentGiven = false;

  final List<Map<String, String>> _genderOptions = [
    {'value': 'male', 'label': 'Nam'},
    {'value': 'female', 'label': 'Nữ'},
    {'value': 'other', 'label': 'Khác'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _citizenIdController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      _phoneController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      gender: _selectedGender,
      dateOfBirth: _selectedDateOfBirth?.toIso8601String().split('T').first,
      citizenId: _citizenIdController.text.trim().isNotEmpty
          ? _citizenIdController.text.trim()
          : null,
      fullAddress: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      province: _provinceController.text.trim().isNotEmpty
          ? _provinceController.text.trim()
          : null,
      district: _districtController.text.trim().isNotEmpty
          ? _districtController.text.trim()
          : null,
      ward: _wardController.text.trim().isNotEmpty
          ? _wardController.text.trim()
          : null,
      consentGiven: _consentGiven,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Show verification prompt dialog
        if (mounted) {
          await _showVerificationPrompt();
        }
        // Pop back, auth state will handle navigation
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showVerificationPrompt() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_outlined, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            const Text('Xác thực tài khoản'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có muốn xác thực số điện thoại ngay bây giờ không?',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              'Bạn cần xác thực số điện thoại để có thể báo cáo ca bệnh.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác thực ngay'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Wait a moment to ensure token is saved
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to phone verification (required)
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const VerificationScreen(
              type: VerificationType.phone,
              canSkip: false,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên *',
                            prefixIcon: const Icon(Icons.person_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
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

                        // Phone field (required)
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại *',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            if (value.trim().length < 9) {
                              return 'Số điện thoại không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email field (optional)
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email (tùy chọn)',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Email không hợp lệ';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gender selection
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Giới tính',
                            prefixIcon: const Icon(Icons.wc_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _genderOptions.map((g) => DropdownMenuItem(
                            value: g['value'],
                            child: Text(g['label']!),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000, 1, 1),
                              firstDate: DateTime(1920),
                              lastDate: DateTime.now(),
                              helpText: 'Chọn ngày sinh',
                            );
                            if (picked != null) {
                              setState(() => _selectedDateOfBirth = picked);
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Ngày sinh',
                                prefixIcon: const Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: _selectedDateOfBirth != null
                                    ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                    : 'Chọn ngày sinh',
                              ),
                              controller: TextEditingController(
                                text: _selectedDateOfBirth != null
                                    ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                    : '',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Citizen ID
                        TextFormField(
                          controller: _citizenIdController,
                          decoration: InputDecoration(
                            labelText: 'Số CCCD/CMND (tùy chọn)',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Address section header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Địa chỉ (tùy chọn)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                        // Province
                        TextFormField(
                          controller: _provinceController,
                          decoration: InputDecoration(
                            labelText: 'Tỉnh/Thành phố',
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // District
                        TextFormField(
                          controller: _districtController,
                          decoration: InputDecoration(
                            labelText: 'Quận/Huyện',
                            prefixIcon: const Icon(Icons.map_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ward
                        TextFormField(
                          controller: _wardController,
                          decoration: InputDecoration(
                            labelText: 'Phường/Xã',
                            prefixIcon: const Icon(Icons.home_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Full address
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Địa chỉ chi tiết',
                            prefixIcon: const Icon(Icons.place_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu *',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu *',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Consent checkbox
                        CheckboxListTile(
                          value: _consentGiven,
                          onChanged: (v) => setState(() => _consentGiven = v ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Tôi đồng ý cho phép SafeZone thu thập và sử dụng thông tin cá nhân phục vụ giám sát dịch bệnh',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Register button
                        ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Đăng ký',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Note
                        Text(
                          '* Thông tin bắt buộc',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (authProvider.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

