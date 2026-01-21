import 'package:flutter/material.dart'; // THÊM DÒNG NÀY
import 'package:equatable/equatable.dart';

enum NotificationType {
  zoneAlert,      // Cảnh báo vùng dịch
  reportUpdate,   // Cập nhật báo cáo
  systemAlert,    // Thông báo hệ thống
  healthAlert,    // Cảnh báo sức khỏe
}

enum NotificationPriority {
  high,     // Đỏ - Quan trọng
  medium,   // Vàng - Trung bình
  low,      // Xanh - Thông thường
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? data; // Additional data
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['body'] ?? json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      priority: _parsePriority(json['priority']),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'zone_alert':
        return NotificationType.zoneAlert;
      case 'report_update':
        return NotificationType.reportUpdate;
      case 'system_alert':
        return NotificationType.systemAlert;
      default:
        return NotificationType.healthAlert;
    }
  }

  static NotificationPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'high':
        return NotificationPriority.high;
      case 'medium':
        return NotificationPriority.medium;
      default:
        return NotificationPriority.low;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.low:
        return Colors.green;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.zoneAlert:
        return Icons.warning_amber;
      case NotificationType.reportUpdate:
        return Icons.update;
      case NotificationType.systemAlert:
        return Icons.notifications;
      case NotificationType.healthAlert:
        return Icons.health_and_safety;
    }
  }

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    type,
    priority,
    isRead,
    createdAt,
  ];

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}