import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class BookingFlowDateTimeStep extends StatelessWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> slots;
  final int selectedTimeSlotIndex;
  final Future<void> Function() onRefresh;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int> onSlotSelected;

  const BookingFlowDateTimeStep({
    super.key,
    required this.selectedDate,
    required this.slots,
    required this.selectedTimeSlotIndex,
    required this.onRefresh,
    required this.onDateSelected,
    required this.onSlotSelected,
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
          Text(
            'Thời gian đặt chỗ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          Text(
            'Chọn Ngày',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                builder: (pickerContext, child) {
                  final isDark = context.isDark;
                  return Theme(
                    data: Theme.of(pickerContext).copyWith(
                      colorScheme: isDark
                          ? ColorScheme.dark(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: context.cardColor,
                              onSurface: context.textColor,
                            )
                          : const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: AppColors.cardBg,
                              onSurface: AppColors.textPrimary,
                            ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onDateSelected(picked);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: context.inputColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),
          Text(
            'Chọn Khung Giờ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Center(
                child: Text(
                  'Không có khung giờ trống cho ngày này',
                  style: TextStyle(
                    color: context.textSecColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms)
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(slots.length, (index) {
                final slot = slots[index];
                final isSelected = selectedTimeSlotIndex == index;
                return GestureDetector(
                  onTap: () => onSlotSelected(index),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : context.borderColor,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      '${slot['slot']} (${slot['hours']}h)',
                      style: TextStyle(
                        color: isSelected ? Colors.white : context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}
