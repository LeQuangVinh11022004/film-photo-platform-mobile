import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_item.dart';
import '../models/booking_schedule.dart';
import 'package:intl/intl.dart';

class BookingFlowScreen extends StatefulWidget {
  final BookingItem item;
  const BookingFlowScreen({super.key, required this.item});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Add-ons state
  final List<String> _selectedAddons = [];
  late List<Map<String, dynamic>> _availableAddons;

  // Step 2: Date & Time state
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedTimeSlotIndex = 0;
  final List<Map<String, dynamic>> _timeSlots = [
    {'slot': '08:00 - 10:00', 'hours': 2},
    {'slot': '10:00 - 12:00', 'hours': 2},
    {'slot': '13:00 - 16:00', 'hours': 3},
    {'slot': '16:00 - 19:00', 'hours': 3},
    {'slot': '19:00 - 22:00', 'hours': 3},
  ];

  @override
  void initState() {
    super.initState();
    _initAddons();
  }

  void _initAddons() {
    if (widget.item.category == BookingCategory.studio) {
      _availableAddons = [
        {'name': 'Đèn Flash Profoto B10', 'price': 150000, 'icon': Icons.flash_on_rounded},
        {'name': 'Background Vải Canvas (Nhiều màu)', 'price': 50000, 'icon': Icons.format_paint_rounded},
        {'name': 'Máy ảnh Leica M6 (Kèm lens)', 'price': 200000, 'icon': Icons.camera_alt_rounded},
        {'name': 'Kỹ thuật viên hỗ trợ ánh sáng', 'price': 300000, 'icon': Icons.person_rounded},
      ];
    } else if (widget.item.category == BookingCategory.darkroom) {
      _availableAddons = [
        {'name': 'Hóa chất tráng màu C41', 'price': 100000, 'icon': Icons.science_rounded},
        {'name': 'Hóa chất đen trắng D-76', 'price': 80000, 'icon': Icons.science_outlined},
        {'name': 'Giấy rọi ảnh Ilford (10 tờ)', 'price': 150000, 'icon': Icons.insert_drive_file_rounded},
      ];
    } else {
      _availableAddons = [
        {'name': 'Chân máy Manfrotto', 'price': 50000, 'icon': Icons.camera_rounded},
        {'name': 'Dây bấm mềm', 'price': 20000, 'icon': Icons.settings_input_component_rounded},
      ];
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submitBooking();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _submitBooking() {
    final slot = _timeSlots[_selectedTimeSlotIndex];
    final hours = slot['hours'] as int;
    double addonPrice = 0;
    for (var a in _availableAddons) {
      if (_selectedAddons.contains(a['name'])) addonPrice += a['price'];
    }
    final totalPrice = (widget.item.pricePerHour * hours) + addonPrice;

    final newSchedule = BookingSchedule(
      id: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      item: widget.item,
      bookingDate: _selectedDate,
      timeSlot: '${slot['slot']} ($hours giờ)',
      totalPrice: totalPrice,
      status: BookingStatus.confirmed,
    );
    BookingSchedule.sampleSchedules.insert(0, newSchedule);

    Navigator.pop(context); // close booking flow

    // Trigger REAL Native Android System Notification
    NotificationService().triggerLocalNotification(
      context: context,
      title: 'Đặt Lịch Thành Công! 🎉',
      body: 'Đã xác nhận đặt ${newSchedule.item.name} vào ngày ${_selectedDate.day}/${_selectedDate.month}. Bấm để xem chi tiết.',
      route: '/notifications',
      routeArgs: newSchedule,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _prevStep,
        ),
        title: const Text('Tiến trình Đặt chỗ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Dịch vụ thêm'),
                _buildStepDivider(),
                _buildStepIndicator(1, 'Ngày & Giờ'),
                _buildStepDivider(),
                _buildStepIndicator(2, 'Thanh toán'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Addons(),
                _buildStep2DateTime(),
                _buildStep3Checkout(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text('${step + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textHint)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppColors.textPrimary : AppColors.textHint),
          )
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 20,
      height: 2,
      color: AppColors.inputFill,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }

  Widget _buildStep1Addons() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Nâng cấp trải nghiệm',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          'Chọn thêm các trang thiết bị hoặc dịch vụ đi kèm phù hợp với nhu cầu của bạn.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        ..._availableAddons.map((addon) {
          final isSelected = _selectedAddons.contains(addon['name']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedAddons.remove(addon['name']);
                } else {
                  _selectedAddons.add(addon['name']);
                }
              });
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.cardBg,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(addon['icon'], color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon['name'],
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(addon['price'])}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ],
              ),
            ),
          );
        }).toList().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildStep2DateTime() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Thời gian đặt chỗ',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 24),
        
        const Text('Chọn Ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
        
        const SizedBox(height: 28),
        
        const Text('Chọn Khung Giờ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_timeSlots.length, (index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedTimeSlotIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTimeSlotIndex = index),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Text(
                  '${slot['slot']} (${slot['hours']}h)',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildStep3Checkout() {
    final slot = _timeSlots[_selectedTimeSlotIndex];
    final hours = slot['hours'] as int;
    final basePrice = widget.item.pricePerHour * hours;
    
    double addonPrice = 0;
    for (var a in _availableAddons) {
      if (_selectedAddons.contains(a['name'])) addonPrice += a['price'];
    }
    
    final totalPrice = basePrice + addonPrice;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Tổng quan Đơn đặt',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} • ${slot['slot']}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Phí thuê cơ bản', style: TextStyle(color: AppColors.textSecondary)),
                  Text(NumberFormat.currency(locale: 'vi', symbol: 'đ').format(basePrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              if (_selectedAddons.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Dịch vụ thêm:', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ..._selectedAddons.map((name) {
                  final price = _availableAddons.firstWhere((a) => a['name'] == name)['price'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('• $name', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                        Text(NumberFormat.currency(locale: 'vi', symbol: 'đ').format(price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(
                NumberFormat.currency(locale: 'vi', symbol: 'đ').format(totalPrice),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: PrimaryButton(
          text: _currentStep < 2 ? 'Tiếp tục' : 'Xác nhận & Thanh toán',
          onPressed: _nextStep,
        ),
      ),
    );
  }
}
