import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/verification_screen.dart';

/// A dialog that prompts user to verify email and phone before creating reports
class VerificationRequiredDialog extends StatelessWidget {
  final VoidCallback? onVerificationComplete;

  const VerificationRequiredDialog({super.key, this.onVerificationComplete});

  static Future<bool> show(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    // Both email and phone must be verified for reporting
    if (authProvider.isEmailVerified && authProvider.isPhoneVerified) {
      return true;
    }

    // Fetch latest verification status
    await authProvider.fetchVerificationStatus();

    if (authProvider.isEmailVerified && authProvider.isPhoneVerified) {
      return true;
    }

    // Show dialog
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VerificationRequiredDialog(),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isEmailVerified = authProvider.isEmailVerified;
        final isPhoneVerified = authProvider.isPhoneVerified;
        final user = authProvider.user;
        final isReady = isEmailVerified && isPhoneVerified;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Text('Xác thực tài khoản'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Để gửi báo cáo, bạn cần xác thực email và số điện thoại bằng mã OTP.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              _VerificationItem(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: user?.email?.isNotEmpty == true
                    ? user!.email!
                    : 'Chưa cập nhật email',
                isVerified: isEmailVerified,
                hasValue: user?.email?.isNotEmpty == true,
                onVerify: () async {
                  if (user?.email?.isNotEmpty != true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng cập nhật email trong hồ sơ'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const VerificationScreen(
                        type: VerificationType.email,
                        canSkip: false,
                      ),
                    ),
                  );

                  if (result == true && context.mounted) {
                    await authProvider.fetchVerificationStatus();
                    await authProvider.fetchProfile();
                    if (authProvider.isEmailVerified &&
                        authProvider.isPhoneVerified &&
                        context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              // Phone verification status
              _VerificationItem(
                icon: Icons.phone_outlined,
                title: 'Số điện thoại',
                subtitle: user?.phone ?? 'Chưa cập nhật',
                isVerified: isPhoneVerified,
                hasValue: user != null && user.phone.isNotEmpty,
                onVerify: () async {
                  if (user == null || user.phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng cập nhật số điện thoại trong hồ sơ',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const VerificationScreen(
                        type: VerificationType.phone,
                        canSkip: false,
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    await authProvider.fetchVerificationStatus();
                    if (authProvider.isEmailVerified &&
                        authProvider.isPhoneVerified &&
                        context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  }
                },
              ),
              if (!isReady)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Bạn cần hoàn tất cả 2 bước xác minh để tiếp tục.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Để sau'),
            ),
          ],
        );
      },
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isVerified;
  final bool hasValue;
  final VoidCallback onVerify;

  const _VerificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isVerified,
    this.hasValue = true,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isVerified ? Colors.green : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isVerified)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            TextButton(
              onPressed: onVerify,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
              ),
              child: Text(
                hasValue ? 'Xác thực' : 'Cập nhật',
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
