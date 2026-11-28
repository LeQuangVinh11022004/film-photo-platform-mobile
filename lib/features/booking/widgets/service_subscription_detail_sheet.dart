import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_api_models.dart';
import 'service_subscription_card.dart';

Future<void> showServiceSubscriptionDetailSheet({
  required BuildContext context,
  required PhotographerPackageSubscriptionResponseDTO detailed,
  required String Function(DateTime) formatDate,
  required VoidCallback onRedeemPressed,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      detailed.packageName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ServicePackageStatusChip(status: detailed.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Nhà cung cấp: ${detailed.providerName}',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecColor,
                ),
              ),
              Divider(height: 24, color: context.dividerColor),
              ServicePackageInfoRow(
                label: 'Mã Subscription:',
                value: detailed.subscriptionId,
              ),
              ServicePackageInfoRow(
                label: 'Hiệu lực:',
                value:
                    '${formatDate(detailed.startsAt)} - ${formatDate(detailed.endsAt)}',
              ),
              ServicePackageInfoRow(
                label: 'Kỳ hiện tại:',
                value:
                    '${formatDate(detailed.usagePeriodStart)} - ${formatDate(detailed.usagePeriodEnd)}',
              ),
              ServicePackageInfoRow(
                label: 'Số lượt sử dụng/tháng:',
                value: '${detailed.usesPerMonth} lượt',
              ),
              ServicePackageInfoRow(
                label: 'Đã dùng / Đang giữ chỗ:',
                value:
                    '${detailed.usedThisPeriod} / ${detailed.reservedThisPeriod} lượt',
              ),
              ServicePackageInfoRow(
                label: 'Số lượt còn lại kỳ này:',
                value: '${detailed.remainingUsesThisPeriod} lượt',
                highlight: true,
              ),
              if (detailed.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Chi tiết các bước trong Gói:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...detailed.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.inputColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${item.stepOrder}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '[${item.componentType}] ${item.resourceName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: context.textColor,
                                ),
                              ),
                              if (item.includedDurationMinutes != null)
                                Text(
                                  'Thời lượng: ${item.includedDurationMinutes} phút • SL: ${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (detailed.status.toUpperCase() == 'ACTIVE' &&
                  detailed.remainingUsesThisPeriod > 0)
                PrimaryButton(
                  text: 'ĐẶT LỊCH SỬ DỤNG GÓI NGAY',
                  onPressed: () {
                    Navigator.pop(ctx);
                    onRedeemPressed();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
