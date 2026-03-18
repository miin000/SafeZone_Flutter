import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

enum VerificationType { email, phone }

class VerificationScreen extends StatefulWidget {
  final VerificationType type;
  final bool canSkip;
  final VoidCallback? onSkip;
  final VoidCallback? onVerified;

  const VerificationScreen({
    super.key,
    required this.type,
    this.canSkip = true,
    this.onSkip,
    this.onVerified,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Auto send OTP when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _title => widget.type == VerificationType.email
      ? 'Xác thực Email'
      : 'Xác thực Số điện thoại';

  String get _subtitle => widget.type == VerificationType.email
      ? 'Nhập mã OTP đã được gửi đến email của bạn'
      : 'Nhập mã OTP đã được gửi đến số điện thoại của bạn';

  IconData get _icon => widget.type == VerificationType.email
      ? Icons.email_outlined
      : Icons.phone_outlined;

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (widget.type == VerificationType.email) {
      success = await authProvider.sendEmailOtp();
    } else {
      success = await authProvider.sendPhoneOtp();
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        setState(() => _isOtpSent = true);
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.type == VerificationType.email
                  ? 'Mã OTP đã được gửi đến email của bạn'
                  : 'Mã OTP đã được gửi đến số điện thoại của bạn',
            ),
            backgroundColor: Colors.green,
          ),
        );
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

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ mã OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (widget.type == VerificationType.email) {
      success = await authProvider.verifyEmailOtp(otp);
    } else {
      success = await authProvider.verifyPhoneOtp(otp);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onVerified?.call();
        Navigator.of(context).pop(true);
      } else if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: Colors.red,
          ),
        );
        _otpController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: widget.canSkip
            ? [
                TextButton(
                  onPressed: () {
                    widget.onSkip?.call();
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 48, color: Colors.blue.shade600),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              // OTP input
              TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits != value) {
                    _otpController.value = TextEditingValue(
                      text: digits,
                      selection: TextSelection.collapsed(offset: digits.length),
                    );
                  }

                  if (digits.length == 6 && !_isLoading) {
                    _verifyOtp();
                  }
                },
                onSubmitted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 32),
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Xác thực',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Resend OTP
              if (_isOtpSent)
                _resendCountdown > 0
                    ? Text(
                        'Gửi lại mã sau $_resendCountdown giây',
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    : TextButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: const Text('Gửi lại mã OTP'),
                      ),
              const Spacer(),
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Để báo cáo ca bệnh, bạn cần xác thực cả email và số điện thoại.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
