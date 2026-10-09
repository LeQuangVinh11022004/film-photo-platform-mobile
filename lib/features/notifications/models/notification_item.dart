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

  static List<NotificationItem> sampleNotifications = [
    NotificationItem(
      id: 'NOTIF-01',
      title: 'Lịch đặt Studio đã được xác nhận! 🎉',
      body: 'Chủ Vintage Film Studio Saigon đã xác nhận lịch đặt của bạn vào lúc 09:00 sáng mai. Bấm để xem chi tiết.',
      timeAgo: '5 phút trước',
      type: NotificationType.booking,
      isRead: false,
      route: '/notifications',
    ),
    NotificationItem(
      id: 'NOTIF-02',
      title: 'Chuyên gia Lộc Film vừa đăng bài viết mới 📸',
      body: 'Bài viết "Kỹ thuật tráng film Kodak Tri-X 400 trong phòng tối" đang thu hút 128 lượt thảo luận. Xem ngay!',
      timeAgo: '1 giờ trước',
      type: NotificationType.community,
      isRead: false,
    ),
    NotificationItem(
      id: 'NOTIF-03',
      title: 'Ưu Đãi Đặc Biệt: Giảm 20% Thuê Phòng Tối 🎞️',
      body: 'Sử dụng mã ANALOG20 để nhận ưu đãi 20% khi đặt Silver Halide Darkroom trong tuần này.',
      timeAgo: '3 giờ trước',
      type: NotificationType.promo,
      isRead: true,
      route: '/service-packages',
    ),
    NotificationItem(
      id: 'NOTIF-04',
      title: 'AI Phục Chế Ảnh Film 4K đã sẵn sàng 🤖',
      body: 'Tính năng AI Enhancer mới giúp tự động làm nét hạt film và phục hồi màu sắc phim cũ trong 3 giây.',
      timeAgo: '1 ngày trước',
      type: NotificationType.system,
      isRead: true,
      route: '/ai-restoration',
    ),
  ];
}
