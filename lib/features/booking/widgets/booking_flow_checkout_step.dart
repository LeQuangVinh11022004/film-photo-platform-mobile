import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';

class BookingFlowCheckoutStep extends StatelessWidget {
  final String itemName;
  final DateTime selectedDate;
  final Map<String, dynamic>? selectedSlot;
  final double basePrice;
  final double totalPrice;
  final List<String> selectedAddons;
  final List<Map<String, dynamic>> availableAddons;
  final List<PhotographerPackageSubscriptionResponseDTO> matchingSubscriptions;
  final PhotographerPackageSubscriptionResponseDTO? selectedSubscription;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onSubscriptionToggled;

  const BookingFlowCheckoutStep({
    super.key,
    required this.itemName,
    required this.selectedDate,
    required this.selectedSlot,
    required this.basePrice,
    required this.totalPrice,
    required this.selectedAddons,
    required this.availableAddons,
    required this.matchingSubscriptions,
    required this.selectedSubscription,
    required this.onRefresh,
    required this.onSubscriptionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final slot = selectedSlot;
    if (slot == null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Text(
                'Không có khung giờ trống cho ngày đã chọn',
                style: TextStyle(color: context.textSecColor, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    final hours = slot['hours'] as int;
    final durationHours = slot['durationHours'] as double;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Tổng quan Đơn đặt',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: context.textSecColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} • ${slot['slot']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecColor,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: context.dividerColor),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phí thuê cơ bản',
                      style: TextStyle(color: context.textSecColor),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'vi', symbol: 'đ')
                          .format(basePrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
                if (selectedAddons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Thiết bị đi kèm:',
                    style: TextStyle(color: context.textSecColor),
                  ),
                  const SizedBox(height: 8),
                  ...selectedAddons.map((name) {
                    final addon =
                        availableAddons.firstWhere((a) => a['name'] == name);
                    final unitPrice = (addon['price'] as num).toDouble();
                    final isPerHour = addon['isPerHour'] == true;
                    final lineTotal =
                        isPerHour ? unitPrice * durationHours : unitPrice;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isPerHour ? '• $name (x${hours}h)' : '• $name',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecColor,
                              ),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'vi', symbol: 'đ')
                                .format(lineTotal),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          if (matchingSubscriptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(
                  alpha: context.isDark ? 0.16 : 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.card_membership_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bạn có Gói Subscription áp dụng cho phòng này',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      Switch(
                        value: selectedSubscription != null,
                        activeThumbColor: AppColors.success,
                        activeTrackColor:
                            AppColors.success.withValues(alpha: 0.35),
                        onChanged: onSubscriptionToggled,
                      ),
                    ],
                  ),
                  if (selectedSubscription != null)
                    Text(
                      'Đang áp dụng: ${selectedSubscription!.packageName} (Còn ${selectedSubscription!.remainingUsesThisPeriod} lượt dùng • Miễn đặt cọc)',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.isDark
                            ? context.textSecColor
                            : AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedSubscription != null
                      ? 'Sử dụng Gói Subscription'
                      : 'Tổng thanh toán',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  selectedSubscription != null
                      ? '0đ (-1 lượt)'
                      : NumberFormat.currency(locale: 'vi', symbol: 'đ')
                          .format(totalPrice),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}
