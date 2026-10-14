import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/notifications/models/notification_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Khởi tạo thông báo cho Android dùng launcher_icon chuẩn
    const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click if needed
      },
    );
    _isInitialized = true;
  }

  /// Request permission on Android 13+ & iOS
  Future<bool?> requestPermission() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    final bool? grantedAndroid = await androidImplementation?.requestNotificationsPermission();
    
    final bool? grantedIOS = await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return grantedAndroid ?? grantedIOS;
  }

  /// Show REAL Native Android & iOS Notification
  Future<void> showNativeNotification({required String title, required String body}) async {
    await init();

    // Ensure permission is granted before showing
    await requestPermission();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'film_platform_booking_channel_v2',
      'Lịch Đặt Chỗ Film Platform',
      channelDescription: 'Thông báo hệ thống cho lịch đặt studio, phòng tối và thiết bị',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Lịch đặt chỗ mới',
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
    );

    // Unique notification ID per second
    final int notifId = (DateTime.now().millisecondsSinceEpoch / 1000).floor().remainder(100000);

    await _localNotifications.show(
      notifId,
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
