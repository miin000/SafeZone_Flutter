import '../datasources/remote/notification_remote_datasource.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationListResponse> getNotifications({int page, int limit});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource _remoteDatasource;

  NotificationRepositoryImpl({NotificationRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? NotificationRemoteDatasourceImpl();

  @override
  Future<NotificationListResponse> getNotifications({int page = 1, int limit = 20}) {
    return _remoteDatasource.getNotifications(page: page, limit: limit);
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDatasource.getUnreadCount();
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) {
    return _remoteDatasource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() {
    return _remoteDatasource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _remoteDatasource.deleteNotification(notificationId);
  }
}