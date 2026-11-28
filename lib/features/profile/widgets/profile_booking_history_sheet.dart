import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../booking/models/booking_api_models.dart';

Future<void> showProfileBookingHistorySheet({
  required BuildContext context,
  required List<BookingResponseDTO> bookings,
  required VoidCallback onOpenSchedule,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => Container(
      height: MediaQuery.of(sheetCtx).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      child: Column(
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Lịch Sử Đặt Phòng & Thiết Bị',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  onOpenSchedule();
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bookings.isNotEmpty
                ? ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final b = bookings[index];
                      final shortId = b.bookingId.length >= 6
                          ? b.bookingId.substring(0, 6)
                          : b.bookingId;
                      final priceFormatted =
                          '${b.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          onOpenSchedule();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            border: Border.all(color: context.borderColor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.spaceName.isNotEmpty
                                          ? b.spaceName
                                          : 'Đơn đặt chỗ #$shortId',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: context.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${b.bookingDate} • ${b.startTime} - ${b.endTime}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.textSecColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    priceFormatted,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: b.status.toUpperCase() ==
                                              'CONFIRMED'
                                          ? Colors.green
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: context.textSecColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('Chưa có lịch sử đặt chỗ.')),
          ),
        ],
      ),
    ),
  );
}
