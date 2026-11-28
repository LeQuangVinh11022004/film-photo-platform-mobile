import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_api_models.dart';
import 'schedule_formatters.dart';

Future<void> showScheduleBookingDetailSheet({
  required BuildContext context,
  required BookingResponseDTO booking,
  required String spaceImageUrl,
  required bool isCancelling,
  required VoidCallback onPayPressed,
  required VoidCallback onReviewPressed,
  required VoidCallback onContactHostPressed,
  required void Function(BuildContext sheetContext) onCancelPressed,
}) {
  final shortId = booking.bookingId.length > 8
      ? booking.bookingId.substring(0, 8).toUpperCase()
      : booking.bookingId.toUpperCase();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      final bottomInset = math.max(
        MediaQuery.paddingOf(sheetContext).bottom,
        MediaQuery.viewPaddingOf(sheetContext).bottom,
      );
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
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
                  'Chi Tiết Đơn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ScheduleHelpers.statusBgColor(booking.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ScheduleHelpers.statusLabel(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ScheduleHelpers.statusTextColor(booking.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mã đơn: #$shortId',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textSecColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.inputColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SafeNetworkImage(
                  url: spaceImageUrl,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.spaceName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.providerName,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecColor,
                        ),
                      ),
                      if (booking.packageName != null &&
                          booking.packageName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            booking.packageName!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'THÔNG TIN ĐẶT CHỖ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Ngày đặt:',
            value: ScheduleHelpers.formatDateDisplay(booking.bookingDate),
          ),
          _DetailRow(
            label: 'Khung giờ:',
            value: ScheduleHelpers.formatTimeSlot(booking),
          ),
          _DetailRow(
            label: 'Photographer:',
            value: booking.photographerName,
          ),
          _DetailRow(
            label: 'Tiền cọc (${booking.depositStatus}):',
            value: ScheduleHelpers.formatCurrency(booking.depositAmount),
          ),
          if (booking.qrCode.isNotEmpty)
            _DetailRow(label: 'Mã QR check-in:', value: booking.qrCode),
          if (booking.equipment.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Thiết bị đi kèm:',
              value: booking.equipment
                  .map((e) => '${e.name} (x${e.quantity})')
                  .join(', '),
            ),
          ],
          Divider(height: 24, color: context.inputColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng thanh toán:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.textColor,
                ),
              ),
              Text(
                ScheduleHelpers.formatCurrency(booking.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (booking.status.toUpperCase() == 'AWAITING_DEPOSIT') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onPayPressed();
                    },
                    icon: const Icon(Icons.payment_rounded, size: 20),
                    label: const Text(
                      'Thanh Toán',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (booking.status.toUpperCase() == 'CONFIRMED' ||
                  booking.status.toUpperCase() == 'COMPLETED') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onReviewPressed();
                    },
                    icon: const Icon(Icons.star_rate_rounded, size: 20),
                    label: const Text(
                      'Đánh Giá Không Gian',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        onContactHostPressed();
                      },
                      icon: const Icon(Icons.phone_in_talk, size: 18),
                      label: const Text('Liên Hệ Host'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: context.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (ScheduleHelpers.canCancelBooking(booking)) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isCancelling
                            ? null
                            : () => onCancelPressed(sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isCancelling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Hủy Lịch Đặt',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.textSecColor, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
