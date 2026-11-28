import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PaymentOrderSummaryCard extends StatelessWidget {
  final String bookingId;
  final String itemName;
  final String dateString;
  final String timeSlot;
  final String formattedAmount;

  const PaymentOrderSummaryCard({
    super.key,
    required this.bookingId,
    required this.itemName,
    required this.dateString,
    required this.timeSlot,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TỔNG QUAN ĐƠN HÀNG',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã đơn: $bookingId',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.textSecColor,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Địa điểm:',
            value: itemName,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Ngày đặt:',
            value: dateString,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Khung giờ:',
            value: timeSlot,
            fontWeight: FontWeight.bold,
          ),
          Divider(height: 24, color: context.dividerColor),
          _SummaryRow(
            label: 'Tổng thanh toán:',
            value: formattedAmount,
            valueColor: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double fontSize;
  final FontWeight fontWeight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                valueColor == null ? context.textSecColor : context.textColor,
            fontSize: fontSize,
            fontWeight:
                valueColor == null ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: fontWeight,
              fontSize: fontSize,
              color: valueColor ?? context.textColor,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
