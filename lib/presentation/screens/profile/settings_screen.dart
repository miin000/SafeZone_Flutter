import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/presentation/providers/settings_provider.dart';
import 'package:mobile_flutter/data/models/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAdvancedSettings = false;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt ứng dụng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              settingsProvider.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đặt lại tất cả cài đặt về mặc định'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Đặt lại mặc định',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Appearance Settings
            _SettingsSection(
              title: 'Giao diện',
              icon: Icons.palette,
              children: [
                _SettingsItem(
                  icon: Icons.brightness_6,
                  title: 'Chế độ hiển thị',
                  subtitle: 'Thay đổi giao diện sáng/tối',
                  trailing: DropdownButton<AppTheme>(
                    value: settings.theme,
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateTheme(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: AppTheme.light,
                        child: Text('Sáng'),
                      ),
                      DropdownMenuItem(
                        value: AppTheme.dark,
                        child: Text('Tối'),
                      ),
                      DropdownMenuItem(
                        value: AppTheme.system,
                        child: Text('Theo hệ thống'),
                      ),
                    ],
                  ),
                ),
                _SettingsItem(
                  icon: Icons.format_size,
                  title: 'Cỡ chữ',
                  subtitle: 'Điều chỉnh kích thước văn bản',
                  trailing: DropdownButton<FontSize>(
                    value: settings.fontSize,
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateFontSize(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: FontSize.small,
                        child: Text('Nhỏ'),
                      ),
                      DropdownMenuItem(
                        value: FontSize.medium,
                        child: Text('Trung bình'),
                      ),
                      DropdownMenuItem(
                        value: FontSize.large,
                        child: Text('Lớn'),
                      ),
                    ],
                  ),
                ),
                _SettingsItem(
                  icon: Icons.animation,
                  title: 'Giảm chuyển động',
                  subtitle: 'Tắt hiệu ứng chuyển động',
                  trailing: Switch(
                    value: settings.reduceAnimations,
                    onChanged: settingsProvider.toggleReduceAnimations,
                    activeColor: Colors.blue,
                  ),
                ),
                _SettingsItem(
                  icon: Icons.contrast,
                  title: 'Chế độ tương phản cao',
                  subtitle: 'Tăng độ tương phản cho dễ đọc',
                  trailing: Switch(
                    value: settings.highContrastMode,
                    onChanged: settingsProvider.toggleHighContrastMode,
                    activeColor: Colors.blue,
                  ),
                ),
              ],
            ),

            // Notification Settings
            _SettingsSection(
              title: 'Thông báo',
              icon: Icons.notifications,
              children: [
                _SettingsItem(
                  icon: Icons.notifications_active,
                  title: 'Nhận thông báo',
                  subtitle: 'Bật/tắt thông báo từ ứng dụng',
                  trailing: Switch(
                    value: settings.receiveNotifications,
                    onChanged: settingsProvider.toggleNotifications,
                    activeColor: Colors.blue,
                  ),
                ),
                if (settings.receiveNotifications) ...[
                  _SettingsItem(
                    icon: Icons.filter_list,
                    title: 'Loại thông báo',
                    subtitle: 'Chọn loại thông báo muốn nhận',
                    trailing: DropdownButton<NotificationType>(
                      value: settings.notificationType,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateNotificationType(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: NotificationType.all,
                          child: Text('Tất cả'),
                        ),
                        DropdownMenuItem(
                          value: NotificationType.zoneAlerts,
                          child: Text('Cảnh báo vùng dịch'),
                        ),
                        DropdownMenuItem(
                          value: NotificationType.reportUpdates,
                          child: Text('Cập nhật báo cáo'),
                        ),
                        DropdownMenuItem(
                          value: NotificationType.systemOnly,
                          child: Text('Chỉ thông báo hệ thống'),
                        ),
                      ],
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.volume_up,
                    title: 'Âm thanh thông báo',
                    subtitle: 'Phát âm thanh khi có thông báo',
                    trailing: Switch(
                      value: settings.notificationSound,
                      onChanged: settingsProvider.toggleNotificationSound,
                      activeColor: Colors.blue,
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.vibration,
                    title: 'Rung khi thông báo',
                    subtitle: 'Rung điện thoại khi có thông báo',
                    trailing: Switch(
                      value: settings.notificationVibration,
                      onChanged: settingsProvider.toggleNotificationVibration,
                      activeColor: Colors.blue,
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.preview,
                    title: 'Hiển thị nội dung',
                    subtitle: 'Hiển thị nội dung trên màn hình khóa',
                    trailing: Switch(
                      value: settings.showNotificationPreview,
                      onChanged: settingsProvider.toggleShowNotificationPreview,
                      activeColor: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),

            // Privacy & Security Settings
            _SettingsSection(
              title: 'Bảo mật & Quyền riêng tư',
              icon: Icons.security,
              children: [
                _SettingsItem(
                  icon: Icons.location_on,
                  title: 'Theo dõi vị trí',
                  subtitle: 'Cho phép ứng dụng truy cập vị trí',
                  trailing: Switch(
                    value: settings.locationTracking,
                    onChanged: settingsProvider.toggleLocationTracking,
                    activeColor: Colors.blue,
                  ),
                ),
                _SettingsItem(
                  icon: Icons.fingerprint,
                  title: 'Xác thực sinh trắc học',
                  subtitle: 'Đăng nhập bằng vân tay/khuôn mặt',
                  trailing: Switch(
                    value: settings.biometricAuth,
                    onChanged: settingsProvider.toggleBiometricAuth,
                    activeColor: Colors.blue,
                  ),
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip,
                  title: 'Chia sẻ dữ liệu ẩn danh',
                  subtitle: 'Giúp cải thiện ứng dụng',
                  trailing: Switch(
                    value: settings.shareAnonymousData,
                    onChanged: settingsProvider.toggleShareAnonymousData,
                    activeColor: Colors.blue,
                  ),
                ),
                _SettingsItem(
                  icon: Icons.history,
                  title: 'Lưu lịch sử đăng nhập',
                  subtitle: 'Ghi nhớ thiết bị đăng nhập',
                  trailing: Switch(
                    value: settings.saveLoginHistory,
                    onChanged: settingsProvider.toggleSaveLoginHistory,
                    activeColor: Colors.blue,
                  ),
                ),
                _SettingsItem(
                  icon: Icons.login,
                  title: 'Tự động đăng nhập',
                  subtitle: 'Tự động đăng nhập lần sau',
                  trailing: Switch(
                    value: settings.autoLogin,
                    onChanged: settingsProvider.toggleAutoLogin,
                    activeColor: Colors.blue,
                  ),
                ),
              ],
            ),

            // General Settings
            _SettingsSection(
              title: 'Chung',
              icon: Icons.settings,
              children: [
                _SettingsItem(
                  icon: Icons.language,
                  title: 'Ngôn ngữ',
                  subtitle: 'Thay đổi ngôn ngữ ứng dụng',
                  trailing: DropdownButton<Language>(
                    value: settings.language,
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateLanguage(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: Language.vietnamese,
                        child: Text('Tiếng Việt'),
                      ),
                      DropdownMenuItem(
                        value: Language.english,
                        child: Text('English'),
                      ),
                    ],
                  ),
                ),
                _SettingsItem(
                  icon: Icons.data_usage,
                  title: 'Mức sử dụng dữ liệu',
                  subtitle: 'Kiểm soát lượng dữ liệu sử dụng',
                  trailing: DropdownButton<DataUsage>(
                    value: settings.dataUsage,
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateDataUsage(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: DataUsage.low,
                        child: Text('Thấp'),
                      ),
                      DropdownMenuItem(
                        value: DataUsage.medium,
                        child: Text('Trung bình'),
                      ),
                      DropdownMenuItem(
                        value: DataUsage.high,
                        child: Text('Cao'),
                      ),
                    ],
                  ),
                ),
                _SettingsItem(
                  icon: Icons.map,
                  title: 'Kiểu bản đồ',
                  subtitle: 'Chọn kiểu hiển thị bản đồ',
                  trailing: DropdownButton<MapStyle>(
                    value: settings.mapStyle,
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateMapStyle(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: MapStyle.standard,
                        child: Text('Tiêu chuẩn'),
                      ),
                      DropdownMenuItem(
                        value: MapStyle.satellite,
                        child: Text('Vệ tinh'),
                      ),
                      DropdownMenuItem(
                        value: MapStyle.hybrid,
                        child: Text('Kết hợp'),
                      ),
                    ],
                  ),
                ),
                _SettingsItem(
                  icon: Icons.update,
                  title: 'Tự động cập nhật',
                  subtitle: 'Tự động cập nhật ứng dụng',
                  trailing: Switch(
                    value: settings.autoUpdate,
                    onChanged: settingsProvider.toggleAutoUpdate,
                    activeColor: Colors.blue,
                  ),
                ),
                _SettingsItem(
                  icon: Icons.bug_report,
                  title: 'Báo cáo lỗi tự động',
                  subtitle: 'Tự động gửi báo cáo lỗi',
                  trailing: Switch(
                    value: settings.crashReports,
                    onChanged: settingsProvider.toggleCrashReports,
                    activeColor: Colors.blue,
                  ),
                ),
              ],
            ),

            // Advanced Settings (Collapsible)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                leading: const Icon(Icons.code, color: Colors.grey),
                title: const Text(
                  'Cài đặt nâng cao',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text('Cài đặt dành cho nhà phát triển'),
                initiallyExpanded: _showAdvancedSettings,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _showAdvancedSettings = expanded;
                  });
                },
                children: [
                  _SettingsItem(
                    icon: Icons.developer_mode,
                    title: 'Chế độ nhà phát triển',
                    subtitle: 'Kích hoạt tính năng dành cho nhà phát triển',
                    trailing: Switch(
                      value: settings.developerMode,
                      onChanged: settingsProvider.toggleDeveloperMode,
                      activeColor: Colors.blue,
                    ),
                  ),
                  if (settings.developerMode) ...[
                    _SettingsItem(
                      icon: Icons.bug_report_outlined,
                      title: 'Ghi log debug',
                      subtitle: 'Ghi lại log chi tiết',
                      trailing: Switch(
                        value: settings.debugLogging,
                        onChanged: settingsProvider.toggleDebugLogging,
                        activeColor: Colors.blue,
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.speed,
                      title: 'Hiển thị overlay hiệu suất',
                      subtitle: 'Hiển thị thông tin hiệu suất',
                      trailing: Switch(
                        value: settings.showPerformanceOverlay,
                        onChanged: settingsProvider.togglePerformanceOverlay,
                        activeColor: Colors.blue,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Clear app cache
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa cache ứng dụng'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade50,
                          foregroundColor: Colors.orange.shade800,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('XÓA CACHE ỨNG DỤNG'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // App Info
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.health_and_safety, size: 48, color: Colors.blue),
                    const SizedBox(height: 12),
                    const Text(
                      'SafeZone',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Phiên bản 2.0.0 (Build 2024.12)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Show privacy policy
                          },
                          child: const Text('Chính sách bảo mật'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Show terms of service
                          },
                          child: const Text('Điều khoản sử dụng'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Show license information
                          },
                          child: const Text('Giấy phép'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Reset Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đặt lại cài đặt'),
                      content: const Text(
                        'Bạn có chắc chắn muốn đặt lại tất cả cài đặt về mặc định? Hành động này không thể hoàn tác.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            settingsProvider.resetToDefaults();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đặt lại cài đặt về mặc định'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('ĐẶT LẠI'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text(
                      'ĐẶT LẠI TẤT CẢ CÀI ĐẶT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Column(
            children: children,
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}