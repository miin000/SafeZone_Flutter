import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/data/mock_data/mock_notifications.dart';
import 'package:mobile_flutter/data/models/notification_model.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/presentation/providers/post_provider.dart';
import 'create_post_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FloatingActionButtonLocation _fabLocation;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fabLocation = FloatingActionButtonLocation.endFloat;
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = MockNotifications.notifications;
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    });
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount--;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
    });
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
        actions: [
          if (_unreadCount > 0)
            Badge(
              label: Text(_unreadCount.toString()),
              child: IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: _markAllAsRead,
                tooltip: 'Đánh dấu tất cả đã đọc',
              ),
            ),
        ],
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
        children: [
          // Tab Thông báo
          _NotificationsTab(
            notifications: _notifications,
            unreadCount: _unreadCount,
            onMarkAsRead: _markAsRead,
            onRefresh: _loadNotifications,
          ),
          // Tab Cộng đồng
          Consumer<PostProvider>(
            builder: (context, postProvider, child) {
              final posts = postProvider.posts;

              return _CommunityTab(
                posts: posts,
                onRefresh: () {
                  postProvider.refreshPosts();
                },
                isLoading: postProvider.isLoading,
              );
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add),
      )
          : null,
      floatingActionButtonLocation: _fabLocation,
    );
  }
}

// Tab Thông báo
class _NotificationsTab extends StatelessWidget {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final Function(String) onMarkAsRead;
  final VoidCallback onRefresh;

  const _NotificationsTab({
    required this.notifications,
    required this.unreadCount,
    required this.onMarkAsRead,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Không có thông báo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final zoneAlerts = notifications.where((n) => n.type == NotificationType.zoneAlert).toList();
    final reportUpdates = notifications.where((n) => n.type == NotificationType.reportUpdate).toList();
    final otherNotifications = notifications.where((n) => n.type != NotificationType.zoneAlert && n.type != NotificationType.reportUpdate).toList();

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (zoneAlerts.isNotEmpty) ...[
            const _SectionHeader(
              title: '⚠️ CẢNH BÁO VÙNG DỊCH',
              icon: Icons.warning_amber,
              color: Colors.red,
            ),
            ...zoneAlerts.map((notification) => _NotificationCard(
              notification: notification,
              onTap: () => onMarkAsRead(notification.id),
            )),
            const SizedBox(height: 24),
          ],

          if (reportUpdates.isNotEmpty) ...[
            const _SectionHeader(
              title: '📋 CẬP NHẬT BÁO CÁO',
              icon: Icons.update,
              color: Colors.blue,
            ),
            ...reportUpdates.map((notification) => _NotificationCard(
              notification: notification,
              onTap: () => onMarkAsRead(notification.id),
            )),
            const SizedBox(height: 24),
          ],

          if (otherNotifications.isNotEmpty) ...[
            const _SectionHeader(
              title: '📢 THÔNG BÁO HỆ THỐNG',
              icon: Icons.notifications,
              color: Colors.grey,
            ),
            ...otherNotifications.map((notification) => _NotificationCard(
              notification: notification,
              onTap: () => onMarkAsRead(notification.id),
            )),
          ],
        ],
      ),
    );
  }
}

// Tab Cộng đồng - CẢI TIẾN
class _CommunityTab extends StatelessWidget {
  final List<PostModel> posts;
  final VoidCallback onRefresh;
  final bool isLoading;

  const _CommunityTab({
    required this.posts,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa có bài đăng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy là người đầu tiên chia sẻ thông tin!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo bài viết'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header với thông tin và button tạo bài
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(
                color: Colors.blue.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cộng đồng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    '${posts.length} bài đăng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Bài mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        // Danh sách bài viết
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              onRefresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(
                  post: post,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        )
    );
  }
}

// Notification Card
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: notification.priorityColor.withOpacity(0.1),
                    radius: 18,
                    child: Icon(
                      notification.typeIcon,
                      size: 16,
                      color: notification.priorityColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: notification.priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.message,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (notification.data != null && notification.data!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: notification.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getNotificationActionText(notification.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: notification.priorityColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNotificationActionText(NotificationType type) {
    switch (type) {
      case NotificationType.zoneAlert:
        return 'Xem bản đồ';
      case NotificationType.reportUpdate:
        return 'Xem báo cáo';
      default:
        return 'Chi tiết';
    }
  }
}

// Post Card
class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with source info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: post.sourceColor.withOpacity(0.1),
                  child: Icon(
                    post.sourceIcon,
                    color: post.sourceColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.sourceText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: post.sourceColor,
                            ),
                          ),
                          if (post.source == PostSource.government ||
                              post.source == PostSource.healthWorker)
                            const SizedBox(width: 4),
                          if (post.source == PostSource.government ||
                              post.source == PostSource.healthWorker)
                            const Icon(Icons.verified, color: Colors.blue, size: 14),
                        ],
                      ),
                      if (post.author != null)
                        Text(
                          post.author!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  post.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location and disease type
            if (post.location != null || post.diseaseType != null)
              Row(
                children: [
                  if (post.location != null) ...[
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      post.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (post.diseaseType != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                  if (post.diseaseType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.diseaseType!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            if (post.location != null || post.diseaseType != null)
              const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Reaction buttons
            const SizedBox(height: 16),
            Row(
              children: [
                // Helpful button
                _ReactionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  activeIcon: Icons.thumb_up_alt,
                  count: post.helpfulCount,
                  isActive: false,
                  onTap: () {
                    // TODO: Implement reaction
                  },
                  color: Colors.green,
                ),
                const SizedBox(width: 16),

                // Not helpful button
                _ReactionButton(
                  icon: Icons.thumb_down_alt_outlined,
                  activeIcon: Icons.thumb_down_alt,
                  count: post.notHelpfulCount,
                  isActive: false,
                  onTap: () {
                    // TODO: Implement reaction
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Reaction Button
class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;

  const _ReactionButton({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? color : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                color: isActive ? color : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
