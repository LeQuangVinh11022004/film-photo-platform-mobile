import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';
import 'schedule_booking_card.dart';

Future<void> showScheduleAllBookingsSheet({
  required BuildContext context,
  required List<BookingResponseDTO> bookings,
  required int initialFilterIndex,
  required String Function(BookingResponseDTO) resolveSpaceImage,
  required ValueChanged<int> onFilterChanged,
  required ValueChanged<BookingResponseDTO> onSelectBooking,
}) {
  int filterIndex = initialFilterIndex;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setModalState) {
        List<BookingResponseDTO> list = List.from(bookings);
        if (filterIndex == 1) {
          list =
              list.where((s) => s.status.toUpperCase() == 'CONFIRMED').toList();
        } else if (filterIndex == 2) {
          list = list.where((s) {
            final st = s.status.toUpperCase();
            return st == 'AWAITING_DEPOSIT' || st == 'PENDING';
          }).toList();
        } else if (filterIndex == 3) {
          list =
              list.where((s) => s.status.toUpperCase() == 'CANCELLED').toList();
        }

        Widget buildFilterChip(String label, int index) {
          final isSelected = filterIndex == index;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: context.inputColor,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: isSelected ? context.cardColor : context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            onSelected: (selected) {
              if (selected) {
                setModalState(() => filterIndex = index);
                onFilterChanged(index);
              }
            },
          );
        }

        return Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.85,
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
              Text(
                'Tất Cả Lịch Đặt Chỗ (${list.length})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildFilterChip('Tất cả', 0),
                    const SizedBox(width: 8),
                    buildFilterChip('Đã xác nhận', 1),
                    const SizedBox(width: 8),
                    buildFilterChip('Chờ cọc / Xác nhận', 2),
                    const SizedBox(width: 8),
                    buildFilterChip('Đã hủy', 3),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 56,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Không có lịch đặt nào',
                              style: TextStyle(
                                color: context.textSecColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final booking = list[index];
                          return ScheduleBookingCard(
                            booking: booking,
                            spaceImageUrl: resolveSpaceImage(booking),
                            showDate: true,
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              onSelectBooking(booking);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
