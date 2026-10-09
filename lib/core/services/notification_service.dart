import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/notifications/models/notification_item.dart';
import '../theme/app_colors.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Khởi tạo thông báo cho Android
    const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);

    await _localNotifications.initialize(initSettings);
    _isInitialized = true;
  }

  /// Request permission on Android 13+
  Future<void> requestPermission() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  /// Show REAL Native Android Notification using flutter_local_notifications
  Future<void> showNativeNotification({required String title, required String body}) async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'film_platform_booking_channel',
      'Lịch Đặt Chỗ Film Platform',
      channelDescription: 'Thông báo hệ thống cho lịch đặt studio, phòng tối và thiết bị',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Triggers device-level system notification banner when booking occurs
  void triggerLocalNotification({
    required BuildContext context,
    required String title,
    required String body,
    String? route,
    dynamic routeArgs,
  }) {
    // 1. Dispatch REAL native Android System Notification using package
    showNativeNotification(title: title, body: body);

    // 2. Insert into in-app notification model list
    final newNotif = NotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timeAgo: 'Vừa xong',
      type: NotificationType.booking,
      isRead: false,
      route: route,
      routeArgs: routeArgs,
    );

    NotificationItem.sampleNotifications.insert(0, newNotif);
  }
}
