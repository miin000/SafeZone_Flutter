import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/presentation/providers/auth_provider.dart';
import 'package:mobile_flutter/presentation/providers/settings_provider.dart';
import 'package:mobile_flutter/data/models/user_model.dart';
import 'package:mobile_flutter/presentation/screens/profile/edit_profile_screen.dart';
import 'package:mobile_flutter/presentation/screens/profile/my_reports_screen.dart';
import 'package:mobile_flutter/presentation/screens/profile/my_posts_screen.dart';
import 'package:mobile_flutter/presentation/screens/profile/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings when profile screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with user info
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: user.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      user.avatarUrl!,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 20),
                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.phone,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Verification status
                      Row(
                        children: [
                          _VerificationBadge(
                            verified: user.isEmailVerified,
                            text: 'Email',
                          ),
                          const SizedBox(width: 12),
                          _VerificationBadge(
                            verified: user.isPhoneVerified,
                            text: 'SĐT',
                          ),
                          const SizedBox(width: 12),
                          if (user.role == UserRole.healthWorker ||
                              user.role == UserRole.admin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role == UserRole.admin
                                    ? 'Quản trị viên'
                                    : 'Nhân viên y tế',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Menu items
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              // Activity Section
              _MenuSection(
                title: 'Hoạt động của tôi',
                items: [
                  _MenuItem(
                    icon: Icons.description,
                    title: 'Báo cáo của tôi',
                    subtitle: 'Xem lịch sử báo cáo dịch bệnh',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyReportsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.post_add,
                    title: 'Bài đăng của tôi',
                    subtitle: 'Bài viết đã chia sẻ với cộng đồng',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPostsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Settings Section
              _MenuSection(
                title: 'Cài đặt & Bảo mật',
                items: [
                  _MenuItem(
                    icon: Icons.edit,
                    title: 'Chỉnh sửa hồ sơ',
                    subtitle: 'Cập nhật thông tin cá nhân',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.settings,
                    title: 'Cài đặt ứng dụng',
                    subtitle: 'Giao diện, thông báo, ngôn ngữ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.notifications,
                    title: 'Thông báo',
                    subtitle: 'Cài đặt loại thông báo nhận',
                    onTap: () {
                      // TODO: Navigate to notification settings
                    },
                  ),
                  _MenuItem(
                    icon: Icons.security,
                    title: 'Bảo mật',
                    subtitle: 'Xác thực, quyền truy cập',
                    trailing: Switch(
                      value: settingsProvider.biometricAuth,
                      onChanged: settingsProvider.toggleBiometricAuth,
                      activeColor: Colors.blue,
                    ),
                    onTap: () {
                      // TODO: Navigate to security settings
                    },
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip,
                    title: 'Quyền riêng tư',
                    subtitle: 'Kiểm soát dữ liệu cá nhân',
                    onTap: () {
                      // TODO: Navigate to privacy settings
                    },
                  ),
                ],
              ),
              // Support Section
              _MenuSection(
                title: 'Hỗ trợ',
                items: [
                  _MenuItem(
                    icon: Icons.help_center,
                    title: 'Trung tâm trợ giúp',
                    subtitle: 'Câu hỏi thường gặp & hướng dẫn',
                    onTap: () {
                      // TODO: Navigate to help center
                    },
                  ),
                  _MenuItem(
                    icon: Icons.article,
                    title: 'Điều khoản sử dụng',
                    subtitle: 'Chính sách bảo mật & điều khoản',
                    onTap: () {
                      // TODO: Show terms and conditions
                    },
                  ),
                  _MenuItem(
                    icon: Icons.info,
                    title: 'Về ứng dụng',
                    subtitle: 'Phiên bản 2.0.0 | SafeZone',
                    onTap: () {
                      // TODO: Show about dialog
                    },
                  ),
                ],
              ),
              // Logout button
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: _showLogoutDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'ĐĂNG XUẤT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }
}

// Verification Badge Widget
class _VerificationBadge extends StatelessWidget {
  final bool verified;
  final String text;

  const _VerificationBadge({
    required this.verified,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: verified ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified : Icons.pending,
            size: 14,
            color: verified ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '$text ${verified ? '✓' : '!'}',
            style: TextStyle(
              fontSize: 12,
              color: verified ? Colors.green.shade800 : Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Menu Section Widget
class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: items,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Menu Item Widget
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blue.shade600, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
