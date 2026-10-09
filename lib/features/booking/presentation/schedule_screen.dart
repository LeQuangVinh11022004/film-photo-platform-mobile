import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _currentMonth = DateTime(2026, 10, 1);
  int _selectedDayIndex = 6; // Active day selection (Day 7)
  int _statusFilterIndex = 0; // 0: All, 1: Confirmed, 2: Completed

  final List<String> _months = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
  ];

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  void _showBookingDetailModal(BookingSchedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
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
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi Tiết Đơn #${schedule.id}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: schedule.status == BookingStatus.confirmed ? Colors.green.shade50 : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: schedule.status == BookingStatus.confirmed ? Colors.green.shade700 : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Item Banner
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.inputColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SafeNetworkImage(
                    url: schedule.item.imageUrl,
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.item.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            schedule.item.categoryName,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Time & Price Info
            Text('THÔNG TIN ĐẶT CHỖ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textHint, letterSpacing: 0.5)),
            SizedBox(height: 12),
            _buildDetailRow('Ngày đặt:', '${schedule.bookingDate.day}/${schedule.bookingDate.month}/${schedule.bookingDate.year}'),
            _buildDetailRow('Khung giờ:', schedule.timeSlot),
            _buildDetailRow('Địa điểm:', schedule.item.location),
            Divider(height: 24, color: context.inputColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textColor)),
                Text(
                  '${schedule.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
            SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang kết nối tới chủ địa điểm/thiết bị...')),
                      );
                    },
                    icon: Icon(Icons.phone_in_talk, size: 18),
                    label: Text('Liên Hệ Host'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        BookingSchedule.sampleSchedules.remove(schedule);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã hủy lịch đặt thành công!'), backgroundColor: Colors.redAccent),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Hủy Lịch Đặt', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecColor, fontSize: 14)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textColor))),
        ],
      ),
    );
  }

  void _showAllSchedulesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List<BookingSchedule> list = BookingSchedule.sampleSchedules;
          if (_statusFilterIndex == 1) {
            list = list.where((s) => s.status == BookingStatus.confirmed).toList();
          } else if (_statusFilterIndex == 2) {
            list = list.where((s) => s.status == BookingStatus.completed).toList();
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.all(24),
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
                SizedBox(height: 20),
                Text(
                  'Tất Cả Lịch Đặt Chỗ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 16),

                // Status filter row
                Row(
                  children: [
                    _buildFilterChip('Tất cả', 0, setModalState),
                    SizedBox(width: 8),
                    _buildFilterChip('Đã xác nhận', 1, setModalState),
                    SizedBox(width: 8),
                    _buildFilterChip('Hoàn thành', 2, setModalState),
                  ],
                ),
                SizedBox(height: 20),

                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 56, color: AppColors.textHint),
                              SizedBox(height: 12),
                              Text('Không có lịch đặt nào', style: TextStyle(color: context.textSecColor, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final schedule = list[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _showBookingDetailModal(schedule);
                              },
                              child: _buildScheduleCard(schedule),
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

  Widget _buildFilterChip(String label, int index, StateSetter setModalState) {
    final isSelected = _statusFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: context.inputColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: isSelected ? context.cardColor : context.textColor,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() {
            _statusFilterIndex = index;
          });
          setState(() {
            _statusFilterIndex = index;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Quản Lý Lịch Đặt Chỗ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Card Container
              Container(
                padding: EdgeInsets.all(20),
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
                    // Month Selector Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_months[_currentMonth.month - 1]}, ${_currentMonth.year}',
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
                                icon: Icon(Icons.chevron_left, color: context.textColor, size: 20),
                                onPressed: () => _changeMonth(-1),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: context.inputColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.chevron_right, color: context.textColor, size: 20),
                                onPressed: () => _changeMonth(1),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Calendar Days Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _CalendarDayHeader(day: 'CN'),
                        _CalendarDayHeader(day: 'T2'),
                        _CalendarDayHeader(day: 'T3'),
                        _CalendarDayHeader(day: 'T4'),
                        _CalendarDayHeader(day: 'T5'),
                        _CalendarDayHeader(day: 'T6'),
                        _CalendarDayHeader(day: 'T7'),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Days Numbers Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 31,
                      itemBuilder: (context, index) {
                        final dayNumber = index + 1;
                        final isSelected = _selectedDayIndex == index;

                        // Check if any schedule matches this day
                        final hasBooking = BookingSchedule.sampleSchedules.any((s) => s.bookingDate.day == dayNumber);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDayIndex = index;
                            });
                          },
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
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected || hasBooking ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? context.cardColor
                                      : (hasBooking ? AppColors.primaryDark : context.textColor),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Section Header: My Schedule
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch đặt ngày ${_selectedDayIndex + 1}/${_currentMonth.month}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAllSchedulesModal,
                    child: Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Schedules Cards List
              BookingSchedule.sampleSchedules.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text('Ngày này chưa có lịch đặt', style: TextStyle(color: context.textSecColor, fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: BookingSchedule.sampleSchedules.length,
                      itemBuilder: (context, index) {
                        final schedule = BookingSchedule.sampleSchedules[index];
                        return GestureDetector(
                          onTap: () => _showBookingDetailModal(schedule),
                          child: _buildScheduleCard(schedule),
                        );
                      },
                    ),
              
              SizedBox(height: 120), // Bottom padding for navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BookingSchedule schedule) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeNetworkImage(
            url: schedule.item.imageUrl,
            width: 84,
            height: 84,
            borderRadius: BorderRadius.circular(16),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: context.textSecColor),
                    SizedBox(width: 6),
                    Text(
                      schedule.timeSlot,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.textSecColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${schedule.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: schedule.status == BookingStatus.confirmed ? Colors.green.shade50 : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schedule.statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: schedule.status == BookingStatus.confirmed ? Colors.green.shade700 : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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


