import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class BookingFlowAddonsStep extends StatelessWidget {
  final String itemId;
  final bool isLoadingEquipment;
  final bool hasLoadedLiveEquipment;
  final int liveEquipmentCount;
  final List<Map<String, dynamic>> availableAddons;
  final List<String> selectedAddons;
  final Map<String, int> equipmentAvailabilityCounts;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onToggleAddon;

  const BookingFlowAddonsStep({
    super.key,
    required this.itemId,
    required this.isLoadingEquipment,
    required this.hasLoadedLiveEquipment,
    required this.liveEquipmentCount,
    required this.availableAddons,
    required this.selectedAddons,
    required this.equipmentAvailabilityCounts,
    required this.onRefresh,
    required this.onToggleAddon,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Trang thiết bị đi kèm',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
              ),
              if (isLoadingEquipment)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (hasLoadedLiveEquipment && liveEquipmentCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$liveEquipmentCount thiết bị sẵn sàng',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 8),
          Text(
            'Chọn thêm các trang thiết bị của không gian này để đính kèm trực tiếp vào đơn đặt chỗ.',
            style: TextStyle(
              fontSize: 14,
              color: context.textSecColor,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          if (hasLoadedLiveEquipment &&
              liveEquipmentCount == 0 &&
              itemId.trim().length >= 32)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.inputColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Không có thiết bị khả dụng cho không gian hoặc khung giờ này.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ...availableAddons.map((addon) {
            final name = addon['name'] as String;
            final isSelected = selectedAddons.contains(name);
            final availabilityCount =
                equipmentAvailabilityCounts[addon['equipmentId']];

            return _BookingFlowAddonCard(
              addon: addon,
              isSelected: isSelected,
              availabilityCount: availabilityCount,
              onTap: () => onToggleAddon(name),
            );
          }).toList().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

class _BookingFlowAddonCard extends StatelessWidget {
  final Map<String, dynamic> addon;
  final bool isSelected;
  final int? availabilityCount;
  final VoidCallback onTap;

  const _BookingFlowAddonCard({
    required this.addon,
    required this.isSelected,
    required this.availabilityCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = addon['category']?.toString() ?? '';
    final variant = addon['variant']?.toString() ?? '';
    final description = addon['description']?.toString() ?? '';
    final quantityTotal = (addon['quantityTotal'] as num?)?.toInt();
    final isPerHour = addon['isPerHour'] == true;
    final priceStr =
        NumberFormat.currency(locale: 'vi', symbol: 'đ').format(addon['price']);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDark
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.primarySoft.withValues(alpha: 0.55))
              : context.cardColor,
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : context.inputColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                addon['icon'],
                color: isSelected ? AppColors.primary : context.textSecColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addon['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  if (availabilityCount != null && availabilityCount! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$availabilityCount slot trống',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                  if (category.isNotEmpty || variant.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.inputColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.textSecColor,
                              ),
                            ),
                          ),
                        if (variant.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              variant,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (quantityTotal != null && quantityTotal > 0)
                          Text(
                            '• SL: $quantityTotal',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    isPerHour ? '+$priceStr / giờ' : '+$priceStr',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.borderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
