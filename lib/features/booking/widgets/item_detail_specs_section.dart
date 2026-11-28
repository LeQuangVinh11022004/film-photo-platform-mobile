import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_item.dart';

class ItemDetailSpecsSection extends StatelessWidget {
  final BookingItem item;

  const ItemDetailSpecsSection({
    super.key,
    required this.item,
  });

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textColor,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.location,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textSecColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (item.providerName.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.providerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                        height: 1.35,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_formatPrice(item.pricePerHour)}đ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ giờ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, curve: Curves.easeOutQuad),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    item.ratingLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tối đa ${item.capacity} người',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textSecColor,
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
        const SizedBox(height: 28),
        if (item.lengthM > 0 ||
            item.operatingHours.isNotEmpty ||
            item.artisticStyle.isNotEmpty) ...[
          Text(
            'Thông số & Đặc điểm không gian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                if (item.lengthM > 0 && item.widthM > 0) ...[
                  _SpecRow(
                    icon: Icons.straighten_rounded,
                    label: 'Kích thước',
                    value:
                        '${item.lengthM}m × ${item.widthM}m (Trần cao ${item.heightM}m)',
                  ),
                  const Divider(height: 22),
                ],
                if (item.operatingHours.isNotEmpty) ...[
                  _SpecRow(
                    icon: Icons.schedule_rounded,
                    label: 'Giờ hoạt động',
                    value: item.operatingHours,
                  ),
                  const Divider(height: 22),
                ],
                if (item.artisticStyle.isNotEmpty) ...[
                  _SpecRow(
                    icon: Icons.palette_outlined,
                    label: 'Phong cách',
                    value: item.artisticStyle,
                  ),
                  if (item.supportedProcesses.isNotEmpty ||
                      item.lightingConditions.isNotEmpty)
                    const Divider(height: 22),
                ],
                if (item.supportedProcesses.isNotEmpty) ...[
                  _SpecRow(
                    icon: Icons.science_outlined,
                    label: 'Quy trình tráng rọi',
                    value: item.supportedProcesses,
                  ),
                  if (item.lightingConditions.isNotEmpty)
                    const Divider(height: 22),
                ],
                if (item.lightingConditions.isNotEmpty) ...[
                  _SpecRow(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Ánh sáng',
                    value: item.lightingConditions,
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),
          const SizedBox(height: 28),
        ],
        Text(
          'Tiện ích cung cấp',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: item.amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amenity,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
