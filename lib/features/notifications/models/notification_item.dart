enum NotificationType { booking, community, promo, system }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final NotificationType type;
  bool isRead;
  final String? route;
  final dynamic routeArgs;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
    this.route,
    this.routeArgs,
  });

  String get typeName {
    switch (type) {
      case NotificationType.booking:
        return 'Lịch đặt';
      case NotificationType.community:
        return 'Cộng đồng';
      case NotificationType.promo:
        return 'Khuyến mãi';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }

  /// Danh sách thông báo thực phát sinh trong phiên làm việc (không dùng dữ liệu mẫu)
  static final List<NotificationItem> notifications = [];
}
