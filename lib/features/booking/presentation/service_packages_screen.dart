import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_api_models.dart';
import '../models/service_package.dart';
import '../services/booking_api_service.dart';
import 'payment_screen.dart';

class ServicePackagesScreen extends StatefulWidget {
  const ServicePackagesScreen({super.key});

  @override
  State<ServicePackagesScreen> createState() => _ServicePackagesScreenState();
}

class _ServicePackagesScreenState extends State<ServicePackagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final BookingApiService _apiService = BookingApiService();

  bool _isLoadingPackages = true;
  bool _isLoadingSubscriptions = true;
  bool _packagesError = false;
  bool _subscriptionsError = false;

  List<ServicePackage> _packages = [];
  List<PhotographerPackageSubscriptionResponseDTO> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchPackages(),
      _fetchSubscriptions(),
    ]);
  }

  Future<void> _fetchPackages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPackages = true;
      _packagesError = false;
    });

    try {
      final apiDtos = await _apiService.getServicePackages();
      if (!mounted) return;

      setState(() {
        _packages = apiDtos.map(ServicePackage.fromDto).toList();
        _isLoadingPackages = false;
      });
    } catch (e) {
      debugPrint('Không thể tải gói dịch vụ: $e');
      if (!mounted) return;
      setState(() {
        _packages = [];
        _packagesError = true;
        _isLoadingPackages = false;
      });
    }
  }

  Future<void> _fetchSubscriptions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSubscriptions = true;
      _subscriptionsError = false;
    });

    try {
      final subs = await _apiService.getPackageSubscriptions();
      if (!mounted) return;
      setState(() {
        _subscriptions = subs;
        _isLoadingSubscriptions = false;
      });
    } catch (e) {
      debugPrint('Không thể tải gói đã đăng ký: $e');
      if (!mounted) return;
      setState(() {
        _subscriptions = [];
        _subscriptionsError = true;
        _isLoadingSubscriptions = false;
      });
    }
  }

  String _formatCurrency(num value) {
    return '${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return DateFormat('dd/MM/yyyy').format(local);
  }

  Future<void> _handlePurchasePackage(ServicePackage pkg) async {
    NotificationService().triggerLocalNotification(
      context: context,
      title: 'Khởi Tạo Mua Gói Dịch Vụ! 📦',
      body: 'Combo ${pkg.name} đã được chọn. Chuyển sang thanh toán VNPay.',
      route: '/payment',
    );

    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          packageId: pkg.id,
          customItemName: pkg.name,
          totalAmount: pkg.price,
          timeSlot: pkg.durationText,
        ),
      ),
    );

    if (mounted) {
      await _fetchSubscriptions();
      if (paid == true && mounted) {
        _tabController.animateTo(1);
      }
    }
  }

  Future<void> _showSubscriptionDetailModal(
      PhotographerPackageSubscriptionResponseDTO sub) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final detailed =
        await _apiService.getPackageSubscriptionDetail(sub.subscriptionId) ??
            sub;

    if (!mounted) return;
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: SingleChildScrollView(
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
                        detailed.packageName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ),
                    _buildStatusChip(detailed.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Nhà cung cấp: ${detailed.providerName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecColor,
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow('Mã Subscription:', detailed.subscriptionId),
                _buildInfoRow(
                  'Hiệu lực:',
                  '${_formatDate(detailed.startsAt)} - ${_formatDate(detailed.endsAt)}',
                ),
                _buildInfoRow(
                  'Kỳ hiện tại:',
                  '${_formatDate(detailed.usagePeriodStart)} - ${_formatDate(detailed.usagePeriodEnd)}',
                ),
                _buildInfoRow(
                  'Số lượt sử dụng/tháng:',
                  '${detailed.usesPerMonth} lượt',
                ),
                _buildInfoRow(
                  'Đã dùng / Đang giữ chỗ:',
                  '${detailed.usedThisPeriod} / ${detailed.reservedThisPeriod} lượt',
                ),
                _buildInfoRow(
                  'Số lượt còn lại kỳ này:',
                  '${detailed.remainingUsesThisPeriod} lượt',
                  highlight: true,
                ),
                if (detailed.items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Chi tiết các bước trong Gói:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detailed.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.inputColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              '${item.stepOrder}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '[${item.componentType}] ${item.resourceName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: context.textColor,
                                  ),
                                ),
                                if (item.includedDurationMinutes != null)
                                  Text(
                                    'Thời lượng: ${item.includedDurationMinutes} phút • SL: ${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (detailed.status.toUpperCase() == 'ACTIVE' &&
                    detailed.remainingUsesThisPeriod > 0)
                  PrimaryButton(
                    text: 'ĐẶT LỊCH SỬ DỤNG GÓI NGAY',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showRedeemSubscriptionSheet(detailed);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Slot phòng chỉ hợp lệ khi mỗi nhóm thiết bị của bước đều có lịch phủ trọn khung giờ đó.
  bool _isRoomSlotCoveredByEquipment(
    ProviderSpaceAvailabilityResponseDTO slot,
    List<List<PhotographerEquipmentAvailabilityResponseDTO>> equipmentAvailability,
  ) {
    final roomStart = _combineDateAndTime(slot.date, slot.startTime);
    final roomEnd = _combineDateAndTime(slot.date, slot.endTime);
    if (roomStart == null || roomEnd == null) return false;

    return equipmentAvailability.every((availabilities) => availabilities.any((a) {
          final start = a.startAt;
          final end = a.endAt;
          if (start == null || end == null) return false;
          return !_wallClock(start).isAfter(roomStart) &&
              !_wallClock(end).isBefore(roomEnd);
        }));
  }

  /// So sánh theo giờ hiển thị (bỏ múi giờ) vì backend trả DateOnly/TimeOnly cho phòng.
  DateTime _wallClock(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

  DateTime? _combineDateAndTime(String date, String time) {
    final day = DateTime.tryParse(date.length >= 10 ? date.substring(0, 10) : date);
    final parts = time.split(':');
    if (day == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? int.tryParse(parts[2].split('.').first) ?? 0 : 0;
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute, second);
  }

  Future<void> _showRedeemSubscriptionSheet(
      PhotographerPackageSubscriptionResponseDTO sub) async {
    // Group items by stepOrder
    final stepNumbers = sub.items.map((e) => e.stepOrder).toSet().toList()
      ..sort();
    if (stepNumbers.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        title: const Text('Gói chưa có cấu hình bước'),
        description: const Text(
          'Gói đăng ký này chưa có danh sách phòng hoặc thiết bị để đặt lịch.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final Map<int, List<ProviderSpaceAvailabilityResponseDTO>> stepSlots = {};
    final Map<int, String?> selectedAvailabilityByStep = {};
    final Map<int, List<String>> equipmentIdsByStep = {};

    for (final step in stepNumbers) {
      final stepItems = sub.items.where((i) => i.stepOrder == step).toList();
      final roomItem = stepItems.firstWhere(
        (i) =>
            i.componentType.toUpperCase() == 'STUDIO' ||
            i.componentType.toUpperCase() == 'DARKROOM',
        orElse: () => stepItems.first,
      );
      final equipItems = stepItems
          .where((i) => i.componentType.toUpperCase() == 'EQUIPMENT')
          .map((e) => e.resourceId)
          .where((id) => id.isNotEmpty)
          .toList();

      equipmentIdsByStep[step] = equipItems;

      final equipAvailability = <String, List<PhotographerEquipmentAvailabilityResponseDTO>>{};
      for (final eqId in equipItems) {
        equipAvailability[eqId] =
            await _apiService.getEquipmentAvailability(equipmentId: eqId);
      }

      final roomSlots = await _apiService.getAvailableSlots(
        spaceId: roomItem.resourceId,
      );
      // Backend chỉ nhận slot phòng mà mọi thiết bị của bước đều có lịch phủ trọn khung giờ đó
      final slots = equipItems.isEmpty
          ? roomSlots
          : roomSlots
              .where((slot) => _isRoomSlotCoveredByEquipment(
                    slot,
                    equipItems.map((id) => equipAvailability[id] ?? const []).toList(),
                  ))
              .toList();
      stepSlots[step] = slots;
      selectedAvailabilityByStep[step] =
          slots.isNotEmpty ? slots.first.availabilityId : null;
    }

    if (!mounted) return;
    Navigator.pop(context);

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
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
                  Text(
                    'Đặt Lịch Từ Gói: ${sub.packageName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn khung giờ trống cho từng bước trong gói (Miễn phí đặt cọc - Trừ 1 lượt dùng).',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...stepNumbers.map((step) {
                    final stepItems =
                        sub.items.where((i) => i.stepOrder == step).toList();
                    final roomItem = stepItems.firstWhere(
                      (i) =>
                          i.componentType.toUpperCase() == 'STUDIO' ||
                          i.componentType.toUpperCase() == 'DARKROOM',
                      orElse: () => stepItems.first,
                    );
                    final slots = stepSlots[step] ?? [];
                    final selectedId = selectedAvailabilityByStep[step];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.inputColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bước $step: ${roomItem.resourceName} (${roomItem.componentType})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (slots.isEmpty)
                            Text(
                              equipmentIdsByStep[step]?.isNotEmpty ?? false
                                  ? 'Không có khung giờ nào còn đủ phòng và thiết bị cho bước này.'
                                  : 'Hiện chưa có khung giờ trống cho phòng này.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: selectedId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: context.inputColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: slots.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s.availabilityId,
                                  child: Text(
                                    '${s.date} • ${s.startTime} - ${s.endTime}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedAvailabilityByStep[step] = val;
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'XÁC NHẬN ĐẶT LỊCH THEO GÓI',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final segments = <PackageBookingSegmentRequestDTO>[];
                      for (final step in stepNumbers) {
                        final availId = selectedAvailabilityByStep[step];
                        if (availId == null || availId.isEmpty) {
                          toastification.show(
                            context: context,
                            type: ToastificationType.warning,
                            style: ToastificationStyle.flatColored,
                            title: const Text('Thiếu khung giờ'),
                            description: Text(
                              'Vui lòng chọn khung giờ hợp lệ cho Bước $step.',
                            ),
                            alignment: Alignment.topCenter,
                            autoCloseDuration: const Duration(seconds: 3),
                            showProgressBar: false,
                          );
                          return;
                        }
                        segments.add(
                          PackageBookingSegmentRequestDTO(
                            stepOrder: step,
                            availabilityId: availId,
                            equipmentIds: equipmentIdsByStep[step] ?? const [],
                          ),
                        );
                      }

                      setModalState(() => isSubmitting = true);
                      final result = await _apiService.createPackageBooking(
                        subscriptionId: sub.subscriptionId,
                        segments: segments,
                      );
                      if (!ctx.mounted) return;
                      setModalState(() => isSubmitting = false);

                      if (result['success'] == true) {
                        Navigator.pop(ctx);
                        await _fetchSubscriptions();
                        if (!mounted) return;
                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          style: ToastificationStyle.flatColored,
                          title: const Text('Đặt lịch theo gói thành công!'),
                          description: const Text(
                            'Đơn đặt lịch đã được xác nhận ngay mà không cần đặt cọc.',
                          ),
                          alignment: Alignment.topCenter,
                          autoCloseDuration: const Duration(seconds: 4),
                          showProgressBar: false,
                        );
                      } else {
                        if (!mounted) return;
                        toastification.show(
                          context: context,
                          type: ToastificationType.error,
                          style: ToastificationStyle.flatColored,
                          title: const Text('Đặt lịch theo gói thất bại'),
                          description: Text(
                            result['message']?.toString() ??
                                'Không thể tạo đơn đặt lịch theo gói.',
                          ),
                          alignment: Alignment.topCenter,
                          autoCloseDuration: const Duration(seconds: 4),
                          showProgressBar: false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecColor,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.primary : context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final upper = status.toUpperCase();
    Color bg = AppColors.primary.withValues(alpha: 0.12);
    Color fg = AppColors.primary;
    String label = status;

    if (upper == 'ACTIVE') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = 'Đang hoạt động';
    } else if (upper == 'PENDING_PAYMENT') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      label = 'Chờ thanh toán';
    } else if (upper == 'EXPIRED' || upper == 'CANCELLED') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = upper == 'EXPIRED' ? 'Hết hạn' : 'Đã hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Gói Dịch Vụ & Subscription'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecColor,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Gói Combo (${_packages.length})'),
            Tab(text: 'Gói Đã Đăng Ký (${_subscriptions.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPackagesTab(),
            _buildSubscriptionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesTab() {
    if (_isLoadingPackages) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_packagesError || _packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_packagesError
                ? 'Không thể tải gói dịch vụ.'
                : 'Hiện chưa có gói dịch vụ khả dụng.'),
            TextButton(onPressed: _fetchPackages, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchPackages,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          final pkg = _packages[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SafeNetworkImage(
                      url: pkg.imageUrl,
                      height: 160,
                      width: double.infinity,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    if (pkg.isPopular)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'COMBO BÁN CHẠY NHẤT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              pkg.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            pkg.durationText,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pkg.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pkg.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Gói dịch vụ bao gồm:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pkg.includes.map(
                        (inc) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  inc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatCurrency(pkg.price),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(
                            width: 155,
                            child: PrimaryButton(
                              text: 'MUA GÓI COMBO',
                              onPressed: () => _handlePurchasePackage(pkg),
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
        },
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    if (_isLoadingSubscriptions) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_subscriptionsError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không thể tải gói đã đăng ký.'),
            TextButton(
              onPressed: _fetchSubscriptions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchSubscriptions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.card_membership_rounded,
              size: 68,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa có gói dịch vụ nào đã đăng ký',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy chọn mua một Gói Combo ở tab bên cạnh để tiết kiệm chi phí thuê Studio, Phòng tối và Thiết bị hàng tháng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'KHÁM PHÁ GÓI COMBO',
              onPressed: () => _tabController.animateTo(0),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final sub = _subscriptions[index];
          final canBook = sub.status.toUpperCase() == 'ACTIVE' &&
              sub.remainingUsesThisPeriod > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sub.packageName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ),
                    _buildStatusChip(sub.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sub.providerName,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecColor,
                  ),
                ),
                const Divider(height: 22),
                _buildInfoRow(
                  'Hạn sử dụng:',
                  '${_formatDate(sub.startsAt)} - ${_formatDate(sub.endsAt)}',
                ),
                _buildInfoRow(
                  'Lượt dùng trong kỳ:',
                  'Đã dùng ${sub.usedThisPeriod}/${sub.usesPerMonth} (Còn ${sub.remainingUsesThisPeriod} lượt)',
                  highlight: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showSubscriptionDetailModal(sub),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Chi Tiết Gói',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (canBook) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showRedeemSubscriptionSheet(sub),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Đặt Lịch Theo Gói',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
