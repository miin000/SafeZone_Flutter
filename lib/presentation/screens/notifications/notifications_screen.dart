import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications),
              text: 'Thông báo',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Cộng đồng',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NotificationsTab(),
          _CommunityTab(),
        ],
      ),
    );
  }
}

// Tab Thông báo
class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    // Mock notifications data
    final notifications = [
      _NotificationItem(
        title: 'Cảnh báo dịch bệnh',
        message: 'Phát hiện ổ dịch sốt xuất huyết tại quận Đống Đa, Hà Nội',
        time: '5 phút trước',
        type: NotificationType.warning,
        isRead: false,
      ),
      _NotificationItem(
        title: 'Báo cáo được xác minh',
        message: 'Báo cáo của bạn về ca bệnh COVID-19 đã được xác minh',
        time: '1 giờ trước',
        type: NotificationType.success,
        isRead: false,
      ),
      _NotificationItem(
        title: 'Cập nhật vùng dịch',
        message: 'Vùng dịch tại quận Cầu Giấy đã được thu hẹp phạm vi',
        time: '2 giờ trước',
        type: NotificationType.info,
        isRead: true,
      ),
      _NotificationItem(
        title: 'Nhắc nhở tiêm chủng',
        message: 'Đã đến lịch tiêm mũi vaccine nhắc lại của bạn',
        time: '1 ngày trước',
        type: NotificationType.reminder,
        isRead: true,
      ),
      _NotificationItem(
        title: 'Cảnh báo khu vực',
        message: 'Bạn đang ở gần vùng có nguy cơ dịch bệnh cao',
        time: '2 ngày trước',
        type: NotificationType.warning,
        isRead: true,
      ),
    ];

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không có thông báo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh notifications
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationCard(notification: notification);
        },
      ),
    );
  }
}

enum NotificationType { warning, success, info, reminder }

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? Colors.grey.shade50 : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor().withOpacity(0.1),
          child: Icon(_getTypeIcon(), color: _getTypeColor()),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              notification.time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to notification detail
        },
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.reminder:
        return Icons.schedule;
    }
  }
}

// Tab Cộng đồng - Bài đăng từ cơ quan y tế và cảnh báo từ người dùng
class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Cộng đồng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Nơi cơ quan y tế đăng bài khuyến cáo và cộng đồng chia sẻ cảnh báo dịch bệnh',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
