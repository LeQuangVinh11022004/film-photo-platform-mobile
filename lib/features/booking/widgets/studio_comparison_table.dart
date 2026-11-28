import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_item.dart';

class StudioComparisonTable extends StatelessWidget {
  final int selectedSpaceTab;
  final String spaceLabel;
  final BookingItem item1;
  final BookingItem item2;

  const StudioComparisonTable({
    super.key,
    required this.selectedSpaceTab,
    required this.spaceLabel,
    required this.item1,
    required this.item2,
  });

  String _formatDimensions(BookingItem item) {
    if (item.lengthM > 0 && item.widthM > 0) {
      final area = (item.lengthM * item.widthM).toStringAsFixed(0);
      final heightPart = item.heightM > 0 ? ' × ${item.heightM}m' : '';
      return '${item.lengthM}m × ${item.widthM}m$heightPart (~${area}m²)';
    }
    return 'Đang cập nhật';
  }

  String _formatPrice(double price) {
    final formatted = price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formattedđ / giờ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _CompHeader(spaceLabel: spaceLabel),
          _CompRow(
            label: 'Đơn giá thuê',
            val1: _formatPrice(item1.pricePerHour),
            val2: _formatPrice(item2.pricePerHour),
          ),
          _CompRow(
            label: 'Đánh giá ⭐',
            val1: item1.ratingLabel,
            val2: item2.ratingLabel,
          ),
          _CompRow(
            label: 'Vị trí',
            val1: item1.location,
            val2: item2.location,
          ),
          _CompRow(
            label: 'Sức chứa',
            val1: 'Tối đa ${item1.capacity} người',
            val2: 'Tối đa ${item2.capacity} người',
          ),
          if (selectedSpaceTab == 0) ...[
            _CompRow(
              label: 'Kích thước',
              val1: _formatDimensions(item1),
              val2: _formatDimensions(item2),
            ),
            _CompRow(
              label: 'Phong cách',
              val1: item1.artisticStyle.isNotEmpty
                  ? item1.artisticStyle
                  : 'Tiêu chuẩn Film',
              val2: item2.artisticStyle.isNotEmpty
                  ? item2.artisticStyle
                  : 'Tiêu chuẩn Film',
            ),
            _CompRow(
              label: 'Ánh sáng',
              val1: item1.lightingConditions.isNotEmpty
                  ? item1.lightingConditions
                  : 'Đang cập nhật',
              val2: item2.lightingConditions.isNotEmpty
                  ? item2.lightingConditions
                  : 'Đang cập nhật',
            ),
          ] else ...[
            _CompRow(
              label: 'Quy trình tráng',
              val1: item1.supportedProcesses.isNotEmpty
                  ? item1.supportedProcesses
                  : 'B&W / C-41',
              val2: item2.supportedProcesses.isNotEmpty
                  ? item2.supportedProcesses
                  : 'B&W / C-41',
            ),
            _CompRow(
              label: 'Thông gió',
              val1: item1.ventilationDetails.isNotEmpty
                  ? item1.ventilationDetails
                  : 'Tiêu chuẩn phòng tối',
              val2: item2.ventilationDetails.isNotEmpty
                  ? item2.ventilationDetails
                  : 'Tiêu chuẩn phòng tối',
            ),
          ],
          _CompRow(
            label: 'Giờ hoạt động',
            val1: item1.operatingHours.isNotEmpty
                ? item1.operatingHours
                : 'Theo lịch mở',
            val2: item2.operatingHours.isNotEmpty
                ? item2.operatingHours
                : 'Theo lịch mở',
          ),
          _CompRow(
            label: 'Số tiện ích',
            val1: '${item1.amenities.length} trang bị',
            val2: '${item2.amenities.length} trang bị',
          ),
        ],
      ),
    );
  }
}

class _CompHeader extends StatelessWidget {
  final String spaceLabel;

  const _CompHeader({required this.spaceLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.inputColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              'Tiêu chí',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.textSecColor,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$spaceLabel 1',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$spaceLabel 2',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.textColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  final String label;
  final String val1;
  final String val2;

  const _CompRow({
    required this.label,
    required this.val1,
    required this.val2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudioComparisonEmptyState extends StatelessWidget {
  final int selectedSpaceTab;
  final String spaceLabel;
  final int availableCount;
  final VoidCallback onReload;

  const StudioComparisonEmptyState({
    super.key,
    required this.selectedSpaceTab,
    required this.spaceLabel,
    required this.availableCount,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedSpaceTab == 0
                  ? Icons.camera_alt_outlined
                  : Icons.wb_twilight_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 14),
            Text(
              'Cần ít nhất 2 $spaceLabel để so sánh cùng loại',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hiện có $availableCount $spaceLabel khả dụng.',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecColor,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onReload,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại dữ liệu'),
            ),
          ],
        ),
      ),
    );
  }
}
