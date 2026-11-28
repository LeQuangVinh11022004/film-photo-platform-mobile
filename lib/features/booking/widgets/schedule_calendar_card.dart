import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';
import 'schedule_formatters.dart';

class ScheduleCalendarCard extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<BookingResponseDTO> bookings;
  final ValueChanged<int> onChangeMonth;
  final ValueChanged<DateTime> onSelectDate;

  const ScheduleCalendarCard({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.bookings,
    required this.onChangeMonth,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekdayOffset =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday % 7;
    final totalCells = daysInMonth + firstWeekdayOffset;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            onChangeMonth(-1);
          } else if (details.primaryVelocity! < 0) {
            onChangeMonth(1);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ScheduleHelpers.months[currentMonth.month - 1]}, ${currentMonth.year}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.inputColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: context.textColor,
                          size: 20,
                        ),
                        onPressed: () => onChangeMonth(-1),
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.inputColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: context.textColor,
                          size: 20,
                        ),
                        onPressed: () => onChangeMonth(1),
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Center(child: _CalendarDayHeader(day: 'CN'))),
                Expanded(child: Center(child: _CalendarDayHeader(day: 'T2'))),
                Expanded(child: Center(child: _CalendarDayHeader(day: 'T3'))),
                Expanded(child: Center(child: _CalendarDayHeader(day: 'T4'))),
                Expanded(child: Center(child: _CalendarDayHeader(day: 'T5'))),
                Expanded(child: Center(child: _CalendarDayHeader(day: 'T6'))),
                Expanded(child: Center(child: _CalendarDayHeader(day: 'T7'))),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              key: ValueKey('month_${currentMonth.year}_${currentMonth.month}'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < firstWeekdayOffset) {
                  return const SizedBox.shrink();
                }

                final dayNumber = index - firstWeekdayOffset + 1;
                final cellDate =
                    DateTime(currentMonth.year, currentMonth.month, dayNumber);
                final isSelected =
                    ScheduleHelpers.isSameDay(selectedDate, cellDate);
                final isPast = cellDate.isBefore(today);

                final hasBooking = bookings.any((b) {
                  final parsed =
                      ScheduleHelpers.parseBookingDate(b.bookingDate);
                  return ScheduleHelpers.isSameDay(parsed, cellDate);
                });

                return GestureDetector(
                  onTap: () => onSelectDate(cellDate),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (hasBooking
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected || hasBooking
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? context.cardColor
                                : (isPast
                                    ? AppColors.textHint.withValues(alpha: 0.65)
                                    : (hasBooking
                                        ? AppColors.primaryDark
                                        : context.textColor)),
                          ),
                        ),
                        if (hasBooking) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            )
                .animate(
                  key: ValueKey(
                    'month_${currentMonth.year}_${currentMonth.month}',
                  ),
                )
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayHeader extends StatelessWidget {
  final String day;
  const _CalendarDayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Text(
      day,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: context.textSecColor,
      ),
    );
  }
}
