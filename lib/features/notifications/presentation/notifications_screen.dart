import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = NotificationItem.sampleNotifications;
  int _selectedFilterIndex = 0; // 0: All, 1: Booking, 2: Community, 3: Promo

  final List<String> _filters = ['Tất cả', 'Lịch đặt', 'Cộng đồng', 'Khuyến mãi'];

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilterIndex == 1) {
      return _notifications.where((n) => n.type == NotificationType.booking).toList();
    }
    if (_selectedFilterIndex == 2) {
      return _notifications.where((n) => n.type == NotificationType.community).toList();
    }
    if (_selectedFilterIndex == 3) {
      return _notifications.where((n) => n.type == NotificationType.promo).toList();
    }
    return _notifications;
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trung Tâm Thông Báo'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc tất cả', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Category Chips Row
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isSelected ? Colors.transparent : AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Notifications List
            Expanded(
              child: _filteredNotifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
                          SizedBox(height: 16),
                          Text('Chưa có thông báo nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = _filteredNotifications[index];
                        return _buildNotificationCard(notif);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notif) {
    IconData iconData;
    Color iconColor;

    switch (notif.type) {
      case NotificationType.booking:
        iconData = Icons.event_available_rounded;
        iconColor = AppColors.primary;
        break;
      case NotificationType.community:
        iconData = Icons.forum_rounded;
        iconColor = Colors.blue.shade700;
        break;
      case NotificationType.promo:
        iconData = Icons.local_offer_rounded;
        iconColor = Colors.amber.shade800;
        break;
      case NotificationType.system:
        iconData = Icons.auto_awesome;
        iconColor = Colors.purple.shade600;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          notif.isRead = true;
        });
        if (notif.route != null) {
          Navigator.pushNamed(context, notif.route!, arguments: notif.routeArgs);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : AppColors.primarySoft.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notif.timeAgo,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
                      ),
                      if (notif.route != null)
                        Row(
                          children: [
                            Text(
                              'Xem chi tiết',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: iconColor),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
