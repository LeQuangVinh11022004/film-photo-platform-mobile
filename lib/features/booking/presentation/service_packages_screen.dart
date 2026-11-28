import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';
import '../models/service_package.dart';
import '../services/booking_api_service.dart';
import '../widgets/service_package_card.dart';
import '../widgets/service_redeem_subscription_sheet.dart';
import '../widgets/service_subscription_card.dart';
import '../widgets/service_subscription_detail_sheet.dart';
import '../widgets/service_subscription_empty_state.dart';
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
    PhotographerPackageSubscriptionResponseDTO sub,
  ) async {
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

    await showServiceSubscriptionDetailSheet(
      context: context,
      detailed: detailed,
      formatDate: _formatDate,
      onRedeemPressed: () => _showRedeemSubscriptionSheet(detailed),
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
    final day =
        DateTime.tryParse(date.length >= 10 ? date.substring(0, 10) : date);
    final parts = time.split(':');
    if (day == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second =
        parts.length > 2 ? int.tryParse(parts[2].split('.').first) ?? 0 : 0;
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute, second);
  }

  Future<void> _showRedeemSubscriptionSheet(
    PhotographerPackageSubscriptionResponseDTO sub,
  ) async {
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

      final equipAvailability =
          <String, List<PhotographerEquipmentAvailabilityResponseDTO>>{};
      for (final eqId in equipItems) {
        equipAvailability[eqId] =
            await _apiService.getEquipmentAvailability(equipmentId: eqId);
      }

      final roomSlots = await _apiService.getAvailableSlots(
        spaceId: roomItem.resourceId,
      );
      final slots = equipItems.isEmpty
          ? roomSlots
          : roomSlots
              .where((slot) => _isRoomSlotCoveredByEquipment(
                    slot,
                    equipItems
                        .map((id) => equipAvailability[id] ?? const [])
                        .toList(),
                  ))
              .toList();
      stepSlots[step] = slots;
      selectedAvailabilityByStep[step] =
          slots.isNotEmpty ? slots.first.availabilityId : null;
    }

    if (!mounted) return;
    Navigator.pop(context);

    final redeemed = await showServiceRedeemSubscriptionSheet(
      context: context,
      subscription: sub,
      stepNumbers: stepNumbers,
      stepSlots: stepSlots,
      initialSelectedAvailabilityByStep: selectedAvailabilityByStep,
      equipmentIdsByStep: equipmentIdsByStep,
      apiService: _apiService,
    );

    if (redeemed == true && mounted) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('Gói Dịch Vụ & Subscription'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecColor,
          indicatorColor: AppColors.primary,
          dividerColor: context.borderColor,
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
            Text(
              _packagesError
                  ? 'Không thể tải gói dịch vụ.'
                  : 'Hiện chưa có gói dịch vụ khả dụng.',
              style: TextStyle(color: context.textSecColor),
            ),
            TextButton(
              onPressed: _fetchPackages,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: context.cardColor,
      onRefresh: _fetchPackages,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          final pkg = _packages[index];
          return ServicePackageCard(
            package: pkg,
            formattedPrice: _formatCurrency(pkg.price),
            onPurchase: () => _handlePurchasePackage(pkg),
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
            Text(
              'Không thể tải gói đã đăng ký.',
              style: TextStyle(color: context.textSecColor),
            ),
            TextButton(
              onPressed: _fetchSubscriptions,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return ServiceSubscriptionEmptyState(
        onRefresh: _fetchSubscriptions,
        onExplorePressed: () => _tabController.animateTo(0),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: context.cardColor,
      onRefresh: _fetchSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final sub = _subscriptions[index];
          return ServiceSubscriptionCard(
            subscription: sub,
            validityText:
                '${_formatDate(sub.startsAt)} - ${_formatDate(sub.endsAt)}',
            onDetailTap: () => _showSubscriptionDetailModal(sub),
            onRedeemTap: () => _showRedeemSubscriptionSheet(sub),
          );
        },
      ),
    );
  }
}
