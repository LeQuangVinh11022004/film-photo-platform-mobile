import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../models/booking_schedule.dart';
import '../services/booking_api_service.dart';
import 'payment_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  final BookingItem item;
  const BookingFlowScreen({super.key, required this.item});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _isSubmitting = false;

  // Step 1: Add-ons / Space Equipment state
  final List<String> _selectedAddons = [];
  late List<Map<String, dynamic>> _availableAddons;
  List<PhotographerEquipmentResponseDTO> _liveEquipment = [];
  bool _isLoadingEquipment = false;
  bool _hasLoadedLiveEquipment = false;
  final Map<String, int> _equipmentAvailabilityCounts = {};
  int _equipmentRequestGeneration = 0;

  // Step 2: Date & Time state
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedTimeSlotIndex = 0;
  List<Map<String, dynamic>> _liveAvailableSlots = [];
  List<PhotographerPackageSubscriptionResponseDTO> _matchingSubscriptions = [];
  PhotographerPackageSubscriptionResponseDTO? _selectedSubscription;

  List<Map<String, dynamic>> get _timeSlots {
    final sourceSlots = _liveAvailableSlots.isNotEmpty
        ? _liveAvailableSlots
        : widget.item.availableSlots;
    if (sourceSlots.isEmpty) {
      return [];
    }

    final formattedSlots = <Map<String, dynamic>>[];
    for (int i = 0; i < sourceSlots.length; i++) {
    final slotMap = sourceSlots[i];
    final availabilityId = slotMap['availabilityId']?.toString() ?? '';

    DateTime? startAt;
    DateTime? endAt;

    final rawStart = slotMap['startAt'];
    if (rawStart is DateTime) {
    startAt = rawStart;
    } else if (rawStart is String) {
    startAt = DateTime.tryParse(rawStart);
    }

    final rawEnd = slotMap['endAt'];
    if (rawEnd is DateTime) {
    endAt = rawEnd;
    } else if (rawEnd is String) {
    endAt = DateTime.tryParse(rawEnd);
    }

    if (startAt != null && endAt != null) {
    final utcStart = startAt.toUtc();
    final utcEnd = endAt.toUtc();

    if (utcStart.year == _selectedDate.year &&
    utcStart.month == _selectedDate.month &&
    utcStart.day == _selectedDate.day) {
    final startFormatted = DateFormat('HH:mm').format(utcStart);
    final endFormatted = DateFormat('HH:mm').format(utcEnd);
    final diffMinutes = utcEnd.difference(utcStart).inMinutes;
    final hours = (diffMinutes / 60).round();

    formattedSlots.add({
    'slot': '$startFormatted - $endFormatted',
    'hours': hours > 0 ? hours : 1,
    'durationHours': diffMinutes / 60,
    'price': slotMap['price'],
    'availabilityId': availabilityId,
    'startAt': utcStart,
    'endAt': utcEnd,
    });
    }
    }
    }

    return formattedSlots;
  }

  double _calculateBasePrice(Map<String, dynamic> slot, double durationHours) {
    final slotPrice = (slot['price'] as num?)?.toDouble();
    if (slotPrice != null) {
      return slotPrice;
    }
    return widget.item.pricePerHour * durationHours;
  }

  double _calculateAddonPrice([double durationHours = 1]) {
    double addonPrice = 0;
    for (var a in _availableAddons) {
      if (_selectedAddons.contains(a['name'])) {
        final unitPrice = (a['price'] as num).toDouble();
        final isPerHour = a['isPerHour'] == true;
        addonPrice += isPerHour ? unitPrice * durationHours : unitPrice;
      }
    }
    return addonPrice;
  }

  List<String> _getSelectedEquipmentIds() {
    final ids = <String>[];
    for (final a in _availableAddons) {
      if (_selectedAddons.contains(a['name'])) {
        final eqId = a['equipmentId']?.toString() ?? '';
        if (eqId.length >= 32 && !ids.contains(eqId)) {
          ids.add(eqId);
        }
      }
    }
    return ids;
  }

  IconData _resolveEquipmentIcon(PhotographerEquipmentResponseDTO eq) {
    final lowerCat = eq.category.toLowerCase();
    final lowerType = eq.equipmentType.toLowerCase();
    final lowerName = eq.name.toLowerCase();
    if (lowerCat.contains('light') ||
        lowerType.contains('light') ||
        lowerName.contains('đèn') ||
        lowerName.contains('flash') ||
        lowerName.contains('strobe')) {
      return Icons.flash_on_rounded;
    }
    if (lowerCat.contains('camera') ||
        lowerType.contains('camera') ||
        lowerName.contains('máy ảnh') ||
        lowerName.contains('leica') ||
        lowerName.contains('hasselblad') ||
        lowerName.contains('nikon') ||
        lowerName.contains('canon')) {
      return Icons.camera_alt_rounded;
    }
    if (lowerCat.contains('lens') || lowerName.contains('lens')) {
      return Icons.camera_rounded;
    }
    if (lowerCat.contains('chemical') ||
        lowerCat.contains('darkroom') ||
        lowerType.contains('enlarger') ||
        lowerName.contains('enlarger') ||
        lowerName.contains('tráng') ||
        lowerName.contains('rọi')) {
      return Icons.science_rounded;
    }
    if (lowerCat.contains('backdrop') ||
        lowerName.contains('phông') ||
        lowerName.contains('background')) {
      return Icons.format_paint_rounded;
    }
    return Icons.precision_manufacturing_rounded;
  }

  @override
  void initState() {
    super.initState();
    _liveAvailableSlots = List<Map<String, dynamic>>.from(widget.item.availableSlots);
    _initAddons();
    _initSelectedDate();
    _syncLiveSlotsSubscriptionsAndEquipment();
  }

  Future<void> _syncLiveSlotsSubscriptionsAndEquipment() async {
    final spaceId = widget.item.id.trim();
    if (spaceId.length < 32) return; // Skip mock non-UUID items

    setState(() => _isLoadingEquipment = true);

    try {
      final results = await Future.wait([
        BookingApiService().getAvailableSlots(spaceId: spaceId),
        BookingApiService().getPackageSubscriptions(),
        BookingApiService().getEquipmentForSpace(
          spaceId: spaceId,
          page: 1,
          pageSize: 50,
        ),
      ]);

      if (!mounted) return;

      final apiSlots = results[0] as List<ProviderSpaceAvailabilityResponseDTO>;
      final apiSubs = results[1] as List<PhotographerPackageSubscriptionResponseDTO>;
      final equipPage =
          results[2] as PagedResponseDTO<PhotographerEquipmentResponseDTO>?;

      if (apiSlots.isNotEmpty) {
        final converted = <Map<String, dynamic>>[];
        for (final s in apiSlots) {
          final startIso = '${s.date}T${s.startTime}Z';
          final endIso = '${s.date}T${s.endTime}Z';
          converted.add({
            'availabilityId': s.availabilityId,
            'startAt': startIso,
            'endAt': endIso,
            'price': s.price,
          });
        }
        setState(() {
          _liveAvailableSlots = converted;
        });
        if (widget.item.availableSlots.isEmpty) {
          _initSelectedDateFromSource(_liveAvailableSlots);
        }
      }

      if (equipPage != null) {
        _applyLiveEquipmentList(equipPage.items);
      }

      // Now if there is an active selected slot, refresh equipment filtered by availabilityId
      final currentSlots = _timeSlots;
      if (currentSlots.isNotEmpty) {
        final safeIdx = _selectedTimeSlotIndex < currentSlots.length
            ? _selectedTimeSlotIndex
            : 0;
        final currentAvailId =
            currentSlots[safeIdx]['availabilityId']?.toString() ?? '';
        if (currentAvailId.length >= 32) {
          await _refreshEquipmentForAvailabilitySlot(currentAvailId);
        }
      }

      final activeMatching = apiSubs.where((sub) {
        if (sub.status.toUpperCase() != 'ACTIVE' ||
            sub.remainingUsesThisPeriod <= 0) {
          return false;
        }
        return sub.items.any(
          (i) => i.resourceId.toLowerCase() == spaceId.toLowerCase(),
        );
      }).toList();

      if (activeMatching.isNotEmpty && mounted) {
        setState(() {
          _matchingSubscriptions = activeMatching;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingEquipment = false);
      }
    }
  }

  void _applyLiveEquipmentList(List<PhotographerEquipmentResponseDTO> items) {
    if (!mounted) return;
    if (items.isEmpty) {
      setState(() {
        _liveEquipment = [];
        _initAddons();
        _selectedAddons.clear();
        _hasLoadedLiveEquipment = true;
      });
      return;
    }

    final mapped = items.map((eq) {
      final price = eq.priceForSelectedSlot ?? eq.rentalPrice ?? 0.0;
      return <String, dynamic>{
        'equipmentId': eq.equipmentId,
        'equipmentAvailabilityId': eq.equipmentAvailabilityId,
        'name': eq.name,
        'category': eq.category,
        'equipmentType': eq.equipmentType,
        'variant': eq.variant,
        'description': eq.description,
        'quantityTotal': eq.quantityTotal,
        'price': price,
        'isPerHour': true,
        'icon': _resolveEquipmentIcon(eq),
      };
    }).toList();

    setState(() {
      _liveEquipment = items;
      _availableAddons = mapped;
      _hasLoadedLiveEquipment = true;
      // Keep only selections that still exist in available equipment
      final validNames = mapped.map((m) => m['name'] as String).toSet();
      _selectedAddons.removeWhere((name) => !validNames.contains(name));
    });
  }

  /// Gọi GET /api/photographer/spaces/{spaceId}/equipment?availabilityId={availabilityId}
  /// và GET /api/photographer/equipment/{equipmentId}/availability để đồng bộ thiết bị trống theo khung giờ
  Future<void> _refreshEquipmentForAvailabilitySlot(
      String availabilityId) async {
    final spaceId = widget.item.id.trim();
    if (spaceId.length < 32 || availabilityId.length < 32) return;
    final generation = ++_equipmentRequestGeneration;
    final fromDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final toDate = DateFormat('yyyy-MM-dd')
        .format(_selectedDate.add(const Duration(days: 7)));
    setState(() => _equipmentAvailabilityCounts.clear());

    try {
      final equipPage = await BookingApiService().getEquipmentForSpace(
        spaceId: spaceId,
        availabilityId: availabilityId,
        page: 1,
        pageSize: 50,
      );
      if (!mounted || generation != _equipmentRequestGeneration) return;
      if (equipPage != null) {
        _applyLiveEquipmentList(equipPage.items);
        final counts = await Future.wait(equipPage.items.map((eq) async {
          final slots = await BookingApiService().getEquipmentAvailability(
            equipmentId: eq.equipmentId,
            fromDate: fromDate,
            toDate: toDate,
          );
          return MapEntry(eq.equipmentId, slots.length);
        }));
        if (!mounted || generation != _equipmentRequestGeneration) return;
        setState(() => _equipmentAvailabilityCounts.addEntries(counts));
      }
    } catch (e) {
      debugPrint('Error refreshing space equipment: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initSelectedDate() {
    _initSelectedDateFromSource(
      _liveAvailableSlots.isNotEmpty
          ? _liveAvailableSlots
          : widget.item.availableSlots,
    );
  }

  void _initSelectedDateFromSource(List<Map<String, dynamic>> source) {
    if (source.isNotEmpty) {
      final firstSlot = source.first;
      final rawStart = firstSlot['startAt'];
      DateTime? startAt;
      if (rawStart is DateTime) {
        startAt = rawStart;
      } else if (rawStart is String) {
        startAt = DateTime.tryParse(rawStart);
      }
      if (startAt != null) {
        final utcStart = startAt.toUtc();
        setState(() {
          _selectedDate = DateTime(utcStart.year, utcStart.month, utcStart.day);
        });
      }
    }
  }

  void _initAddons() {
    if (widget.item.category == BookingCategory.studio) {
      _availableAddons = [
        {
          'name': 'Đèn Flash Profoto B10',
          'price': 150000,
          'icon': Icons.flash_on_rounded,
        },
        {
          'name': 'Background Vải Canvas (Nhiều màu)',
          'price': 50000,
          'icon': Icons.format_paint_rounded,
        },
        {
          'name': 'Máy ảnh Leica M6 (Kèm lens)',
          'price': 200000,
          'icon': Icons.camera_alt_rounded,
        },
        {
          'name': 'Kỹ thuật viên hỗ trợ ánh sáng',
          'price': 300000,
          'icon': Icons.person_rounded,
        },
      ];
    } else if (widget.item.category == BookingCategory.darkroom) {
      _availableAddons = [
        {
          'name': 'Hóa chất tráng màu C41',
          'price': 100000,
          'icon': Icons.science_rounded,
        },
        {
          'name': 'Hóa chất đen trắng D-76',
          'price': 80000,
          'icon': Icons.science_outlined,
        },
        {
          'name': 'Giấy rọi ảnh Ilford (10 tờ)',
          'price': 150000,
          'icon': Icons.insert_drive_file_rounded,
        },
      ];
    } else {
      _availableAddons = [
        {
          'name': 'Chân máy Manfrotto',
          'price': 50000,
          'icon': Icons.camera_rounded,
        },
        {
          'name': 'Dây bấm mềm',
          'price': 20000,
          'icon': Icons.settings_input_component_rounded,
        },
      ];
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _timeSlots.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        title: const Text('Không có khung giờ khả dụng'),
        description: const Text(
          'Ngày bạn chọn hiện không có khung giờ trống. Vui lòng chọn ngày khác.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
      return;
    }

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

  Future<void> _submitBooking() async {
    final slots = _timeSlots;
    if (slots.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        title: const Text('Không có khung giờ khả dụng'),
        description: const Text(
          'Vui lòng chọn ngày có khung giờ khả dụng trước khi tiếp tục.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final safeIndex =
    _selectedTimeSlotIndex < slots.length ? _selectedTimeSlotIndex : 0;
    final slot = slots[safeIndex];
    final hours = slot['hours'] as int;
    final availabilityId = slot['availabilityId'] as String;

    final durationHours = slot['durationHours'] as double;
    final basePrice = _calculateBasePrice(slot, durationHours);
    final addonPrice = _calculateAddonPrice(durationHours);
    final totalPrice = basePrice + addonPrice;
    final selectedEquipmentIds = _getSelectedEquipmentIds();

    final BookingCreateRequestDTO request;
    if (_selectedSubscription != null) {
      final stepItem = _selectedSubscription!.items.firstWhere(
        (i) => i.resourceId.toLowerCase() == widget.item.id.toLowerCase(),
        orElse: () => _selectedSubscription!.items.first,
      );
      final equipIds = _selectedSubscription!.items
          .where((i) =>
              i.stepOrder == stepItem.stepOrder &&
              i.componentType.toUpperCase() == 'EQUIPMENT')
          .map((e) => e.resourceId)
          .where((id) => id.isNotEmpty)
          .toList();
      request = BookingCreateRequestDTO.fromSubscription(
        subscriptionId: _selectedSubscription!.subscriptionId,
        segments: [
          PackageBookingSegmentRequestDTO(
            stepOrder: stepItem.stepOrder,
            availabilityId: availabilityId,
            equipmentIds: equipIds.isNotEmpty ? equipIds : selectedEquipmentIds,
          ),
        ],
      );
    } else {
      request = BookingCreateRequestDTO(
        availabilityId: availabilityId,
        equipmentIds: selectedEquipmentIds,
      );
    }

    final result = await BookingApiService().createBooking(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      final createdBooking = result['booking'] as BookingResponseDTO?;
      final bookingId = createdBooking?.bookingId;
      if (bookingId == null || bookingId.isEmpty) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Đặt lịch thất bại'),
          description: const Text('Backend không trả về mã đơn đặt chỗ hợp lệ.'),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: false,
        );
        return;
      }

      final newSchedule = BookingSchedule(
        id: bookingId,
        item: widget.item,
        bookingDate: _selectedDate,
        timeSlot: '${slot['slot']} ($hours giờ)',
        totalPrice: createdBooking != null && createdBooking.totalAmount > 0
            ? createdBooking.totalAmount
            : totalPrice,
        status: BookingStatus.confirmed,
      );
      BookingSchedule.sampleSchedules.insert(0, newSchedule);

      if (_selectedSubscription != null ||
          createdBooking?.depositStatus.toUpperCase() == 'NOT_REQUIRED') {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          title: const Text('Đặt lịch theo gói thành công!'),
          description: const Text(
            'Đơn đặt lịch của bạn đã được xác nhận ngay từ Gói Subscription.',
          ),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: false,
        );
        Navigator.pop(context);
        return;
      }

      final amountToPay =
          (createdBooking != null && createdBooking.depositAmount > 0)
              ? createdBooking.depositAmount
              : totalPrice;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            bookingId: bookingId,
            item: widget.item,
            totalAmount: amountToPay,
            bookingDate: _selectedDate,
            timeSlot: '${slot['slot']} ($hours giờ)',
          ),
        ),
      );
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Đặt lịch thất bại'),
        description: Text(result['message'] ?? 'Không thể tạo đơn đặt chỗ.'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
      );
    }
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
                _buildStepIndicator(0, 'Ngày & Giờ'),
                _buildStepDivider(),
                _buildStepIndicator(1, 'Dịch vụ thêm'),
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
                _buildStep2DateTime(),
                _buildStep1Addons(),
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
                  : Text(
                '${step + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Trang thiết bị đi kèm',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_isLoadingEquipment)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else if (_hasLoadedLiveEquipment && _liveEquipment.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_liveEquipment.length} thiết bị sẵn sàng',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          'Chọn thêm các trang thiết bị của không gian này để đính kèm trực tiếp vào đơn đặt chỗ.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        if (_hasLoadedLiveEquipment &&
            _liveEquipment.isEmpty &&
            widget.item.id.trim().length >= 32)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Không gian này hiện chưa cấu hình thiết bị riêng trên máy chủ. Đang hiển thị phụ kiện tiêu chuẩn.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ..._availableAddons.map((addon) {
          final isSelected = _selectedAddons.contains(addon['name']);
          final category = addon['category']?.toString() ?? '';
          final variant = addon['variant']?.toString() ?? '';
          final description = addon['description']?.toString() ?? '';
          final quantityTotal = (addon['quantityTotal'] as num?)?.toInt();
          final availabilityCount =
              _equipmentAvailabilityCounts[addon['equipmentId']];
          final isPerHour = addon['isPerHour'] == true;
          final priceStr = NumberFormat.currency(locale: 'vi', symbol: 'đ')
              .format(addon['price']);

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
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.cardBg,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      addon['icon'],
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon['name'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (availabilityCount != null &&
                            availabilityCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$availabilityCount slot trống',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                        if (category.isNotEmpty || variant.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              if (variant.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    variant,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              if (quantityTotal != null && quantityTotal > 0)
                                Text(
                                  '• SL: $quantityTotal',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          isPerHour ? '+$priceStr / giờ' : '+$priceStr',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
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
    final slots = _timeSlots;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Thời gian đặt chỗ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 24),
        const Text(
          'Chọn Ngày',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
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
              setState(() {
                _selectedDate = picked;
                _selectedTimeSlotIndex = 0;
                _equipmentRequestGeneration++;
                _equipmentAvailabilityCounts.clear();
              });
              final nextSlots = _timeSlots;
              if (nextSlots.isNotEmpty) {
                final availId =
                    nextSlots.first['availabilityId']?.toString() ?? '';
                if (availId.length >= 32) {
                  _refreshEquipmentForAvailabilitySlot(availId);
                }
              }
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 28),
        const Text(
          'Chọn Khung Giờ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Không có khung giờ trống cho ngày này',
                style: TextStyle(
                  color: AppColors.textSecondary,
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
              final isSelected = _selectedTimeSlotIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTimeSlotIndex = index);
                  final availId = slot['availabilityId']?.toString() ?? '';
                  if (availId.length >= 32) {
                    _refreshEquipmentForAvailabilitySlot(availId);
                  }
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
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
    final slots = _timeSlots;
    if (slots.isEmpty) {
      return const Center(
        child: Text(
          'Không có khung giờ trống cho ngày đã chọn',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }
    final safeIndex =
    _selectedTimeSlotIndex < slots.length ? _selectedTimeSlotIndex : 0;
    final slot = slots[safeIndex];
    final hours = slot['hours'] as int;
    final durationHours = slot['durationHours'] as double;
    final basePrice = _calculateBasePrice(slot, durationHours);
    final addonPrice = _calculateAddonPrice(durationHours);
    final totalPrice = basePrice + addonPrice;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Tổng quan Đơn đặt',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
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
              Text(
                widget.item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} • ${slot['slot']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Phí thuê cơ bản',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'vi', symbol: 'đ')
                        .format(basePrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_selectedAddons.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Thiết bị đi kèm:',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ..._selectedAddons.map((name) {
                  final addon =
                      _availableAddons.firstWhere((a) => a['name'] == name);
                  final unitPrice = (addon['price'] as num).toDouble();
                  final isPerHour = addon['isPerHour'] == true;
                  final lineTotal =
                      isPerHour ? unitPrice * durationHours : unitPrice;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isPerHour ? '• $name (x${hours}h)' : '• $name',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'vi', symbol: 'đ')
                              .format(lineTotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        if (_matchingSubscriptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.card_membership_rounded,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn có Gói Subscription áp dụng cho phòng này',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                    Switch(
                      value: _selectedSubscription != null,
                      activeThumbColor: Colors.green.shade700,
                      onChanged: (val) {
                        setState(() {
                          _selectedSubscription =
                              val ? _matchingSubscriptions.first : null;
                        });
                      },
                    ),
                  ],
                ),
                if (_selectedSubscription != null)
                  Text(
                    'Đang áp dụng: ${_selectedSubscription!.packageName} (Còn ${_selectedSubscription!.remainingUsesThisPeriod} lượt dùng • Miễn đặt cọc)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSubscription != null
                    ? 'Sử dụng Gói Subscription'
                    : 'Tổng thanh toán',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _selectedSubscription != null
                    ? '0đ (-1 lượt)'
                    : NumberFormat.currency(locale: 'vi', symbol: 'đ')
                        .format(totalPrice),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: PrimaryButton(
          text: _currentStep < 2 ? 'Tiếp tục' : 'Xác nhận & Sang thanh toán',
          isLoading: _isSubmitting,
          onPressed: _nextStep,
        ),
      ),
    );
  }
}