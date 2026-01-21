import 'package:mobile_flutter/data/models/notification_model.dart';

class MockNotifications {
  static List<NotificationModel> get notifications => [
    // Zone alerts - Cảnh báo vùng dịch
    NotificationModel(
      id: '1',
      title: '⚠️ CẢNH BÁO VÙNG DỊCH',
      message: 'Bạn đang ở gần vùng dịch Sốt xuất huyết tại Quận Hoàn Kiếm, Hà Nội. Số ca mắc: 45 | Mức độ: Nguy hiểm',
      type: NotificationType.zoneAlert,
      priority: NotificationPriority.high,
      data: {
        'zoneId': 'zone_001',
        'diseaseType': 'dengue',
        'lat': 21.0285,
        'lon': 105.8542,
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationModel(
      id: '2',
      title: '⚠️ CẢNH BÁO KHU VỰC',
      message: 'Khu vực quận Cầu Giấy đang có dịch Tay chân miệng. Vui lòng hạn chế đến khu vực này.',
      type: NotificationType.zoneAlert,
      priority: NotificationPriority.medium,
      data: {
        'zoneId': 'zone_002',
        'diseaseType': 'hfmd',
        'lat': 21.0333,
        'lon': 105.7994,
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),

    // Report updates - Cập nhật báo cáo
    NotificationModel(
      id: '3',
      title: '✅ BÁO CÁO ĐÃ ĐƯỢC XÁC MINH',
      message: 'Báo cáo của bạn về ca COVID-19 tại số 10 Phố Huế đã được xác minh và hiển thị trên bản đồ.',
      type: NotificationType.reportUpdate,
      priority: NotificationPriority.low,
      data: {
        'reportId': 'report_123',
        'status': 'verified',
      },
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: '4',
      title: '📋 BÁO CÁO CẦN BỔ SUNG THÔNG TIN',
      message: 'Báo cáo sốt xuất huyết của bạn cần bổ sung hình ảnh triệu chứng để xác minh.',
      type: NotificationType.reportUpdate,
      priority: NotificationPriority.medium,
      data: {
        'reportId': 'report_456',
        'status': 'pending',
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // System alerts - Thông báo hệ thống
    NotificationModel(
      id: '5',
      title: '📢 CẬP NHẬT HỆ THỐNG',
      message: 'SafeZone v2.0 đã có tính năng cảnh báo real-time. Hãy cập nhật ứng dụng!',
      type: NotificationType.systemAlert,
      priority: NotificationPriority.low,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    NotificationModel(
      id: '6',
      title: '🏥 THÔNG BÁO Y TẾ',
      message: 'Trung tâm Y tế quận Đống Đa tổ chức tiêm vaccine miễn phí từ ngày 15-20/12/2024.',
      type: NotificationType.healthAlert,
      priority: NotificationPriority.medium,
      data: {
        'location': 'Trung tâm Y tế quận Đống Đa',
        'date': '15-20/12/2024',
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // More notifications
    NotificationModel(
      id: '7',
      title: '🌡️ CẢNH BÁO THỜI TIẾT',
      message: 'Thời tiết nóng ẩm những ngày tới tạo điều kiện cho muỗi phát triển. Hãy phòng chống sốt xuất huyết!',
      type: NotificationType.healthAlert,
      priority: NotificationPriority.low,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    NotificationModel(
      id: '8',
      title: '📊 THỐNG KÊ DỊCH BỆNH',
      message: 'Tuần này, Hà Nội ghi nhận 124 ca sốt xuất huyết, tăng 15% so với tuần trước.',
      type: NotificationType.systemAlert,
      priority: NotificationPriority.low,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}