import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';

class ServiceSubscriptionCard extends StatelessWidget {
  final PhotographerPackageSubscriptionResponseDTO subscription;
  final String validityText;
  final VoidCallback onDetailTap;
  final VoidCallback onRedeemTap;

  const ServiceSubscriptionCard({
    super.key,
    required this.subscription,
    required this.validityText,
    required this.onDetailTap,
    required this.onRedeemTap,
  });

  @override
  Widget build(BuildContext context) {
    final canBook = subscription.status.toUpperCase() == 'ACTIVE' &&
        subscription.remainingUsesThisPeriod > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subscription.packageName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ServicePackageStatusChip(status: subscription.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subscription.providerName,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecColor,
            ),
          ),
          Divider(height: 22, color: context.dividerColor),
          ServicePackageInfoRow(
            label: 'Hạn sử dụng:',
            value: validityText,
          ),
          ServicePackageInfoRow(
            label: 'Lượt dùng trong kỳ:',
            value:
                'Đã dùng ${subscription.usedThisPeriod}/${subscription.usesPerMonth} (Còn ${subscription.remainingUsesThisPeriod} lượt)',
            highlight: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetailTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                    side: BorderSide(
                      color: context.isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Chi Tiết Gói',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (canBook) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRedeemTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Đặt Lịch Theo Gói',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ServicePackageInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const ServicePackageInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecColor,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.primary : context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServicePackageStatusChip extends StatelessWidget {
  final String status;

  const ServicePackageStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    Color bg = AppColors.primary.withValues(alpha: 0.12);
    Color fg = AppColors.primary;
    String label = status;

    if (upper == 'ACTIVE') {
      bg = AppColors.success.withValues(alpha: context.isDark ? 0.18 : 0.1);
      fg = AppColors.success;
      label = 'Đang hoạt động';
    } else if (upper == 'PENDING_PAYMENT') {
      bg = AppColors.warning.withValues(alpha: context.isDark ? 0.18 : 0.12);
      fg = AppColors.warning;
      label = 'Chờ thanh toán';
    } else if (upper == 'EXPIRED' || upper == 'CANCELLED') {
      bg = AppColors.error.withValues(alpha: context.isDark ? 0.18 : 0.1);
      fg = AppColors.error;
      label = upper == 'EXPIRED' ? 'Hết hạn' : 'Đã hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
