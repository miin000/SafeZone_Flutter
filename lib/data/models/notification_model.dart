// Notification Model
import 'package:intl/intl.dart';

enum NotificationType {
  epidemicAlert,
  zoneEntry,
  reportUpdate,
  zoneUpdate,
  newPost,
  system,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] as String?;
    DateTime createdAt = DateTime.now();

    if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
      final hasTimezone =
          createdAtRaw.endsWith('Z') ||
          RegExp(r'([+-]\d{2}:?\d{2})$').hasMatch(createdAtRaw);
      final parsed = DateTime.parse(createdAtRaw);
      createdAt = hasTimezone ? parsed.toLocal() : parsed;
    }

    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      // API returns 'body' not 'message'
      message: (json['body'] ?? json['message']) as String? ?? '',
      type: _parseType(json['type'] as String? ?? 'system'),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: createdAt,
      metadata: json['data'] as Map<String, dynamic>?,
    );
  }

  static NotificationType _parseType(String type) {
    // Handle both uppercase and lowercase type names from API
    switch (type.toLowerCase()) {
      case 'epidemic_alert':
        return NotificationType.epidemicAlert;
      case 'zone_entry':
        return NotificationType.zoneEntry;
      case 'report_update':
        return NotificationType.reportUpdate;
      case 'zone_update':
        return NotificationType.zoneUpdate;
      case 'new_post':
        return NotificationType.newPost;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }
}

class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;

  NotificationListResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(dynamic json) {
    // Handle both array response and object response
    if (json is List) {
      // API returns array directly
      final list = json
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final unread = list.where((n) => !n.isRead).length;
      return NotificationListResponse(
        notifications: list,
        total: list.length,
        unreadCount: unread,
      );
    } else if (json is Map<String, dynamic>) {
      // API returns object with data, total, unreadCount
      final list =
          (json['data'] as List?)
              ?.map(
                (e) => NotificationModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];
      return NotificationListResponse(
        notifications: list,
        total: json['total'] as int? ?? list.length,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
    }

    // Fallback
    return NotificationListResponse(
      notifications: [],
      total: 0,
      unreadCount: 0,
    );
  }
}
