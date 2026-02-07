// Notification Remote Datasource
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/notification_model.dart';

abstract class NotificationRemoteDatasource {
  Future<NotificationListResponse> getNotifications({int page, int limit});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
}

class NotificationRemoteDatasourceImpl implements NotificationRemoteDatasource {
  final ApiClient _apiClient;

  NotificationRemoteDatasourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      // Pass response.data directly - can be List or Map
      return NotificationListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('${ApiConstants.notifications}/unread-count');
      return response.data['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.post('${ApiConstants.notifications}/$notificationId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('${ApiConstants.notifications}/read-all');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete('${ApiConstants.notifications}/$notificationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return Exception(data['message']);
      }
    }
    return Exception(e.message ?? 'Đã xảy ra lỗi kết nối');
  }
}
}

class NotificationRemoteDatasourceImpl implements NotificationRemoteDatasource {
  final ApiClient _apiClient;

  NotificationRemoteDatasourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<List<NotificationModel>> getNotifications({int? page, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['items'] ?? [];

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(ApiConstants.notificationsUnread);
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.notifications}/$notificationId/read',
      );
      return NotificationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('${ApiConstants.notifications}/read-all');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete('${ApiConstants.notifications}/$notificationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    String message = 'Đã xảy ra lỗi';

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
    }

    return Exception(message);
  }
}
>>>>>>> feature/notification2
