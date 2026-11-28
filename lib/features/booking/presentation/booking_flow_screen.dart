import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/booking_api_service.dart';
import '../widgets/booking_flow_addons_step.dart';
import '../widgets/booking_flow_checkout_step.dart';
import '../widgets/booking_flow_date_time_step.dart';
import '../widgets/booking_flow_step_header.dart';
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
    final sourceSlots = _liveAvailableSlots;
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
    _liveAvailableSlots =
        List<Map<String, dynamic>>.from(widget.item.availableSlots);
    _initAddons();
    _initSelectedDate();
    _syncLiveSlotsSubscriptionsAndEquipment(isInitial: true);
  }

  String get _resolvedSpaceId {
    if (widget.item.category == BookingCategory.equipment &&
        widget.item.parentSpaceId != null &&
        widget.item.parentSpaceId!.trim().isNotEmpty) {
      return widget.item.parentSpaceId!.trim();
    }
    return widget.item.id.trim();
  }

  Future<void> _syncLiveSlotsSubscriptionsAndEquipment({
    bool isInitial = false,
  }) async {
    final spaceId = _resolvedSpaceId;
    if (spaceId.length < 32) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    setState(() => _isLoadingEquipment = true);

    try {
      var subscriptionsFailed = false;
      final results = await Future.wait([
        BookingApiService().getAvailableSlots(spaceId: spaceId),
        BookingApiService().getPackageSubscriptions().catchError((Object e) {
          debugPrint('Không thể tải gói đã đăng ký: $e');
          subscriptionsFailed = true;
          return <PhotographerPackageSubscriptionResponseDTO>[];
        }),
        BookingApiService().getEquipmentForSpace(
          spaceId: spaceId,
          page: 1,
          pageSize: 50,
        ),
      ]);

      if (!mounted) return;
      if (subscriptionsFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể tải gói đã đăng ký. Bạn vẫn có thể đặt lịch thông thường.',
            ),
          ),
        );
      }

      final apiSlots = results[0] as List<ProviderSpaceAvailabilityResponseDTO>;
      final apiSubs =
          results[1] as List<PhotographerPackageSubscriptionResponseDTO>;
      final equipPage =
          results[2] as PagedResponseDTO<PhotographerEquipmentResponseDTO>?;

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
      if (isInitial &&
          widget.item.availableSlots.isEmpty &&
          converted.isNotEmpty) {
        _initSelectedDateFromSource(converted);
      }

      if (equipPage != null) {
        _applyLiveEquipmentList(equipPage.items);
      }

      final currentSlots = _timeSlots;
      if (_selectedTimeSlotIndex >= currentSlots.length) {
        setState(() {
          _selectedTimeSlotIndex = 0;
        });
      }
      if (currentSlots.isNotEmpty) {
        final safeIdx =
            _selectedTimeSlotIndex < currentSlots.length ? _selectedTimeSlotIndex : 0;
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
    } catch (e) {
      debugPrint('Không thể đồng bộ dữ liệu đặt lịch: $e');
      if (mounted) {
        setState(() => _liveAvailableSlots = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải dữ liệu đặt lịch. Vui lòng thử lại.'),
          ),
        );
      }
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
      final validNames = mapped.map((m) => m['name'] as String).toSet();
      _selectedAddons.removeWhere((name) => !validNames.contains(name));
      if (widget.item.category == BookingCategory.equipment) {
        for (final m in mapped) {
          if (m['equipmentId']?.toString().toLowerCase() ==
                  widget.item.id.trim().toLowerCase() &&
              !_selectedAddons.contains(m['name'])) {
            _selectedAddons.add(m['name'] as String);
          }
        }
      }
    });
  }

  /// Gọi GET /api/photographer/spaces/{spaceId}/equipment?availabilityId={availabilityId}
  /// và GET /api/photographer/equipment/{equipmentId}/availability để đồng bộ thiết bị trống theo khung giờ
  Future<void> _refreshEquipmentForAvailabilitySlot(
    String availabilityId,
  ) async {
    final spaceId = _resolvedSpaceId;
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
    if (widget.item.id.trim().length >= 32) {
      _availableAddons = [];
      return;
    }
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
    if (_isLoadingEquipment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải dữ liệu đặt lịch, vui lòng chờ.'),
        ),
      );
      return;
    }
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
        (i) => i.resourceId.toLowerCase() == _resolvedSpaceId.toLowerCase(),
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
    final slots = _timeSlots;
    final selectedSlot = slots.isEmpty
        ? null
        : slots[_selectedTimeSlotIndex < slots.length
            ? _selectedTimeSlotIndex
            : 0];
    final durationHours =
        (selectedSlot?['durationHours'] as double?) ?? 1.0;
    final basePrice = selectedSlot == null
        ? 0.0
        : _calculateBasePrice(selectedSlot, durationHours);
    final totalPrice = basePrice + _calculateAddonPrice(durationHours);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: _prevStep,
        ),
        title: const Text('Tiến trình Đặt chỗ'),
        bottom: BookingFlowStepHeader(currentStep: _currentStep),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BookingFlowDateTimeStep(
                  selectedDate: _selectedDate,
                  slots: slots,
                  selectedTimeSlotIndex: _selectedTimeSlotIndex,
                  onRefresh: _syncLiveSlotsSubscriptionsAndEquipment,
                  onDateSelected: (picked) {
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
                  },
                  onSlotSelected: (index) {
                    setState(() => _selectedTimeSlotIndex = index);
                    final availId =
                        slots[index]['availabilityId']?.toString() ?? '';
                    if (availId.length >= 32) {
                      _refreshEquipmentForAvailabilitySlot(availId);
                    }
                  },
                ),
                BookingFlowAddonsStep(
                  itemId: widget.item.id,
                  isLoadingEquipment: _isLoadingEquipment,
                  hasLoadedLiveEquipment: _hasLoadedLiveEquipment,
                  liveEquipmentCount: _liveEquipment.length,
                  availableAddons: _availableAddons,
                  selectedAddons: _selectedAddons,
                  equipmentAvailabilityCounts: _equipmentAvailabilityCounts,
                  onRefresh: _syncLiveSlotsSubscriptionsAndEquipment,
                  onToggleAddon: (name) {
                    setState(() {
                      if (_selectedAddons.contains(name)) {
                        _selectedAddons.remove(name);
                      } else {
                        _selectedAddons.add(name);
                      }
                    });
                  },
                ),
                BookingFlowCheckoutStep(
                  itemName: widget.item.name,
                  selectedDate: _selectedDate,
                  selectedSlot: selectedSlot,
                  basePrice: basePrice,
                  totalPrice: totalPrice,
                  selectedAddons: _selectedAddons,
                  availableAddons: _availableAddons,
                  matchingSubscriptions: _matchingSubscriptions,
                  selectedSubscription: _selectedSubscription,
                  onRefresh: _syncLiveSlotsSubscriptionsAndEquipment,
                  onSubscriptionToggled: (val) {
                    setState(() {
                      _selectedSubscription =
                          val ? _matchingSubscriptions.first : null;
                    });
                  },
                ),
              ],
            ),
          ),
          BookingFlowBottomBar(
            currentStep: _currentStep,
            isSubmitting: _isSubmitting,
            onNextPressed: _nextStep,
          ),
        ],
      ),
    );
  }
}
