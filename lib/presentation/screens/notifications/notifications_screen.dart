import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/post_provider.dart';
import '../community/widgets/post_card.dart';
import '../community/widgets/create_post_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Load notifications on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications(refresh: true);
      _startAutoRefresh();
    });
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      context.read<PostProvider>().refreshPosts(showLoading: false);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      await context.read<NotificationProvider>().loadNotifications(refresh: true);
      if (_tabController.index == 1 && mounted) {
        await context.read<PostProvider>().refreshPosts(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
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
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () => provider.markAllAsRead(),
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  label: const Text(
                    'Đọc tất cả',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null && provider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải thông báo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => provider.loadNotifications(refresh: true),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.notifications.isEmpty) {
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
          onRefresh: () => provider.refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= provider.notifications.length) {
                // Load more trigger
                provider.loadMore();
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final notification = provider.notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => provider.markAsRead(notification.id),
                onDismiss: () => provider.deleteNotification(notification.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationCard({
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
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
                notification.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.epidemicAlert:
      case NotificationType.zoneEntry:
        return Colors.orange;
      case NotificationType.reportUpdate:
        return Colors.green;
      case NotificationType.zoneUpdate:
      case NotificationType.newPost:
        return Colors.blue;
      case NotificationType.system:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.epidemicAlert:
      case NotificationType.zoneEntry:
        return Icons.warning_amber;
      case NotificationType.reportUpdate:
        return Icons.check_circle;
      case NotificationType.zoneUpdate:
        return Icons.location_on;
      case NotificationType.newPost:
        return Icons.article;
      case NotificationType.system:
        return Icons.info;
    }
  }
}

// Tab Cộng đồng - Bài đăng từ cơ quan y tế và cảnh báo từ người dùng
class _CommunityTab extends StatefulWidget {
  const _CommunityTab();

  @override
  State<_CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<_CommunityTab> {
  @override
  void initState() {
    super.initState();
    // Load posts when tab initializes
    Future.microtask(() {
      if (mounted) {
        context.read<PostProvider>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFF6F8FB),
          child: Consumer<PostProvider>(
            builder: (context, postProvider, _) {
            if (postProvider.isLoading && postProvider.posts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (postProvider.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.post_add,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có bài viết nào',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy là người đầu tiên chia sẻ thông tin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              );
            }

              return RefreshIndicator(
                onRefresh: () => postProvider.refreshPosts(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: postProvider.posts.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.lightBlue.shade500],
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.campaign, color: Colors.white),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cộng đồng SafeZone: chia sẻ thông tin chính xác, tránh tin chưa kiểm chứng.',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final post = postProvider.posts[index - 1];
                    return PostCard(post: post);
                  },
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreatePostDialog(),
              );
            },
            tooltip: 'Tạo bài viết',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
