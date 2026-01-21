import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository_impl.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepositoryImpl();

  // State
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get zoneAlerts => _notifications
      .where((n) => n.type == NotificationType.zoneAlert)
      .toList();

  List<NotificationModel> get reportUpdates => _notifications
      .where((n) => n.type == NotificationType.reportUpdate)
      .toList();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Fetch notifications
  Future<void> fetchNotifications({int? page, int? limit}) async {
    _setLoading(true);
    _setError(null);

    try {
      _notifications = await _repository.getNotifications(
        page: page,
        limit: limit,
      );
      await _fetchUnreadCount();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Fetch unread count
  Future<void> _fetchUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      // Silently fail for unread count
    }
  }

  // Mark as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final updatedNotification = await _repository.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updatedNotification;
      }

      if (unreadCount > 0) {
        _unreadCount--;
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mark all as read
  Future<bool> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);

      // Recalculate unread count
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Add new notification (for push notifications)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
}