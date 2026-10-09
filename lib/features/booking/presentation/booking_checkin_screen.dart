import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_schedule.dart';

class BookingCheckinScreen extends StatefulWidget {
  const BookingCheckinScreen({super.key});

  @override
  State<BookingCheckinScreen> createState() => _BookingCheckinScreenState();
}

class _BookingCheckinScreenState extends State<BookingCheckinScreen> {
  late BookingSchedule _schedule;
  bool _isCheckedIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookingSchedule) {
      _schedule = args;
    } else {
      _schedule = BookingSchedule.sampleSchedules[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thẻ Check-in / Check-out QR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Ticket Pass Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PASS ĐẶT CHỖ CHÍNH THỨC',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.primary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isCheckedIn ? Colors.green.shade50 : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isCheckedIn ? 'ĐANG SỬ DỤNG' : 'ĐÃ SẴN SÀNG',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isCheckedIn ? Colors.green : AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // QR Code Box Placeholder
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 160,
                            color: _isCheckedIn ? Colors.green : AppColors.textPrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MÃ ĐƠN: REF-FLM-${_schedule.id}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Booking Spec Details
                    _buildInfoRow('Địa điểm:', _schedule.item.name),
                    _buildInfoRow('Thời gian:', '${_schedule.bookingDate.day}/${_schedule.bookingDate.month}/${_schedule.bookingDate.year}'),
                    _buildInfoRow('Khung giờ:', _schedule.timeSlot),
                    _buildInfoRow('Tài nguyên đã dùng:', '2x Cuộn Kodak Gold, 1x Đèn Profoto'),

                    const Divider(height: 28),

                    // Check-in / Check-out Action Button
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isCheckedIn = !_isCheckedIn;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isCheckedIn ? 'Check-in thành công! Thời gian sử dụng bắt đầu tính.' : 'Check-out hoàn tất! Đã ghi nhận tổng thời gian sử dụng.'),
                            backgroundColor: _isCheckedIn ? Colors.green : AppColors.primary,
                          ),
                        );
                      },
                      icon: Icon(_isCheckedIn ? Icons.logout : Icons.login),
                      label: Text(_isCheckedIn ? 'XÁC NHẬN CHECK-OUT' : 'QUÉT QR CHECK-IN NGAY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCheckedIn ? Colors.green : AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
